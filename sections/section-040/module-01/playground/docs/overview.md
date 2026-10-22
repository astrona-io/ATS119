# Overview: Manage Signing Keys (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with a registry, the workstation pod and OpenBao, copies two example images, and then waits. There is no task, no `astrona submit` and no pass or fail.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- An OCI registry at `registry.localtest.me:5001` inside the cluster (plain HTTP, lab-only) with `inventory/podinfo:6.15.0` and `inventory/podinfo:6.14.1`.
- The **workstation** pod with `cosign` v3.1.4, `regctl`, `openssl`, `curl` and `jq`. Open a shell with `kubectl -n workstation exec -it deploy/workstation -- sh`; it starts in `/work`. `BAO_ADDR=http://openbao.kms:8200` and `BAO_TOKEN=root` are set.
- **OpenBao 2.7.1** in development mode in the namespace `kms`: in memory, unsealed, root token `root`, the Transit engine enabled at `transit/`. Lab-only: deleting its pod loses every key.
- `/setup/offline-signing-config.json`, a signing configuration with no Fulcio, Rekor or timestamp service.

## Helpers

Paste these once in each new workstation shell. `transit_key` prints what OpenBao knows about a Transit key, and `verify_with` verifies the current release with a public key file.

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
CURRENT=$(regctl image digest $REPO:6.15.0)
transit_key() { curl -s -H "X-Vault-Token: $BAO_TOKEN" "$BAO_ADDR/v1/transit/keys/$1" | jq '.data | {type, latest_version, keys}'; }
verify_with() { cosign verify --key "$1" --insecure-ignore-tlog --allow-http-registry $REPO@$CURRENT; }
```

Use them like this: `transit_key cosign-demo`, `verify_with /work/keys/cosign-demo.pub`.

## Practice tasks

- Create a key with OpenSSL as RSA (`openssl genrsa -out rsa.pem 3072`), import it, sign with it, and compare the key type in `release.pub` and the imported `.pub`.
- Create two Transit keys, sign the release with both, and verify with each exported public key.
- Rotate a Transit key with `curl -s -X POST -H "X-Vault-Token: $BAO_TOKEN" $BAO_ADDR/v1/transit/keys/cosign-demo/rotate`, sign again, and find out which public key now verifies which signature.
- Unset `BAO_ADDR` in your shell and run a cosign command with an `openbao://` key, then read the error.
- Read the signed payload of a signature with annotations and find the digest in it.
