# Annotations In The Signed Payload

A signature on its own says only that a key signed an image digest. Teams often need more: which environment the image was approved for, who approved it, or which ticket it belongs to. cosign lets you put such facts into the signature itself with annotations. This part shows what an annotation is, where it sits in the signed payload and why it cannot be changed afterwards.

## What an annotation is

An **annotation** is a key=value pair that cosign adds to the payload before it signs the payload. The payload is the small JSON document that names the image and carries the annotations. Because the signature covers the whole payload, changing an annotation after signing breaks the signature.

`cosign sign` takes one `-a` flag per annotation. The long form of the flag is `--annotations`. Start by creating a key pair and signing the current release with one annotation:

<!-- astrona:playground:renew -->

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
mkdir -p /work/keys && cd /work/keys && cosign generate-key-pair --output-key-prefix release && cd /work
DIGEST=$(regctl image digest $REPO:6.15.0)
cosign sign --key /work/keys/release.key --signing-config $SC --allow-http-registry -y \
  -a env=staging $REPO@$DIGEST
```

Sign the digest, as always: the reference is `$REPO@$DIGEST`. The annotation `env=staging` now belongs to the signature of that digest.

## Where the annotation sits in the payload

`cosign verify` prints the payload of every signature it accepted. Annotations appear in the `optional` object of the payload, next to the part that names the image:

```sh
cosign verify --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry $REPO@$DIGEST | jq '.[].optional'
```

The `optional` object holds `env` with the value `staging`. The `critical` object holds the repository and the digest. Both objects are inside the signed bytes, so a registry administrator who edits the stored bundle cannot turn `staging` into `production` without invalidating the signature.

## Annotations are not secret and not checked by default

Anyone who can read the signature can read the annotations, so never put a secret in one. Also, a plain `cosign verify` does not look at annotations at all. It reports success when at least one signature from the key is valid, whatever the annotations say. The next parts show how a verifier requires them.

You now know that an annotation is a signed key=value pair in the `optional` part of the payload. The open question is what happens when the same digest gets more than one signature.


## Common pitfalls

> [!WARNING]
> - **Putting secrets in annotations.** The payload is stored in the registry in the clear.
> - **Expecting annotations to change the image.** They describe the signature; the image and its digest do not change.
> - **Forgetting the digest.** Annotations on a signature of a tag make no sense; sign `$REPO@$DIGEST`.
