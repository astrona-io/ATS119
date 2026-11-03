# Troubleshooting Signing And Verification

A signing workflow fails in a few typical ways, and each failure has a short list of causes. Knowing them saves time, especially because several messages look alike. This part reproduces the common failures one at a time, names the cause of each and shows the fix.

## No signature found

`cosign verify` exits with an error when no signature on the digest verifies with the key. It does not say whether there is no signature at all or only none from this key. Tell the two apart with the referrers:

<!-- astrona:playground:renew -->

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
DIGEST=$(regctl image digest $REPO:6.15.0)
cosign tree --allow-http-registry $REPO@$DIGEST
for k in release dev; do
  cosign verify --key /work/keys/$k.pub --insecure-ignore-tlog --allow-http-registry $REPO@$DIGEST > /dev/null 2>&1 && echo "$k: ok" || echo "$k: no valid signature"
done
```

If `cosign tree` lists signatures but a key fails, the image was signed by a different key. If the tree lists none, the image is unsigned. Create the key pairs with `cosign generate-key-pair --output-key-prefix` first if they do not exist.

## Signing a tag

When you pass a tag to `cosign sign`, cosign resolves it to a digest and prints a warning that signing by tag is unsafe, because the tag can move between the resolution and a later check. The signature is still made for the digest it resolved. Avoid the warning by resolving the digest yourself with `regctl image digest` and signing `$REPO@$DIGEST`.

## A registry that speaks plain HTTP

The lab registry uses HTTP. Without `--allow-http-registry`, cosign tries HTTPS and fails with a connection or TLS error. The flag belongs on every command that talks to the registry: `sign`, `verify`, `tree`, `attest` and `verify-attestation`. Production registries use HTTPS, and the flag is then not used.

## Wrong password

A wrong `COSIGN_PASSWORD` gives a decryption error and no signature is pushed. Check the variable with `echo` only in a private lab; in real use, check that the secret store passes the right value.

## Log flags

cosign v3 reads a signing configuration. With the lab configuration, which lists no transparency log, signing works, and verification needs `--insecure-ignore-tlog`. Do not pass `--tlog-upload=false` with a signing configuration: cosign v3.1.4 rejects it. Leave the log decision to the configuration file.

## A method for any failure

Work in the same order every time. Resolve the digest. Run `cosign tree` to see what is attached. Verify with each public key you know. Read the payload with `jq` if a signature verifies but an annotation does not. These four steps separate "nothing is there", "the wrong key signed" and "the annotation is missing".

You now have a checklist for the failures that occur most often when signing and verifying images.


## Common pitfalls

> [!WARNING]
> - **Changing several things at once.** Change one flag, run again, read the message.
> - **Reading a verification failure as an unsigned image.** The image may carry a signature from another key.
> - **Skipping `--allow-http-registry` on `tree`.** It needs the flag too.
