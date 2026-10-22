# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Attestations

## Scenario

The inventory team's release gate will soon require two attestations on every release: the SLSA provenance from the release builder and the vulnerability scan from Trivy. The 6.15.0 release has neither yet. The predicates are ready, and so is the release key.

The release key pair is at `/work/keys/release.key` and `/work/keys/release.pub` (password `lab-only-password`). The predicates are `/work/predicates/provenance.json` (SLSA provenance version 1) and `/work/predicates/vuln.json` (a Trivy scan in cosign's vulnerability format). Work in a workstation shell: `kubectl -n workstation exec -it deploy/workstation -- sh`.

## Your task

1. Attach the provenance to the digest of `registry.localtest.me:5001/inventory/podinfo:6.15.0` as a SLSA provenance version 1 attestation.
2. Attach the scan to the same digest as a vulnerability attestation.
3. Sign both with the release key and the signing configuration `/setup/offline-signing-config.json`.

## Constraints

- Do not change the predicate files.
- Do not attest `inventory/podinfo:6.14.1`.

## Done when

- `cosign verify-attestation --type slsaprovenance1` with the release public key passes for the 6.15.0 digest, and the statement names the builder `https://ci.inventory.example/builders/release`.
- `cosign verify-attestation --type vuln` passes for the same digest, and the scanner is Trivy.
- The 6.14.1 digest carries no attestation from the release key.
