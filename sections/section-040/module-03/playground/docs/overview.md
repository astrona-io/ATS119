# Overview: Auditing KMS Keys (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with a registry and the workstation pod, copies two example images, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- An OCI registry at `registry.localtest.me:5001` inside the cluster. It uses plain HTTP, which is lab-only, so `cosign` needs `--allow-http-registry`. It holds `inventory/podinfo:6.15.0` and `inventory/podinfo:6.14.1`.
- The **workstation** pod with `cosign` v3.1.4, `regctl`, `syft`, `rekor-cli`, `gitsign`, `jq`, `git` and `openssl`. Open a shell with `kubectl -n workstation exec -it deploy/workstation -- sh`; it starts in `/work`.
- `/setup/offline-signing-config.json`, a signing configuration with no Fulcio, Rekor or timestamp service, so nothing you sign goes to a public log.
- An OpenBao 2.7.1 server in development mode at `http://openbao.kms:8200` with the root token `root` and the Transit engine at `transit/`. `BAO_ADDR` and `BAO_TOKEN` are already set in the workstation. This is lab-only.

No Transit key exists yet; you create them.

## Helpers

Paste these once in each new workstation shell:

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
release_digest() { regctl image digest "$REPO:$1"; }
```

## Practice tasks

- Run `cosign generate-key-pair --kms openbao://demo-a` and read the key with `curl -s -H "X-Vault-Token: $BAO_TOKEN" $BAO_ADDR/v1/transit/keys/demo-a | jq '.data | {type, latest_version}'`.
- Export the public key with `cosign public-key --key openbao://demo-a --outfile demo-a.pub`.
- Sign a digest with the Transit key and verify it with the exported public key file.
- Create a second key `demo-b` and verify the same digest with its public key. Read the error.
