# Solution: Rotate The Release Signing Key

Work the task yourself first. Running `astrona submit -c sections/section-040/module-01/labs/lab-01` after a step tells you which checks pass.

The grader checks the new key pair, verifies 6.15.0 with both keys (the new one with its annotation), verifies 6.14.1 with the old key only, using its own copy of the 2025 public key, and compares the trust set files.

## Step 1: Set the values

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
CURRENT=$(regctl image digest $REPO:6.15.0)
OLD=$(regctl image digest $REPO:6.14.1)
```

## Step 2: Create the 2026 key pair

```sh
cd /work/keys && cosign generate-key-pair --output-key-prefix release-2026 && cd /work
```

## Step 3: Sign the supported release only

```sh
cosign sign --key /work/keys/release-2026.key --signing-config $SC --allow-http-registry -y \
  -a key=release-2026 $REPO@$CURRENT
```

6.14.1 is left alone; it keeps only its 2025 signature.

## Step 4: Publish the trust set

```sh
mkdir -p /work/keys/trusted
cp /work/keys/release-2025.pub /work/keys/release-2026.pub /work/keys/trusted/
```

## Step 5: Check, the way the grader does

```sh
cosign verify --key /work/keys/trusted/release-2026.pub --insecure-ignore-tlog --allow-http-registry -a key=release-2026 $REPO@$CURRENT > /dev/null && echo "6.15.0: new key ok"
cosign verify --key /work/keys/trusted/release-2025.pub --insecure-ignore-tlog --allow-http-registry $REPO@$CURRENT > /dev/null && echo "6.15.0: old key ok"
cosign verify --key /work/keys/trusted/release-2025.pub --insecure-ignore-tlog --allow-http-registry $REPO@$OLD > /dev/null && echo "6.14.1: old key ok"
cosign verify --key /work/keys/trusted/release-2026.pub --insecure-ignore-tlog --allow-http-registry $REPO@$OLD > /dev/null || echo "6.14.1: new key refused, as expected"
```

## Step 6: Submit

Leave the workstation shell with `exit`, and send the lab for grading from your own terminal:

```sh
astrona submit -c sections/section-040/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Clean the image and sign with the new key only | Users who still trust the 2025 key stop verifying 6.15.0 |
| Re-sign 6.14.1 with the new key | The new key vouches for a release it never covered |
| Overwrite `release-2025.*` with the new key | The trust set loses the old public key |
