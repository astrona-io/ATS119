# Section 020: Signing Blobs, Bundles And SBOMs

Not everything you ship is a container image. Release archives, binaries, checksum files and software bills of materials are plain files, and they need protection too. This section signs files with `cosign sign-blob`, keeps each signature in a Sigstore bundle next to the file, and signs the SBOM that describes an image.

## What you will learn

- Signing any file with `cosign sign-blob` and writing a Sigstore bundle.
- What a bundle holds when you sign with a key and no transparency log.
- Verifying a file with `cosign verify-blob`, and seeing a changed file fail.
- What a software bill of materials (SBOM) is, and generating one in SPDX JSON with `syft`.
- Signing an SBOM so a consumer knows who produced it.

## The learning path

The section has one module, with a landing page, two short parts, a graded lab right after the part it tests, and a summary. The landing page starts the module's playground.

### 1. Sign Files And SBOMs With Bundles

The playground holds the registry with the `podinfo` images and the workstation with `cosign` and `syft`.

1. Signing A File With A Bundle
2. Generating And Signing An SBOM, followed by the lab **Sign A Release Archive And Its SBOM**
3. Summary

## Section capstone: Repair The Signatures Of A Release Download

The download page of inventory 1.5.0 offers an archive, an SBOM and a checksum file. One bundle was made with the wrong key, one file changed after it was signed, and one file was never signed. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS119.git -c sections/section-020/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-119-capstone-020
```
