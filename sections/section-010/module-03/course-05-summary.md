# Summary

cosign v3 stores each signature as a Sigstore bundle in a manifest whose `subject` field names the signed image. A manifest that points at another manifest in this way is an OCI referrer. A registry that implements the referrers API of the OCI distribution specification 1.1 lists all referrers of a digest in one request, and `regctl artifact list` shows that list.

A registry without the referrers API cannot answer that request. Clients then keep an image index in a fallback tag whose name is `sha256-` followed by the hex digest of the subject. The index lists the referrers. This tag is a normal tag, so it appears in tag listings and can be deleted by a cleanup job, which makes the image look unsigned. Copy tools must copy the referrers or the fallback tag for signatures to follow an image.

To find unsigned images, resolve each release tag to a digest, skip the fallback tags, and ask for the referrers of every digest. A referrer proves that something is attached, not that your key signed it, so trust comes from `cosign verify --key`. One digest can hold signatures from several keys. Each verifier accepts the signatures that match its own key and ignores the rest. Removing a signature means deleting only that signature manifest, never the image digest. Key facts:

- A referrer has a `subject` that names the image digest.
- The fallback tag is `sha256-<hex digest of the subject>`.
- The referrer list shows what exists; `cosign verify --key` shows who signed.
- Delete exactly one signature manifest, and verify the others afterwards.

<!-- astrona:playground:destroy -->
