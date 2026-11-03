# Summary

An SBOM is a list of the components in an image. `syft scan registry:<repo>@<digest>` generates one, and `-o spdx-json=<file>` writes the SPDX JSON format. The SBOM should be generated from the digest that will be attested and checked for a non-zero package count, since an empty list usually means the scan failed. An SBOM describes the image at scan time and depends on the scanner; it does not make the image safe.

`cosign attest --type spdxjson --predicate <file>` wraps the SBOM in an in-toto statement whose subject is the image digest, signs it and attaches it to the image as a referrer. A signature and an attestation are different referrers of the same digest: a signature approves the image, and an attestation states a fact about it. Verification uses `cosign verify-attestation` with the matching `--type`, and the output has one JSON line for each attestation, whose `payload` field is the base64 encoded statement.

For facts without a standard type, `--type` takes a URI that the team controls and versions. One digest can carry attestations of several types, and each check sees only its own type. A digest without the required attestation fails the check, which makes a release gate possible. Reading predicates with `jq` informs people, while `--policy` enforces rules. Key facts:

- Scan, sign and verify the digest, never the tag.
- `--type` names the predicate type when attaching and when verifying.
- The subject of the statement is the image digest.
- A missing attestation is a failed verification.

<!-- astrona:playground:destroy -->
