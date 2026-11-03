# Rules On SBOM Content

SBOMs are large documents, and a policy usually checks a few fields of them: which tool made the SBOM, whether it lists any packages, whether a forbidden package appears. This part writes three rules on SPDX content and combines them.

## The fields of an SPDX statement

For an attestation made with `--type spdxjson`, `input.predicate` is the SPDX document. These fields are useful in a policy:

- `input.predicate.creationInfo.creators`: a list of strings such as `Tool: syft-1.55.0`.
- `input.predicate.packages`: the list of packages, each with `name` and `versionInfo`.
- `input.predicate.spdxVersion`: the SPDX version string.

## A rule on the tool

The `creators` list has several entries. In Rego, `creators[_]` visits each one, and the rule is true when at least one entry meets the condition. `startswith` allows any version of the tool:

<!-- astrona:playground:renew -->

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
mkdir -p /work/sbom /work/policies
DIGEST=$(regctl image digest $REPO:6.15.0)
syft scan registry:$REPO@$DIGEST -o spdx-json=/work/sbom/podinfo-6.15.0.spdx.json
cosign attest -y --key /work/keys/release.key --signing-config $SC --allow-http-registry \
  --type spdxjson --predicate /work/sbom/podinfo-6.15.0.spdx.json $REPO@$DIGEST
cat > /work/policies/sbom.rego <<'EOF'
package signature

default allow = false

allow {
  creator := input.predicate.creationInfo.creators[_]
  startswith(creator, "Tool: syft-")
  count(input.predicate.packages) > 0
}
EOF
cosign verify-attestation --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry \
  --type spdxjson --policy /work/policies/sbom.rego $REPO@$DIGEST > /dev/null && echo "sbom policy passed"
```

Both conditions are lines of one rule body, so both must hold. The first one needs one creator that starts with `Tool: syft-`. The second needs at least one package.

## A rule that forbids a package

To block a package, you write a rule that is true when the package is present, and require its negation. Rego uses `not` for this. A helper rule keeps the policy readable:

```sh
cat > /work/policies/no-openssl.rego <<'EOF'
package signature

default allow = false

has_forbidden {
  pkg := input.predicate.packages[_]
  pkg.name == "openssl-legacy"
}

allow {
  not has_forbidden
}
EOF
cosign verify-attestation --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry \
  --type spdxjson --policy /work/policies/no-openssl.rego $REPO@$DIGEST > /dev/null && echo "no forbidden package"
```

The rule `has_forbidden` is true if some package has that name. The rule `allow` is true if `has_forbidden` is not true. The image does not contain a package of that name, so the check passes. Change the name to one that the SBOM lists, and it fails.

## What a policy cannot know

A policy sees only the SBOM. If the scanner missed a package, the policy cannot see it. A rule such as "no forbidden package" is only as good as the SBOM it reads, which is why a policy on the creator tool and on the package count is a useful companion.

You can now write rules on SPDX content. The last part compares Rego with CUE and describes how policies fit a release process.


## Common pitfalls

> [!WARNING]
> - **Comparing the full creator string.** The tool version changes; use `startswith`.
> - **Using `not` on a rule with no `default`.** Define the helper rule clearly, and keep `default allow = false`.
> - **Believing the policy checks the image.** It checks the SBOM.
