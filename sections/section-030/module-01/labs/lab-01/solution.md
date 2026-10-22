# Solution: Attach Provenance And Vulnerability Attestations

Work the task yourself first. Running `astrona submit -c sections/section-030/module-01/labs/lab-01` after a step tells you which checks pass.

The grader uses its own copy of the release public key. It verifies a `slsaprovenance1` and a `vuln` attestation on the 6.15.0 digest, reads the builder and the scanner from the statements, and checks that 6.14.1 has no attestation.

## Step 1: Set the values

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
DIGEST=$(regctl image digest $REPO:6.15.0)
```

## Step 2: Attach both attestations

```sh
cosign attest --key /work/keys/release.key --signing-config $SC --allow-http-registry -y \
  --type slsaprovenance1 --predicate /work/predicates/provenance.json $REPO@$DIGEST
cosign attest --key /work/keys/release.key --signing-config $SC --allow-http-registry -y \
  --type vuln --predicate /work/predicates/vuln.json $REPO@$DIGEST
```

The type decides the `predicateType` in each statement: `https://slsa.dev/provenance/v1` and `https://cosign.sigstore.dev/attestation/vuln/v1`.

## Step 3: Verify and read, the way the grader does

```sh
cosign verify-attestation --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry \
  --type slsaprovenance1 $REPO@$DIGEST | jq -r '.payload' | head -1 | base64 -d | jq -r '.predicate.runDetails.builder.id'
cosign verify-attestation --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry \
  --type vuln $REPO@$DIGEST | jq -r '.payload' | head -1 | base64 -d | jq -r '.predicate.scanner.uri'
```

The first prints the release builder, the second the Trivy package URL.

## Step 4: Submit

Leave the workstation shell with `exit`, and send the lab for grading from your own terminal:

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Attest the provenance with the default type | It becomes `custom`, and a check for `slsaprovenance1` does not find it |
| Use `slsaprovenance` instead of `slsaprovenance1` | That is SLSA v0.2, a different predicate type and format |
| Attest every tag in the repository | 6.14.1 gets attestations that describe a different build |
