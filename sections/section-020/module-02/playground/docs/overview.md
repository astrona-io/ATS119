# Overview: Verifying Blob Bundles (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with a registry and the workstation pod, copies two example images, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- An OCI registry at `registry.localtest.me:5001` inside the cluster. It uses plain HTTP, which is lab-only, so `cosign` needs `--allow-http-registry`. It holds `inventory/podinfo:6.15.0` and `inventory/podinfo:6.14.1`.
- The **workstation** pod with `cosign` v3.1.4, `regctl`, `syft`, `rekor-cli`, `gitsign`, `jq`, `git` and `openssl`. Open a shell with `kubectl -n workstation exec -it deploy/workstation -- sh`; it starts in `/work`.
- `/setup/offline-signing-config.json`, a signing configuration with no Fulcio, Rekor or timestamp service, so nothing you sign goes to a public log.

No key pair exists yet; you create one.

## Helpers

Paste these once in each new workstation shell:

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
release_digest() { regctl image digest "$REPO:$1"; }
```

## Practice tasks

- Create a file, sign it with `cosign sign-blob --bundle` and verify it with `cosign verify-blob --bundle`.
- Change one byte of the file and verify again. Read the error.
- Sign the file with a second key and verify the bundle with the first public key.
- Read the bundle with `jq` and find the message signature and the digest.
