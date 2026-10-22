# Solution: Repair The Signatures Of A Release Download

Work the task yourself first. Running `astrona submit -c sections/section-020/capstone/labs/lab-01` after a step tells you which checks pass.

The grader checks that the archive and the SBOM are unchanged, that all three files verify with their bundles and its own copy of the release key, and that `SHA256SUMS` lists both files and matches them.

## Step 1: Set the values and look

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

```sh
export COSIGN_PASSWORD=lab-only-password
SC=/setup/offline-signing-config.json
cd /work/release && ls -l && cat SHA256SUMS
```

There are bundles for the archive and the SBOM, none for `SHA256SUMS`, and `SHA256SUMS` lists only the archive.

## Step 2: Find out why each bundle fails

Check every bundle with both public keys:

```sh
for file in inventory-1.5.0.tar.gz inventory-1.5.0.spdx.json; do
  for key in release build; do
    if cosign verify-blob --key /work/keys/$key.pub --insecure-ignore-tlog --bundle $file.sigstore.json $file >/dev/null 2>&1; then
      echo "$file: verifies with $key"
    else
      echo "$file: fails with $key"
    fi
  done
done
```

The archive verifies only with the build key: it was signed with the wrong key. The SBOM fails with both keys: it changed after it was signed, so its hash no longer matches the bundle. Compare the hash in its bundle with the file to see it:

```sh
jq -r '.messageSignature.messageDigest.digest' inventory-1.5.0.spdx.json.sigstore.json | base64 -d | od -An -tx1 | tr -d ' \n'; echo
sha256sum inventory-1.5.0.spdx.json
```

The two values differ.

## Step 3: Rebuild the checksum file

```sh
sha256sum inventory-1.5.0.tar.gz inventory-1.5.0.spdx.json > SHA256SUMS
sha256sum -c SHA256SUMS
```

## Step 4: Sign all three files with the release key

```sh
for file in inventory-1.5.0.tar.gz inventory-1.5.0.spdx.json SHA256SUMS; do
  cosign sign-blob --key /work/keys/release.key --signing-config $SC -y --bundle $file.sigstore.json $file
done
```

cosign overwrites the old bundles with new ones.

## Step 5: Verify and submit

```sh
for file in inventory-1.5.0.tar.gz inventory-1.5.0.spdx.json SHA256SUMS; do
  cosign verify-blob --key /work/keys/release.pub --insecure-ignore-tlog --bundle $file.sigstore.json $file
done
astrona submit -c sections/section-020/capstone/labs/lab-01
```

Run `astrona submit` from your own terminal, not from the workstation shell.

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Remove the late package from the SBOM so the old bundle verifies | The SBOM is final; the grader requires it unchanged |
| Publish the build public key as a second trusted key | Customers trust the release key only |
| Sign `SHA256SUMS` before rebuilding it | The bundle covers the old checksum list |
