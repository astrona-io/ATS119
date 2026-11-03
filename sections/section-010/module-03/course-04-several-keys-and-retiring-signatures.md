# Several Keys And Retiring Signatures

Real repositories collect signatures from several keys: a build key, a release key, a team key. Each one adds a referrer to the same digest, and a verifier picks the one it trusts. This part signs one digest with two keys, reads the result and describes how to retire signatures without breaking the others.

## One digest, two signatures

After the previous part, the current release carries a signature from the `release` key and one from the `dev` key. Look at the tree and verify with each public key in turn:

<!-- astrona:playground:renew -->

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
D=$(regctl image digest $REPO:6.15.0)
cosign tree --allow-http-registry $REPO@$D
for k in release dev; do
  cosign verify --key /work/keys/$k.pub --insecure-ignore-tlog --allow-http-registry $REPO@$D > /dev/null 2>&1 && echo "$k signed it" || echo "$k did not sign it"
done
```

Both keys sign the digest. The two checks are independent: the signature of one key does not make the other pass, and neither hides the other.

## Which signatures does a verifier see

`cosign verify --key` looks at every referrer that is a signature, tries the public key on each and accepts the check if at least one matches. A verifier that trusts only the release key ignores the developer signature. The developer signature does no harm, and it also grants nothing.

## Retiring a signature

Signatures sometimes have to go: a key leaked, or a signature was made by mistake. A signature is a manifest in the registry, so removing it means deleting that manifest. `regctl manifest delete` deletes a manifest, and `--referrers` also deletes the manifests that point at it. Both commands are destructive:

> [!WARNING]
> `regctl manifest delete --referrers` on the digest of an image deletes the image and every signature attached to it. To remove one signature, delete only the digest of that signature manifest, taken from `regctl artifact list`. Deleting the image digest removes every tag that points at it. `cosign clean` is another option, but it ignores `--allow-http-registry`, so it does not work against the plain-HTTP registry of this course.

Plan the deletion before you run it: list the referrers, identify the digest to remove by its annotations or by verification, and delete exactly that manifest. Verify afterwards that the other signatures still pass.

You now know how a digest can hold signatures from many keys, how a verifier chooses among them and how a signature is removed. This closes the picture of where signatures live and how they are found. The graded lab asks you to report the referrers, the fallback tag and the unsigned release of a repository.


## Common pitfalls

> [!WARNING]
> - **Deleting by digest of the image.** That removes the image, not the signature.
> - **Assuming a second signature weakens the first.** Signatures are independent artifacts.
> - **Cleaning up without checking.** After a deletion, run `cosign verify` for every key that should still work.

## Your mission: Report On The Signatures In A Repository

You can now list the referrers of a digest, find the fallback tag and tell signed releases from unsigned ones. The graded lab gives you a repository with signatures from two keys and asks you to write a report of what the registry holds.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-119-playground-010-03
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS119.git -c sections/section-010/module-03/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-03/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-119-lab-010-03
astrona start ats-119-playground-010-03
```
