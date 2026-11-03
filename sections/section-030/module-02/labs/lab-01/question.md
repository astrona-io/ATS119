# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Attestations

## Scenario

The inventory team wants two attestations on the current release, `inventory/podinfo:6.15.0`: the software bill of materials in SPDX JSON, and a record that the release team reviewed the release. The release key pair is in `/work/keys` (`release.key`, `release.pub`) with the lab-only password `lab-only-password`. The review record is in `/work/predicates/review.json`. The folder `/work/sbom` is empty and waits for the SBOM.

Work in a workstation shell: `kubectl -n workstation exec -it deploy/workstation -- sh`. The registry is `registry.localtest.me:5001` (the variable `REGISTRY` holds it). Sign with the offline signing configuration `/setup/offline-signing-config.json`.

## Your task

1. Generate an SPDX JSON SBOM of `registry.localtest.me:5001/inventory/podinfo:6.15.0` (by its digest) with `syft` and save it in `/work/sbom`.
2. Attach the SBOM to the 6.15.0 digest as an attestation of type `spdxjson`.
3. Attach `/work/predicates/review.json` to the same digest as an attestation with the predicate type `https://inventory.example/attestations/review/v1`.

## Constraints

- Sign with the existing release key. Do not create or replace a key pair.
- Attach the attestations to the digest of 6.15.0 only. Do not attest 6.14.1.

## Done when

- `cosign verify-attestation --type spdxjson` with the release public key passes for the 6.15.0 digest, and the statement has the predicate type `https://spdx.dev/Document`.
- `cosign verify-attestation` with the review predicate type passes for the 6.15.0 digest.
- The 6.14.1 digest has no SPDX attestation.
