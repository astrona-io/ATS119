# Running And Testing A Policy

Writing a policy is easy to get wrong in a way that still lets everything through, so the policy must be tested in both directions: it must accept what is right and reject what is wrong. This part runs the policy from the previous part, then changes the input to see it fail.

## Run the policy

Pass the policy file to `cosign verify-attestation` with `--policy`. The type must still be given, because it selects which attestations are checked:

<!-- astrona:playground:renew -->

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
DIGEST=$(regctl image digest $REPO:6.15.0)
cosign verify-attestation --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry \
  --type https://inventory.example/attestations/review/v1 --policy /work/policies/review.rego $REPO@$DIGEST > /dev/null && echo "policy passed"
```

cosign first verifies the signature of every attestation of the type. It then evaluates the policy against each statement. The command succeeds only if all of them pass.

## Make it fail

Attach a second review attestation whose result is `rejected`, then run the same check:

```sh
printf '{"reviewer":"security-team","result":"rejected","ticket":"INV-1043"}\n' > /work/predicates/review-rejected.json
cosign attest -y --key /work/keys/release.key --signing-config $SC --allow-http-registry \
  --type https://inventory.example/attestations/review/v1 --predicate /work/predicates/review-rejected.json $REPO@$DIGEST
cosign verify-attestation --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry \
  --type https://inventory.example/attestations/review/v1 --policy /work/policies/review.rego $REPO@$DIGEST > /dev/null || echo "policy failed"
```

The check fails, although the approving attestation is still there. Every attestation of the type has to satisfy the policy, so one bad record blocks the release. This is a safe default: a rejection cannot be hidden by adding an approval next to it.

## What a failure looks like

When a policy fails, cosign reports that the policy was not satisfied for the attestation and exits with a non-zero status. A syntax error in the file gives a different message that names the line. Fix syntax errors first, then test the rule.

## Always test the negative case

A policy that is always true passes the first test, because everything passes. Only the failing test proves that the rule has an effect. Keep a rejected example next to every policy. When a test only passes, you have only tested half of it.

You can now run a policy and show that it rejects what it should. The next part writes rules for the content of an SBOM.


## Common pitfalls

> [!WARNING]
> - **Testing only the passing case.** A policy of `allow = true` passes too.
> - **Expecting an extra approval to fix a rejection.** All attestations of the type must pass.
> - **Forgetting `--type`.** The policy is applied to the attestations of that type.
