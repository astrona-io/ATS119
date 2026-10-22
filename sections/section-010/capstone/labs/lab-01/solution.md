# Solution: Repair The Signature Of A Release Channel

Work the task yourself first. Running `astrona submit -c sections/section-010/capstone/labs/lab-01` after a step tells you which checks pass.

The grader checks four things: `stable` and `6.15.0` have the same digest, that digest verifies with its own copy of the release key and both annotations, 6.14.1 does not verify with the release key, and the release public key file is unchanged.

## Step 1: Set the values

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
```

## Step 2: Find what is wrong

Compare the digests of the three tags:

```sh
for tag in stable 6.15.0 6.14.1; do echo "$tag $(regctl image digest $REPO:$tag)"; done
```

`stable` has the same digest as `6.14.1`, the old release. That is the first fault.

Now find out which key signed the current release, by verifying with each public key:

```sh
CURRENT=$(regctl image digest $REPO:6.15.0)
for key in release dev; do
  if cosign verify --key /work/keys/$key.pub --insecure-ignore-tlog --allow-http-registry $REPO@$CURRENT >/dev/null 2>&1; then
    echo "$key: verifies"
  else
    echo "$key: no valid signature"
  fi
done
```

Only the developer key verifies. The release was signed with the wrong key, the second fault.

## Step 3: Point stable at the release

Copy the `6.15.0` tag to `stable`. Both tags then name the same manifest, so nothing is pushed twice:

```sh
regctl image copy $REPO:6.15.0 $REPO:stable
regctl image digest $REPO:stable
```

The digest now equals `$CURRENT`.

## Step 4: Sign the digest with the release key

Sign the digest, not the tag, with both annotations:

```sh
cosign sign --key /work/keys/release.key --signing-config $SC --allow-http-registry -y \
  -a release=6.15.0 -a channel=stable $REPO@$CURRENT
```

The developer signature stays attached. It does no harm: a verifier that trusts the release key ignores signatures it cannot check with that key.

## Step 5: Verify

```sh
cosign verify --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry \
  -a release=6.15.0 -a channel=stable $REPO@$(regctl image digest $REPO:stable) | jq '.[].optional'
cosign verify --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry $REPO@$(regctl image digest $REPO:6.14.1)
```

The first command passes and shows both annotations. The second fails, which is correct: 6.14.1 has no release signature.

## Step 6: Submit

Leave the workstation shell with `exit`, and send the lab for grading from your own terminal:

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Sign `stable` while it still points at 6.14.1 | The old release gets a release signature, and `stable` still runs the old image |
| Sign with the developer key again | The clusters trust the release key only |
| Generate a new `release` key pair | `release.pub` changes, and nobody trusts the new key |
| Sign the tag `stable` instead of its digest | It works only if the tag is right at that moment; resolving the digest first lets you check it |
