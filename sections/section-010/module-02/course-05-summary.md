# Summary

An annotation is a key=value pair that cosign adds to the payload before it signs, so the signature covers it. Annotations appear in the `optional` part of the payload that `cosign verify` prints, next to the `critical` part that names the repository and the digest. They are public, so they must not hold secrets, and a plain `cosign verify` does not check them.

A digest can carry many signatures. Each `cosign sign` adds one Sigstore bundle as a referrer, so a staging signature and a production signature exist side by side, and `cosign tree` or `regctl artifact list` shows both. Adding a signature keeps the earlier evidence; deleting one removes it for every verifier.

`cosign verify -a` turns an annotation into a requirement. One single signature from the trusted key must carry every annotation that is named, and values are compared as exact strings. A release gate therefore verifies the digest with the trusted public key and the annotation for the stage it protects. The old release stays unapproved because nobody signed it for that stage, and moving a tag cannot change that. Key facts:

- `-a` adds an annotation when signing and filters signatures when verifying.
- All required annotations must be on one signature.
- Annotation values match exactly.
- The key and the annotations are checked together.

<!-- astrona:playground:destroy -->
