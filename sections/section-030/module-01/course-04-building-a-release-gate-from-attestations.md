# Building A Release Gate From Attestations

A release gate rarely asks for one attestation. It asks for a set: provenance from the builder, a scan result and an SBOM, for example. Each is a separate attestation of a separate type, and the gate passes only when every required type verifies. This part builds that gate as a loop and shows where it fails.

## The list of required types

Write down the types the release must have. The names are the short names cosign accepts for `--type`:

<!-- astrona:playground:renew -->

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
REQUIRED="slsaprovenance1 vuln spdxjson"
echo $REQUIRED
```

The list is part of your release policy. It changes only through review, because it decides what may ship.

## A gate as a loop

For each type, `cosign verify-attestation` must succeed for the digest. The loop collects the types that fail:

```sh
DIGEST=$(regctl image digest $REPO:6.15.0)
MISSING=""
for t in $REQUIRED; do
  cosign verify-attestation --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry \
    --type $t $REPO@$DIGEST > /dev/null 2>&1 || MISSING="$MISSING $t"
done
if [ -z "$MISSING" ]; then echo "gate passed"; else echo "gate failed, missing:$MISSING"; fi
```

On a digest with no attestations, the gate fails and lists all three types. Attach the missing ones one by one, as in the earlier parts, and run the loop again. When the list of missing types is empty, the gate passes.

## Add the policy

Presence is not enough. A scan result with critical findings should also stop a release. Add `--policy` to the check for that type, so the same loop enforces content rules:

```sh
cosign verify-attestation --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry \
  --type vuln --policy /work/policies/no-critical.rego $REPO@$DIGEST > /dev/null 2>&1 || echo "scan policy failed"
```

The policy file is yours; a rule that reads the findings from `input.predicate` and allows only when none is critical. The check fails if the file does not exist, which is the right default: a gate must not pass because the rule is missing.

## Keep the gate and the signer separate

The key that signs attestations belongs to the builders. The gate holds only the public key. If the gate could sign, a failing release could be made to pass by signing the missing attestation. Keep the signing key where only the release process can use it.

You now know how to turn several attestation types into one release gate with content rules.


## Common pitfalls

> [!WARNING]
> - **Checking presence without type.** An SBOM attestation does not satisfy a provenance requirement.
> - **Passing the gate on a missing policy file.** Treat a missing rule as a failure.
> - **Gating by tag.** Resolve the digest first and gate that.
