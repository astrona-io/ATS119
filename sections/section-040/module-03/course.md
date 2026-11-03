# Auditing And Controlling KMS Keys

When signing keys live in a key management service, a team still has to answer practical questions: how does a verifier get the public key, which key signed which release, and who may sign at all? This module creates keys in the Transit engine of OpenBao, exports public keys, finds the signer of a release by verification and describes the access rules that keep the keys safe. Keep one sentence in mind: **a KMS key has no file to steal, so access control is the protection.**

The module has four parts. **Keys In The Transit Engine** creates a Transit key through cosign and reads it from the server side. **Exporting And Using The Public Key** exports the public key and verifies with a file and with the reference. **Finding Out Which Key Signed** tries every public key against every release to build an audit report. **Controlling Who May Sign** describes access policies, tokens and leftover key files. A graded lab follows the fourth part.

## Learning objectives

After this module you can:

- Create a Transit key with `cosign generate-key-pair --kms openbao://NAME`.
- Export a public key with `cosign public-key --key` and verify with it.
- Find out which key signed a release by trying known public keys.
- Explain what the report can and cannot tell and where the KMS audit log fits.
- Describe the access a signing identity needs and why signing and administration are separated.

## Before you start

You need the basics of a cosign key pair and of verifying with a public key. Knowing what a key management service is helps.

Your playground is a single-node `kind` cluster with:

| Component | What it is |
| --- | --- |
| `registry.localtest.me:5001` | An OCI registry inside the cluster, plain HTTP (lab-only), holding `inventory/podinfo:6.15.0` (the current release) and `inventory/podinfo:6.14.1` (the old release) |
| `workstation` pod | `cosign` v3.1.4, `regctl`, `syft`, `jq` and other tools. Every command in this module runs here |
| `/setup/offline-signing-config.json` | A signing configuration that lists no Fulcio, Rekor or timestamp service |
| `openbao.kms:8200` | An OpenBao 2.7.1 server in development mode with the root token `root` and the Transit engine at `transit/`. `BAO_ADDR` and `BAO_TOKEN` are already set in the workstation (lab-only) |

Open a shell in the workstation with `kubectl -n workstation exec -it deploy/workstation -- sh` and keep it open while you read. Launch your playground now:

<!-- astrona:playground -->
