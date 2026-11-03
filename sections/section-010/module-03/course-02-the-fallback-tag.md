# The Fallback Tag

Not every registry implements the referrers API. The registry in this course is one of them. Clients still have to find signatures, so the OCI specification describes a fallback that needs nothing from the registry except tags. This part shows the fallback tag, how its name is built and why it matters for operations.

## The fallback tag

When a client pushes a manifest with a `subject` and the registry has no referrers API, the client maintains an image index in a tag of the same repository. The tag name is the algorithm and the hex digest of the subject joined by a dash: for `sha256:abc...` the tag is `sha256-abc...`. The index lists the descriptors of all referrers of that subject. A client that wants the referrers of a digest first tries the API. If that is not available, it reads the tag.

List the tags of the repository after the signing in the previous part:

<!-- astrona:playground:renew -->

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
DIGEST=$(regctl image digest $REPO:6.15.0)
regctl tag ls $REPO
echo "sha256-${DIGEST#sha256:}"
```

The tag list contains `6.15.0`, `6.14.1` and one more tag that starts with `sha256-`. The `echo` command builds the expected name from the digest: it removes the `sha256:` prefix and puts `sha256-` in front. The built name is the extra tag.

## Read the index

The fallback tag is an ordinary image index. Read it with `regctl`:

```sh
TAG="sha256-${DIGEST#sha256:}"
regctl manifest get $REPO:$TAG --format body | jq '.manifests[] | {digest, artifactType}'
```

Each entry is a referrer: the signature bundle. The digests here are the same as in `regctl artifact list`, because `regctl` reads this index when the registry has no referrers API.

## Why you must care

The fallback tag is a real tag. A registry cleanup job that deletes "unused" tags can delete it, and the image then looks unsigned. Tag listings are longer than the number of releases, so a script that expects only version tags must skip tags that start with `sha256-`. Copying an image to another registry copies the image only. The signatures follow only if the copy tool also copies the referrers or the fallback tag.

You can now explain how a verifier finds signatures on a registry without the referrers API: by the tag built from the digest. Next, you use the same knowledge in the other direction, to find images that have no signature at all.


## Common pitfalls

> [!WARNING]
> - **Deleting tags that start with `sha256-`.** They hold the list of signatures.
> - **Counting release tags with `regctl tag ls`.** The fallback tags are in the list too.
> - **Building the tag name with a colon.** The tag uses a dash because a colon is not allowed in a tag.
