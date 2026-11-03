# Summary

An attestation is a signed in-toto statement about an artifact. The statement has a subject, which names the artifact by digest, a predicate type, which is a URI that names the kind of fact, and a predicate, which is the fact itself. cosign wraps the statement in a DSSE envelope, signs it and stores the envelope in a Sigstore bundle. For a file, the subject digest is the SHA-256 hash of the file.

`cosign attest-blob` builds the statement from a file and a predicate file, with `--type` choosing the predicate type, and writes the bundle with `--bundle`. The payload can be read back by decoding the base64 payload of the envelope with `jq` and `base64`. `cosign verify-blob-attestation` checks the signature against a public key, the predicate type against `--type`, and the file digest against the subject. A changed file, a bundle of another artifact or a wrong type all fail.

A valid attestation proves who signed the statement and which artifact it describes. It does not prove that the predicate is true, so consumers combine the signature with trust in the key holder and with their own rules about the predicate. cosign knows short names for common types, including `custom`, `slsaprovenance1`, `spdxjson`, `cyclonedx` and `vuln`, and accepts any URI. One file can have several attestation bundles, one for each type. Key facts:

- The subject digest binds an attestation to one file.
- `--type` must match when creating and when verifying.
- Verification proves origin and subject, not the truth of the predicate.
- Publish each bundle next to the file it describes.

<!-- astrona:playground:destroy -->
