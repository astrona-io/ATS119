# Exporting And Using The Public Key

Verifiers do not need access to the KMS. They need the public key. This part exports the public key of a Transit key and verifies an image signature with it, both through a file and through the KMS reference.

## Sign with the KMS key

Sign the current release by digest, as with a key file. The only change is the key reference:

<!-- astrona:playground:renew -->

```sh
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
DIGEST=$(regctl image digest $REPO:6.15.0)
cosign sign -y --key openbao://demo-a --signing-config $SC --allow-http-registry $REPO@$DIGEST
```

No `COSIGN_PASSWORD` is set. The service authenticates cosign by the token from the environment, and no password protects a key file.

## Export the public key

`cosign public-key --key` asks the service for the public part of the key and writes it to a file:

```sh
mkdir -p /work/keys
cosign public-key --key openbao://demo-a --outfile /work/keys/demo-a.pub
head -n 1 /work/keys/demo-a.pub
```

The file is an ordinary PEM public key. Give it to anyone who verifies your images. They do not need an OpenBao token.

## Verify with the file

```sh
cosign verify --key /work/keys/demo-a.pub --insecure-ignore-tlog --allow-http-registry $REPO@$DIGEST > /dev/null && echo "verified with the file"
```

This verification does not contact OpenBao at all. It is the check a consumer runs.

## Verify with the KMS reference

You can also verify by passing the reference, so cosign fetches the public key from the service:

```sh
cosign verify --key openbao://demo-a --insecure-ignore-tlog --allow-http-registry $REPO@$DIGEST > /dev/null && echo "verified through OpenBao"
```

The result is the same, but now the check depends on the service being reachable and on its answer. Use the file for consumers and for pipelines that should work without the service. Use the reference when you want the current key from the service.

You can now export a KMS public key and verify with it in two ways. The next part answers the audit question: which key signed which image.


## Common pitfalls

> [!WARNING]
> - **Handing out tokens so others can verify.** Give out the public key file.
> - **Verifying through the reference in an air-gapped pipeline.** It needs the service.
> - **Assuming the exported key is secret.** It is public by design.
