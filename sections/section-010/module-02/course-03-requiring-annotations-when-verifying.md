# Requiring Annotations When Verifying

When a digest carries several signatures, a plain `cosign verify` is not enough to answer a question such as "was this approved for production?". The verifier has to require the annotation. This part uses `cosign verify -a` as that requirement and explains exactly how cosign matches it.

## The annotation filter

`cosign verify -a key=value` keeps only the signatures whose payload carries that annotation with that exact value. If at least one signature remains, the check passes. If none remains, cosign exits with an error. Ask for the production signature:

<!-- astrona:playground:renew -->

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
DIGEST=$(regctl image digest $REPO:6.15.0)
cosign verify --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry \
  -a env=production $REPO@$DIGEST | jq -c '.[].optional'
```

Only the production signature comes back. Its `optional` object also shows `approved-by`, because the filter does not hide the other annotations of a signature it keeps.

## All annotations must be on one signature

When you give more than one `-a`, one single signature must carry all of them. Two signatures that each carry one of the annotations do not satisfy the check:

```sh
cosign verify --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry \
  -a env=production -a approved-by=release-team $REPO@$DIGEST > /dev/null && echo "passes"
cosign verify --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry \
  -a env=staging -a approved-by=release-team $REPO@$DIGEST > /dev/null || echo "fails"
```

The first check passes, because the production signature has both annotations. The second fails, because no single signature has `env=staging` together with `approved-by=release-team`.

## Values match exactly

cosign compares the value as a string. `env=Production` does not match `env=production`, and `env=prod` does not match either. A typo in a value gives the same error as a missing signature, so check the spelling first when a verification that should pass fails.

```sh
cosign verify --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry \
  -a env=Production $REPO@$DIGEST > /dev/null 2>&1 || echo "no signature carries env=Production"
```

## Reading the result in a script

A pipeline can use the exit code of the command, or read the payload with `jq`. The exit code is the simpler, safer choice because it is zero only when a signature with all annotations verifies.

You can now require an exact set of annotations in one signature. What is left is to use this in a release flow, where the old release must never look approved.


## Common pitfalls

> [!WARNING]
> - **Expecting a partial match.** Annotation values are compared as whole strings.
> - **Splitting required annotations over two signatures.** One signature must hold all of them.
> - **Reading the payload with `jq` instead of using `-a`.** A script that only prints annotations does not fail when they are wrong.
