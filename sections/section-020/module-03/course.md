# Attesting Files And Release Archives

A signature says that a key holder approved a file. An attestation also says something about the file, such as who built it and from which commit, and it is bound to the file by its hash. This module builds an attestation for a release archive, reads the signed statement and verifies it the way a consumer does. Keep one sentence in mind: **an attestation is a signed statement whose subject is the hash of the file.**

The module has four parts. **The In-toto Statement For A File** explains subject, predicate type and predicate and prepares an archive. **Creating A File Attestation** attests an archive and decodes the signed statement. **Verifying A File Attestation** verifies the bundle and shows the failures for a changed file and a wrong type. **Predicate Types And SBOMs For Files** lists predicate types and attaches an SBOM to the archive. A graded lab follows the fourth part.

## Learning objectives

After this module you can:

- Describe the subject, predicate type and predicate of an in-toto statement.
- Create an attestation for a file with `cosign attest-blob`.
- Decode the signed statement from a bundle and compare its subject digest with `sha256sum`.
- Verify an attestation with `cosign verify-blob-attestation` and explain each way it fails.
- Name the common predicate types and attach an SBOM to a file.

## Before you start

You need the basics of signing a file with `cosign sign-blob` and of SHA-256 hashes. Reading JSON with `jq` helps.

Your playground is a single-node `kind` cluster with:

| Component | What it is |
| --- | --- |
| `registry.localtest.me:5001` | An OCI registry inside the cluster, plain HTTP (lab-only), holding `inventory/podinfo:6.15.0` (the current release) and `inventory/podinfo:6.14.1` (the old release) |
| `workstation` pod | `cosign` v3.1.4, `regctl`, `syft`, `jq` and other tools. Every command in this module runs here |
| `/setup/offline-signing-config.json` | A signing configuration that lists no Fulcio, Rekor or timestamp service |

Open a shell in the workstation with `kubectl -n workstation exec -it deploy/workstation -- sh` and keep it open while you read. Launch your playground now:

<!-- astrona:playground -->
