# Solution: Inventory The Signatures In The Registry

Work the task yourself first. Running `astrona submit -c sections/section-010/module-03/labs/lab-01` after a step tells you which checks pass.

The grader lists the referrers of the 6.15.0 digest itself and compares them with your file, checks that the tag you named exists in the repository, and checks that 6.14.1 is the only tag without referrers.

## Step 1: Set the values and find the digests

Open a workstation shell and set the values the commands use:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
```

Resolve both tags to digests:

```sh
CURRENT=$(regctl image digest $REPO:6.15.0)
OLD=$(regctl image digest $REPO:6.14.1)
echo $CURRENT $OLD
```

## Step 2: List the referrers

`cosign tree` and `regctl artifact list` both show what is attached to a digest:

```sh
cosign tree --allow-http-registry $REPO@$CURRENT
regctl artifact list $REPO@$CURRENT
```

Write the digests, one per line, into the report file. The template makes `regctl` print only the digests:

```sh
regctl artifact list $REPO@$CURRENT --format '{{range .Descriptors}}{{println .Digest}}{{end}}' > /work/report/referrers.txt
cat /work/report/referrers.txt
```

The file holds two digests: the release signature and the developer signature.

## Step 3: Find the tag that lists the referrers

The lab registry has no referrers API, so clients keep a list of referrers in a tag named `sha256-` followed by the 64 hexadecimal characters of the digest. List the tags:

```sh
regctl tag ls $REPO
```

Besides `6.15.0` and `6.14.1` the list holds a tag that starts with `sha256-`. Build the expected name from the digest and write it down:

```sh
printf 'sha256-%s\n' "${CURRENT#sha256:}" > /work/report/fallback-tag.txt
cat /work/report/fallback-tag.txt
```

The name matches the tag in the list.

## Step 4: Find the tags without referrers

The tag `6.15.0` has referrers. Check `6.14.1`:

```sh
regctl artifact list $REPO@$OLD
```

The command lists no referrers. The `sha256-` tag is not a release, so it does not belong in the answer:

```sh
echo 6.14.1 > /work/report/unsigned.txt
```

## Step 5: Submit

Leave the workstation shell with `exit`, and send the lab for grading from your own terminal:

```sh
astrona submit -c sections/section-010/module-03/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Copy the digests from the `cosign tree` output by hand | A typo makes the list differ from the registry; use the template and the redirect |
| Put the tag `6.15.0` in `unsigned.txt` | It has two referrers |
| Put the `sha256-` tag in `unsigned.txt` | It is the fallback tag, not a release |
| Delete the developer signature to make the list shorter | The grader lists the referrers itself, and the task only reads |

## Common mistakes

- Using the digest of the image in `referrers.txt` instead of the digests of the referrers.
- Leaving the `sha256:` prefix off the digests, or adding it to the tag name. The tag name uses `sha256-` with a dash.
- Writing the files with extra text such as a heading.
