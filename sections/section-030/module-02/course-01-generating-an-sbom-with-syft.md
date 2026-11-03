# Generating An SBOM With Syft

A software bill of materials (SBOM) lists the components inside an image: operating system packages, libraries and their versions. Consumers use it to answer questions such as "does this image contain the vulnerable library?". Before you can attest an SBOM, you need to generate one. This part uses `syft` to create an SBOM of the current release and looks at what it contains.

## Scan an image by digest

`syft scan` reads an image and catalogs its contents. The prefix `registry:` tells syft to pull the image from a registry and not from a local container runtime. Always scan the digest, because a tag can move between the scan and the signing. The workstation sets `SYFT_REGISTRY_INSECURE_USE_HTTP=true`, so syft talks plain HTTP to the lab registry.

<!-- astrona:playground:renew -->

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
DIGEST=$(regctl image digest $REPO:6.15.0)
mkdir -p /work/sbom
syft scan registry:$REPO@$DIGEST -o spdx-json=/work/sbom/podinfo-6.15.0.spdx.json
```

The option `-o spdx-json=<file>` writes the SPDX JSON format to a file. Without a file name, syft would print the document to the terminal.

## Output formats

syft writes several formats. The two that cosign treats by name are SPDX JSON (`spdx-json`) and CycloneDX JSON (`cyclonedx-json`). Both describe packages and relationships. The format you pick decides the attestation type later: `spdxjson` for SPDX and `cyclonedx` for CycloneDX. Pick one format per attestation and keep it the same for all releases, so consumers write one policy.

## Read the SBOM

The SPDX document is plain JSON. These commands show its version, the tool that made it and the number of packages:

```sh
jq '.spdxVersion, .creationInfo.creators' /work/sbom/podinfo-6.15.0.spdx.json
jq '.packages | length' /work/sbom/podinfo-6.15.0.spdx.json
jq -r '.packages[0:5][] | "\(.name) \(.versionInfo)"' /work/sbom/podinfo-6.15.0.spdx.json
```

The `creators` list contains an entry such as `Tool: syft-1.55.0`. A consumer can use that entry to see which tool made the SBOM. The package count tells whether the scan found anything. An SBOM with zero packages usually means the scan failed to read the image, and it should not be attested.

## An SBOM describes, it does not secure

An SBOM is data about the image at scan time. It does not stop the image from containing a vulnerable package. It also trusts the scanner: a scanner can miss components it does not understand. Its value comes from being signed and attached to the digest, so that a consumer gets the same document you generated. The next part attaches it.

You can now generate an SPDX JSON SBOM of an image digest and read its key fields. The next part attests it.


## Common pitfalls

> [!WARNING]
> - **Scanning a tag.** Scan the digest you will sign.
> - **Forgetting the `registry:` prefix.** Without it syft looks for a local image first.
> - **Attesting an empty SBOM.** Check the package count before you sign.
