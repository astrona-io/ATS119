# Solution: Add A Production Signature With Annotations

Work the task yourself first. Running `astrona submit -c sections/section-010/module-02/labs/lab-01` after a step tells you which checks pass.

The grader checks three things with its own copy of the release public key: the 6.15.0 digest has a signature with both production annotations, the staging signature is still there, and 6.14.1 has no production signature.

## Step 1: Set the values and read the current signatures

Open a workstation shell and set the values the commands use:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
```

Look at what signs the release now. Verify with the annotation `env=staging`, then with `env=production`:

```sh
DIGEST=$(regctl image digest $REPO:6.15.0)
cosign verify --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry -a env=staging $REPO@$DIGEST > /dev/null && echo "staging: yes"
cosign verify --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry -a env=production $REPO@$DIGEST > /dev/null && echo "production: yes"
```

The first check passes and the second fails: only the staging signature exists. `--insecure-ignore-tlog` is needed because the offline signing configuration put the signature in no transparency log.

## Step 2: Add the production signature

Sign the same digest again, with both annotations:

```sh
cosign sign --key /work/keys/release.key --signing-config $SC --allow-http-registry -y \
  -a env=production -a approved-by=release-team $REPO@$DIGEST
```

The annotations are part of the signed payload, so this payload differs from the staging one. cosign pushes a second signature to the registry and leaves the first in place.

## Step 3: Verify, the way the grader does

```sh
cosign verify --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry \
  -a env=production -a approved-by=release-team $REPO@$DIGEST | jq '.[].optional'
cosign verify --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry -a env=staging $REPO@$DIGEST > /dev/null && echo "staging still verifies"
```

The first command prints the two production annotations. The second shows the staging signature is intact. Then confirm the old release has no production signature:

```sh
cosign verify --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry \
  -a env=production $REPO@$(regctl image digest $REPO:6.14.1)
```

This one fails, because only a staging signature exists for that digest.

## Step 4: Submit

Leave the workstation shell with `exit`, and send the lab for grading from your own terminal:

```sh
astrona submit -c sections/section-010/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Generate a new key pair for production | The signature does not verify with the published release key, which is the one the grader uses |
| Delete the staging signature first | The staging check fails: the task asks for an added signature |
| Sign every tag in the repository | 6.14.1 gets a production signature it must not have |
| Sign the tag `6.15.0` | cosign resolves it to a digest and warns; the habit breaks as soon as a tag moves |

## Common mistakes

- Typing `-a env=production,approved-by=release-team`; each annotation needs its own `-a`.
- Forgetting `-y`, so cosign waits for a confirmation in a script.
- Verifying without `-a` and assuming the production signature exists because the check passed. Without `-a`, any valid signature from the key is enough.
