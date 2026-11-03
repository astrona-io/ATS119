# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Signing container images

## Scenario

The security team asks for an inventory of what the registry holds for `inventory/podinfo`. The repository has two tags: `6.15.0` and `6.14.1`. The current release, 6.15.0, was signed twice, by the release key and by a developer key. Nothing signs 6.14.1. The registry is the lab registry, which has no referrers API, so cosign and other clients keep the list of referrers for each digest in a tag of the repository.

Work in a workstation shell: `kubectl -n workstation exec -it deploy/workstation -- sh`. The registry is `registry.localtest.me:5001` (the variable `REGISTRY` holds it). The folder `/work/report` exists for your answers.

## Your task

1. Write the digest of every referrer of the 6.15.0 digest into `/work/report/referrers.txt`, one digest per line (each starts with `sha256:`).
2. Write the name of the tag in the repository that lists those referrers into `/work/report/fallback-tag.txt`.
3. Write the release tags of the repository that have no referrers into `/work/report/unsigned.txt`, one per line. Do not list the tag from step 2.

## Constraints

- Do not sign, delete or copy anything in the registry. This task only reads.
- Each file holds plain text with no extra words.

## Done when

- `referrers.txt` lists exactly the referrers that `regctl artifact list` shows for the 6.15.0 digest.
- `fallback-tag.txt` holds the name of an existing tag that is derived from the 6.15.0 digest.
- `unsigned.txt` lists `6.14.1` and nothing else.
