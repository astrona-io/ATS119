# Solution: Attach An SBOM And A Review Attestation

Work the task yourself first. Running `astrona submit -c sections/section-030/module-02/labs/lab-01` after a step tells you which checks pass.

The grader verifies each attestation by its type with its own copy of the release public key and reads the predicate type from the statement. It also checks that 6.14.1 has no SPDX attestation.

## Step 1: Set the values and find the digest

Open a workstation shell and set the values the commands use:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
```

```sh
DIGEST=$(regctl image digest $REPO:6.15.0)
echo $DIGEST
```

## Step 2: Generate the SBOM and attach it

`syft scan` reads the image from the registry. The workstation already sets `SYFT_REGISTRY_INSECURE_USE_HTTP=true`, so `syft` talks plain HTTP to the lab registry. `-o spdx-json=<file>` writes the SPDX JSON format to a file:

```sh
syft scan registry:$REPO@$DIGEST -o spdx-json=/work/sbom/podinfo-6.15.0.spdx.json
cosign attest --key /work/keys/release.key --signing-config $SC --allow-http-registry -y \
  --type spdxjson --predicate /work/sbom/podinfo-6.15.0.spdx.json $REPO@$DIGEST
```

cosign wraps the SBOM in an in-toto statement whose subject is the image digest, signs the statement and attaches it to the image as a referrer.

## Step 3: Attach the review record

The review record uses a predicate type that cosign does not know by name, so `--type` takes the full URI:

```sh
cosign attest --key /work/keys/release.key --signing-config $SC --allow-http-registry -y \
  --type https://inventory.example/attestations/review/v1 \
  --predicate /work/predicates/review.json $REPO@$DIGEST
```

## Step 4: Verify, the way the grader does

Verify each attestation by its type and read the predicate type from the statement:

```sh
cosign verify-attestation --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry \
  --type spdxjson $REPO@$DIGEST | jq -r .payload | base64 -d | jq -r .predicateType
cosign verify-attestation --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry \
  --type https://inventory.example/attestations/review/v1 $REPO@$DIGEST | jq -r .payload | base64 -d | jq '.predicateType, .predicate'
```

The first command prints `https://spdx.dev/Document`. The second prints the review predicate type and the review record. Then confirm that the old release has no SBOM attestation:

```sh
cosign verify-attestation --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry \
  --type spdxjson $REPO@$(regctl image digest $REPO:6.14.1)
```

This one fails because no attestation of that type exists for the digest.

## Step 5: Submit

Leave the workstation shell with `exit`, and send the lab for grading from your own terminal:

```sh
astrona submit -c sections/section-030/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Sign the SBOM with `cosign sign-blob` | That makes a bundle on disk, not an attestation attached to the image |
| Attest the tag `6.14.1` as well | The old release gets an attestation it must not have |
| Use `--type custom` for the review record | The predicate type is the generic cosign type, not the inventory review URI the check looks for |
| Skip `--allow-http-registry` | cosign tries HTTPS against the plain-HTTP lab registry and fails |

## Common mistakes

- Giving `syft` the tag instead of the digest, so the SBOM describes whatever the tag points at when you run it.
- Forgetting that `--type` must match when verifying. A check with `--type vuln` does not see an SPDX attestation.
- Putting the predicate file in the `--type` option.
