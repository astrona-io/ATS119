# Proving The Identity Survived

After an import and a password change, the question that counts is whether the signing identity survived. A consumer does not care about passwords. It cares that the public key it holds verifies what you sign now and what you signed before. This part proves that continuity with a signature made before the import and one made after.

## A signature made with the old key

Simulate the past. Import the PEM key under a temporary name, sign the old release with it, and remove the temporary files again:

<!-- astrona:playground:renew -->

```sh
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
mkdir -p /tmp/past && cd /tmp/past
COSIGN_PASSWORD=temp-password cosign import-key-pair --key /work/legacy/signing.pem --output-key-prefix past
OLD=$(regctl image digest $REPO:6.14.1)
COSIGN_PASSWORD=temp-password cosign sign -y --key /tmp/past/past.key --signing-config $SC --allow-http-registry -a signer=legacy $REPO@$OLD
cd /work && rm -rf /tmp/past
```

The temporary key file is gone, but the signature stays in the registry.

## Verify it with the imported public key

```sh
cosign verify --key /work/keys/imported.pub --insecure-ignore-tlog --allow-http-registry -a signer=legacy $REPO@$OLD > /dev/null && echo "old signature verifies"
```

The old signature verifies with `imported.pub`. The file `imported.pub` was created after the signature, from the same private key, so it is the same public key.

## Sign with the imported key

Sign the current release with the new key file and its password, and verify it with the same public key:

```sh
NEW=$(regctl image digest $REPO:6.15.0)
COSIGN_PASSWORD=second-password cosign sign -y --key /work/keys/imported.key --signing-config $SC --allow-http-registry -a rotated=true $REPO@$NEW
cosign verify --key /work/keys/imported.pub --insecure-ignore-tlog --allow-http-registry -a rotated=true $REPO@$NEW > /dev/null && echo "new signature verifies"
```

A consumer who holds `imported.pub` verifies both releases, and does not know that the password changed. That is the goal of the whole exercise.

## Summary of the procedure

The migration has four steps. Import the PEM key with a password from your secret store. Compare the public key or verify an old signature with the new public key to prove the identity survived. Sign new releases with the cosign key file. Move the PEM file out of reach. At each step the public key stays the same.

You now have the full procedure for moving a legacy key into cosign and re-protecting it. The graded lab asks you to do it, including a new password and a signature on the current release.


## Common pitfalls

> [!WARNING]
> - **Assuming a new password needs a new public key.** The public key depends on the key material only.
> - **Forgetting to verify an old signature after the import.** That is the proof that the identity survived.
> - **Leaving temporary key files in `/tmp`.** Remove them as soon as you have used them.

## Your mission: Import A Legacy PEM Key And Re-Protect It

You can now import a legacy key, protect it with a new password and prove that the signing identity did not change. The graded lab gives you a PEM key that signed an old release. You import it with the team password and sign the current release.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-119-playground-040-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS119.git -c sections/section-040/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-119-lab-040-02
astrona start ats-119-playground-040-02
```
