# Summary

A policy decides whether the content of a verified attestation is acceptable. `cosign verify-attestation --policy` first verifies the signature of every attestation of the chosen `--type`, then evaluates the policy against each statement. The command succeeds only if all of them satisfy the policy, so one bad attestation blocks the release, and an extra good one cannot hide it.

cosign evaluates Rego in the version 0 syntax. The file declares `package signature` and defines a rule named `allow`, because cosign queries `data.signature.allow`. The input is the whole in-toto statement, so the content of the attestation is under `input.predicate`. Rules are written `allow { ... }` with all lines in the body true, and `default allow = false` closes the policy when nothing matches. CUE policies, chosen by the `.cue` extension, describe the shape the statement must have.

Policies on SPDX content read fields such as the creators list and the package list. A policy can require a trusted tool with `startswith`, require a non-empty package list, or forbid a package with a helper rule and `not`. It sees only the SBOM, not the image. A policy must be tested in both directions, with an example that passes and one that fails, and it belongs in version control with the same review as other code that controls deployment. Key facts:

- Package `signature`, rule `allow`, query `data.signature.allow`.
- `input` is the statement; the attested content is `input.predicate`.
- All attestations of the type must pass.
- Always test a failing case.

<!-- astrona:playground:destroy -->
