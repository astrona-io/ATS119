# Keys In The Transit Engine

A key file can be copied. A key that never leaves a key management service (KMS) cannot. With a KMS, cosign sends the data to be signed to the service, and the service returns the signature. The private key stays inside. This part creates a key in the Transit engine of OpenBao and looks at it from the server side.

## What Transit is

**OpenBao** is an open source secrets manager that came from HashiCorp Vault. Its **Transit** engine performs cryptographic operations for clients without giving them the keys. A client asks Transit to sign some data with a named key, and Transit returns the signature. cosign uses this as a signing backend through the references `openbao://NAME` or `hashivault://NAME`.

The lab OpenBao runs in development mode at `http://openbao.kms:8200` with the root token `root` and Transit enabled at `transit/`. Development mode keeps data in memory and uses a known token, so it is only for labs. The workstation has `BAO_ADDR` and `BAO_TOKEN` set, and cosign reads them.

## Create a key

`cosign generate-key-pair --kms` asks the service to create the key:

<!-- astrona:playground:renew -->

```sh
echo $BAO_ADDR
cosign generate-key-pair --kms openbao://demo-a
```

No files appear in the current folder, because there is no private key to write. cosign created a Transit key named `demo-a` and printed a message about the public key.

## Look at the key in OpenBao

OpenBao has an HTTP API. The header `X-Vault-Token` carries the token, a name that OpenBao kept from its Vault origin. Read the key:

```sh
curl -s -H "X-Vault-Token: $BAO_TOKEN" $BAO_ADDR/v1/transit/keys/demo-a | jq '.data | {type, latest_version}'
```

The `type` is an elliptic curve key type, and `latest_version` is `1`. The response contains the public key for each version, and no private key.

## The consequence for key handling

With a key file, protecting the key means protecting a file and a password. With a KMS, protecting the key means controlling who may ask the service to sign. The key cannot leak by copying a file, because no file exists. It can still be misused by anyone who has a token that allows signing. The next parts treat that as the main risk.

You now know that a KMS key is created and used by name, and that the private key never reaches the workstation. The next part gets the public key out of the service.


## Common pitfalls

> [!WARNING]
> - **Looking for a key file.** A KMS key has none.
> - **Using development mode outside a lab.** It stores data in memory with a known token.
> - **Forgetting the environment.** Without `BAO_ADDR` and a token, cosign cannot reach the service.
