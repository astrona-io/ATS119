# Solution: Find Out Which KMS Key Signed Which Release

Work the task yourself first. Running `astrona submit -c sections/section-040/module-03/labs/lab-01` after a step tells you which checks pass.

The grader exports both public keys again, verifies each release with them to find the real signer, and compares the result with your two report files.

## Step 1: Set the values

Open a workstation shell and set the values the commands use:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
```

Check that OpenBao answers:

```sh
echo $BAO_ADDR
curl -s http://openbao.kms:8200/v1/sys/health | jq '{initialized, sealed}'
```

## Step 2: Export the public keys

`cosign public-key --key` asks OpenBao for the public part of a Transit key. The private key stays in OpenBao:

```sh
cosign public-key --key openbao://cosign-audit-a --outfile /work/keys/audit-a.pub
cosign public-key --key openbao://cosign-audit-b --outfile /work/keys/audit-b.pub
```

## Step 3: Find the signer of each release

Try each public key against each digest. A signature verifies only with the public key that belongs to the signing key:

```sh
for tag in 6.15.0 6.14.1; do
  D=$(regctl image digest $REPO:$tag)
  for k in a b; do
    if cosign verify --key /work/keys/audit-$k.pub --insecure-ignore-tlog --allow-http-registry $REPO@$D >/dev/null 2>&1; then
      echo "$tag is signed by cosign-audit-$k"
    fi
  done
done
```

The loop prints one line per release. The key letter in each line is the answer for that release.

## Step 4: Write the report

Use the names the loop printed. For example, if 6.15.0 is signed by `cosign-audit-a`:

```sh
echo cosign-audit-a > /work/report/signer-6.15.0.txt
```

Write the other file the same way with the key the loop printed for 6.14.1. Check both files with `cat`.

## Step 5: Submit

Leave the workstation shell with `exit`, and send the lab for grading from your own terminal:

```sh
astrona submit -c sections/section-040/module-03/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Guess from the key names | The names say nothing about which key signed which release; only verification does |
| Run `cosign generate-key-pair --kms` again | That asks OpenBao for a new key and changes the state under audit |
| Export the Transit key as a file | A Transit key is not exportable by default, and the task forbids private key files |

## Common mistakes

- Using `openbao://` without `BAO_ADDR` and `BAO_TOKEN`, so cosign cannot reach the server.
- Verifying the tag instead of the digest.
- Writing extra text such as a sentence into a report file. It holds the key name only.
