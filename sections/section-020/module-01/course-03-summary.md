# Summary

Files outside a registry need signatures that travel with them. `cosign sign-blob` signs any file and, with `--bundle`, writes a Sigstore bundle: one JSON file with a `mediaType`, a `verificationMaterial` hint about the key, and a `messageSignature` that holds the hash of the file and the signature over it. With the offline signing configuration, the bundle has no transparency log entry or timestamp; with the public-good configuration it would have both.

`cosign verify-blob --key <pub> --bundle <bundle> <file>` hashes the file again and checks the signature against that hash. Any change to the file, even one byte, changes the hash and makes verification fail. The bundle only hints at the key, so the verifier must get the public key from a trusted place. A signature that is in no log is verified with `--insecure-ignore-tlog`.

A software bill of materials (SBOM) lists the packages inside an artifact. SPDX and CycloneDX are the common formats; SPDX JSON has fields such as `spdxVersion`, `name` and `packages`. `syft scan registry:<ref> -o spdx-json=<file>` writes one for an image, and scanning the digest ties the SBOM to the exact image you ship. An SBOM is trusted only when it is signed, and a signed SBOM file names the image only through its file name. The key facts to remember are these:

- Sign last, and never change a file after you sign it.
- Publish each file together with its `.sigstore.json` bundle.
- Scan and sign the digest you release, not a tag.
- `cosign attach` is deprecated in cosign v3.1.4 and will be removed in v4.0.0.

<!-- astrona:playground:destroy -->
