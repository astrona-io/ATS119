# Importing Keys And Changing Their Passwords

A signing key is only as safe as the file that holds it and the password that protects it. Teams also arrive with keys that were not made by cosign. This module explains how cosign protects a key file, imports an existing PEM key so that the public key stays the same, changes the password by importing again and proves that old and new signatures verify with one public key. Keep one sentence in mind: **the password protects the file, the public key identifies the signer, and a good migration changes only the first.**

The module has four parts. **Key Files And Passwords** shows how a key file is encrypted and how the password reaches cosign. **Importing An Existing PEM Key** moves an unprotected PEM key into a cosign key pair. **Changing A Key Password** re-imports the key with a new password and checks that the public key is unchanged. **Proving The Identity Survived** verifies an old and a new signature with one public key. A graded lab follows the fourth part.

## Learning objectives

After this module you can:

- Explain how cosign protects a private key file and where the password comes from.
- Import a PEM private key with `cosign import-key-pair`.
- Explain why an imported key keeps its public key.
- Change the password of a key by importing it again, and test a password with `cosign public-key`.
- Decide when a password change is enough and when a rotation is needed.

## Before you start

You need the basics of a cosign key pair and of signing an image digest. Knowing what a PEM file is helps.

Your playground is a single-node `kind` cluster with:

| Component | What it is |
| --- | --- |
| `registry.localtest.me:5001` | An OCI registry inside the cluster, plain HTTP (lab-only), holding `inventory/podinfo:6.15.0` (the current release) and `inventory/podinfo:6.14.1` (the old release) |
| `workstation` pod | `cosign` v3.1.4, `regctl`, `syft`, `jq` and other tools. Every command in this module runs here |
| `/setup/offline-signing-config.json` | A signing configuration that lists no Fulcio, Rekor or timestamp service |

Open a shell in the workstation with `kubectl -n workstation exec -it deploy/workstation -- sh` and keep it open while you read. Launch your playground now:

<!-- astrona:playground -->
