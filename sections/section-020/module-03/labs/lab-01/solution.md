# Solution: Attest The Build Details Of A Release Archive

Work the task yourself first. Running `astrona submit -c sections/section-020/module-03/labs/lab-01` after a step tells you which checks pass.

The grader verifies the bundle against the archive with its own copy of the release public key, reads the digest from the statement in the bundle, and checks that a changed copy of the archive fails.

## Step 1: Set the values and look at the inputs

Open a workstation shell and set the values the commands use:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
```

Look at the archive and the predicate:

```sh
ls -l /work/release /work/predicates
cat /work/predicates/build.json
```

The predicate is a small JSON document with the builder, the commit and a `reproducible` flag.

## Step 2: Create the attestation

`cosign attest-blob` builds an in-toto statement for a file, signs it as a DSSE envelope and writes the result into the bundle:

```sh
cosign attest-blob --key /work/keys/release.key --signing-config $SC -y \
  --type custom --predicate /work/predicates/build.json \
  --bundle /work/release/inventory-1.4.0.tar.gz.att.sigstore.json \
  /work/release/inventory-1.4.0.tar.gz
```

cosign computes the SHA-256 digest of the archive, puts it in the `subject` of the statement, signs the statement with the key and writes the bundle.

## Step 3: Verify, the way the grader does

```sh
cosign verify-blob-attestation --key /work/keys/release.pub --insecure-ignore-tlog --type custom \
  --bundle /work/release/inventory-1.4.0.tar.gz.att.sigstore.json /work/release/inventory-1.4.0.tar.gz
```

The command passes. Read the statement in the bundle and compare its subject digest with the archive:

```sh
jq -r .dsseEnvelope.payload /work/release/inventory-1.4.0.tar.gz.att.sigstore.json | base64 -d | jq '{predicateType, subject, predicate}'
sha256sum /work/release/inventory-1.4.0.tar.gz
```

The `subject` digest equals the `sha256sum` value. Last, show that a changed copy fails:

```sh
cp /work/release/inventory-1.4.0.tar.gz /tmp/changed.tar.gz && printf 'x' >> /tmp/changed.tar.gz
cosign verify-blob-attestation --key /work/keys/release.pub --insecure-ignore-tlog --type custom \
  --bundle /work/release/inventory-1.4.0.tar.gz.att.sigstore.json /tmp/changed.tar.gz
```

This one fails because the digest of the copy differs from the digest in the statement.

## Step 4: Submit

Leave the workstation shell with `exit`, and send the lab for grading from your own terminal:

```sh
astrona submit -c sections/section-020/module-03/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Use `cosign sign-blob` with the predicate file | That signs the predicate file itself, not the archive, and produces no statement about the archive |
| Skip `--bundle` | cosign does not write the file the grader reads |
| Attest a different type than the one verified | `verify-blob-attestation --type custom` rejects a statement with another predicate type |
| Rebuild the archive first | The digest changes and the grader's recorded digest no longer matches |

## Common mistakes

- Forgetting `--type custom` when verifying. The default type is `custom` in cosign, but state it so the check is explicit.
- Passing the predicate as the blob. The blob is the archive; the predicate goes with `--predicate`.
- Forgetting `--insecure-ignore-tlog` when verifying a bundle that is in no log.
