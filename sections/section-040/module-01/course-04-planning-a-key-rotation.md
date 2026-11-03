# Planning A Key Rotation

Keys do not last forever. They expire by policy, people who knew them leave, and sometimes they leak. A rotation replaces a key without breaking consumers, and the plan must exist before the day it is needed. This part describes the plan and runs the check that makes it work: verifying with a set of trusted keys.

## Two reasons to rotate

A **scheduled rotation** replaces a key before it becomes risky, for example every year. Old signatures stay valid, and the old key is retired. A **compromise rotation** replaces a key because it may be in the wrong hands. Here, signatures made by the old key after the compromise date cannot be trusted, and the old key leaves the trust set at once.

## The overlap period

At rotation time, consumers still hold the old public key. If you switch signing to the new key and nothing else, those consumers cannot verify new releases. So the new public key is published first, then new releases are signed with it. For a time, consumers trust both keys. Create two keys and sign one release with each, to see what a consumer with both public keys does:

<!-- astrona:playground:renew -->

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
mkdir -p /work/keys && cd /work/keys
cosign generate-key-pair --output-key-prefix release-2025
cosign generate-key-pair --output-key-prefix release-2026
cd /work
NEW=$(regctl image digest $REPO:6.15.0)
OLD=$(regctl image digest $REPO:6.14.1)
cosign sign -y --key /work/keys/release-2025.key --signing-config $SC --allow-http-registry $REPO@$OLD
cosign sign -y --key /work/keys/release-2026.key --signing-config $SC --allow-http-registry $REPO@$NEW
```

## Verify against a trust set

`cosign verify --key` takes one key. A trust set is a folder of public keys, and the consumer tries each one until a verification succeeds:

```sh
verify_trusted() {
  for pub in /work/keys/release-*.pub; do
    cosign verify --key $pub --insecure-ignore-tlog --allow-http-registry "$1" > /dev/null 2>&1 && return 0
  done
  return 1
}
verify_trusted $REPO@$OLD && echo "6.14.1 trusted"
verify_trusted $REPO@$NEW && echo "6.15.0 trusted"
```

Both releases verify, each with its own key. A release signed by a key outside the folder fails.

## End of the overlap

Once every consumer has the new public key, and old releases are no longer deployed, remove the old public key from the trust set. After that, signatures made by the old key no longer verify for those consumers. For a compromise, do this immediately, and re-sign the releases you still support with the new key.

## What to write down

Keep a short record: which key signed which period, where the public keys are published, who may use the signing key, and the date of the next rotation. The record turns a rotation from an emergency into a routine.

You now have a plan for rotating keys and the check that lets consumers follow it.


## Common pitfalls

> [!WARNING]
> - **Switching the signing key before publishing the new public key.** Consumers cannot verify the new releases.
> - **Keeping a compromised key in the trust set.** Remove it at once.
> - **Forgetting to re-sign supported releases after a compromise.** They no longer verify.
