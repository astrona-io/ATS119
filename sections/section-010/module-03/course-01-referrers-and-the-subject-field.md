# Referrers And The Subject Field

A verifier that is given only an image digest has to find the signatures that belong to it. The registry does not hold a signature folder per image, so there must be a rule that links an artifact to an image. This part explains the rule, the OCI referrer, and shows it in the registry with two commands.

## The subject field

Every OCI manifest can carry an optional `subject` field. The field holds a descriptor: the media type, the size and the digest of another manifest. A manifest with a `subject` is a **referrer** of the manifest it names. cosign v3 pushes each signature as such a manifest. Its `subject` is the image you signed, and its `artifactType` tells what the artifact is, here a Sigstore bundle.

The OCI distribution specification 1.1 adds a **referrers API** to registries. A client sends one request, `GET /v2/<name>/referrers/<digest>`, and the registry answers with an index of all manifests whose `subject` is that digest. A verifier needs the digest only.

## Sign and list the referrers

Create a key pair, sign the current release and ask the registry for its referrers with `regctl`:

<!-- astrona:playground:renew -->

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
mkdir -p /work/keys && cd /work/keys && cosign generate-key-pair --output-key-prefix release && cd /work
DIGEST=$(regctl image digest $REPO:6.15.0)
cosign sign --key /work/keys/release.key --signing-config $SC --allow-http-registry -y $REPO@$DIGEST
regctl artifact list $REPO@$DIGEST
```

The list shows one referrer: the signature bundle, with its digest and its artifact type. The digest is the digest of the signature manifest, not of the image.

## Format the list

`regctl` accepts a Go template through `--format`. This prints only the referrer digests, which is the form a script needs:

```sh
regctl artifact list $REPO@$DIGEST --format '{{range .Descriptors}}{{.Digest}} {{end}}'
```

You can read the manifest of a referrer like any other manifest. Pass its digest to `regctl manifest get` and look for the `subject` field:

```sh
REF=$(regctl artifact list $REPO@$DIGEST --format '{{range .Descriptors}}{{.Digest}} {{end}}' | cut -d' ' -f1)
regctl manifest get $REPO@$REF --format body | jq '{artifactType, subject}'
```

The `subject` of the referrer is the digest of the image you signed. That is the whole link.

You now know that a signature is a manifest that points at the image through its `subject`. A registry without the referrers API cannot answer the request, so the next part shows what clients do instead.


## Common pitfalls

> [!WARNING]
> - **Looking for the signature by the tag of the image.** A referrer is found by digest, never by tag.
> - **Reading `regctl artifact list` as a list of tags.** The entries are manifest digests.
> - **Assuming the referrers API exists.** Older registries and some self-hosted ones do not implement it.
