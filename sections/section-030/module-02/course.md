# SBOM And Custom Attestations On Images

A signature approves an image. An attestation adds a signed fact about it, for example the list of components inside it or the result of a human review. This module generates an SBOM, attaches it as an attestation, adds a custom attestation and reads both. Keep one sentence in mind: **an attestation is a signed statement whose subject is the image digest and whose type tells a consumer what it says.**

The module has four parts. **Generating An SBOM With Syft** creates an SPDX JSON SBOM of an image digest and reads it. **Attaching An SBOM As An Attestation** attests the SBOM with cosign and verifies it by type. **Custom Predicate Types** attaches a review record with a predicate type of your own. **Reading Attestations In Scripts** reads verified predicates and treats a missing attestation as a failure. A graded lab follows the fourth part.

## Learning objectives

After this module you can:

- Generate an SPDX JSON SBOM of an image digest with `syft scan`.
- Attach the SBOM with `cosign attest --type spdxjson` and verify it.
- Attach a custom attestation with a predicate type URI.
- Decode the statement from `cosign verify-attestation` output and read the predicate.
- Explain why a missing attestation fails a release gate.

## Before you start

You need the basics of signing an image digest and of in-toto statements. Reading JSON with `jq` helps.

Your playground is a single-node `kind` cluster with:

| Component | What it is |
| --- | --- |
| `registry.localtest.me:5001` | An OCI registry inside the cluster, plain HTTP (lab-only), holding `inventory/podinfo:6.15.0` (the current release) and `inventory/podinfo:6.14.1` (the old release) |
| `workstation` pod | `cosign` v3.1.4, `regctl`, `syft`, `jq` and other tools. Every command in this module runs here |
| `/setup/offline-signing-config.json` | A signing configuration that lists no Fulcio, Rekor or timestamp service |

Open a shell in the workstation with `kubectl -n workstation exec -it deploy/workstation -- sh` and keep it open while you read. Launch your playground now:

<!-- astrona:playground -->
