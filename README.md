# ATS119 — Cosign Container & Blob Artifact Signing (Sigstore)

Course material for the **Cosign Container & Blob Artifact Signing** domain of
the Astrona Sigstore training path ([ATP023](https://github.com/astrona-io/ATP023)),
which is **20% of the path**. Written for **cosign v3.1.4**.

> **Status: draft, not yet run.** Every page, playground and lab was written
> from the Sigstore documentation and the cosign v3.1.4 source. None has been
> started on a cluster, and no lab has passed `astrona test` yet. See
> `CLAUDE.md` for the ranked list of things to check first.

The course opens with an Introduction in `sections/intro/` (welcome, machine
setup, how the course is made). Each section has three modules (a landing page,
short parts, a summary, a playground and a graded lab) and a capstone.

---

## Sections

| Section | Title | Labs | Topic |
| --- | --- | --- | --- |
| [010](sections/section-010) | Signing And Verifying Container Images | 3 + capstone | image-signing |
| [020](sections/section-020) | Signing Blobs, Bundles And SBOMs | 3 + capstone | blob-signing |
| [030](sections/section-030) | Attestations And Policies | 3 + capstone | attestations |
| [040](sections/section-040) | Managing Signing Keys | 3 + capstone | key-management |

## Labs and capstones

| Environment | Title | Kind |
| --- | --- | --- |
| `ats-119-lab-010-01` | Sign The Release Digest With Annotations | build |
| `ats-119-capstone-010` | Repair The Signature Of A Release Channel | troubleshooting |
| `ats-119-lab-020-01` | Sign A Release Archive And Its SBOM | build |
| `ats-119-capstone-020` | Repair The Signatures Of A Release Download | troubleshooting |
| `ats-119-lab-030-01` | Attach Provenance And Vulnerability Attestations | build |
| `ats-119-capstone-030` | Gate A Release On Its Attestations | troubleshooting |
| `ats-119-lab-040-01` | Rotate The Release Signing Key | migration |
| `ats-119-capstone-040` | Move Release Signing Into OpenBao Transit | migration |

---

## The lab environment

Every playground and lab is a **kind** cluster with an OCI registry
(`registry:3.1.2`, plain HTTP, `registry.localtest.me:5001` inside the cluster)
holding `inventory/podinfo:6.15.0` and `:6.14.1`, and a `workstation` pod with
`cosign` v3.1.4, `syft` v1.55.0, `regctl`, `rekor-cli`, `gitsign` and the usual
shell tools. Section 040 adds OpenBao 2.7.1 in development mode with the
Transit engine.

All signing uses `/setup/offline-signing-config.json`, a signing configuration
with no Fulcio, Rekor or timestamp service, so nothing reaches the public-good
instance. Verification therefore uses `--insecure-ignore-tlog`, and the pages
explain that trade-off. Keys are generated inside the environment; the
repository holds no key material.

## Running

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS119.git -c sections/<section>/module-01/playground
astrona run --git ssh://git@github.com/astrona-io/ATS119.git -c sections/<section>/module-01/labs/lab-01
astrona submit -c sections/<section>/module-01/labs/lab-01
astrona destroy <name>
```

Graders check behaviour with their own copy of the public key and reject the
plausible but wrong fix: signing with a new key, signing the wrong digest,
changing a signed file, removing an old release's attestations, or keeping a
private key on disk after moving to a KMS.
