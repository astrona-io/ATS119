# Section 040: Managing Signing Keys

Every signature in this course is only as trustworthy as the key behind it. A leaked private key lets an attacker sign anything; a lost one means you can no longer release. This section covers the life of a signing key: how cosign protects a key file, how to bring an existing key in, how to keep a key inside a key management service so it never touches a disk, and how to rotate a key without breaking the signatures users already trust.

## What you will learn

- How cosign encrypts a private key file, and how the password reaches it.
- Importing an existing PEM key with `cosign import-key-pair`, and exporting a public key.
- The key references cosign accepts for key management services (KMS).
- Creating and using a signing key in OpenBao's Transit engine.
- What the signed payload of an image contains.
- Rotating a signing key: signing with the new key, keeping the old signatures, publishing both public keys.

## The learning path

The section has three modules. The first has a landing page, four short parts, a graded lab right after the part it tests, and a summary. Modules 2 and 3 each have a landing page, four parts, a graded lab and a summary. Every landing page starts the module's playground.

### 1. Manage Signing Keys

The playground holds the registry with the `podinfo` images, the workstation, and OpenBao in development mode with the Transit engine enabled.

1. Key Files, Passwords And Imported Keys
2. Keys In A Key Management Service
3. Rotating Keys And Reading The Signed Payload, followed by the lab **Rotate The Release Signing Key**
4. Planning A Key Rotation
5. Summary

### 2. Importing Keys And Changing Their Passwords

Each part ends in a step you run in the module's playground, and the graded lab **Import A Legacy PEM Key And Re-Protect It** follows the fourth part.

1. Key Files And Passwords
2. Importing An Existing PEM Key
3. Changing A Key Password
4. Proving The Identity Survived
5. Summary

### 3. Auditing And Controlling KMS Keys

Each part ends in a step you run in the module's playground, and the graded lab **Find Out Which KMS Key Signed Which Release** follows the fourth part.

1. Keys In The Transit Engine
2. Exporting And Using The Public Key
3. Finding Out Which Key Signed
4. Controlling Who May Sign
5. Summary

## Section capstone: Move Release Signing Into OpenBao Transit

The release key still lives in a file. The task is to create the release key in OpenBao Transit, sign the release with it, publish its public key, and delete the file-based private key. OpenBao is running, but Transit is not enabled and the workstation points at the wrong address. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS119.git -c sections/section-040/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-119-capstone-040
```
