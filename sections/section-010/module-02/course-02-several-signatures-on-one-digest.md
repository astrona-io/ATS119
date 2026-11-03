# Several Signatures On One Digest

A release usually passes through stages: it is built, tested in staging and then approved for production. Each stage can add its own signature to the same digest. This part signs one digest twice, with different annotations, and shows how cosign treats several signatures on one image.

## A digest can carry many signatures

Signing does not replace earlier signatures. Every `cosign sign` pushes one more Sigstore bundle as a referrer of the digest. Two signatures made with the same key and different annotations are two separate artifacts. Sign the release for production, after the staging signature from the previous part:

<!-- astrona:playground:renew -->

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
DIGEST=$(regctl image digest $REPO:6.15.0)
cosign sign --key /work/keys/release.key --signing-config $SC --allow-http-registry -y \
  -a env=production -a approved-by=release-team $REPO@$DIGEST
```

This command uses two `-a` flags, so the signature carries two annotations. List what is attached to the digest:

```sh
cosign tree --allow-http-registry $REPO@$DIGEST
regctl artifact list $REPO@$DIGEST --format '{{range .Descriptors}}{{.Digest}} {{end}}'
```

The tree and the list show one entry for each signature, so there are two. The staging signature is still there.

## What verify reports

Without `-a`, `cosign verify` accepts every signature from the key and prints one payload for each. Count them with `jq`:

```sh
cosign verify --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry $REPO@$DIGEST | jq 'length'
cosign verify --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry $REPO@$DIGEST | jq -c '.[].optional'
```

The first command prints `2`. The second prints the annotations of each signature on its own line. A person reading this can see the whole approval history of the digest.

## Why you add signatures and do not replace them

An earlier signature is evidence. The staging signature records that the release passed staging, and some verifiers still ask for it. Deleting it to "clean up" removes that record and changes what every verifier sees. Add a new signature for each new fact. The registry keeps the old ones until someone deletes them on purpose.

You can now put several signatures on one digest and read all of them. The next question is how a verifier asks for one particular signature among them.


## Common pitfalls

> [!WARNING]
> - **Re-signing to fix an annotation.** A new signature does not edit the old one. Both exist afterwards and both verify.
> - **Counting signatures by tags.** In cosign v3 the signatures are referrers, so count them with `cosign tree` or `regctl artifact list`.
> - **Signing an old release by mistake.** Check the digest with `regctl image digest` before each signing command.
