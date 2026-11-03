# Signing A Checksum List

Large releases can have dozens of files, and a bundle per file is awkward to publish. A common solution is a checksum file: one file that lists the SHA-256 hash of every download, signed once. This part builds a checksum file, signs it and verifies the downloads from it, then lists what a consumer needs to check a release.

## Build and sign the checksum list

`sha256sum` writes one line for each file: the hash, two spaces and the name. Sign that list as a blob:

<!-- astrona:playground:renew -->

```sh
export COSIGN_PASSWORD=lab-only-password
SC=/setup/offline-signing-config.json
cd /work/dl
rm -f ok.txt bad.txt tool-orphan tool-changed tool-dev tool-dev.sigstore.json
sha256sum tool-linux-amd64 tool-linux-arm64 tool-darwin-arm64 > SHA256SUMS
cosign sign-blob -y --key /work/keys/release.key --signing-config $SC --bundle SHA256SUMS.sigstore.json SHA256SUMS
```

The bundle now covers the list, and through the list every file in it.

## Verify in two steps

A consumer first verifies the list, and only then uses it to check the files:

```sh
cosign verify-blob --key /work/keys/release.pub --insecure-ignore-tlog --bundle SHA256SUMS.sigstore.json SHA256SUMS
sha256sum -c SHA256SUMS
```

The first command proves that the list was signed by the release key. `sha256sum -c` then recomputes the hash of each file and compares it with the list. If a file changed, `sha256sum -c` reports FAILED for it. The order matters: checking files against an unverified list proves nothing, because an attacker can change both.

## When to use one bundle per file and when a list

One bundle per file keeps every download independently verifiable and needs no extra tool. A signed list needs only one bundle and one signature operation, and it works well with tools that already publish checksum files. The cost is that the file names are inside the list, so renaming a file breaks the check. Either way, the security comes from the same two facts: a trusted public key, and a hash that matches.

## What a consumer needs

To trust a download, the consumer needs three things: the file, the bundle or the signed list, and the public key obtained over a trusted channel. A public key that comes from the same web page as the download adds no trust, because someone who can replace the file can replace the key too.

You now know how to verify one file, a set of files and a release described by a signed checksum list. The graded lab gives you three downloads, one of them damaged and one with a bundle from the wrong key, and asks you to sort them.


## Common pitfalls

> [!WARNING]
> - **Running `sha256sum -c` before verifying the list.** The list must be trusted first.
> - **Getting the public key from the download page.** An attacker who controls the page controls the key.
> - **Renaming files after signing a checksum list.** The names in the list must match the files.

## Your mission: Check Three Downloads Against Their Bundles

You can now read a bundle, name the cause of a failed verification and sort a set of downloads. The graded lab gives you three downloads, each with its own bundle, and asks you to report which ones verify and which do not, without changing anything.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-119-playground-020-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS119.git -c sections/section-020/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-119-lab-020-02
astrona start ats-119-playground-020-02
```
