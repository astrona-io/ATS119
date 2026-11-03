# Changing A Key Password

Passwords change: a person leaves, a password leaks, a policy asks for rotation. cosign has no command that changes the password of a key file in place. This part shows what to do instead and what stays the same afterwards.

## What stays the same

A password protects the private key file. It is not part of the key. The key material, and with it the public key, does not depend on the password. So re-protecting a key with a new password does not change the public key. Every signature made with the key still verifies.

## Re-import with a new password

Because there is no in-place change, the way to a new password is to import the original private key again, with the new password. This needs the original PEM key:

<!-- astrona:playground:renew -->

```sh
cd /work/keys
cp imported.pub imported-old.pub
COSIGN_PASSWORD=second-password cosign import-key-pair --key /work/legacy/signing.pem --output-key-prefix imported
cd /work
cmp /work/keys/imported.pub /work/keys/imported-old.pub && echo "public key unchanged"
```

The new `imported.key` opens with `second-password`. The old one, which was overwritten, opened with `first-password`. The `cmp` command prints nothing and returns success when the two public key files are identical.

## Check which password works

```sh
COSIGN_PASSWORD=second-password cosign public-key --key /work/keys/imported.key
COSIGN_PASSWORD=first-password cosign public-key --key /work/keys/imported.key
```

`cosign public-key --key` prints the public key for a private key reference after it decrypts the file. The first command prints the key. The second fails, because the old password no longer opens the new file. Use this command when you need to test a password without signing anything.

## When you have no PEM file

If the key exists only as a cosign key file, there is no import source. Generate a new key pair instead, publish the new public key, and treat it as a rotation. Keys created by `cosign generate-key-pair` are not meant to be exported to PEM again. Plan for this when you create a key: if you may need to change the password, keep the original private key in secure storage.

## A leaked password is not a leaked key

If only the password leaked, the key file is still safe as long as no copy of it exists outside your control. Changing the password is then enough. If the key file leaked as well, the key itself is compromised, and re-protecting it does not help: the attacker already has a copy protected by the old password. The only answer is a new key and a rotation.

You can now change the password of an imported key and tell when that is not enough. The last part checks the result from the point of view of a consumer.


## Common pitfalls

> [!WARNING]
> - **Looking for a `change-password` command.** cosign has none; you re-import the original key.
> - **Changing the password after the key file leaked.** The leaked copy keeps the old password.
> - **Overwriting the old key file without keeping the public key.** Keep a copy of the public key for comparisons.
