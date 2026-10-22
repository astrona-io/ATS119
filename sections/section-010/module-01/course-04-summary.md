# Summary

A signature binds one exact image to a key. With `cosign` and a key pair, the private key signs and the public key verifies. cosign encrypts the private key with a password when it creates the pair, so the key file alone cannot sign; `COSIGN_PASSWORD` supplies the password without a prompt.

You sign a digest, not a tag. A tag is a name that can move to another image, while a digest is the SHA-256 hash of one exact manifest. The signed payload records the repository and the digest, and a verifier trusts the digest in the payload, so a signature can never follow a tag to a different image.

cosign v3 always reads a signing configuration that lists the Sigstore services to use. Without one, it uses the public-good instance and uploads every signature to the public Rekor log. The labs use a configuration with no services, so signatures stay in the cluster; `--tlog-upload=false` is rejected in cosign v3.1.4 while a configuration is in use. A signature that is in no log is verified with `--insecure-ignore-tlog`, which gives up public evidence that the signature exists.

The signature lives in the registry next to the image. cosign v3 stores it as a Sigstore bundle attached as an OCI referrer, an artifact whose `subject` points at the image. `cosign tree` and `regctl artifact list` show it; older signatures may still use the legacy `.sig` tag layout. Annotations are key=value pairs inside the signed payload, and `cosign verify -a` requires a signature that carries them. The key facts to remember are these:

- Resolve the digest with `regctl image digest` and sign `$REPO@$DIGEST`.
- Sign with `--key`, `--signing-config` and, for this lab registry, `--allow-http-registry`.
- Verify with `cosign verify --key <pub>`, and add `-a key=value` to check annotations.
- Verifying with each known public key tells you which key made a signature.

<!-- astrona:playground:destroy -->
