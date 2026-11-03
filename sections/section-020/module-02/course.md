# Verifying Blob Bundles And Downloads

A file download has no registry that stores its signature, so the signature travels in a bundle next to the file. A consumer can use the file only after the bundle and the public key confirm that the file is the one that was signed. This module opens a bundle, explains each way a verification can fail and sorts a set of downloads. Keep one sentence in mind: **a verifier needs the file, the bundle and a public key it trusts.**

The module has four parts. **What Is Inside A Bundle** signs a file and reads the bundle with jq. **Why A Verification Fails** runs verify-blob on a good file, a changed file and a bundle from another key. **Verifying A Set Of Downloads** sorts several files into trusted and untrusted with a loop. **Signing A Checksum List** signs one list of hashes and verifies the downloads from it. A graded lab follows the fourth part.

## Learning objectives

After this module you can:

- Sign a file with `cosign sign-blob --bundle` and read the bundle with `jq`.
- Explain what the digest in a bundle is and how to recompute it.
- Tell a changed file from a bundle made by another key.
- Verify several downloads with a loop and use the exit status.
- Sign a checksum list and verify the downloads from it.

## Before you start

You need the basics of a cosign key pair and of SHA-256 hashes. Reading JSON with `jq` helps.

Your playground is a single-node `kind` cluster with:

| Component | What it is |
| --- | --- |
| `registry.localtest.me:5001` | An OCI registry inside the cluster, plain HTTP (lab-only), holding `inventory/podinfo:6.15.0` (the current release) and `inventory/podinfo:6.14.1` (the old release) |
| `workstation` pod | `cosign` v3.1.4, `regctl`, `syft`, `jq` and other tools. Every command in this module runs here |
| `/setup/offline-signing-config.json` | A signing configuration that lists no Fulcio, Rekor or timestamp service |

Open a shell in the workstation with `kubectl -n workstation exec -it deploy/workstation -- sh` and keep it open while you read. Launch your playground now:

<!-- astrona:playground -->
