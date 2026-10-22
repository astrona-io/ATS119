# Prerequisites

Before starting this capstone you should be able to:

- Attach and verify attestations with `cosign attest` and `cosign verify-attestation`.
- Write a small Rego rule with `package`, `default` and a rule body.
- Remove signatures and attestations from an image with `cosign clean`.

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

## Working rules

- Everything is graded on the **final state**, so check your result at the end
  and leave it in place.
- The key password is the lab-only `lab-only-password`. Set it with
  `export COSIGN_PASSWORD=lab-only-password` in your shell.
- Files in `/work` survive a restart of the workstation container, but not a
  new pod. Do not delete the workstation pod.
