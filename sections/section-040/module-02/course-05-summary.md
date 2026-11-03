# Summary

A cosign private key file holds the private key encrypted with a key derived from the password by scrypt. The password is the only barrier for someone who has a copy of the file. It reaches cosign through the environment variable `COSIGN_PASSWORD` or a prompt, and a pipeline takes it from its secret store, never from a script or a repository. A wrong password stops cosign before it signs.

`cosign import-key-pair --key <pem> --output-key-prefix <name>` converts an existing PEM private key into a cosign key pair, so the public key stays the same and earlier signatures keep verifying. The PEM file remains unprotected after the import, so it must move to secure storage or be destroyed. The password is not part of the key. Changing it does not change the public key, but cosign has no in-place command for it. The way to a new password is to import the original PEM key again with the new password. A cosign key file cannot be exported back to PEM.

The proof that the identity survived is practical: a signature made with the old key verifies with the public key of the imported pair, and new signatures made with the imported key verify with the same file. A leaked password with no leaked file is solved by changing the password. A leaked key file needs a new key and a rotation. Key facts:

- `COSIGN_PASSWORD` supplies the password; `cosign public-key --key` tests it without signing.
- Import keeps the public key; generating a new pair changes it.
- Re-import with a new password to change the password.
- A leaked key file means rotation, not a password change.

<!-- astrona:playground:destroy -->
