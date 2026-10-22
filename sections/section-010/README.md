# Section 010: Signing And Verifying Container Images

A container image travels from a build system through a registry to a cluster, and anyone with write access to the registry can change what a tag points at. A signature lets the cluster, or a person, check that the image is the one a trusted key holder approved. This section signs and verifies images with `cosign` and a key pair, the simplest form of Sigstore signing and the base for everything later in the course.

## What you will learn

- What a key pair is, how `cosign` creates one, and why the private key is encrypted with a password.
- Why you sign an image by its digest, not by its tag.
- Where cosign v3 stores a signature in the registry: as a Sigstore bundle attached to the image as an OCI referrer.
- Signing with a signing configuration that lists no transparency log, and what that means for verification.
- Adding annotations to a signature and checking them with `cosign verify`.
- Telling which key made a signature.

## The learning path

The section has one module, with a landing page, three short parts, a graded lab right after the part it tests, and a summary. The landing page starts the module's playground, a cluster where you can explore freely.

### 1. Sign And Verify Container Images With A Key Pair

The playground holds a registry with two versions of the `podinfo` image and the workstation pod with `cosign` and its friends.

1. Key Pairs And Signing An Image By Digest
2. Where The Signature Lives In The Registry
3. Verifying Signatures And Annotations, followed by the lab **Sign The Release Digest With Annotations**
4. Summary

## Section capstone: Repair The Signature Of A Release Channel

The capstone combines the module's skills in one scenario. The `stable` tag of `inventory/podinfo` should point at the current release and carry a release signature with two annotations. Instead it points at the old release, and the current release was signed with a developer key. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS119.git -c sections/section-010/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-119-capstone-010
```
