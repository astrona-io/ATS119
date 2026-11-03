# Sign And Verify Container Images With A Key Pair

An image tag such as `podinfo:6.15.0` is only a name. Anyone who can push to the registry can move it to another image, and the cluster that pulls the tag gets whatever the tag points at that moment. A signature fixes this: it binds one exact image to a key, and a verifier who trusts the key can check the image before it runs.

`cosign` is the Sigstore command-line tool that signs and verifies container images. In this module you use it with a **key pair**: a private key that signs and a public key that verifies. Keep one sentence in mind: **you sign a digest, you verify with a public key, and the signature lives next to the image in the registry.**

The module has four parts. **Key Pairs And Signing An Image By Digest** creates a key pair and signs the current release by its digest, with a signing configuration that keeps the signature out of any public log. **Where The Signature Lives In The Registry** finds the signature in the registry and explains the Sigstore bundle cosign v3 stores there. **Verifying Signatures And Annotations** checks the signature with the public key, adds annotations, and shows what a verifier sees when the image changes. **Troubleshooting Signing And Verification** reproduces the most common failures and names the cause of each. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Create a cosign key pair and explain why the private key is encrypted.
- Find the digest of a tag and sign that digest.
- Explain what the signing configuration does and why the labs use one with no services.
- Find a signature in the registry with `cosign tree` and `regctl`.
- Verify a signature with `cosign verify --key` and check its annotations.
- Explain why `--insecure-ignore-tlog` is needed here and what it gives up.
- Find the cause of the most common signing and verification failures.

## Before you start

You need Kubernetes basics and `kubectl`, and you should know what an image, a tag and a registry are. Reading JSON with `jq` helps.

Your playground is a single-node `kind` cluster with:

| Component | What it is |
| --- | --- |
| `registry.localtest.me:5001` | An OCI registry inside the cluster, plain HTTP (lab-only), holding `inventory/podinfo:6.15.0` (the current release) and `inventory/podinfo:6.14.1` (the old release) |
| `workstation` pod | `cosign` v3.1.4, `regctl`, `syft`, `jq` and other tools. Every command in this module runs here |
| `/setup/offline-signing-config.json` | A signing configuration that lists no Fulcio, Rekor or timestamp service |

Open a shell in the workstation with `kubectl -n workstation exec -it deploy/workstation -- sh` and keep it open while you read. Launch your playground now:

<!-- astrona:playground -->
