# Predicate Types And SBOMs For Files

cosign knows several predicate types by name, and a consumer decides what to accept by type. This part lists them, shows which belong on a file download and describes how to keep the attestation useful over time.

## Predicate types cosign knows

The `--type` option accepts these short names, and a full URI for anything else:

| Short name | Predicate type URI | Used for |
| --- | --- | --- |
| `custom` | `https://cosign.sigstore.dev/attestation/v1` | Any JSON you define |
| `slsaprovenance1` | `https://slsa.dev/provenance/v1` | SLSA build provenance |
| `spdxjson` | `https://spdx.dev/Document` | An SBOM in SPDX JSON |
| `cyclonedx` | `https://cyclonedx.org/bom` | An SBOM in CycloneDX |
| `vuln` | `https://cosign.sigstore.dev/attestation/vuln/v1` | Vulnerability scan results |
| `openvex` | the OpenVEX document type | Statements about exploitability |

Any other URI works too: `--type https://example.com/attestations/review/v1` creates a statement with that predicate type.

## Attach an SBOM to the archive

An SBOM of the archive's contents is a good second attestation. Generate one with `syft` and attest it with the SPDX type:

<!-- astrona:playground:renew -->

```sh
export COSIGN_PASSWORD=lab-only-password
SC=/setup/offline-signing-config.json
cd /work/rel
syft scan file:tool-1.0.tar.gz -o spdx-json=tool-1.0.spdx.json
cosign attest-blob -y --key /work/keys/release.key --signing-config $SC \
  --type spdxjson --predicate tool-1.0.spdx.json --bundle tool-1.0.tar.gz.sbom.sigstore.json tool-1.0.tar.gz
cosign verify-blob-attestation --key /work/keys/release.pub --insecure-ignore-tlog \
  --type spdxjson --bundle tool-1.0.tar.gz.sbom.sigstore.json tool-1.0.tar.gz
```

One archive can have several attestation bundles, one for each type. A consumer asks for the type it needs and ignores the others.

## Keeping attestations useful

Name bundles so that the type is visible, as with `.att` and `.sbom` above. Publish them next to the file. Record which key signs which type, so a consumer knows which public key to pass. Rotate keys on a plan and keep old public keys available for verifying old releases.

## When an attestation is the wrong tool

If you only need to say "the release team approved this file", a signature is enough and simpler. Use an attestation when a consumer must read a fact before deciding, such as the builder, the commit or the list of components. The consumer reads the predicate and applies a rule, and the signature guarantees that the predicate was not changed.

You now have the full picture for files: sign them with a bundle, attest facts about them and verify both. The graded lab asks you to attest a release archive with its build record and to prove that the attestation cannot be moved to another file.


## Common pitfalls

> [!WARNING]
> - **Mixing the SBOM file up with the archive.** The archive is the subject; the SBOM is the predicate.
> - **Using one bundle name for several types.** Each attestation needs its own bundle file.
> - **Trusting the type name without the URI.** Check the `predicateType` field when a consumer must be sure.

## Your mission: Attest The Build Details Of A Release Archive

You can now create, read and verify an attestation for a file. The graded lab gives you a release archive and a build record and asks you to attest the archive with the release key, so that the attestation verifies for the archive and for nothing else.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-119-playground-020-03
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS119.git -c sections/section-020/module-03/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-03/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-119-lab-020-03
astrona start ats-119-playground-020-03
```
