# Solution: Check Three Downloads Against Their Bundles

Work the task yourself first. Running `astrona submit -c sections/section-020/module-02/labs/lab-01` after a step tells you which checks pass.

The grader runs `cosign verify-blob` on every download itself, with its own copy of the release public key, and compares the result with your two files. It also checks that no download or bundle changed.

## Step 1: Set the values and look at the files

Open a workstation shell and set the values the commands use:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
```

List the downloads and their bundles:

```sh
cd /work/downloads
ls -l
```

There are three files and three bundles.

## Step 2: Verify each download

`cosign verify-blob` takes the file as its argument and reads the bundle with `--bundle`. `--insecure-ignore-tlog` is needed because the offline signing configuration put no entry in a transparency log:

```sh
cosign verify-blob --key /work/keys/release.pub --insecure-ignore-tlog --bundle app-linux-amd64.sigstore.json app-linux-amd64
cosign verify-blob --key /work/keys/release.pub --insecure-ignore-tlog --bundle app-linux-arm64.sigstore.json app-linux-arm64
cosign verify-blob --key /work/keys/release.pub --insecure-ignore-tlog --bundle app-darwin-arm64.sigstore.json app-darwin-arm64
```

`app-linux-amd64` passes. `app-linux-arm64` fails because the file changed after it was signed: its hash no longer matches the hash in the bundle. `app-darwin-arm64` fails because its bundle was made by a different key, so the signature does not verify with the release key.

## Step 3: Write the two lists

Let a loop do the sorting so a typo cannot slip in:

```sh
: > /work/report/verified.txt
: > /work/report/failed.txt
for f in app-linux-amd64 app-linux-arm64 app-darwin-arm64; do
  if cosign verify-blob --key /work/keys/release.pub --insecure-ignore-tlog --bundle $f.sigstore.json $f >/dev/null 2>&1; then
    echo $f >> /work/report/verified.txt
  else
    echo $f >> /work/report/failed.txt
  fi
done
cat /work/report/verified.txt /work/report/failed.txt
```

`verified.txt` holds one name and `failed.txt` holds two.

## Step 4: Submit

Leave the workstation shell with `exit`, and send the lab for grading from your own terminal:

```sh
astrona submit -c sections/section-020/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Re-sign the failing files so everything verifies | The task only reads; the grader checks that the files and bundles are unchanged |
| Judge by the file timestamps or sizes | The changed file may look normal; only the hash check tells the truth |
| Verify only the bundle with `jq` | Reading a bundle does not check the signature or the file |

## Common mistakes

- Forgetting `--insecure-ignore-tlog`, so every download fails for the wrong reason.
- Verifying a file against another file's bundle.
- Writing the full path in the lists. The lists hold the file names only.
