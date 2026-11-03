# Getting The Public Key To Consumers

A bundle proves nothing without a public key the consumer trusts, and the consumer must get that key from somewhere. This part covers how the public key reaches the people who verify, what the flags on `cosign verify-blob` mean for a bundle that was made offline, and what changes when a bundle comes from a public log.

## Publish the public key

The public key is a short PEM file. Publish it where consumers already trust your content: the repository of the project, the documentation site served over HTTPS, or a package that the consumer installed earlier. A key published on the same page as the download adds no trust, because someone who can replace the file can replace the key. Print the key and its hash so people can compare it:

<!-- astrona:playground:renew -->

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
mkdir -p /work/keys && cd /work/keys && cosign generate-key-pair --output-key-prefix release && cd /work
cat /work/keys/release.pub
sha256sum /work/keys/release.pub
```

Announce the hash in a second channel, for example in the release notes. A consumer who downloads the key can check it against the hash.

## What the flags mean

A bundle made with the lab signing configuration has no transparency log entry and no timestamp from an authority. `--insecure-ignore-tlog` tells `cosign verify-blob` not to demand one. Without the flag, verification looks for log evidence and fails. The name has the word insecure on purpose: when you skip the log, the only trust anchor is the key.

Signatures from the public-good instance include a log entry and a signed timestamp in the bundle. A verifier then can check that the signature was made while the key was valid, even if the key is revoked later. That check is the reason public releases keep the log.

## Verify with the bundle only

Because the bundle holds the signature and the digest, the consumer needs just the file, the bundle and the key:

```sh
cd /work && printf 'tool 1.0\n' > tool
cosign sign-blob -y --key /work/keys/release.key --signing-config $SC --bundle tool.sigstore.json tool
cosign verify-blob --key /work/keys/release.pub --insecure-ignore-tlog --bundle tool.sigstore.json tool
```

Nothing else is needed. No network access is needed either, since there is no log to ask.

## Keys change over time

When the release key is replaced, old downloads still carry bundles signed by the old key. Keep the old public keys available, labelled with the period they were used, so that old downloads can be verified later. A consumer then picks the key by the release date.

You now know how the public key reaches consumers and what the verification flags give up and keep.


## Common pitfalls

> [!WARNING]
> - **Publishing the key and the file on the same page only.** Add a second channel for the hash.
> - **Removing old public keys after a rotation.** Old downloads still need them.
> - **Reading `insecure` as broken.** It names a trade-off: no log evidence.
