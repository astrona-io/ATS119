# Solution: Sign The Release Digest With Annotations

Work the task yourself first. Running `astrona submit -c sections/section-010/module-01/labs/lab-01` after a step tells you which checks pass.

The grader checks three things with its own copy of the release public key: the 6.15.0 digest verifies, a signature on it carries both annotations, and the 6.14.1 digest does not verify.

## Step 1: Set the values and look at the key

Open a workstation shell and set the values the commands use:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
ls -l /work/keys
```

The folder holds `release.key` and `release.pub`. These are the keys to use; creating a new pair would produce signatures the grader does not trust.

## Step 2: Find the digest

Resolve the tag to its digest:

```sh
DIGEST=$(regctl image digest $REPO:6.15.0)
echo $DIGEST
```

The value starts with `sha256:`. You sign `$REPO@$DIGEST`, so the signature covers exactly this image.

## Step 3: Sign with the annotations

Sign the digest with the release key, the offline signing configuration and both annotations:

```sh
cosign sign --key /work/keys/release.key --signing-config $SC --allow-http-registry -y \
  -a release=6.15.0 -a team=inventory $REPO@$DIGEST
```

cosign reads the password from `COSIGN_PASSWORD`, signs the payload with the annotations in it, and pushes the signature bundle to the registry as a referrer of the image.

## Step 4: Verify, the way the grader does

Check the signature and the annotations:

```sh
cosign verify --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry \
  -a release=6.15.0 -a team=inventory $REPO@$DIGEST | jq '.[].optional'
```

The command passes and shows the two annotations. `--insecure-ignore-tlog` is needed because the offline signing configuration put the signature in no transparency log.

Then confirm the old release stays unsigned:

```sh
cosign verify --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry $REPO@$(regctl image digest $REPO:6.14.1)
```

This one fails: no signature from the release key exists for that digest.

## Step 5: Submit

Leave the workstation shell with `exit`, and send the lab for grading from your own terminal:

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Generate a new key pair and sign with it | The signature does not verify with the published release key, which is the one the grader uses |
| Sign without annotations, then sign again with only one | `cosign verify -a` needs one signature that carries both annotations |
| Sign every tag in the repository | 6.14.1 gets a release signature it must not have |
| Leave out `--signing-config` | cosign tries the public-good services and uploads the signature to the public log |

## Common mistakes

- Forgetting `-y`, so cosign waits for a confirmation in a script.
- Typing `-a release=6.15.0,team=inventory`; each annotation needs its own `-a`.
- Verifying the tag instead of the digest and assuming the result holds later.
