# Keys In A Key Management Service

Every key file can be copied, however well it is encrypted. A **key management service (KMS)** removes the file: the private key is created inside the service and never leaves it, and the signer asks the service to sign. This part lists the KMS references cosign accepts and signs the release with a key in OpenBao's Transit engine.

## The KMS references cosign accepts

cosign names a KMS key with a URI in place of a file path. The same URI works with `generate-key-pair --kms`, `sign --key`, `verify --key` and `public-key --key`:

| Reference | Service |
| --- | --- |
| `awskms://[ENDPOINT]/[ID/ALIAS/ARN]` | AWS Key Management Service |
| `gcpkms://projects/[PROJECT]/locations/[LOCATION]/keyRings/[KEYRING]/cryptoKeys/[KEY]` | Google Cloud KMS |
| `azurekms://[VAULT_NAME][VAULT_URI]/[KEY]` | Azure Key Vault |
| `hashivault://[KEY]` and `openbao://[KEY]` | The Transit engine of HashiCorp Vault or OpenBao |
| `pkcs11:...` | A hardware security module through PKCS#11 |

Each provider reads its own credentials from the environment, the same way the cloud command-line tools do. For Transit, cosign reads the server address from `VAULT_ADDR` or `BAO_ADDR`, the token from `VAULT_TOKEN` or `BAO_TOKEN`, and the mount path of the Transit engine from `TRANSIT_SECRET_ENGINE_PATH`, which defaults to `transit`.

## OpenBao and the Transit engine

**OpenBao** is an open-source secrets manager, a community fork of HashiCorp Vault under the Linux Foundation. Its **Transit engine** performs cryptographic operations on keys it keeps: it signs, verifies and encrypts, but never hands out a private key. In this playground OpenBao runs in development mode: in memory, already unsealed, with the root token `root`. That is lab-only; a development server loses every key when its pod restarts.

The workstation already has `BAO_ADDR=http://openbao.kms:8200` and `BAO_TOKEN=root` set. Check that OpenBao answers and that Transit is enabled at `transit/`:

<!-- astrona:playground:renew -->

```sh
curl -s http://openbao.kms:8200/v1/sys/health | jq '{initialized, sealed}'
curl -s -H "X-Vault-Token: $BAO_TOKEN" http://openbao.kms:8200/v1/sys/mounts | jq 'keys | map(select(startswith("transit")))'
```

OpenBao reports that it is initialized and not sealed, and the mount list contains `transit/`. OpenBao keeps the request header name `X-Vault-Token` from its Vault origin.

## Create the key in Transit and sign with it

`cosign generate-key-pair --kms` asks the KMS to create the key. Nothing is written to disk except what you export yourself:

```sh
cosign generate-key-pair --kms openbao://cosign-demo
curl -s -H "X-Vault-Token: $BAO_TOKEN" http://openbao.kms:8200/v1/transit/keys/cosign-demo | jq '.data | {type, latest_version}'
```

OpenBao now holds a Transit key named `cosign-demo`; its `type` is an elliptic-curve signing key. Export its public key, then sign the release with the key reference instead of a file:

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
DIGEST=$(regctl image digest $REPO:6.15.0)
mkdir -p /work/keys && cosign public-key --key openbao://cosign-demo --outfile /work/keys/cosign-demo.pub
cosign sign --key openbao://cosign-demo --signing-config $SC --allow-http-registry -y -a signer=openbao $REPO@$DIGEST
```

cosign builds the payload, sends its hash to OpenBao's Transit sign endpoint, and attaches the signature OpenBao returns. No password is involved, because there is no key file: access to the key is controlled by the OpenBao token and its policies.

## Verify without the KMS

A verifier only needs the public key, so it does not need access to OpenBao at all:

```sh
cosign verify --key /work/keys/cosign-demo.pub --insecure-ignore-tlog --allow-http-registry -a signer=openbao $REPO@$DIGEST > /dev/null && echo "verified"
```

The check passes with the exported public key file. You could also pass `--key openbao://cosign-demo`, and cosign would fetch the public key from OpenBao, but most verifiers should not need a token for the signing system.

You can now keep a signing key in a KMS, sign with it, and hand out only the public key. The open question is what to do when a key has to be replaced.

## Common pitfalls

> [!WARNING]
> - **Forgetting the environment.** Without `BAO_ADDR` and a token, cosign cannot reach Transit and reports that the address is not set.
> - **Giving verifiers a KMS token.** Export the public key and distribute that; signing access stays with the signer.
> - **Using a development OpenBao for real keys.** Development mode keeps everything in memory, with a known root token.
> - **Mounting Transit at another path without telling cosign.** Set `TRANSIT_SECRET_ENGINE_PATH` to the mount path.
