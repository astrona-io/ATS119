# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Signing container images

## Scenario

The `stable` tag of `inventory/podinfo` is what the inventory team's clusters deploy. It must point at the current release, 6.15.0, and carry a signature from the release key with the annotations `release=6.15.0` and `channel=stable`. The admission check in the clusters started to refuse it this morning.

Two key pairs are in the workstation: `/work/keys/release.key` and `.pub` (the published release key) and `/work/keys/dev.key` and `.pub` (a developer key). The password of both is `lab-only-password`. Work in a workstation shell: `kubectl -n workstation exec -it deploy/workstation -- sh`.

## Your task

1. Find out what `stable` points at and which key signed the current release.
2. Make `stable` point at the 6.15.0 release.
3. Make the image behind `stable` verify with the release public key and carry the annotations `release=6.15.0` and `channel=stable`. Use the signing configuration `/setup/offline-signing-config.json`.

## Constraints

- Sign with the published release key. Do not create a new key pair or change `/work/keys/release.pub`.
- Do not sign 6.14.1 with the release key.

## Done when

- `stable` points at the same digest as `6.15.0`.
- That digest verifies with the release public key and carries both annotations.
- The 6.14.1 digest does not verify with the release public key.
- `/work/keys/release.pub` is unchanged.
