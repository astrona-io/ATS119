# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Key management

## Scenario

The inventory team rotates its release key every year. The 2025 key pair, `/work/keys/release-2025.key` and `.pub`, signed both `inventory/podinfo:6.15.0` (supported) and `inventory/podinfo:6.14.1` (end of life), each with the annotation `key=release-2025`. It is time to introduce the 2026 key. Users will keep trusting the 2025 key until they have updated, so nothing may stop verifying with it.

The password of every key is `lab-only-password`. Work in a workstation shell: `kubectl -n workstation exec -it deploy/workstation -- sh`.

## Your task

1. Create a new key pair `/work/keys/release-2026.key` and `/work/keys/release-2026.pub`, with the password `lab-only-password`.
2. Sign the 6.15.0 digest with the new key and the annotation `key=release-2026`. Use the signing configuration `/setup/offline-signing-config.json`.
3. Publish the trust set: copy both public keys to `/work/keys/trusted/release-2025.pub` and `/work/keys/trusted/release-2026.pub`.

## Constraints

- Keep the 2025 signatures on both releases.
- Do not sign 6.14.1 with the new key; it is end of life.

## Done when

- `release-2026.key` and `release-2026.pub` exist, and the new public key differs from the 2025 one.
- 6.15.0 verifies with the new key and the annotation `key=release-2026`, and still with the 2025 key.
- 6.14.1 verifies with the 2025 key and not with the new key.
- `/work/keys/trusted/` holds both public keys under the names above.
