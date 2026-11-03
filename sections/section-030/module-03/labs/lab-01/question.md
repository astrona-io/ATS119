# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Policies on attestations

## Scenario

Both `inventory/podinfo:6.15.0` and `inventory/podinfo:6.14.1` carry an SPDX JSON SBOM attestation signed by the release key. The security team only trusts SBOMs that `syft` generated, because the SPDX document records the tool in `creationInfo.creators` as a string such as `Tool: syft-1.55.0`. The SBOM of 6.14.1 was written by hand with another tool. The release key pair is in `/work/keys` (`release.pub`) and the SBOM files are in `/work/sbom`.

Work in a workstation shell: `kubectl -n workstation exec -it deploy/workstation -- sh`. The registry is `registry.localtest.me:5001` (the variable `REGISTRY` holds it). The folder `/work/policies` exists.

## Your task

1. Write a Rego policy in `/work/policies/sbom-tool.rego` that accepts an SPDX attestation only when one of its `creationInfo.creators` starts with `Tool: syft-` and the document lists at least one package.
2. Use cosign's policy conventions: the package name and the rule that cosign evaluates.
3. Check the policy against both releases with `cosign verify-attestation --policy`.

## Constraints

- Do not change, add or remove any attestation or signature.
- The policy must not accept every statement. It has to look at the creators.

## Done when

- `cosign verify-attestation --type spdxjson --policy /work/policies/sbom-tool.rego` with the release public key passes for the 6.15.0 digest.
- The same command fails for the 6.14.1 digest.
