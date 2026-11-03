# Finding Unsigned Images

A security review often starts with a question: which images in this repository have no signature? Registries do not answer that directly, because they do not know what a signature is. You answer it by walking the tags, resolving each to a digest and asking for its referrers. This part builds that loop and shows the two ways a digest can look unsigned.

## Check one digest

`cosign tree` prints what is attached to a digest. A digest with no signature prints no signature entry. A script is better served by the exit code of `regctl artifact list` and by counting the lines of its output. Start with the two releases:

<!-- astrona:playground:renew -->

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
for tag in 6.15.0 6.14.1; do
  D=$(regctl image digest $REPO:$tag)
  N=$(regctl artifact list $REPO@$D --format '{{range .Descriptors}}{{.Digest}}{{"\n"}}{{end}}' | grep -c sha256)
  echo "$tag has $N referrers"
done
```

The current release has as many referrers as signatures were made. The old release has none.

## Walk all release tags

A repository holds release tags and fallback tags. Skip the tags that start with `sha256-`, then check each remaining tag:

```sh
for tag in $(regctl tag ls $REPO | grep -v '^sha256-'); do
  D=$(regctl image digest $REPO:$tag)
  if [ -z "$(regctl artifact list $REPO@$D --format '{{range .Descriptors}}{{.Digest}}{{end}}')" ]; then
    echo "$tag: no referrers"
  fi
done
```

The loop prints `6.14.1: no referrers`. A referrer need not be a signature. It could be an SBOM or another artifact type, so a real audit also checks the `artifactType` of the entries.

## Has a referrer, but not from your key

An image can have referrers and still be unsigned for your purpose. A signature by an unknown key is a referrer too. The honest test of "signed by us" is `cosign verify` with your public key. Compare the two checks on the current release after adding a signature from another key:

```sh
cd /work/keys && cosign generate-key-pair --output-key-prefix dev && cd /work
D=$(regctl image digest $REPO:6.15.0)
cosign sign --key /work/keys/dev.key --signing-config $SC --allow-http-registry -y $REPO@$D
regctl artifact list $REPO@$D --format '{{range .Descriptors}}{{.Digest}} {{end}}'
cosign verify --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry $REPO@$D | jq 'length'
```

The registry now lists two referrers, while verification with the release key accepts one. The referrer count shows what is attached. Only verification shows who signed it.

You now have two tools for an audit: the referrer list shows what exists, and `cosign verify --key` shows what you can trust. The last part puts several keys on one digest and reads the result.


## Common pitfalls

> [!WARNING]
> - **Treating any referrer as a signature.** Check `artifactType` and verify with a key.
> - **Using the tag listing as the list of releases.** Skip the `sha256-` tags.
> - **Verifying the tag.** Resolve the digest first, then ask for referrers and verify that digest.
