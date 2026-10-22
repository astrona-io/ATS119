# Summary

A cosign key file holds the private key encrypted with a key derived from a password by scrypt, so a copied file is useless without the password. The password reaches cosign through `COSIGN_PASSWORD` or a prompt, and belongs in a secret store, never next to the key. `cosign import-key-pair` brings an existing PEM key into cosign's encrypted format, and `cosign public-key` prints the public key of any key reference, which is how a lost public key file is rebuilt.

A key management service (KMS) keeps the private key inside the service, so no key file exists. cosign names KMS keys with references such as `awskms://`, `gcpkms://`, `azurekms://` and `hashivault://` or `openbao://`, and the same reference works for creating, signing, verifying and exporting. For OpenBao's Transit engine, cosign reads `BAO_ADDR` or `VAULT_ADDR`, `BAO_TOKEN` or `VAULT_TOKEN`, and `TRANSIT_SECRET_ENGINE_PATH`. Verifiers need only the exported public key, not access to the KMS.

The signed payload of an image names the repository and the digest in its `critical` part and carries annotations in `optional`. It does not name the key: which key signed is found by verifying with each trusted public key.

Rotating a key on schedule means signing every supported release with the new key, keeping the old signatures, leaving end-of-life releases alone, and publishing both public keys as a trust set until the old key retires. A leaked key is different: remove it from every trust set at once, remove its signatures with `cosign clean --type all`, and sign again with a new key. The key facts to remember are these:

- Never keep an unencrypted PEM after an import.
- Give verifiers public keys, never KMS tokens.
- A development OpenBao keeps keys in memory only.
- `cosign verify` checks one key at a time; loop over a trust set.

<!-- astrona:playground:destroy -->
