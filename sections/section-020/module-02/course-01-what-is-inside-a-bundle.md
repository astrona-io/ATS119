# What Is Inside A Bundle

A file download has no registry that stores its signature, so the signature has to travel with the file. In cosign v3 that carrier is a Sigstore bundle, a single JSON file. This part signs a file, then opens the bundle to see what a verifier receives and what it must still bring itself.

## Sign a file

Create a key pair, a file and a bundle. `cosign sign-blob` signs the bytes of any file; the word blob means a file that is not a container image. The option `--bundle` names the file that receives the bundle:

<!-- astrona:playground:renew -->

```sh
export COSIGN_PASSWORD=lab-only-password
SC=/setup/offline-signing-config.json
mkdir -p /work/keys /work/dl && cd /work/keys && cosign generate-key-pair --output-key-prefix release && cd /work/dl
printf 'version 1.0\n' > tool-linux-amd64
cosign sign-blob -y --key /work/keys/release.key --signing-config $SC --bundle tool-linux-amd64.sigstore.json tool-linux-amd64
```

The convention is to name the bundle like the file with `.sigstore.json` added. cosign prints no signature to the screen, because the bundle holds it.

## Open the bundle

A bundle is JSON, so `jq` reads it. First look at the top-level keys, then at the parts that matter:

```sh
jq 'keys' tool-linux-amd64.sigstore.json
jq '.mediaType' tool-linux-amd64.sigstore.json
jq '.messageSignature.messageDigest' tool-linux-amd64.sigstore.json
```

`mediaType` names the bundle format version. `messageSignature` holds the signature and `messageDigest`, the algorithm and the digest of the file that was signed. The digest is how a verifier knows which file the signature belongs to. The key itself is not in the bundle: a key-based bundle carries a hint that identifies the key, and the verifier brings the public key.

## What the digest is

The digest in the bundle is the SHA-256 hash of the file contents. You can compute the same value yourself and compare it:

```sh
sha256sum tool-linux-amd64
jq -r '.messageSignature.messageDigest.digest' tool-linux-amd64.sigstore.json | base64 -d | od -An -tx1 | tr -d ' \n'; echo
```

The bundle stores the digest as base64, so the second command decodes it to hex first. The two hex strings are equal. Verification recomputes the hash of the file you give it and compares it with this value before it checks the signature over it.

You now know what a bundle contains: a signature, the digest it covers and a hint about the key. The next question is what `cosign verify-blob` reports when the file or the key does not match.


## Common pitfalls

> [!WARNING]
> - **Sending the file without its bundle.** The consumer then has nothing to verify.
> - **Expecting the public key inside the bundle.** A key-based bundle holds a hint, not the key.
> - **Editing the bundle by hand.** The signature covers the digest; changing it breaks verification.
