# Manage Signing Keys

Signing is easy; keeping the signing key safe for years is the hard part. A key file can be copied, a password can leak, and a key that signed a hundred releases cannot simply be thrown away. This module covers the options cosign gives you, from an encrypted file to a key that lives in a key management service. Keep one sentence in mind: **the private key must stay where only the signer can use it, and the public keys must stay where every verifier can find them.**

The module has three parts. **Key Files, Passwords And Imported Keys** looks inside the encrypted key file, imports an existing key, and exports a public key. **Keys In A Key Management Service** creates a signing key in OpenBao's Transit engine and signs with it, so the private key never leaves OpenBao. **Rotating Keys And Reading The Signed Payload** reads what a signature actually covers and replaces a release key with a new one. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Explain how cosign protects a private key file and supplies its password.
- Import a PEM key with `cosign import-key-pair` and export a public key with `cosign public-key`.
- Name the KMS key references cosign accepts.
- Create a key in OpenBao Transit with `cosign generate-key-pair --kms` and sign with it.
- Name the fields of the signed payload of an image.
- Rotate a release key and publish a trust set with the old and the new public key.

## Before you start

You need to sign and verify images with a cosign key pair, with annotations, and to resolve a tag to its digest. Your playground is a single-node `kind` cluster with:

| Component | What it is |
| --- | --- |
| `registry.localtest.me:5001` | An OCI registry inside the cluster, plain HTTP (lab-only), with `inventory/podinfo:6.15.0` and `inventory/podinfo:6.14.1` |
| `workstation` pod | `cosign` v3.1.4, `regctl`, `openssl`, `curl`, `jq`. `BAO_ADDR` and `BAO_TOKEN` point at OpenBao |
| OpenBao (namespace `kms`) | OpenBao 2.7.1 in development mode at `http://openbao.kms:8200`, root token `root`, Transit enabled at `transit/`. Lab-only |
| `/setup/offline-signing-config.json` | A signing configuration with no Fulcio, Rekor or timestamp service |

Open a shell with `kubectl -n workstation exec -it deploy/workstation -- sh` and keep it open while you read. Launch your playground now:

<!-- astrona:playground -->
