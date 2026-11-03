# Verifying A Set Of Downloads

A release usually has more than one download: one per operating system and architecture. Checking them one by one by hand does not scale, and a missed file is a hole in the check. This part verifies a set of files with a loop and shows the two results a release manager needs: which files can be trusted and which cannot.

## A set of downloads

Create two more files and sign each with the release key, using the same naming convention:

<!-- astrona:playground:renew -->

```sh
export COSIGN_PASSWORD=lab-only-password
SC=/setup/offline-signing-config.json
cd /work/dl
printf 'linux arm64\n' > tool-linux-arm64
printf 'darwin arm64\n' > tool-darwin-arm64
for f in tool-linux-arm64 tool-darwin-arm64; do
  cosign sign-blob -y --key /work/keys/release.key --signing-config $SC --bundle $f.sigstore.json $f
done
ls
```

The folder now holds the files and one bundle for each of them.

## Sort the files by result

The loop below verifies each file against the bundle with the same name and writes its name to one of two lists. The `if` tests the exit status of `cosign verify-blob`:

```sh
: > ok.txt; : > bad.txt
for f in tool-linux-amd64 tool-linux-arm64 tool-darwin-arm64; do
  if cosign verify-blob --key /work/keys/release.pub --insecure-ignore-tlog --bundle $f.sigstore.json $f > /dev/null 2>&1; then
    echo $f >> ok.txt
  else
    echo $f >> bad.txt
  fi
done
cat ok.txt; echo ---; cat bad.txt
```

All three names are in `ok.txt`. Change one file with `printf 'x' >> tool-linux-arm64` and run the loop again to see the name move to `bad.txt`. The output of the commands is discarded with `> /dev/null 2>&1`, because the script needs only the status.

## A missing bundle is a failure

A file with no bundle is not "unsigned and fine". Create one and run the loop on it:

```sh
printf 'orphan\n' > tool-orphan
cosign verify-blob --key /work/keys/release.pub --insecure-ignore-tlog --bundle tool-orphan.sigstore.json tool-orphan; echo "exit status: $?"
```

cosign reports that it cannot read the bundle and exits with a non-zero status. The loop would put this file in `bad.txt`, which is correct. The rule for a download process is: a file is trusted only if a bundle exists and verifies.

## Do not change what you check

A verification step only reads. It must not re-sign, rename or overwrite files, and it must not create new bundles. If a release manager signs failing files "to fix the report", the report is worthless, because it now describes the repaired state and not the state that was shipped.

You can now sort a set of downloads into trusted and untrusted files with a loop and an exit status. The next part reduces the number of bundles by signing a checksum list.


## Common pitfalls

> [!WARNING]
> - **Treating a missing bundle as a pass.** No bundle means no evidence.
> - **Verifying every file against the same bundle.** Each file has its own bundle.
> - **Changing files while checking them.** A check should leave everything as it found it.
