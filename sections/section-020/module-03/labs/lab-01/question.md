# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Signing blobs and attestations

## Scenario

The inventory team ships `inventory-1.4.0.tar.gz` as a file download, not as an image. Auditors want a signed record of how the archive was built, bound to the archive itself. The build system left the build details in `/work/predicates/build.json`: the builder, the commit and whether the build is reproducible. The release key pair is in `/work/keys` (`release.key`, `release.pub`) with the lab-only password `lab-only-password`.

Work in a workstation shell: `kubectl -n workstation exec -it deploy/workstation -- sh`. The archive is `/work/release/inventory-1.4.0.tar.gz`.

## Your task

1. Create a signed attestation for the archive that carries the contents of `/work/predicates/build.json` as its predicate. Use predicate type `custom`.
2. Sign it with the release key and the offline signing configuration `/setup/offline-signing-config.json`.
3. Write the attestation as a Sigstore bundle to `/work/release/inventory-1.4.0.tar.gz.att.sigstore.json`.

## Constraints

- Sign with the existing release key. Do not create or replace a key pair.
- Do not change the archive or the predicate file.

## Done when

- `cosign verify-blob-attestation` with the release public key, the type `custom` and the bundle passes for the archive.
- The statement inside the bundle names the archive by its SHA-256 digest.
- A changed copy of the archive does not verify with the same bundle.
