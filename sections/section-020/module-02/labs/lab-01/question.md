# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Signing blobs and bundles

## Scenario

The inventory team publishes three downloads in `/work/downloads`: `app-linux-amd64`, `app-linux-arm64` and `app-darwin-arm64`. Each download has a Sigstore bundle next to it, named like the file with `.sigstore.json` added. The release signing key is `/work/keys/release.pub`. A mirror may have damaged a file, and one bundle may come from the wrong key. Before the files go on the website, the release manager wants to know which downloads can be trusted.

Work in a workstation shell: `kubectl -n workstation exec -it deploy/workstation -- sh`. The folder `/work/report` exists for your answers. The bundles were made with the offline signing configuration, so they are in no transparency log.

## Your task

1. Check each download against its own bundle with the release public key.
2. Write the names of the downloads that verify into `/work/report/verified.txt`, one per line.
3. Write the names of the downloads that do not verify into `/work/report/failed.txt`, one per line.

## Constraints

- Do not change, replace or re-sign any download or bundle. This task only reads them.
- Use the public key `/work/keys/release.pub`. Do not create a key pair.

## Done when

- `verified.txt` lists exactly the downloads for which `cosign verify-blob` passes.
- `failed.txt` lists exactly the downloads for which it fails.
- The downloads and the bundles are byte for byte what they were at the start.
