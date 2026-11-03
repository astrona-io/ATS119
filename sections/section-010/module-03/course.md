# Referrers, Fallback Tags And Unsigned Images

The registry does not know what a signature is. It stores manifests, and cosign links the signature manifest to the image through a field called `subject`. This module shows how that link is stored and found, what clients do when the registry cannot list referrers, and how to find images that have no signature. Keep one sentence in mind: **a signature is found by the digest of the image it signs, never by the tag.**

The module has four parts. **Referrers And The Subject Field** explains the link between an image and its signatures. **The Fallback Tag** shows how clients find referrers on a registry without the referrers API. **Finding Unsigned Images** walks the tags of a repository and tells attached artifacts from trusted signatures. **Several Keys And Retiring Signatures** puts two keys on one digest and describes how to remove a signature safely. A graded lab follows the fourth part.

## Learning objectives

After this module you can:

- Explain what an OCI referrer is and what the `subject` field does.
- List the referrers of a digest with `regctl artifact list` and read a referrer manifest.
- Build the name of the fallback tag from an image digest and read its index.
- Find the release tags of a repository that have no referrers.
- Explain why a referrer is not proof of a trusted signature.

## Before you start

You need the basics of signing a digest and verifying with a public key. Knowing that an OCI registry holds manifests addressed by digest helps.

Your playground is a single-node `kind` cluster with:

| Component | What it is |
| --- | --- |
| `registry.localtest.me:5001` | An OCI registry inside the cluster, plain HTTP (lab-only), holding `inventory/podinfo:6.15.0` (the current release) and `inventory/podinfo:6.14.1` (the old release) |
| `workstation` pod | `cosign` v3.1.4, `regctl`, `syft`, `jq` and other tools. Every command in this module runs here |
| `/setup/offline-signing-config.json` | A signing configuration that lists no Fulcio, Rekor or timestamp service |

Open a shell in the workstation with `kubectl -n workstation exec -it deploy/workstation -- sh` and keep it open while you read. Launch your playground now:

<!-- astrona:playground -->
