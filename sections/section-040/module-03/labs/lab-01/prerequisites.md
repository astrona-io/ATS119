# Prerequisites

Before starting this lab you should be able to:

- Export the public key of a KMS key with `cosign public-key --key openbao://NAME`.
- Verify an image signature with a public key.
- Explain why a KMS key has no private key file.

## What the environment gives you

The environment builds itself before the task begins. It takes a few minutes:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- An OCI registry at `registry.localtest.me:5001` inside the cluster (plain HTTP,
  lab-only) holding `inventory/podinfo:6.15.0` and `inventory/podinfo:6.14.1`.
- The `workstation` pod with `cosign` v3.1.4, `rekor-cli`, `gitsign`, `regctl`,
  `syft` v1.55.0, `git`, `curl`, `jq` and `openssl`. Open a shell with
  `kubectl -n workstation exec -it deploy/workstation -- sh`; work in `/work`.
- The file `/setup/offline-signing-config.json`, a signing configuration with no
  Fulcio, Rekor or timestamp service, so nothing goes to a public log.

## OpenBao

An OpenBao 2.7.1 server in development mode runs at `http://openbao.kms:8200` with the
root token `root` and the Transit engine enabled at `transit/`. The workstation already
has `BAO_ADDR` and `BAO_TOKEN` set. This is lab-only; never run a production server in
development mode.

## Working rules

- Everything is graded on the **final state**, so check your result at the end
  and leave it in place.
- The key password is the lab-only `lab-only-password`. Set it with
  `export COSIGN_PASSWORD=lab-only-password` in your shell.
- Files in `/work` survive a restart of the workstation container, but not a
  new pod. Do not delete the workstation pod.
