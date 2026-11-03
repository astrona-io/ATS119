# Annotations And Release Stage Signatures

A bare signature tells a verifier that a key signed a digest. It does not tell the verifier which environment the digest was approved for. Annotations put such facts into the signed payload, and the verifier can require them. Keep one sentence in mind: **an annotation is part of what is signed, and `cosign verify -a` makes it a requirement.**

The module has four parts. **Annotations In The Signed Payload** signs the current release with an annotation and finds it in the payload. **Several Signatures On One Digest** adds a second signature and shows how cosign treats more than one. **Requiring Annotations When Verifying** explains how `cosign verify -a` matches annotations. **A Promotion Flow With Stage Signatures** builds a staging to production gate and shows why the old release stays unapproved. A graded lab follows the fourth part.

## Learning objectives

After this module you can:

- Add annotations to a signature with `-a` and read them from the payload.
- Explain why an annotation cannot be changed after signing.
- Put more than one signature on a digest and list them.
- Require annotations with `cosign verify -a` and explain the matching rules.
- Describe a staging to production flow built on signatures.

## Before you start

You need the basics from the previous module: a key pair, signing a digest and verifying with a public key. Reading JSON with `jq` helps.

Your playground is a single-node `kind` cluster with:

| Component | What it is |
| --- | --- |
| `registry.localtest.me:5001` | An OCI registry inside the cluster, plain HTTP (lab-only), holding `inventory/podinfo:6.15.0` (the current release) and `inventory/podinfo:6.14.1` (the old release) |
| `workstation` pod | `cosign` v3.1.4, `regctl`, `syft`, `jq` and other tools. Every command in this module runs here |
| `/setup/offline-signing-config.json` | A signing configuration that lists no Fulcio, Rekor or timestamp service |

Open a shell in the workstation with `kubectl -n workstation exec -it deploy/workstation -- sh` and keep it open while you read. Launch your playground now:

<!-- astrona:playground -->
