# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Importing keys and key passwords

## Scenario

An old build server signed releases with an unprotected private key stored as a PKCS#8 PEM file, `/work/legacy/signing.pem`. The team is moving to cosign key files and wants to keep the same signing identity, so everything signed in the past still verifies with the same public key. The old release `inventory/podinfo:6.14.1` was signed with that key. The new key file must be protected with the new team password `new-team-password`.

Work in a workstation shell: `kubectl -n workstation exec -it deploy/workstation -- sh`. The registry is `registry.localtest.me:5001` (the variable `REGISTRY` holds it). Sign with the offline signing configuration `/setup/offline-signing-config.json`. The folder `/work/keys` exists.

## Your task

1. Import the PEM key into a cosign key pair named `imported` in `/work/keys` (`imported.key` and `imported.pub`). Protect it with the password `new-team-password`.
2. Sign the digest of `inventory/podinfo:6.15.0` with the imported key and the annotation `rotated=true`.

## Constraints

- Do not generate a new key pair. The public key must be the one that belongs to the PEM key.
- Do not change or delete `/work/legacy/signing.pem`.
- Do not re-sign or remove the signature on 6.14.1.

## Done when

- `/work/keys/imported.pub` is the public key of the legacy key, and `imported.key` opens only with `new-team-password`.
- `cosign verify` with the imported public key passes for the 6.15.0 digest with the annotation `rotated=true`.
- The existing signature on 6.14.1 still verifies with the same public key.
