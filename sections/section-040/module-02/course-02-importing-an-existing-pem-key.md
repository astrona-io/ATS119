# Importing An Existing PEM Key

Teams often start with a private key that was created for another tool, for example an OpenSSL key on a build server. Replacing it with a new cosign key would change the public key, and everything signed before would no longer verify with the new one. cosign can import the old key, so the public key stays the same. This part creates such a key and imports it.

## Create a PEM key

The command below creates an elliptic curve key on the P-256 curve in PKCS#8 form, which is the standard format for private keys in PEM files. It has no password, which is the situation this module repairs:

<!-- astrona:playground:renew -->

```sh
mkdir -p /work/legacy /work/keys
openssl ecparam -genkey -name prime256v1 -noout | openssl pkcs8 -topk8 -nocrypt -out /work/legacy/signing.pem
head -n 1 /work/legacy/signing.pem
```

The first line is `-----BEGIN PRIVATE KEY-----`. This file is unprotected: anyone who copies it can sign.

## Import it

`cosign import-key-pair` reads a PEM private key and writes a cosign key pair. The password for the new key file is read from `COSIGN_PASSWORD`:

```sh
cd /work/keys
COSIGN_PASSWORD=first-password cosign import-key-pair --key /work/legacy/signing.pem --output-key-prefix imported
cd /work
head -n 1 /work/keys/imported.key
```

The result is `imported.key`, an encrypted private key in the cosign format, and `imported.pub`, the public key. The key material is the same as in the PEM file, so the public key is the same one that belonged to the old key.

## Why importing keeps your history

A signature is valid for a public key. If you signed releases with the old key and publish its public key, consumers verify with that public key. An imported key has the same public key, so old signatures still verify, and new signatures verify with the same file. A freshly generated key would have a new public key, and the consumers would have to learn it.

## What to do with the PEM file

After the import, the unprotected PEM file is a liability. It holds the same signing power with no password. Move it to secure, offline storage or destroy it, according to your key policy. Keep it only if you need to re-import the key, which the next part uses.

You now know how to move an existing private key into the cosign format without changing its public key. The next part explains how to change the password of such a key.


## Common pitfalls

> [!WARNING]
> - **Generating a new pair when you meant to import.** The public key changes and old signatures stop verifying with it.
> - **Leaving the PEM file on the build server.** It signs without a password.
> - **Importing into the current folder by accident.** Use `--output-key-prefix` with a path or change to the key folder first.
