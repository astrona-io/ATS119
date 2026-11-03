# How Cosign Evaluates A Policy

A verified attestation proves who signed a statement. It does not decide whether the content is acceptable. A policy does that. cosign can evaluate a policy during `verify-attestation` and fail the command when the content does not meet the rule. This part explains what the policy receives, what it must return and which language cosign expects.

## What a policy is

A **policy** is a small program that reads the statement and answers yes or no. cosign supports two policy languages: Rego, the language of Open Policy Agent, and CUE. cosign chooses the language from the file extension: `.rego` or `.cue`. This module uses Rego.

For Rego, cosign loads the file and evaluates the query `data.signature.allow`. Three rules follow from that:

- The file must declare `package signature`.
- The file must define a rule named `allow`.
- The command succeeds only if `allow` is true for every attestation of the checked type.

The input document, `input`, is the whole in-toto statement: `input.subject`, `input.predicateType` and `input.predicate`. The content you wrote as the predicate is under `input.predicate`.

## Rego syntax that cosign uses

cosign evaluates Rego in the older syntax, version 0. A rule is written `allow { ... }`, and the lines inside the braces must all be true. Do not write `allow if { ... }`: that is the newer syntax, and cosign does not accept it. A `default allow = false` line makes the rule false when no body matches.

## A first policy for the review record

Attach a review record to the current release first. Then write a policy that accepts it only if the result is `approved`:

<!-- astrona:playground:renew -->

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
mkdir -p /work/keys /work/predicates /work/policies && cd /work/keys && cosign generate-key-pair --output-key-prefix release && cd /work
printf '{"reviewer":"release-team","result":"approved","ticket":"INV-1042"}\n' > /work/predicates/review.json
DIGEST=$(regctl image digest $REPO:6.15.0)
cosign attest -y --key /work/keys/release.key --signing-config $SC --allow-http-registry \
  --type https://inventory.example/attestations/review/v1 --predicate /work/predicates/review.json $REPO@$DIGEST
cat > /work/policies/review.rego <<'EOF'
package signature

default allow = false

allow {
  input.predicate.result == "approved"
}
EOF
```

You now know the contract between cosign and a policy file. The next part runs it.


## Common pitfalls

> [!WARNING]
> - **Using another package name.** cosign queries `data.signature.allow`.
> - **Writing `allow if {{`.** cosign uses the Rego v0 syntax.
> - **Reading `input.result`.** `input` is the statement, so the predicate is `input.predicate`.
