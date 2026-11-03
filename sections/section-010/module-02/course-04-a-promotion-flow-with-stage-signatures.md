# A Promotion Flow With Stage Signatures

A release flow decides which digest may run in which environment. Signatures with annotations are the evidence, and the verifier is the gate. This part walks through a promotion from staging to production, shows that the old release stays unapproved and lists how this goes wrong in practice.

## A promotion flow

The flow has three steps. The build system signs the new digest with `env=staging`. After tests pass, the release team signs the same digest with `env=production`. The production cluster accepts only an image whose digest verifies with `-a env=production`. The same key can make both signatures, because the annotation, not the key, tells the stage.

Check the gate on both releases:

<!-- astrona:playground:renew -->

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
NEW=$(regctl image digest $REPO:6.15.0)
OLD=$(regctl image digest $REPO:6.14.1)
for d in $NEW $OLD; do
  cosign verify --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry \
    -a env=production $REPO@$d > /dev/null 2>&1 && echo "$d: approved for production" || echo "$d: not approved"
done
```

The new digest is approved. The old digest is not, because nobody signed it. The old release is not wrongly rejected: it simply has no production signature.

## The gate follows the digest, not the tag

If you move the tag `6.15.0` to the old image, the gate verifies the digest it resolves, finds no production signature and refuses. Moving a tag cannot grant approval. Only a new signature can, and only a holder of the key can make one.

## Using a different key per stage

Annotations tell the stage, but a key tells who signed. Many teams use one key for the build system and another for the release team. The production gate then checks the release team key with `--key release-team.pub -a env=production`. A signature with the right annotation from the wrong key does not pass. Try it with a second key pair:

```sh
cd /work/keys && cosign generate-key-pair --output-key-prefix dev && cd /work
cosign sign --key /work/keys/dev.key --signing-config $SC --allow-http-registry -y -a env=production $REPO@$OLD
cosign verify --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry -a env=production $REPO@$OLD > /dev/null 2>&1 || echo "release key does not accept the dev signature"
```

The dev key signed the old release with `env=production`, yet verification with the release public key still fails. Verification binds the key and the annotations together.

You now know how a release gate uses annotations and keys: the digest must carry a signature from the trusted key with the required annotations. The graded lab asks you to build exactly this state for the current release.


## Common pitfalls

> [!WARNING]
> - **Trusting an annotation without checking the key.** Anyone with any key can write `env=production`. Always verify with the public key you trust.
> - **Approving by tag.** Verify and deploy the digest, not the tag.
> - **Signing the old release to make a check pass.** The old release must stay unapproved.

## Your mission: Sign The Release For Production

You can now annotate a signature, keep earlier signatures and require annotations when verifying. The graded lab starts with a release that has only a staging signature. You add a production signature with two annotations and prove that the old release is not approved.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-119-playground-010-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS119.git -c sections/section-010/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-119-lab-010-02
astrona start ats-119-playground-010-02
```
