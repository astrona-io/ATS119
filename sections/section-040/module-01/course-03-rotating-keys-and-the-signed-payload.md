# Rotating Keys And Reading The Signed Payload

Keys do not last forever. Policy may require a new key every year, a person who had access may leave, or a key may leak. Replacing a key is called **rotation**, and done carelessly it either breaks every release users already verified or keeps a bad key trusted. This part reads exactly what a signature covers, then rotates the release key.

## What a signature covers

Set the usual values, create a release key, and sign the release with an annotation, so there is a signature to read:

<!-- astrona:playground:renew -->

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
CURRENT=$(regctl image digest $REPO:6.15.0)
mkdir -p /work/keys && cd /work/keys && cosign generate-key-pair --output-key-prefix release-2025 && cd /work
cosign sign --key /work/keys/release-2025.key --signing-config $SC --allow-http-registry -y -a key=release-2025 $REPO@$CURRENT
cosign verify --key /work/keys/release-2025.pub --insecure-ignore-tlog --allow-http-registry $REPO@$CURRENT | jq '.[0]'
```

The JSON cosign prints after a successful check is the **signed payload**: the exact bytes the key signed. It has two parts:

| Field | What it holds |
| --- | --- |
| `critical.identity.docker-reference` | The repository the image was signed in |
| `critical.image.docker-manifest-digest` | The digest of the signed image |
| `critical.type` | The kind of payload: a cosign container image signature |
| `optional` | The annotations, such as `key=release-2025` |

Nothing in the payload names the key. A signature says "the holder of some private key signed this digest"; which key it was is only known by verifying with each public key you trust. That is why rotation is about public keys as much as private keys.

## Rotate the release key

A scheduled rotation follows four rules. The new key signs every release that is still supported. The old signatures stay, so users who still trust only the old key keep working. Releases that are no longer supported are not re-signed, so the new key never vouches for them. And both public keys are published together, as a **trust set**, until the old key is retired.

Create the 2026 key and sign the supported release with it:

```sh
cd /work/keys && cosign generate-key-pair --output-key-prefix release-2026 && cd /work
cosign sign --key /work/keys/release-2026.key --signing-config $SC --allow-http-registry -y -a key=release-2026 $REPO@$CURRENT
```

The release now carries two signatures, one from each key. Publish the trust set and check the release with each key in it:

```sh
mkdir -p /work/keys/trusted && cp /work/keys/release-2025.pub /work/keys/release-2026.pub /work/keys/trusted/
for key in /work/keys/trusted/*.pub; do
  cosign verify --key $key --insecure-ignore-tlog --allow-http-registry $REPO@$CURRENT > /dev/null && echo "$key verifies"
done
```

Both keys verify the current release. `cosign verify` takes one key at a time, so a verifier with a trust set loops over it, or uses a policy engine that accepts several keys.

## When a key leaks

A leak is different from a scheduled rotation. Every signature from the leaked key may be forged, so you cannot keep them. You create a new key, re-sign the releases you still stand behind, remove the leaked key from every trust set at once, and remove its signatures before you sign again. cosign v3 stores signatures as referrers, so `cosign clean --type all` (or `--type referrer`) is the command that removes them; it removes everything attached to that digest, so attach the attestations you still need again afterwards. The old public key must disappear from the trust set, or forged signatures keep verifying.

You can now read what a signature covers and replace a release key while users keep verifying. The rest of this module's practice is in the lab.

## Common pitfalls

> [!WARNING]
> - **Re-signing everything with the new key.** End-of-life releases should not gain a fresh signature from a key that never vouched for them.
> - **Removing the old signatures during a scheduled rotation.** Users who have not updated their trust set yet start failing.
> - **Keeping a leaked key in the trust set.** Every forged signature from it keeps verifying.
> - **Thinking the payload names the key.** It names the image; the key is found by verifying.

## Your mission: Rotate The Release Signing Key

You can now read the signed payload and rotate a key while keeping old signatures valid. The graded lab gives you a release key from 2025 that signed both releases, and asks you to introduce the 2026 key for the supported release only and publish the trust set.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-119-playground-040-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS119.git -c sections/section-040/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-119-lab-040-01
astrona start ats-119-playground-040-01
```
