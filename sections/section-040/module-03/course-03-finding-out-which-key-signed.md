# Finding Out Which Key Signed

Audits ask a plain question: who signed this? With several keys in use, nothing in the image says which key signed it. The answer comes from verification. This part creates a second key, signs a second release with it and builds a small report from verification results.

## A second key and a second signature

Create `demo-b` and sign the old release with it:

<!-- astrona:playground:renew -->

```sh
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
cosign generate-key-pair --kms openbao://demo-b
cosign public-key --key openbao://demo-b --outfile /work/keys/demo-b.pub
OLD=$(regctl image digest $REPO:6.14.1)
cosign sign -y --key openbao://demo-b --signing-config $SC --allow-http-registry $REPO@$OLD
```

Now the two releases were signed by two different Transit keys.

## Find the signer by verification

The rule is simple. A signature verifies with the public key that belongs to the signing key and with no other. Try every known public key against every release:

```sh
for tag in 6.15.0 6.14.1; do
  D=$(regctl image digest $REPO:$tag)
  for k in demo-a demo-b; do
    if cosign verify --key /work/keys/$k.pub --insecure-ignore-tlog --allow-http-registry $REPO@$D > /dev/null 2>&1; then
      echo "$tag is signed by $k"
    fi
  done
done
```

The loop prints one line for each release. The report tells which Transit key to look at for each, which is what an auditor needs.

## What the report cannot tell

The report names the key that signed. It does not tell who used the key, from which machine or when. For that, you need the audit log of the KMS, which records requests to the signing endpoint with the identity of the caller. A signature made offline, without a log, leaves no public trace, so the KMS audit log is the only record of who asked for it.

## Do not change the state under audit

An audit only reads. Running `generate-key-pair --kms` again, signing again or deleting keys changes the evidence. Export the public keys, verify, write the report and leave the system as it was.

You can now answer who signed what from verification alone. The last part covers how to control who may sign in the first place.


## Common pitfalls

> [!WARNING]
> - **Guessing from key names.** Only verification shows which key signed.
> - **Verifying the tag.** Resolve the digest first.
> - **Believing a signature log exists.** Offline signing makes none; the KMS audit log is the record.
