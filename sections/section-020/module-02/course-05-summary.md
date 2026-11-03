# Summary

A Sigstore bundle is a single JSON file that carries the signature of a file, the digest of the data that was signed and, for key-based signing, a hint that identifies the key. The public key is not inside the bundle. The consumer brings the public key over a channel it trusts, and `cosign verify-blob --bundle` checks that the signature is valid for that key and that the digest in the bundle equals the hash of the file.

A verification can fail for two different reasons. If the file changed, its hash no longer equals the digest in the bundle. If another key signed the bundle, the signature does not verify with the public key. Both failures return a non-zero exit status, which scripts must use. Re-signing a failing file only signs the damaged content and is not a repair. A file without a bundle has no evidence and counts as a failure.

For many files, a loop sorts them by the exit status of `cosign verify-blob` into trusted and untrusted lists, and the check must change nothing. A signed checksum list reduces the number of bundles: the consumer verifies the list with the public key and then runs `sha256sum -c`. In every variant the trust comes from a public key obtained independently of the download. Key facts:

- `cosign sign-blob --bundle` writes the bundle; `cosign verify-blob --bundle` reads it.
- A bundle made without a log needs `--insecure-ignore-tlog` when verifying.
- A changed file and a wrong key are different failures with the same exit status.
- Verify the checksum list before you trust it.

<!-- astrona:playground:destroy -->
