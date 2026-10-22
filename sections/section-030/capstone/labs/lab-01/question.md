# Question

Solve this question on: `terminal`

**Time:** about 40 minutes · **Topic:** Policies

## Scenario

The inventory team's release gate checks two rules before a release reaches production: the build must come from the release builder `https://ci.inventory.example/builders/release`, and the Trivy scan must show no `CRITICAL` vulnerability. The gate runs `cosign verify-attestation` with two Rego policies that nobody has written yet.

Release 6.15.0 currently carries a stale scan from September with two critical findings, and provenance from the developer builder. A fresh scan and the release provenance are ready in `/work/predicates`: `vuln-rescan.json` and `provenance-release.json`. The old release 6.14.1 is retired; its attestations, a scan with a critical finding and developer provenance, must stay as they are.

The release key pair is at `/work/keys/release.*` (password `lab-only-password`). Work in a workstation shell: `kubectl -n workstation exec -it deploy/workstation -- sh`.

## Your task

1. Write `/work/policy/release-vuln.rego`: allow a `vuln` attestation only when the scanner is Trivy and the result has no `CRITICAL` vulnerability.
2. Write `/work/policy/release-provenance.rego`: allow a `slsaprovenance1` attestation only when the builder is the release builder.
3. Make 6.15.0 pass both policies with `cosign verify-attestation` and the release public key. Sign everything with the signing configuration `/setup/offline-signing-config.json`.

## Constraints

- Both policies are Rego, in `package signature`, as cosign requires.
- Do not change or remove the attestations of 6.14.1.
- Do not change the predicate files.

## Done when

- 6.15.0 passes `release-vuln.rego` with `--type vuln` and `release-provenance.rego` with `--type slsaprovenance1`.
- 6.14.1 fails both policies, and its attestations are still there.
- 6.15.0 carries no attestation that lists a `CRITICAL` vulnerability or names the developer builder.
