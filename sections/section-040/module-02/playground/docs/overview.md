# Overview: Importing Keys And Re-Protecting Them (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with a registry and the workstation pod, copies two example images, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- An OCI registry at `registry.localtest.me:5001` inside the cluster. It uses plain HTTP, which is lab-only, so `cosign` needs `--allow-http-registry`. It holds `inventory/podinfo:6.15.0` and `inventory/podinfo:6.14.1`.
- The **workstation** pod with `cosign` v3.1.4, `regctl`, `syft`, `rekor-cli`, `gitsign`, `jq`, `git` and `openssl`. Open a shell with `kubectl -n workstation exec -it deploy/workstation -- sh`; it starts in `/work`.
- `/setup/offline-signing-config.json`, a signing configuration with no Fulcio, Rekor or timestamp service, so nothing you sign goes to a public log.

No key pair exists yet; you create everything.

## Helpers

Paste these once in each new workstation shell:

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
release_digest() { regctl image digest "$REPO:$1"; }
```

## Practice tasks

- Create a PKCS#8 PEM key with `openssl ecparam -genkey -name prime256v1 -noout | openssl pkcs8 -topk8 -nocrypt -out signing.pem`.
- Import it with `cosign import-key-pair --key signing.pem --output-key-prefix imported` and compare `imported.pub` with the key you get from `openssl pkey -in signing.pem -pubout`.
- Open the key with a wrong `COSIGN_PASSWORD` and read the error.
- Sign a digest with the imported key and verify it with the public key.
