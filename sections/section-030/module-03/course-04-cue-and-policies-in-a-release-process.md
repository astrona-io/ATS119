# CUE And Policies In A Release Process

Rego is not the only language, and a policy file is only useful if it is part of a process. This part shows the same rule in CUE, explains which language to choose and describes how a policy file is kept and used.

## The same rule in CUE

A CUE policy describes the shape the statement must have. cosign loads a file with the `.cue` extension and checks the statement against it. For the review attestation, this file requires the predicate type and a result of `approved`:

<!-- astrona:playground:renew -->

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
DIGEST=$(regctl image digest $REPO:6.15.0)
cat > /work/policies/review.cue <<'EOF'
predicateType: "https://inventory.example/attestations/review/v1"
predicate: {
  result: "approved"
}
EOF
cosign verify-attestation --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry \
  --type https://inventory.example/attestations/review/v1 --policy /work/policies/review.cue $REPO@$DIGEST > /dev/null || echo "cue policy failed"
```

If you attached the rejected review in the previous part, the check fails here too, for the same reason: all attestations of the type must satisfy the policy. If only the approved record exists, it passes.

## Choosing a language

CUE is short and good for fixed shapes: a field must equal a value. Rego can express conditions: a list contains an entry that starts with a string, a package is absent, a number is greater than another. Use CUE for simple checks and Rego when a rule needs logic. Both run inside `cosign verify-attestation`.

## Policies as files in a repository

A policy file is code. Keep it in version control, review changes to it and give it the same care as a deployment manifest. A change to a policy changes what is allowed to run, so it needs a reviewer. Keep a negative test next to it, such as a rejected example, and run both on every change.

## Where the check runs

Policies are used at three points: in the build pipeline before release, in a deployment step before an image is rolled out, and in a cluster admission controller. The command you used here is the pipeline form. The same rule files can be evaluated by tools that run in a cluster. Whichever place you choose, the policy needs the trusted public key, because it decides whose signature counts.

You now know how to check the content of attestations with Rego and CUE, and how a policy fits a release. The graded lab asks you to write a Rego policy that accepts an SBOM made by the trusted tool and rejects one made by another tool.


## Common pitfalls

> [!WARNING]
> - **Mixing up the language and the extension.** cosign chooses by `.rego` or `.cue`.
> - **Treating a policy as documentation.** It is code that decides what runs.
> - **Leaving the negative test out.** A policy without a failing example is untested.

## Your mission: Require A Trusted SBOM Tool With A Rego Policy

You can now write, run and test policies on attestation content. The graded lab gives you two releases whose SBOMs were made by different tools. You write a Rego policy that accepts the first and rejects the second.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-119-playground-030-03
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS119.git -c sections/section-030/module-03/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-03/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-119-lab-030-03
astrona start ats-119-playground-030-03
```
