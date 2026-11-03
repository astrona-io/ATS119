# Sign Files And SBOMs With Bundles

A user who downloads `inventory-1.4.0.tar.gz` from a web page has no registry to ask for a signature. The signature has to travel with the file. `cosign sign-blob` signs any file, and cosign v3 writes the result to a **Sigstore bundle**: one JSON file that holds the signature and the information a verifier needs. Keep one sentence in mind: **the file and its bundle travel together, and `verify-blob` checks one against the other with a public key.**

The module has three parts. **Signing A File With A Bundle** signs a file, looks inside the bundle, and shows a changed file failing. **Generating And Signing An SBOM** creates a software bill of materials for the release image with `syft` and signs it like any other file. **Getting The Public Key To Consumers** covers how consumers get the public key and what the verification flags mean. A graded lab follows the second part.

## Learning objectives

After this module you can:

- Sign a file with `cosign sign-blob --bundle` and the offline signing configuration.
- Name the main fields of a Sigstore bundle made with a key.
- Verify a file with `cosign verify-blob` and explain why a changed file fails.
- Explain what an SBOM is and what SPDX JSON looks like.
- Generate an SBOM for an image with `syft` and sign it.
- Explain how a consumer gets a trusted public key and what `--insecure-ignore-tlog` gives up.

## Before you start

You need to be able to sign and verify an image with a cosign key pair, and to read JSON with `jq`. Your playground is a single-node `kind` cluster with:

| Component | What it is |
| --- | --- |
| `registry.localtest.me:5001` | An OCI registry inside the cluster, plain HTTP (lab-only), with `inventory/podinfo:6.15.0` and `inventory/podinfo:6.14.1` |
| `workstation` pod | `cosign` v3.1.4, `syft` v1.55.0, `regctl`, `jq` and `sha256sum`. Every command in this module runs here |
| `/setup/offline-signing-config.json` | A signing configuration with no Fulcio, Rekor or timestamp service, so nothing goes to a public log |

Open a shell with `kubectl -n workstation exec -it deploy/workstation -- sh` and keep it open while you read. Launch your playground now:

<!-- astrona:playground -->
