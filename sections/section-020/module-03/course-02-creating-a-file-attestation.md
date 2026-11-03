# Creating A File Attestation

Creating an attestation for a file is one command. The work is in choosing the predicate and checking what cosign wrote. This part attests the archive from the previous part and decodes the bundle to read the statement that was signed.

## Create the attestation

`cosign attest-blob` computes the digest of the file, builds the statement, signs it and writes the bundle. You give it the predicate file and the predicate type. The type `custom` is for predicates that follow no standard format:

<!-- astrona:playground:renew -->

```sh
export COSIGN_PASSWORD=lab-only-password
SC=/setup/offline-signing-config.json
cd /work/rel
cosign attest-blob -y --key /work/keys/release.key --signing-config $SC \
  --type custom --predicate build.json --bundle tool-1.0.tar.gz.att.sigstore.json tool-1.0.tar.gz
```

The file is the last argument. `--predicate` is the file with the fact. The bundle name follows the convention of adding `.att.sigstore.json`, so a plain signature bundle and an attestation bundle can sit side by side.

## Read the statement back

The statement sits in the envelope as base64. Decode it with `jq` and `base64`:

```sh
jq -r '.dsseEnvelope.payload' tool-1.0.tar.gz.att.sigstore.json | base64 -d | jq .
```

The output has the three fields: `subject` with the name and the `sha256` digest of the archive, `predicateType` with the URI for `custom`, and `predicate` with the content of `build.json`. Compare the digest in the subject with `sha256sum tool-1.0.tar.gz`. They are equal.

```sh
jq -r '.dsseEnvelope.payload' tool-1.0.tar.gz.att.sigstore.json | base64 -d | jq -r '.subject[0].digest.sha256'
sha256sum tool-1.0.tar.gz
```

## What the predicate file must be

The predicate file must contain valid JSON. cosign puts it in the statement without changing it. A broken JSON file fails the command. Keep predicates small and factual: who built it, from which commit, when. Do not include data that changes every second, because every change needs a new signature.

## What the command does not do

`cosign attest-blob` does not upload anything and does not change the file. The bundle exists only where you wrote it. To share the attestation, you publish the bundle next to the file, in the same way as a signature bundle.

You can now create an attestation for a file and prove that its subject is the hash of the file. The next part verifies it the way a consumer does.


## Common pitfalls

> [!WARNING]
> - **Passing the predicate as the file.** The file to attest is the last argument; the predicate goes in `--predicate`.
> - **Forgetting `--type`.** Without it cosign uses `custom`, which may not be the type your consumers expect.
> - **Hand-editing the payload.** The signature covers the payload exactly; any edit breaks it.
