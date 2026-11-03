# Verifying A File Attestation

An attestation has value only when a consumer verifies it. For blobs, `cosign verify-blob-attestation` does the check. This part runs it, shows how it fails for a changed file and for the wrong predicate type, and explains why each check exists.

## Verify the attestation

The command takes the public key, the bundle, the predicate type and the file:

<!-- astrona:playground:renew -->

```sh
export COSIGN_PASSWORD=lab-only-password
SC=/setup/offline-signing-config.json
cd /work/rel
cosign verify-blob-attestation --key /work/keys/release.pub --insecure-ignore-tlog \
  --type custom --bundle tool-1.0.tar.gz.att.sigstore.json tool-1.0.tar.gz
```

It checks that the envelope signature is valid for the key, that the predicate type of the statement equals `--type`, and that the digest of the file you gave equals a digest in the subject. If all three hold, it prints `Verified OK`. `--insecure-ignore-tlog` is needed for the same reason as before: the bundle was made without a log.

## A changed file fails

Make a copy with one extra byte and verify it with the same bundle:

```sh
cp tool-1.0.tar.gz changed.tar.gz && printf 'x' >> changed.tar.gz
cosign verify-blob-attestation --key /work/keys/release.pub --insecure-ignore-tlog \
  --type custom --bundle tool-1.0.tar.gz.att.sigstore.json changed.tar.gz
```

Verification fails. The signature is valid, but the subject digest names the original archive. The attestation cannot be reused for another file.

## A wrong predicate type fails

Ask for a type that the statement does not have:

```sh
cosign verify-blob-attestation --key /work/keys/release.pub --insecure-ignore-tlog \
  --type slsaprovenance1 --bundle tool-1.0.tar.gz.att.sigstore.json tool-1.0.tar.gz
```

This also fails. The type check protects a consumer that expects SLSA provenance from accepting a different kind of statement signed by the same key. State the type you expect every time.

## What verification does not check

A verified attestation proves who signed the statement and that it is about this file. It does not prove that the predicate is true. If the build system writes `"reproducible": true` and is wrong or dishonest, the signature still verifies. Trust in the content comes from trust in the key holder and from the policy a consumer applies to the predicate. The next part names the predicate types that exist so that consumers can write such policies.


## Common pitfalls

> [!WARNING]
> - **Omitting `--type`.** The default is `custom`, so an attestation of another type fails with an unclear reason.
> - **Assuming a valid signature means a true predicate.** Signing proves origin, not correctness.
> - **Verifying with a bundle from a different artifact.** The subject digest must match the file.
