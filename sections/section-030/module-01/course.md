# Attach Attestations To Images

Before a cluster runs an image, an operator may want to know more than "it is signed". Was it built by the release pipeline, from a tagged commit? Did the vulnerability scan pass? Each answer is a fact about the image, and an **attestation** carries such a fact as a signed statement attached to the image. Keep one sentence in mind: **an attestation is an in-toto statement about a digest, signed and stored next to the image, and a policy decides whether its content is good enough.**

The module has three parts. **In-Toto Statements And Predicate Types** explains the statement format and the predicate types cosign supports. **Attesting Provenance And Scan Results** attaches a SLSA provenance predicate and a vulnerability scan to the release and reads them back. **Checking Attestations With A Policy** writes Rego policies that `cosign verify-attestation` evaluates. A graded lab follows the second part.

## Learning objectives

After this module you can:

- Name the parts of an in-toto statement and say what each holds.
- Choose the right `--type` for a SLSA provenance, a vulnerability scan or a custom predicate.
- Attach an attestation with `cosign attest` and verify it with `cosign verify-attestation --type`.
- Decode the statement inside an attestation and read its predicate.
- Write a Rego policy for `cosign verify-attestation --policy`, and explain why one bad attestation makes the check fail.

## Before you start

You need to sign and verify images with a cosign key pair, resolve a tag to its digest, and read JSON with `jq`. Your playground is a single-node `kind` cluster with:

| Component | What it is |
| --- | --- |
| `registry.localtest.me:5001` | An OCI registry inside the cluster, plain HTTP (lab-only), with `inventory/podinfo:6.15.0` and `inventory/podinfo:6.14.1` |
| `workstation` pod | `cosign` v3.1.4, `regctl`, `jq`. Every command in this module runs here |
| `/work/predicates/provenance.json` | A SLSA v1 provenance predicate for the 6.15.0 build |
| `/work/predicates/vuln.json` | A vulnerability scan predicate from Trivy for 6.15.0 |
| `/setup/offline-signing-config.json` | A signing configuration with no Fulcio, Rekor or timestamp service |

Open a shell with `kubectl -n workstation exec -it deploy/workstation -- sh` and keep it open while you read. Launch your playground now:

<!-- astrona:playground -->
