# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Signing files and SBOMs

## Scenario

The inventory team ships version 1.4.0 as an archive, and its customers now ask for a software bill of materials (SBOM) of the `podinfo` image the archive deploys. Both files must be signed with the release key so customers can check them with the published public key.

The release key pair is at `/work/keys/release.key` and `/work/keys/release.pub` (password `lab-only-password`). The archive is `/work/release/inventory-1.4.0.tar.gz`. Work in a workstation shell: `kubectl -n workstation exec -it deploy/workstation -- sh`.

## Your task

1. Generate an SPDX JSON SBOM of the image `registry.localtest.me:5001/inventory/podinfo:6.15.0`, by its digest, with `syft`. Save it as `/work/release/podinfo-6.15.0.spdx.json`.
2. Sign the archive with the release key into the bundle `/work/release/inventory-1.4.0.tar.gz.sigstore.json`.
3. Sign the SBOM with the release key into the bundle `/work/release/podinfo-6.15.0.spdx.json.sigstore.json`.

Sign with the signing configuration `/setup/offline-signing-config.json`, so nothing goes to a public log.

## Constraints

- Do not change the archive.
- Sign with the existing release key. Do not create a new key pair.

## Done when

- The archive is unchanged and verifies with its bundle and the release public key.
- The SBOM is an SPDX JSON document whose `name` mentions `podinfo`, and it verifies with its bundle.
- A changed copy of the archive does not verify with the archive's bundle.
