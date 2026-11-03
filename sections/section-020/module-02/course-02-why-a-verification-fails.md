# Why A Verification Fails

A verification either passes or fails, and the reason for a failure matters, because it points at the fix. This part runs `cosign verify-blob` on a good file, on a changed file and on a file whose bundle came from another key, and explains each result.

## Verify a good download

`cosign verify-blob` takes the file as its argument. It needs the public key, the bundle and, because this bundle is in no log, `--insecure-ignore-tlog`:

<!-- astrona:playground:renew -->

```sh
export COSIGN_PASSWORD=lab-only-password
SC=/setup/offline-signing-config.json
cd /work/dl
cosign verify-blob --key /work/keys/release.pub --insecure-ignore-tlog --bundle tool-linux-amd64.sigstore.json tool-linux-amd64
```

cosign prints `Verified OK` and exits with status 0. Two things were checked: the signature in the bundle is valid for the public key, and the digest in the bundle equals the hash of the file.

## A file that changed

Append one line to the file and verify again:

```sh
cp tool-linux-amd64 tool-changed
printf 'extra\n' >> tool-changed
cosign verify-blob --key /work/keys/release.pub --insecure-ignore-tlog --bundle tool-linux-amd64.sigstore.json tool-changed
```

Verification fails. The signature is still valid for the original digest, but the file you passed has another hash. This is the failure of a download damaged on a mirror or modified on purpose. The fix is to download the file again, not to re-sign it.

## A bundle from another key

Create a second key pair and sign a copy of the file with it. Then verify that bundle with the release public key:

```sh
cd /work/keys && cosign generate-key-pair --output-key-prefix dev && cd /work/dl
cp tool-linux-amd64 tool-dev
cosign sign-blob -y --key /work/keys/dev.key --signing-config $SC --bundle tool-dev.sigstore.json tool-dev
cosign verify-blob --key /work/keys/release.pub --insecure-ignore-tlog --bundle tool-dev.sigstore.json tool-dev
```

The file is intact, yet verification fails: the signature was not made by the private key that belongs to `release.pub`. This is the failure of a bundle that someone else created. The fix is to find out why the release process used another key. Re-signing with the release key is the right fix only if you are the release owner.

## Two failures, two causes

The error messages differ, but the exit status does not: any failure returns a non-zero status. A script must therefore decide on the status and treat both cases as "do not use this file". For a human, the question that finds the cause is simple: does the digest of the file equal the digest in the bundle? If not, the file changed. If yes, the key or the signature is wrong.


## Common pitfalls

> [!WARNING]
> - **Re-signing a failing file to make the check pass.** That signs whatever the file contains now, including damage.
> - **Reading only the printed text.** Use the exit status in scripts.
> - **Dropping `--insecure-ignore-tlog` for a bundle made offline.** Verification then looks for a log entry and fails for the wrong reason.
