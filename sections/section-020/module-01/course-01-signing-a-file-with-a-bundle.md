# Signing A File With A Bundle

A release archive sits on a web server or in an object store, far from any registry. If an attacker replaces it, a user who downloads it has nothing to compare against. This part signs a file, keeps the signature in a bundle next to it, and shows that the bundle catches any change to the file.

## Create a key pair and a file to sign

Set the values the commands use, and create a release key pair. The password `lab-only-password` is for these labs only.

<!-- astrona:playground:renew -->

```sh
export COSIGN_PASSWORD=lab-only-password
SC=/setup/offline-signing-config.json
mkdir -p /work/keys /work/release && cd /work/keys
cosign generate-key-pair --output-key-prefix release
```

Now make a small release archive to sign. Any file works; an archive is the common case:

```sh
mkdir -p /tmp/src/inventory-1.4.0
echo "Inventory service 1.4.0" > /tmp/src/inventory-1.4.0/README
tar -C /tmp/src -czf /work/release/inventory-1.4.0.tar.gz inventory-1.4.0
cd /work/release
```

## Sign the file into a bundle

`cosign sign-blob` signs a file of any kind. `--bundle` names the file cosign writes the result to. By convention the bundle has the file's name plus `.sigstore.json`:

```sh
cosign sign-blob --key /work/keys/release.key --signing-config $SC -y \
  --bundle inventory-1.4.0.tar.gz.sigstore.json inventory-1.4.0.tar.gz
```

cosign computes the SHA-256 hash of the file, signs it with the private key, and writes the bundle. The offline signing configuration lists no transparency log and no timestamp authority, so the bundle holds the signature and nothing else. With the public-good configuration, the same command would also put a Rekor log entry and a timestamp into the bundle.

## Look inside the bundle

A bundle is ordinary JSON, so `jq` can show its top-level fields:

```sh
jq 'keys' inventory-1.4.0.tar.gz.sigstore.json
jq '.messageSignature.messageDigest' inventory-1.4.0.tar.gz.sigstore.json
```

The bundle has a `mediaType` that names the bundle format and version, `verificationMaterial` with a hint about which public key to use, and `messageSignature`. Inside `messageSignature`, `messageDigest` holds the hash algorithm and the hash of the file, and `signature` holds the signature over that hash. Compare the hash in the bundle with the file: `sha256sum inventory-1.4.0.tar.gz` prints the same value in hexadecimal, while the bundle stores it base64-encoded.

The bundle does not contain the public key itself, only a hint. The verifier must already have the public key and trust it; a bundle that carried its own key would let anyone sign anything.

## Verify, then change the file

`cosign verify-blob` hashes the file again and checks the signature in the bundle against that hash with the public key:

```sh
cosign verify-blob --key /work/keys/release.pub --insecure-ignore-tlog \
  --bundle inventory-1.4.0.tar.gz.sigstore.json inventory-1.4.0.tar.gz
```

cosign prints that the file was verified. As with images, `--insecure-ignore-tlog` is needed because the signature is in no transparency log; nobody outside your cluster can see that it was made.

Now change one byte in a copy of the file and verify the copy against the same bundle:

```sh
cp inventory-1.4.0.tar.gz /tmp/changed.tar.gz && printf x >> /tmp/changed.tar.gz
cosign verify-blob --key /work/keys/release.pub --insecure-ignore-tlog \
  --bundle inventory-1.4.0.tar.gz.sigstore.json /tmp/changed.tar.gz
```

Verification fails. The copy has a different hash, so the signature in the bundle does not match it. One added byte is enough, and so is any other change.

You can now sign any file into a bundle and verify it, and you know the bundle protects every byte of the file. The open question is what to sign besides the release itself, and the next answer is the list of everything inside it.

## Common pitfalls

> [!WARNING]
> - **Shipping the file without the bundle.** The bundle is the signature. Publish both, side by side.
> - **Trusting the key hint.** The bundle only hints at the key. The verifier must get the public key from a trusted place, never from the same download page an attacker could change.
> - **Signing before the last change.** If you edit a file after signing it, the bundle no longer matches. Sign last, then never touch the file.
> - **Leaving out `--signing-config` for practice files.** Without it, cosign v3 uploads the signature to the public Rekor log.
