# Solution: Move Release Signing Into OpenBao Transit

Work the task yourself first. Running `astrona submit -c sections/section-040/capstone/labs/lab-01` after a step tells you which checks pass.

The grader asks OpenBao for the Transit key `cosign-release`, compares its public key with `/work/keys/release-kms.pub`, verifies 6.15.0 with that file and the annotation, and checks that `/work/keys/release.key` is gone.

## Step 1: Find the faults

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

```sh
echo $BAO_ADDR
curl -s --max-time 5 $BAO_ADDR/v1/sys/health || echo "no answer on $BAO_ADDR"
curl -s http://openbao.kms:8200/v1/sys/health | jq '{initialized, sealed}'
```

`BAO_ADDR` ends in `:8300`, where nothing answers. OpenBao answers on port 8200.

## Step 2: Point the shell at OpenBao and enable Transit

The pod's environment variable is wrong, but your shell can override it:

```sh
export BAO_ADDR=http://openbao.kms:8200
export BAO_TOKEN=root
curl -s -H "X-Vault-Token: $BAO_TOKEN" $BAO_ADDR/v1/sys/mounts | jq 'keys | map(select(startswith("transit")))'
curl -s -X POST -H "X-Vault-Token: $BAO_TOKEN" -d '{"type":"transit"}' $BAO_ADDR/v1/sys/mounts/transit
```

The first call shows no Transit mount; the second enables it at `transit/`.

## Step 3: Create the key in Transit and export its public key

```sh
cosign generate-key-pair --kms openbao://cosign-release
cosign public-key --key openbao://cosign-release --outfile /work/keys/release-kms.pub
```

## Step 4: Sign the release with the Transit key

```sh
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
cosign sign --key openbao://cosign-release --signing-config $SC --allow-http-registry -y \
  -a signer=openbao $REPO@$(regctl image digest $REPO:6.15.0)
```

## Step 5: Remove the file-based key and verify

```sh
rm /work/keys/release.key
cosign verify --key /work/keys/release-kms.pub --insecure-ignore-tlog --allow-http-registry -a signer=openbao \
  $REPO@$(regctl image digest $REPO:6.15.0) > /dev/null && echo "verified with the Transit key"
```

## Step 6: Submit

Leave the workstation shell with `exit`, and send the capstone for grading from your own terminal:

```sh
astrona submit -c sections/section-040/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Import `release.key` into Transit | The key existed on disk, which is what the security team wants to end |
| Sign with `release.key` and call it done | The release is not signed with the Transit key, and a private key stays on disk |
| Keep `release.key` "just in case" | The grader requires that no release private key is left on disk |
