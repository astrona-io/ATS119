# Checking Attestations With A Policy

Reading attestations by hand works for one release, not for every deployment. A release gate needs a rule it can apply automatically: "accept only provenance from the release builder" or "accept only scans with no critical findings". `cosign verify-attestation --policy` applies such a rule to every attestation it verifies. This part writes those rules in Rego.

## How cosign runs a policy

A **policy** is a small program that looks at a statement and answers allow or deny. cosign v3.1.4 accepts policies in two languages, chosen by the file extension: **CUE** (`.cue`), a data constraint language, and **Rego** (`.rego`), the policy language of Open Policy Agent. This course uses Rego.

cosign runs a Rego policy with a fixed contract:

- The policy is in `package signature`.
- cosign evaluates the rule `allow`, so the policy must define `allow`, and it passes only when `allow` is true.
- The input, `input`, is the in-toto statement of one attestation, already verified and decoded: `input.predicateType`, `input.subject` and `input.predicate`.
- cosign evaluates Rego in its older syntax (Rego v0), so a rule is written `allow { ... }` without the keyword `if`.

## Write a provenance policy

Start with the simplest rule: the provenance must name the release builder. The condition inside the braces must be true for `allow` to be true, and `default allow = false` makes the answer false when no rule matches. Policy files live in `/work/policy` in the workstation; create the folder with `mkdir -p /work/policy` and write the files with `vi`, the editor in the workstation.

Save this as `/work/policy/release-provenance.rego`:

<!-- astrona:playground:renew -->

```rego
package signature

default allow = false

allow {
  input.predicate.runDetails.builder.id == "https://ci.inventory.example/builders/release"
}
```

Run it against the release you attested earlier on this page's playground, with `--policy`:

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
DIGEST=$(regctl image digest $REPO:6.15.0)
cosign verify-attestation --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry \
  --type slsaprovenance1 --policy /work/policy/release-provenance.rego $REPO@$DIGEST > /dev/null && echo "policy passed"
```

The command passes. Change the builder in the policy to another value and run it again: cosign reports a validation error and exits with an error. If the release has no provenance attestation yet, attest `/work/predicates/provenance.json` as `slsaprovenance1` first.

## Write a scan policy

A scan policy counts findings. The rule below collects every vulnerability with severity `CRITICAL` from the Trivy report inside the predicate, and allows the scan only when the scanner is Trivy and the list is empty.

Save this as `/work/policy/release-vuln.rego`:

```rego
package signature

default allow = false

critical := [v |
  v := input.predicate.scanner.result.Results[_].Vulnerabilities[_]
  v.Severity == "CRITICAL"
]

allow {
  startswith(input.predicate.scanner.uri, "pkg:github/aquasecurity/trivy@")
  count(critical) == 0
}
```

Run it with `--type vuln`:

```sh
cosign verify-attestation --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry \
  --type vuln --policy /work/policy/release-vuln.rego $REPO@$DIGEST > /dev/null && echo "policy passed"
```

The release scan has one low finding and no critical ones, so the policy passes.

## Every attestation must pass

One rule of `verify-attestation` surprises many people: **every attestation of the requested type must pass the policy**. If an image carries an old scan with critical findings and a new clean scan, the check fails, because the old one fails. cosign does not pick the newest or the best one. So when a scan or a build is redone, the old attestation must go before the gate can pass.

cosign v3 stores signatures and attestations as OCI referrers: artifacts in the registry whose `subject` field points at the image digest. `cosign clean` removes referrers, but cosign 3.1.4 ignores `--allow-http-registry` for it, so it only works against an HTTPS registry. In the lab, `regctl` does it instead, because it already talks plain HTTP to the lab registry.

`regctl artifact list` prints the digest of each referrer of the image, and `regctl manifest delete --referrers` deletes each one. This loop removes everything attached to the release digest:

```sh
for referrer in $(regctl artifact list $REPO@$DIGEST --format '{{range .Descriptors}}{{.Digest}} {{end}}'); do
  regctl manifest delete --referrers $REPO@$referrer
done
```

The `--referrers` flag also removes each deleted manifest from the list of referrers that the clients keep for that digest; without it, the list still names the deleted attestation. The loop touches one digest only, and the image itself stays. Afterwards, attach the new attestations again, and sign the image again if it needs a signature. Never remove the referrers of an image you do not mean to change: the attestations of an old release are its history.

You can now turn a review rule into a policy file and let cosign apply it, and you know why stale attestations must be removed before a gate passes.

## Common pitfalls

> [!WARNING]
> - **Writing `allow if { ... }`.** cosign evaluates Rego v0 syntax; write `allow { ... }`.
> - **Using another package name.** cosign asks for `data.signature.allow`, so the package must be `signature`.
> - **Forgetting `default allow = false`.** Without it, a statement that matches no rule leaves `allow` undefined, which cosign also treats as a failure, but the intent is less clear.
> - **Expecting the newest attestation to win.** Every attestation of the type must pass. Remove stale ones.
> - **Deleting a referrer without `--referrers`.** The list of referrers for the digest still names the deleted manifest.
> - **Writing a policy that passes everything.** Test it against an input that must fail, not only against one that must pass.
