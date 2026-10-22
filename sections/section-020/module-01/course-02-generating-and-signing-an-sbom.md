# Generating And Signing An SBOM

When a new vulnerability is published, the first question is "do we ship the affected package anywhere?". You can only answer it quickly if every release comes with a list of what is inside it. That list is a software bill of materials, and it is only useful if users can trust that you produced it. This part generates an SBOM for the release image with `syft` and signs it.

## What an SBOM is

A **software bill of materials (SBOM)** is a machine-readable list of the packages inside an artifact: their names, versions, licenses and where they came from. Two formats are common. **SPDX** (Software Package Data Exchange) is a Linux Foundation standard; **CycloneDX** comes from the OWASP community. This course uses SPDX in its JSON form, SPDX JSON.

`syft` is an open-source tool that reads an image or a folder and writes an SBOM. It inspects the package databases inside the image, such as the Alpine package list and the files of language package managers.

## Generate an SBOM for the release image

Set the usual values and find the digest of the current release. You scan the digest, so the SBOM describes exactly the image you sign:

<!-- astrona:playground:renew -->

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
DIGEST=$(regctl image digest $REPO:6.15.0)
cd /work/release
```

`syft scan` takes a source and an output format. The prefix `registry:` tells syft to read the image straight from the registry. `-o spdx-json=<file>` writes SPDX JSON to a file. The workstation sets `SYFT_REGISTRY_INSECURE_USE_HTTP=true`, so syft may talk to the plain-HTTP lab registry.

```sh
syft scan registry:$REPO@$DIGEST -o spdx-json=podinfo-6.15.0.spdx.json
```

syft pulls the image layers, lists the packages it finds, and writes the file. Look at the start of the document and count the packages:

```sh
jq '{spdxVersion, name, packages: (.packages | length)}' podinfo-6.15.0.spdx.json
jq -r '.packages[] | "\(.name) \(.versionInfo)"' podinfo-6.15.0.spdx.json | head
```

`spdxVersion` names the SPDX version of the document, `name` names what was scanned, and `packages` is the list. The second command prints package names and versions, for example the Alpine packages of the base image and the Go modules of the `podinfo` program.

## Sign the SBOM

An SBOM is a file like any other, so you sign it with `sign-blob` and keep the bundle next to it. You need the release key; create it if this shell does not have one yet with `cd /work/keys && cosign generate-key-pair --output-key-prefix release && cd /work/release`.

```sh
cosign sign-blob --key /work/keys/release.key --signing-config $SC -y \
  --bundle podinfo-6.15.0.spdx.json.sigstore.json podinfo-6.15.0.spdx.json
cosign verify-blob --key /work/keys/release.pub --insecure-ignore-tlog \
  --bundle podinfo-6.15.0.spdx.json.sigstore.json podinfo-6.15.0.spdx.json
```

The second command verifies the SBOM. A user who downloads the release now gets the archive, the SBOM, and a bundle for each, and can check all of them with your public key.

A signed SBOM file proves who produced the list, but it does not say which image the list belongs to; that link is only the file name. A signed statement about an image, with the image digest inside, is called an attestation, and it is the stronger way to attach an SBOM to an image. You may meet `cosign attach sbom` in older guides: it stored an SBOM next to an image without signing it. In cosign v3.1.4 the whole `cosign attach` command is deprecated and will be removed in cosign v4.0.0; its own message points to the `oras` tool for attaching unsigned artifacts.

You can now generate an SBOM for an image and sign it like any release file. The open question is how to tie such a document to the image itself.

## Common pitfalls

> [!WARNING]
> - **Scanning the tag.** Scan the digest you sign, or the SBOM may describe a different image than the one you ship.
> - **Changing the SBOM after signing.** Even pretty-printing it with `jq` changes the bytes, and the bundle no longer verifies. Sign the final file.
> - **Expecting syft to find everything.** syft lists what it can recognise. A program copied into the image without package metadata may be missing from the list.
> - **Calling an unsigned SBOM trusted.** Anyone can write an SBOM. Only the signature says who produced it.

## Your mission: Sign A Release Archive And Its SBOM

You can now sign files into bundles, generate an SBOM with syft, and verify everything with the public key. The graded lab gives you the release key and a release archive, and asks you to produce a signed SBOM for the release image and a signed archive.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-119-playground-020-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS119.git -c sections/section-020/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-119-lab-020-01
astrona start ats-119-playground-020-01
```
