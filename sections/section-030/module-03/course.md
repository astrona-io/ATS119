# Rego Policies For Attestation Content

A signature on an attestation proves who made it, but not that its content is acceptable. cosign can apply a policy to the content while it verifies. This module explains what a policy receives, writes policies in Rego for a review record and an SBOM, shows the same rule in CUE and tests each policy in both directions. Keep one sentence in mind: **a policy is a rule over the statement, and every attestation of the type must satisfy it.**

The module has four parts. **How Cosign Evaluates A Policy** explains the package, the rule and the input, and writes a first policy. **Running And Testing A Policy** runs the policy and makes it fail with a rejected record. **Rules On SBOM Content** writes rules on the tool, the package count and a forbidden package. **CUE And Policies In A Release Process** shows the same rule in CUE and describes where policies run. A graded lab follows the fourth part.

## Learning objectives

After this module you can:

- Explain the package, the rule and the input that cosign expects in a Rego policy.
- Run a policy with `cosign verify-attestation --policy` and read the result.
- Write rules on the creators and packages of an SPDX statement.
- Explain why all attestations of a type must satisfy the policy.
- Write a simple CUE policy and say when to prefer it.

## Before you start

You need the basics of attestations: `cosign attest`, `--type` and `cosign verify-attestation`. Reading JSON with `jq` helps.

Your playground is a single-node `kind` cluster with:

| Component | What it is |
| --- | --- |
| `registry.localtest.me:5001` | An OCI registry inside the cluster, plain HTTP (lab-only), holding `inventory/podinfo:6.15.0` (the current release) and `inventory/podinfo:6.14.1` (the old release) |
| `workstation` pod | `cosign` v3.1.4, `regctl`, `syft`, `jq` and other tools. Every command in this module runs here |
| `/setup/offline-signing-config.json` | A signing configuration that lists no Fulcio, Rekor or timestamp service |

Open a shell in the workstation with `kubectl -n workstation exec -it deploy/workstation -- sh` and keep it open while you read. Launch your playground now:

<!-- astrona:playground -->
