# Solution: Gate A Release On Its Attestations

Work the task yourself first. Running `astrona submit -c sections/section-030/capstone/labs/lab-01` after a step tells you which checks pass.

The grader checks that both policy files exist in `package signature`, that 6.15.0 passes them, that they reject 6.14.1 whose attestations must still exist, and that 6.15.0 also passes the grader's own reference policies.

## Step 1: Set the values and look at the attestations

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
CURRENT=$(regctl image digest $REPO:6.15.0)
cosign verify-attestation --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry \
  --type vuln $REPO@$CURRENT | jq -r '.payload' | base64 -d | jq -c '[.predicate.scanner.result.Results[].Vulnerabilities[] | .Severity]'
```

The stale scan lists two `CRITICAL` findings.

## Step 2: Write the policies

Write `/work/policy/release-vuln.rego` with `vi`:

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

Write `/work/policy/release-provenance.rego`:

```rego
package signature

default allow = false

allow {
  input.predicate.runDetails.builder.id == "https://ci.inventory.example/builders/release"
}
```

Check that both reject the retired release before you touch anything:

```sh
OLD=$(regctl image digest $REPO:6.14.1)
cosign verify-attestation --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry --type vuln --policy /work/policy/release-vuln.rego $REPO@$OLD
cosign verify-attestation --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry --type slsaprovenance1 --policy /work/policy/release-provenance.rego $REPO@$OLD
```

Both fail, as they must.

## Step 3: Replace the stale attestations of 6.15.0

Every attestation of a type must pass the policy, so attaching the rescan next to the stale scan is not enough. Remove what is attached to the 6.15.0 digest, then attest the rescan and the release provenance:

```sh
cosign clean --type all -f --allow-http-registry $REPO@$CURRENT
cosign attest --key /work/keys/release.key --signing-config $SC --allow-http-registry -y \
  --type vuln --predicate /work/predicates/vuln-rescan.json $REPO@$CURRENT
cosign attest --key /work/keys/release.key --signing-config $SC --allow-http-registry -y \
  --type slsaprovenance1 --predicate /work/predicates/provenance-release.json $REPO@$CURRENT
```

`cosign clean` works on one digest only, so 6.14.1 keeps its attestations.

## Step 4: Run the gate

```sh
cosign verify-attestation --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry --type vuln --policy /work/policy/release-vuln.rego $REPO@$CURRENT > /dev/null && echo "vuln gate passed"
cosign verify-attestation --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry --type slsaprovenance1 --policy /work/policy/release-provenance.rego $REPO@$CURRENT > /dev/null && echo "provenance gate passed"
```

## Step 5: Submit

Leave the workstation shell with `exit`, and send the capstone for grading from your own terminal:

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Attach the rescan without removing the stale scan | The stale scan still fails the policy, so the whole check fails |
| Write `allow { true }` | 6.14.1 passes too, and the grader's reference policies catch the critical findings |
| Clean 6.14.1 so the old release stops failing | Its attestations are its history; the grader checks they are still there |
| Write `allow if { ... }` | cosign evaluates Rego v0 syntax and refuses the policy |
