# Question

Solve this question on: `terminal`

**Time:** about 15 minutes · **Topic:** Signing container images

## Scenario

The inventory team has released `podinfo` version 6.15.0. Their release key pair is already in the workstation, at `/work/keys/release.key` and `/work/keys/release.pub`, with the lab-only password `lab-only-password`. Nothing in the registry is signed yet, and the deployment system will only run images that carry a release signature with the right annotations.

Work in a workstation shell: `kubectl -n workstation exec -it deploy/workstation -- sh`. The registry is `registry.localtest.me:5001` (the variable `REGISTRY` holds it).

## Your task

1. Find the digest of `registry.localtest.me:5001/inventory/podinfo:6.15.0`.
2. Sign that digest with the release key. Use the signing configuration `/setup/offline-signing-config.json`, so the signature goes to no public log.
3. Give the signature the annotations `release=6.15.0` and `team=inventory`.

## Constraints

- Sign with the existing release key. Do not create or replace a key pair.
- Do not sign `inventory/podinfo:6.14.1`. It is the old release and must not carry a release signature.

## Done when

- `cosign verify` with the release public key passes for the 6.15.0 digest.
- A signature on that digest carries both annotations `release=6.15.0` and `team=inventory`.
- The 6.14.1 digest does not verify with the release public key.
