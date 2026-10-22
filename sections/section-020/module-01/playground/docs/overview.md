# Overview: Sign Files And SBOMs With Bundles (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with a registry and the workstation pod, copies two example images, and then waits. There is no task, no `astrona submit` and no pass or fail.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- An OCI registry at `registry.localtest.me:5001` inside the cluster (plain HTTP, lab-only) with `inventory/podinfo:6.15.0` and `inventory/podinfo:6.14.1`.
- The **workstation** pod with `cosign` v3.1.4, `syft` v1.55.0, `regctl`, `jq`, `sha256sum` and `tar`. Open a shell with `kubectl -n workstation exec -it deploy/workstation -- sh`; it starts in `/work`. `SYFT_REGISTRY_INSECURE_USE_HTTP=true` is set, so syft can read the lab registry.
- `/setup/offline-signing-config.json`, a signing configuration with no Fulcio, Rekor or timestamp service.

No key pair exists yet; create one with `cosign generate-key-pair`.

## Helpers

Paste these once in each new workstation shell. `sign_file` signs a file into `<file>.sigstore.json` with `/work/keys/release.key`, and `check_file` verifies a file against that bundle with `/work/keys/release.pub`.

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
sign_file() { cosign sign-blob --key /work/keys/release.key --signing-config $SC -y --bundle "$1.sigstore.json" "$1"; }
check_file() { cosign verify-blob --key /work/keys/release.pub --insecure-ignore-tlog --bundle "$1.sigstore.json" "$1"; }
```

Use them like this: `sign_file notes.txt`, then `check_file notes.txt`.

## Practice tasks

- Sign a text file, change one word, and verify it again. Then restore the word and verify once more.
- Compare `sha256sum` of a file with `.messageSignature.messageDigest.digest` of its bundle (`base64 -d | od -An -tx1` turns the base64 value into hexadecimal).
- Generate SBOMs for both releases with `syft` and compare their package lists with `jq`.
- Write the SBOM in CycloneDX JSON with `-o cyclonedx-json=<file>` and compare its top-level fields with SPDX JSON.
- Sign a file with one key pair and verify it with another, and read the error.
