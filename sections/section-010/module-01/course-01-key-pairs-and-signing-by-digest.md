# Key Pairs And Signing An Image By Digest

Before anyone can verify an image, someone has to sign it, and that needs two things: a key to sign with and a precise name for what is signed. This part creates a key pair with `cosign`, finds the digest of the current release, and signs it. It also explains the one setting that keeps these practice signatures out of the public Sigstore log.

## A key pair and its password

A **key pair** is two linked keys. The **private key** makes signatures, so only the person or system that signs may hold it. The **public key** checks signatures, so you give it to everyone who verifies. Anything signed with the private key verifies with the public key, and nothing else does.

Open a shell in the workstation and set the three values every page of this module uses. `COSIGN_PASSWORD` is the password that protects the private key; `lab-only-password` is for these labs only. `REPO` is the repository of the example image, and `SC` is the signing configuration you meet later on this page.

<!-- astrona:playground:renew -->

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
```

Now create a key pair. `cosign generate-key-pair` writes two files, and `--output-key-prefix` chooses their name:

```sh
mkdir -p /work/keys && cd /work/keys
cosign generate-key-pair --output-key-prefix release
ls -l /work/keys
```

The folder now holds `release.key` and `release.pub`. The private key is an elliptic-curve key (ECDSA P-256), and cosign encrypts it with the password before it writes the file, so the file alone is not enough to sign. The first line of `release.key` says it is an encrypted Sigstore private key; `release.pub` is a normal PEM public key that you can share freely. Without `COSIGN_PASSWORD`, cosign asks for the password on the terminal instead.

## Sign the digest, not the tag

The current release is the tag `6.15.0`. A tag is a name that can move: tomorrow someone may push a different image under the same tag. A **digest** is the SHA-256 hash of the image manifest, so it names one exact image and cannot move. You sign the digest, so the signature covers exactly the image you checked.

`regctl image digest` prints the digest a tag points at right now:

```sh
cd /work
DIGEST=$(regctl image digest $REPO:6.15.0)
echo $DIGEST
```

The value starts with `sha256:` followed by 64 hexadecimal characters. From here on, the reference to sign is `$REPO@$DIGEST`: the repository, an `@`, and the digest.

## The signing configuration

When cosign v3 signs, it reads a **signing configuration**: a JSON file that lists which Sigstore services to use. These are Fulcio for certificates, Rekor as the transparency log (a public, append-only record of signing events), and a timestamp authority. If you pass no file, cosign downloads the configuration of the public-good instance and uploads every signature to the public Rekor log.

That public log is the right default for real releases, but not for practice signatures from a lab. So every environment in this course has `/setup/offline-signing-config.json`, a configuration whose service lists are empty. Print it to see what cosign reads:

```sh
jq . $SC
```

The lists `caUrls`, `rekorTlogUrls` and `tsaUrls` are empty. With no Rekor service listed, cosign uploads nothing to a log, and with no services at all it does not need to contact the internet to sign.

An older flag, `--tlog-upload=false`, did the same job in cosign v2. cosign v3.1.4 rejects it while a signing configuration is in use, and since a configuration is always in use by default, the configuration file is the way to sign without a log.

## Sign the release

Now sign the digest with the private key and the offline signing configuration:

```sh
cosign sign --key /work/keys/release.key --signing-config $SC --allow-http-registry -y $REPO@$DIGEST
```

Each flag has one job. `--key` names the private key. `--signing-config` points at the configuration with no services. `--allow-http-registry` lets cosign talk to this lab registry, which uses plain HTTP. `-y` answers yes to the confirmation prompt cosign shows before it publishes anything.

cosign decrypts the private key with `COSIGN_PASSWORD`, signs, and pushes the signature to the registry next to the image. The command ends without an error. What it pushed, and where, is the subject of the next page.

You now have a key pair and one signed release, and you signed it by a name that cannot move. The open question is where that signature went and how a verifier finds it.

## Common pitfalls

> [!WARNING]
> - **Signing a tag.** `cosign sign $REPO:6.15.0` works, but cosign resolves the tag at that moment and warns you. Resolve the digest yourself, check it, and sign `$REPO@$DIGEST`.
> - **Losing the password.** The private key file is useless without its password. Store both, separately and safely.
> - **Forgetting the signing configuration.** Without `--signing-config`, cosign v3 uses the public-good services and uploads to the public log. For real releases that is often what you want; for practice it is not.
> - **Using `--tlog-upload=false` with cosign v3.** cosign v3.1.4 rejects it while a signing configuration is in use. Use a signing configuration without a Rekor service instead.
