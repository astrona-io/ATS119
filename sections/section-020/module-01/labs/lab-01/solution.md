# Solution: Sign A Release Archive And Its SBOM

Work the task yourself first. Running `astrona submit -c sections/section-020/module-01/labs/lab-01` after a step tells you which checks pass.

The grader uses its own copy of the release public key. It checks that the archive is unchanged and verifies, that the SBOM is SPDX JSON for podinfo and verifies, and that a changed copy of the archive fails.

## Step 1: Set the values

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
cd /work/release && ls -l
```

## Step 2: Generate the SBOM from the digest

```sh
DIGEST=$(regctl image digest $REPO:6.15.0)
syft scan registry:$REPO@$DIGEST -o spdx-json=podinfo-6.15.0.spdx.json
jq '{spdxVersion, name, packages: (.packages | length)}' podinfo-6.15.0.spdx.json
```

`spdxVersion` starts with `SPDX-`, and `name` contains the image reference, so it mentions `podinfo`.

## Step 3: Sign both files

```sh
for file in inventory-1.4.0.tar.gz podinfo-6.15.0.spdx.json; do
  cosign sign-blob --key /work/keys/release.key --signing-config $SC -y --bundle $file.sigstore.json $file
done
```

Each file gets its own bundle next to it.

## Step 4: Verify, the way the grader does

```sh
for file in inventory-1.4.0.tar.gz podinfo-6.15.0.spdx.json; do
  cosign verify-blob --key /work/keys/release.pub --insecure-ignore-tlog --bundle $file.sigstore.json $file
done
cp inventory-1.4.0.tar.gz /tmp/changed.tar.gz && printf x >> /tmp/changed.tar.gz
cosign verify-blob --key /work/keys/release.pub --insecure-ignore-tlog --bundle inventory-1.4.0.tar.gz.sigstore.json /tmp/changed.tar.gz
```

Both release files verify, and the changed copy fails, as it must.

## Step 5: Submit

Leave the workstation shell with `exit`, and send the lab for grading from your own terminal:

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Scan the tag `6.15.0` | It works today, but the SBOM is not tied to the digest you checked |
| Pretty-print the SBOM with `jq` after signing it | The bytes change and the bundle no longer verifies |
| Re-create the archive to "clean it up" | The archive changes, and the grader requires the original |
| Sign with a new key pair | Customers trust the published release key only |
