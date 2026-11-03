# Reading Attestations In Scripts

Attestations are only useful when something reads them. A pipeline wants to answer questions such as "which tool made the SBOM?" or "who reviewed this release?" This part reads the predicate of verified attestations with `jq`, checks for a missing attestation and compares the old and the current release.

## Read a predicate

`cosign verify-attestation` verifies first, so what you read is signed. Decode the payload and select the predicate:

<!-- astrona:playground:renew -->

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
DIGEST=$(regctl image digest $REPO:6.15.0)
cosign verify-attestation --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry \
  --type https://inventory.example/attestations/review/v1 $REPO@$DIGEST \
  | jq -r '.payload' | base64 -d | jq '.predicate'
```

The output is the review record you attached. Because verification ran first, a consumer can rely on the signer. If the digest had no review attestation, the command would fail and print nothing to decode.

## A missing attestation is a failure

Run the same check on the old release:

```sh
OLD=$(regctl image digest $REPO:6.14.1)
cosign verify-attestation --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry \
  --type spdxjson $REPO@$OLD > /dev/null 2>&1 || echo "6.14.1 has no SBOM attestation"
```

The old release was never attested, so the check fails. In a release gate that is the intended result: only digests with the required attestations pass.

## Count components

A short script can answer a question about content. How many packages does the SBOM list?

```sh
cosign verify-attestation --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry \
  --type spdxjson $REPO@$DIGEST | jq -r '.payload' | base64 -d | jq '.predicate.packages | length'
```

The number equals the package count of the SBOM file. Comparing the two proves that the attestation carries the document you generated.

## Limits of reading with jq

Reading a predicate with `jq` tells a human what is inside. It does not enforce a rule. A script that prints the tool name does not fail when the tool is wrong. For enforcement, use `cosign verify-attestation --policy`, which fails the verification when the content does not meet a rule.

You now know how to attach, verify and read SBOM and custom attestations on an image. The graded lab asks you to attach both kinds of attestation to the current release and to keep the old release clean.


## Common pitfalls

> [!WARNING]
> - **Reading the file on disk instead of the verified attestation.** Only the verified payload is signed.
> - **Piping an unverified download into `jq`.** Always verify before you read.
> - **Ignoring exit status in scripts.** A failed verification must stop the pipeline.

## Your mission: Attach An SBOM And A Review Attestation

You can now generate an SBOM, attach it and a review record as attestations and read them back. The graded lab asks you to attest the current release with both and to leave the old release without an SBOM attestation.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-119-playground-030-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS119.git -c sections/section-030/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-119-lab-030-02
astrona start ats-119-playground-030-02
```
