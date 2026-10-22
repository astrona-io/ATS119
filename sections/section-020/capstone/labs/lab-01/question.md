# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Signing files and SBOMs

## Scenario

The download page of inventory 1.5.0 offers three files in `/work/release`: the archive `inventory-1.5.0.tar.gz`, the SBOM `inventory-1.5.0.spdx.json`, and the checksum file `SHA256SUMS`. A customer reports that the signatures do not check out. The release engineer says the SBOM got one more package added late, and that the files on disk are the final ones.

Two key pairs are in the workstation: `/work/keys/release.*` (the published release key) and `/work/keys/build.*` (the build system's key). The password of both is `lab-only-password`. Work in a workstation shell: `kubectl -n workstation exec -it deploy/workstation -- sh`.

## Your task

1. Find out which bundles fail and why.
2. Make `SHA256SUMS` list both the archive and the SBOM, with their correct checksums.
3. Make each of the three files verify with a bundle named `<file>.sigstore.json` and the release public key. Use the signing configuration `/setup/offline-signing-config.json`.

## Constraints

- Do not change the archive or the SBOM. They are final.
- Sign with the published release key only.

## Done when

- The archive and the SBOM are unchanged.
- `inventory-1.5.0.tar.gz`, `inventory-1.5.0.spdx.json` and `SHA256SUMS` each verify with their bundle and the release public key.
- `SHA256SUMS` lists both files and `sha256sum -c SHA256SUMS` passes in `/work/release`.
