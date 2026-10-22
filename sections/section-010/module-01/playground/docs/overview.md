# Overview: Sign And Verify Container Images With A Key Pair (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with a registry and the workstation pod, copies two example images, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- An OCI registry at `registry.localtest.me:5001` inside the cluster. It uses plain HTTP, which is lab-only, so `cosign` needs `--allow-http-registry`. It holds `inventory/podinfo:6.15.0` (the current release) and `inventory/podinfo:6.14.1` (the old release).
- The **workstation** pod with `cosign` v3.1.4, `regctl`, `syft`, `rekor-cli`, `gitsign`, `jq`, `git` and `openssl`. Open a shell with `kubectl -n workstation exec -it deploy/workstation -- sh`; it starts in `/work`.
- `/setup/offline-signing-config.json`, a signing configuration with no Fulcio, Rekor or timestamp service, so nothing you sign goes to a public log.

No key pair exists yet; you create one.

## Helpers

Paste these once in each new workstation shell. They set the values the module uses and define two helpers: `release_digest` prints the digest of a tag, and `verify_with` verifies an image reference with a public key file.

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
release_digest() { regctl image digest "$REPO:$1"; }
verify_with() { cosign verify --key "$1" --insecure-ignore-tlog --allow-http-registry "$2"; }
```

Use them like this: `release_digest 6.15.0`, `verify_with /work/keys/release.pub $REPO@$(release_digest 6.15.0)`.

## Practice tasks

- Create two key pairs, `release` and `dev`, sign the current release with one of them, and find out which one by verifying with both public keys.
- Sign the release by its tag instead of its digest and read the warning cosign prints.
- Sign the same digest twice with different annotations, then use `cosign verify -a` to require each set in turn.
- Run `cosign tree` and `regctl artifact list` before and after signing, and compare.
- Copy the old release to a new tag with `regctl image copy $REPO:6.14.1 $REPO:moved`, then verify `$REPO:moved` with the release key and explain the result.
