# Solution: Require A Trusted SBOM Tool With A Rego Policy

Work the task yourself first. Running `astrona submit -c sections/section-030/module-03/labs/lab-01` after a step tells you which checks pass.

The grader runs your policy against both digests with its own copy of the release public key. The policy must pass the 6.15.0 attestation and reject the 6.14.1 attestation.

## Step 1: Set the values and read an SBOM

Open a workstation shell and set the values the commands use:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
```

Look at the field the policy has to read in each SBOM:

```sh
jq '.creationInfo.creators, (.packages | length)' /work/sbom/podinfo-6.15.0.spdx.json
jq '.creationInfo.creators, (.packages | length)' /work/sbom/podinfo-6.14.1.spdx.json
```

The first SBOM names `Tool: syft-1.55.0`. The second names a different tool.

## Step 2: Write the policy

cosign evaluates the query `data.signature.allow` against the in-toto statement, so the package is `signature` and the rule is `allow`. The SPDX document is the `predicate` of the statement. cosign uses Rego v0 syntax, so the rule is written `allow { ... }`:

```rego
package signature

default allow = false

allow {
  creator := input.predicate.creationInfo.creators[_]
  startswith(creator, "Tool: syft-")
  count(input.predicate.packages) > 0
}
```

Save it as `/work/policies/sbom-tool.rego`. A rule body is true when every line in it is true. `creators[_]` tries each creator in turn, so one matching creator is enough.

## Step 3: Check both releases

```sh
cosign verify-attestation --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry \
  --type spdxjson --policy /work/policies/sbom-tool.rego $REPO@$(regctl image digest $REPO:6.15.0) > /dev/null && echo "6.15.0: policy passed"
cosign verify-attestation --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry \
  --type spdxjson --policy /work/policies/sbom-tool.rego $REPO@$(regctl image digest $REPO:6.14.1) > /dev/null || echo "6.14.1: policy failed, as intended"
```

The first check passes. The second fails because no creator of the 6.14.1 SBOM starts with `Tool: syft-`.

## Step 4: Submit

Leave the workstation shell with `exit`, and send the lab for grading from your own terminal:

```sh
astrona submit -c sections/section-030/module-03/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| `allow = true` | The 6.14.1 attestation passes too, and the grader requires it to fail |
| Write `allow if { ... }` | cosign evaluates Rego v0 syntax and does not accept `if` |
| Use another package name | cosign asks for `data.signature.allow`, which does not exist |
| Delete the 6.14.1 attestation | The grader expects the attestation to stay and the policy to reject it |

## Common mistakes

- Reading `input.creationInfo` instead of `input.predicate.creationInfo`. `input` is the whole statement.
- Comparing the whole creator string with `==`. The version after `syft-` changes, so use `startswith`.
- Testing only the release that must pass.
