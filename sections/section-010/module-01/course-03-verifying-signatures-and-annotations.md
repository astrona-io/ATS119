# Verifying Signatures And Annotations

Signing is half the work. The other half is the check a deployment system or a person runs before they trust an image: does this exact image carry a signature from a key I trust, and does the signature say what I expect? This part verifies the release with the public key, adds annotations to a signature, and shows what happens when the image changes.

## Verify with the public key

`cosign verify --key` finds the signatures attached to an image and checks each one with the public key. Set the usual variables, then verify the signed digest:

<!-- astrona:playground:renew -->

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
DIGEST=$(regctl image digest $REPO:6.15.0)
cosign verify --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry $REPO@$DIGEST | jq .
```

cosign prints that the signature was verified against the key, and then the **signed payload** as JSON. The payload is the small document cosign actually signed. Its `critical` part names the image: `critical.identity.docker-reference` is the repository, and `critical.image.docker-manifest-digest` is the digest you signed. A verifier trusts the digest in the payload, not the tag it was asked about.

The flag `--insecure-ignore-tlog` tells cosign not to look for a transparency log entry. The signature has none, because the offline signing configuration listed no log. The flag name says "insecure" on purpose: without a log entry, nobody else can see that this signature was made, and you rely on the key alone. In this course that is the deliberate trade-off; for public releases you keep the log.

## Add annotations

An **annotation** is a key=value pair that cosign adds to the payload before it signs. Because the annotation is inside the signed payload, nobody can change it without breaking the signature. Teams use annotations to record facts such as the release number or the team that approved it.

Sign the release a second time, with two annotations. `-a` adds one annotation each time you use it:

```sh
cosign sign --key /work/keys/release.key --signing-config $SC --allow-http-registry -y \
  -a release=6.15.0 -a team=inventory $REPO@$DIGEST
```

Now the image has two signatures: the first one without annotations and this one with them. `cosign verify -a` adds a condition: at least one signature must carry every annotation you name.

```sh
cosign verify --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry \
  -a release=6.15.0 -a team=inventory $REPO@$DIGEST | jq '.[].optional'
```

The annotations appear in the `optional` part of the payload. Ask for an annotation no signature carries, for example `-a team=payments`, and cosign reports that no signature matched.

## What the verifier sees when the image changes

The point of signing a digest shows when a tag moves. Verify the old release with the release key:

```sh
OLD=$(regctl image digest $REPO:6.14.1)
cosign verify --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry $REPO@$OLD
```

cosign finds no valid signature and exits with an error. If someone moved the tag `6.15.0` to the old image, a verifier that checks `$REPO:6.15.0` would resolve the tag, get the old digest, and fail in exactly this way. The signature protects the digest, so it cannot follow a tag to a different image.

The same check tells you which key made a signature. Create a second key pair, `dev`, and verify the release with it: the check fails, because the release was signed with `release.key` only. Verifying with each public key you know is the simplest way to find out who signed an image.

You can now sign a digest with annotations and verify both the signature and its annotations. You also know what `--insecure-ignore-tlog` gives up: public evidence that the signature exists.

## Common pitfalls

> [!WARNING]
> - **Verifying the tag and trusting the result for later.** A verification is true for the digest the tag pointed at during the check. Deploy by that digest.
> - **Forgetting that `-a` is a filter.** `cosign verify` without `-a` passes as soon as any signature from the key is valid, even one without the annotations you care about.
> - **Using `--insecure-ignore-tlog` out of habit.** It is right for signatures that were never logged. For signatures from the public-good instance, keep the log check.
> - **Mixing up the keys.** Verify with the `.pub` file; signing needs the `.key` file and its password.

## Your mission: Sign The Release Digest With Annotations

You can now sign an image digest with a key pair, add annotations, and verify both. The graded lab gives you the release key pair and asks you to sign the current release by its digest with two annotations, without signing the old release.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-119-playground-010-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS119.git -c sections/section-010/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-119-lab-010-01
astrona start ats-119-playground-010-01
```
