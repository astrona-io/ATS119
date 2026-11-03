# Summary

An attestation is a signed statement about an artifact. It uses the in-toto statement format: `subject` lists the artifacts and their digests, `predicateType` is a URI that says what kind of fact it is, and `predicate` holds the fact. cosign builds the statement from your predicate file and the image digest, signs it in a DSSE envelope, and stores it in the registry as a referrer of the image.

`cosign attest --type` turns a short name into the predicate type. `slsaprovenance1` is SLSA provenance v1, with `buildDefinition` and `runDetails.builder.id`; `vuln` is cosign's vulnerability scan format, with `scanner`, `invocation` and `metadata`; `spdxjson` and `cyclonedx` carry SBOMs; `custom` is the default. cosign checks the shape of some predicates, such as `vuln` and `slsaprovenance1`, before it signs them.

`cosign verify-attestation --type` checks each attestation's signature with the public key and keeps those of the requested type. Each output line is an envelope whose `payload` is the base64-encoded statement. Verification proves who signed a statement and which digest it is about, not that its content is good.

`--policy` adds a content check in Rego or CUE. A Rego policy is in `package signature`, defines `allow`, uses Rego v0 syntax, and receives the statement as `input`. Every attestation of the requested type must pass, so stale attestations must be removed before a gate passes. The attestations of releases you do not change stay as their history.

Attestations are OCI referrers of the image digest, so removing them means deleting those referrers. `cosign clean` does this job, but cosign 3.1.4 ignores `--allow-http-registry` for it, so it only works against an HTTPS registry. On the plain-HTTP lab registry, `regctl artifact list` lists the referrers and `regctl manifest delete --referrers` deletes them. The key facts to remember are these:

- Attest the digest, with the precise predicate type.
- Verify with the same `--type` you attested with.
- Decode `payload` with `base64 -d` to read the statement.
- Test every policy against an input that must fail.

<!-- astrona:playground:destroy -->
