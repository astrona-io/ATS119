# Question

Solve this question on: `terminal`

**Time:** about 35 minutes · **Topic:** Key management

## Scenario

The security team wants no release private key on any disk. From now on the inventory release key lives in OpenBao's Transit engine. OpenBao 2.7.1 runs in development mode at `http://openbao.kms:8200` with the lab-only root token `root`. The old file-based key is still at `/work/keys/release.key`.

Someone prepared the workstation, but two things are not ready: the Transit engine is not enabled in OpenBao, and the `BAO_ADDR` variable in the workstation points at the wrong port. Work in a workstation shell: `kubectl -n workstation exec -it deploy/workstation -- sh`.

## Your task

1. Make cosign reach OpenBao at `http://openbao.kms:8200`, and enable the Transit engine at the path `transit/`.
2. Create the release signing key in Transit with cosign, with the key name `cosign-release`.
3. Export its public key to `/work/keys/release-kms.pub`.
4. Sign the 6.15.0 digest with the Transit key and the annotation `signer=openbao`. Use the signing configuration `/setup/offline-signing-config.json`.
5. Delete the file-based private key `/work/keys/release.key`.

## Constraints

- The private key of `cosign-release` must be created in OpenBao, not imported from a file.

## Done when

- OpenBao Transit holds a key named `cosign-release`.
- `/work/keys/release-kms.pub` is the public key of that Transit key.
- 6.15.0 verifies with `/work/keys/release-kms.pub` and carries the annotation `signer=openbao`.
- `/work/keys/release.key` no longer exists.
