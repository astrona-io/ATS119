# Question

Solve this question on: `terminal`

**Time:** about 15 minutes · **Topic:** Signing container images

## Scenario

The inventory team signs every release twice: once for staging, and again for production when the release team approves it. Both `inventory/podinfo:6.15.0` and `inventory/podinfo:6.14.1` already carry a staging signature made with the release key, annotated `env=staging`. The release key pair is at `/work/keys/release.key` and `/work/keys/release.pub`, with the lab-only password `lab-only-password`.

The release team has approved 6.15.0 for production. The deployment system only runs an image that has a signature annotated `env=production` and `approved-by=release-team`.

Work in a workstation shell: `kubectl -n workstation exec -it deploy/workstation -- sh`. The registry is `registry.localtest.me:5001` (the variable `REGISTRY` holds it).

## Your task

1. Find the digest of `registry.localtest.me:5001/inventory/podinfo:6.15.0`.
2. Add a second signature to that digest with the release key and the offline signing configuration `/setup/offline-signing-config.json`.
3. Give the new signature the annotations `env=production` and `approved-by=release-team`.

## Constraints

- Sign with the existing release key. Do not create or replace a key pair.
- Keep the staging signature on 6.15.0. Add a signature; do not remove one.
- Do not give 6.14.1 a production signature.

## Done when

- `cosign verify` with the release public key and both annotations `env=production` and `approved-by=release-team` passes for the 6.15.0 digest.
- `cosign verify` with the annotation `env=staging` still passes for the 6.15.0 digest.
- `cosign verify` with the annotation `env=production` fails for the 6.14.1 digest.
