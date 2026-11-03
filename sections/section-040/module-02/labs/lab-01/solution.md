# Solution: Import A Legacy PEM Key And Re-Protect It

Work the task yourself first. Running `astrona submit -c sections/section-040/module-02/labs/lab-01` after a step tells you which checks pass.

The grader compares the public key with the one recorded for the legacy key, tries both passwords on the new key file, and verifies both releases with its own copies of the public key.

## Step 1: Set the values and look at the PEM key

Open a workstation shell and set the values the commands use:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
```

The PEM file holds a private key without a password:

```sh
head -n 1 /work/legacy/signing.pem
```

The first line is `-----BEGIN PRIVATE KEY-----`, the PKCS#8 header.

## Step 2: Import the key with a new password

`cosign import-key-pair` reads a PEM private key and writes a cosign key pair. It takes the password for the new key file from `COSIGN_PASSWORD`:

```sh
cd /work/keys
COSIGN_PASSWORD=new-team-password cosign import-key-pair --key /work/legacy/signing.pem --output-key-prefix imported
cd /work
```

This creates `imported.key`, encrypted with the new password, and `imported.pub`, the matching public key. Because the private key is the same, the public key is the same as the one used in the past.

## Step 3: Sign the new release

Sign the digest, not the tag, with the new password:

```sh
DIGEST=$(regctl image digest $REPO:6.15.0)
COSIGN_PASSWORD=new-team-password cosign sign --key /work/keys/imported.key --signing-config $SC --allow-http-registry -y \
  -a rotated=true $REPO@$DIGEST
```

## Step 4: Verify both releases

```sh
cosign verify --key /work/keys/imported.pub --insecure-ignore-tlog --allow-http-registry -a rotated=true $REPO@$DIGEST
cosign verify --key /work/keys/imported.pub --insecure-ignore-tlog --allow-http-registry -a signer=legacy $REPO@$(regctl image digest $REPO:6.14.1)
```

Both pass: the new signature carries `rotated=true`, and the old signature carries `signer=legacy` and was made by the same key. Check the password too. Opening the key with the old password has to fail:

```sh
COSIGN_PASSWORD=lab-only-password cosign public-key --key /work/keys/imported.key
```

## Step 5: Submit

Leave the workstation shell with `exit`, and send the lab for grading from your own terminal:

```sh
astrona submit -c sections/section-040/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| `cosign generate-key-pair` | A new key has a different public key, so the old signature on 6.14.1 no longer verifies with it |
| Import with the `lab-only-password` | The grader requires the new team password and rejects the old one |
| Edit the PEM file to add a password | The grader requires the PEM file to be unchanged |
| Re-sign 6.14.1 with the imported key | The signature already exists; the task is to keep the old signature valid |

## Common mistakes

- Forgetting `COSIGN_PASSWORD`, so cosign waits at a password prompt.
- Importing into the current folder instead of `/work/keys`.
- Signing the tag instead of the digest.
