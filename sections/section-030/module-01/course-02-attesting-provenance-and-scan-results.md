# Attesting Provenance And Scan Results

A predicate file on a build machine helps nobody downstream. It has to be signed, tied to the image digest, and stored where a verifier will look. This part attaches the provenance and the scan to the current release with `cosign attest`, verifies each by its type, and reads the statement back.

## Attach the two attestations

Set the usual values, create a release key pair, and find the digest of the release:

<!-- astrona:playground:renew -->

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
mkdir -p /work/keys && cd /work/keys && cosign generate-key-pair --output-key-prefix release && cd /work
DIGEST=$(regctl image digest $REPO:6.15.0)
```

`cosign attest` takes the predicate file, the type and the key, and attaches the signed statement to the image. Attest the provenance as SLSA v1 and the scan as `vuln`:

```sh
cosign attest --key /work/keys/release.key --signing-config $SC --allow-http-registry -y \
  --type slsaprovenance1 --predicate /work/predicates/provenance.json $REPO@$DIGEST
cosign attest --key /work/keys/release.key --signing-config $SC --allow-http-registry -y \
  --type vuln --predicate /work/predicates/vuln.json $REPO@$DIGEST
```

For each command, cosign checks the predicate against its type, builds the in-toto statement with the digest as its subject, signs it with the release key, and pushes it to the registry as a referrer of the image. `cosign tree --allow-http-registry $REPO@$DIGEST` now lists two attestations.

## Verify by type

`cosign verify-attestation` works like `cosign verify`, with one more question: which type of attestation do you want? `--type` takes the same short names:

```sh
cosign verify-attestation --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry \
  --type slsaprovenance1 $REPO@$DIGEST > /tmp/provenance.out
```

cosign finds the attestations of the image, checks each signature with the public key, keeps the ones whose `predicateType` matches, and prints them. Ask for a type the image does not have, for example `--type cyclonedx`, and cosign fails with a message that lists the types it did find. That message is useful when a check fails because of a wrong type.

## Read the statement

Each line cosign prints is a signed envelope in JSON. Its `payload` field is the statement, base64-encoded. Decode it and read the fields you care about:

```sh
jq -r '.payload' /tmp/provenance.out | head -1 | base64 -d | jq '{type: .predicateType, subject: .subject, builder: .predicate.runDetails.builder.id}'
```

The statement names the image digest as its subject, the SLSA v1 predicate type, and the release builder. The same steps for the scan show its scanner and findings:

```sh
cosign verify-attestation --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry \
  --type vuln $REPO@$DIGEST | jq -r '.payload' | head -1 | base64 -d | jq '.predicate.scanner.uri'
```

Verification proves two things at once: the statement was signed by the release key, and it is about this exact digest. It does not judge the content; a scan full of critical findings verifies just as well as a clean one.

You can now attach provenance and scan results to an image and read them back after verification. The open question is how to reject an attestation whose content is not good enough, without reading every one by hand.

## Common pitfalls

> [!WARNING]
> - **Attesting a tag.** Attest the digest you checked, so the statement's subject is the image you mean.
> - **Forgetting `--type` when verifying.** Without it, cosign looks for the `custom` type, which may not be there.
> - **Reading `payload` without decoding.** It is base64. Decode it before you look for fields.
> - **Thinking a verified attestation is a good one.** Verification checks who signed it and for which digest, not what it says.

## Your mission: Attach Provenance And Vulnerability Attestations

You can now attest provenance and scan results and verify them by type. The graded lab gives you the release key and the two predicates, and asks you to attach both to the current release only.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-119-playground-030-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS119.git -c sections/section-030/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-119-lab-030-01
astrona start ats-119-playground-030-01
```
