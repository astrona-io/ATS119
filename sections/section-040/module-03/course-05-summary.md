# Summary

A key management service keeps the private key inside the service. With the Transit engine of OpenBao, `cosign generate-key-pair --kms openbao://NAME` creates a key, `cosign sign --key openbao://NAME` sends the data to be signed to the service, and the service returns the signature. cosign reads the server address and the token from `BAO_ADDR` and `BAO_TOKEN`. No key file exists, so a copy of a file cannot leak the key, but anyone with a token that allows signing can use it. Development mode with the root token is for labs only.

`cosign public-key --key openbao://NAME --outfile <file>` exports the public key, which is all a verifier needs. Consumers verify with the file and do not need the service. Verifying with the reference fetches the key from the service and depends on it being reachable. A signature verifies only with the public key of the key that made it, so trying every known public key against a digest tells you which key signed. That is the basis of an audit. The report shows the key, not the person, the machine or the time; the audit log of the KMS records those.

Access control is the main protection. A signing identity needs permission to sign with one key and to read its public part, and a separate identity manages keys. Tokens should be short lived and stay out of repositories. After a migration, old key files must be removed from folders and backups, since they can still sign. Key facts:

- A KMS key has no private key file.
- Export the public key with `cosign public-key --key`.
- Verification identifies the signing key; the KMS audit log identifies the caller.
- Separate signing rights from key administration.

<!-- astrona:playground:destroy -->
