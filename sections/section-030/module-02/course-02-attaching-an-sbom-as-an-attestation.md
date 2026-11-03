# Attaching An SBOM As An Attestation

An SBOM file on a workstation proves nothing to a consumer. To be useful it must be tied to the image digest and signed. `cosign attest` does both: it builds an in-toto statement whose subject is the image digest, signs it and attaches it to the image. This part attaches the SBOM and verifies it.

## Attach the SBOM

Create a key pair if you do not have one, then attest the SBOM with the type `spdxjson`:

<!-- astrona:playground:renew -->

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
mkdir -p /work/keys && cd /work/keys && cosign generate-key-pair --output-key-prefix release && cd /work
DIGEST=$(regctl image digest $REPO:6.15.0)
cosign attest -y --key /work/keys/release.key --signing-config $SC --allow-http-registry \
  --type spdxjson --predicate /work/sbom/podinfo-6.15.0.spdx.json $REPO@$DIGEST
```

cosign wraps the SBOM as the predicate of a statement and pushes the signed envelope to the registry as a referrer of the image. The command takes the image reference as its last argument. Use the digest.

## Check what is attached

```sh
cosign tree --allow-http-registry $REPO@$DIGEST
```

The tree now lists the attestation. A signature made with `cosign sign` and an attestation made with `cosign attest` are different referrers of the same digest. The first says "this key approves the image". The second says "this key states a fact about the image".

## Verify the attestation

Verify by type. The output has one line of JSON for each attestation of that type:

```sh
cosign verify-attestation --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry \
  --type spdxjson $REPO@$DIGEST | jq -r '.payload' | base64 -d | jq '{predicateType, subject}'
```

The `predicateType` is `https://spdx.dev/Document`, and the `subject` holds the image digest as `sha256`. The `payload` field is the statement, encoded in base64. The SBOM itself is in the `predicate` field of the statement.

## Why the digest is the subject

The statement names the image by digest. If someone moves a tag to another image, the attestation does not follow it. A verifier that resolves the tag gets the new digest, finds no matching attestation and fails. This is the same protection as for signatures.

You can now attach a signed SBOM to an image digest and verify it. The same command attaches facts that are not SBOMs, which the next part covers.


## Common pitfalls

> [!WARNING]
> - **Using `cosign sign` for an SBOM.** It signs the image, not a statement about it.
> - **Using the wrong `--type` when verifying.** A check for `vuln` does not see an SPDX attestation.
> - **Attesting the tag.** Attest the digest.
