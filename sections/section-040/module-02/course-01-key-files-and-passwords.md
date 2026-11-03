# Key Files And Passwords

A cosign private key is a file, and a file can be copied. What stops a copy from being used is the password. This part looks at how cosign stores a private key, what the password protects and how the password reaches cosign when you sign.

## What is in a key file

`cosign generate-key-pair` writes two files. The public key, `release.pub`, is a PEM file that anyone may read. The private key, `release.key`, is a PEM file whose type line says it is encrypted. cosign derives an encryption key from your password with the scrypt algorithm, which is deliberately slow to make guessing passwords expensive, and encrypts the private key with it.

Generate a pair and look at the headers of the files. The environment variable `COSIGN_PASSWORD` gives cosign the password without a prompt:

<!-- astrona:playground:renew -->

```sh
mkdir -p /work/keys && cd /work/keys
export COSIGN_PASSWORD=lab-only-password
cosign generate-key-pair --output-key-prefix release
head -n 1 release.key release.pub
cd /work
```

The first line of `release.key` names an encrypted private key, and the first line of `release.pub` names a public key. Only the private key needs protection.

## The password and signing

To sign, cosign reads the key file and decrypts it with the password. If the password is wrong, decryption fails and cosign stops before it signs anything. Test this with a wrong password:

```sh
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
DIGEST=$(regctl image digest $REPO:6.15.0)
COSIGN_PASSWORD=wrong-password cosign sign -y --key /work/keys/release.key --signing-config $SC --allow-http-registry $REPO@$DIGEST
```

cosign reports an error about decrypting the key and does not push a signature. With the correct password, the same command signs.

## How the password reaches cosign

There are two ways. Without `COSIGN_PASSWORD`, cosign asks for the password on the terminal. That works for a person and cannot work in a pipeline. In a pipeline, the password comes from the environment, which the pipeline fills from its secret store. Do not write the password in a script, in the repository or in a command typed in a shared shell, because shells keep history and process listings can show environment variables.

## What the password does not protect

The password protects a stolen file. It does not protect against an attacker who gets the file and the password together, for example from the same backup. It also does not limit what the key may sign: whoever can decrypt the key can sign any digest. Store the key file and the password in different places, and give the pipeline only what it needs.

You now know that a key file is an encrypted private key and that the password is the only barrier. The next part moves an existing key into this format.


## Common pitfalls

> [!WARNING]
> - **Keeping the password next to the key file.** A copy of both signs as well as the original.
> - **Typing the password on a shared command line.** Use the secret store of the pipeline.
> - **Sharing the private key to share access.** Share the public key; keep the private key with its owner.
