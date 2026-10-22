# Key Files, Passwords And Imported Keys

Most teams start with a key file, and many already have keys made with other tools. Before you can manage those keys, you need to know what cosign stores in its key file, how the password reaches it, and how to bring an existing key into cosign. This part answers all three.

## What is in a cosign key file

Set the usual values and create a key pair. `COSIGN_PASSWORD` holds the lab-only password, so cosign does not ask for it:

<!-- astrona:playground:renew -->

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
mkdir -p /work/keys && cd /work/keys
cosign generate-key-pair --output-key-prefix release
head -1 release.key; head -1 release.pub
```

The first line of `release.key` says it is an encrypted Sigstore private key, and the first line of `release.pub` says it is a public key. cosign derives an encryption key from the password with scrypt, a function designed to make guessing passwords slow, and encrypts the private key with it. So a copied `release.key` is useless without the password, and a weak password undoes that protection.

The password reaches cosign in one of two ways: the `COSIGN_PASSWORD` environment variable, or a prompt on the terminal. In a pipeline, the password comes from the pipeline's secret store into `COSIGN_PASSWORD`; it never belongs in a script or a repository.

## Import an existing key

Some teams already have a key made with OpenSSL or by another tool. `cosign import-key-pair` reads a PEM-encoded RSA or elliptic-curve private key and writes it in cosign's encrypted format. Make such a key with OpenSSL, then import it:

```sh
openssl ecparam -name prime256v1 -genkey -noout -out existing-ec.pem
cosign import-key-pair --key existing-ec.pem --output-key-prefix imported
ls imported.*
```

cosign writes `imported.key`, encrypted with `COSIGN_PASSWORD`, and `imported.pub`. The original `existing-ec.pem` is not encrypted; once the import worked, delete it with `rm existing-ec.pem`, so the only copy left is the encrypted one.

## Export a public key

`cosign public-key` prints the public key that belongs to a private key reference. It works for key files and, as you will see, for keys in a KMS:

```sh
cosign public-key --key /work/keys/imported.key --outfile /tmp/imported-check.pub
diff /tmp/imported-check.pub /work/keys/imported.pub && echo "same public key"
```

The exported key matches the one cosign wrote during the import. This is how you rebuild a lost `.pub` file from the private key, and how you get the public key of a key you cannot read directly.

## Other places a key can come from

cosign's `--key` flag takes more than a file path. `env://NAME` reads the private key from an environment variable, which suits pipelines that inject secrets as variables. `k8s://namespace/name` reads a key pair that `cosign generate-key-pair k8s://...` stored in a Kubernetes Secret, together with its password; it needs access to the Kubernetes API, which the workstation does not have in this course. KMS references keep the key in a service, and they are the subject of the next part.

You now know how cosign protects a key file, how to bring an existing key in, and how to get a public key back from a private key. The open question is how to avoid having a private key file at all.

## Common pitfalls

> [!WARNING]
> - **Storing the password next to the key.** The encryption protects nothing if `release.key` and its password sit in the same repository or folder.
> - **Keeping the unencrypted PEM after an import.** Delete the original file once the import worked.
> - **Weak passwords.** scrypt slows guessing down; it does not make a short password strong.
> - **Losing the `.pub` file and making a new pair.** Export the public key from the private key instead; a new pair breaks every existing signature's trust.
