# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Keys in a key management service

## Scenario

Two signing keys live in the OpenBao Transit engine: `cosign-audit-a` and `cosign-audit-b`. A past rotation left it unclear which key signed which release. The two images `inventory/podinfo:6.15.0` and `inventory/podinfo:6.14.1` each carry one signature, made with one of the two keys. An auditor needs the public keys and the answer, without any private key leaving OpenBao.

Work in a workstation shell: `kubectl -n workstation exec -it deploy/workstation -- sh`. The registry is `registry.localtest.me:5001` (the variable `REGISTRY` holds it). `BAO_ADDR` and `BAO_TOKEN` are already set. The folders `/work/keys` and `/work/report` exist.

## Your task

1. Export the public key of `openbao://cosign-audit-a` to `/work/keys/audit-a.pub` and the public key of `openbao://cosign-audit-b` to `/work/keys/audit-b.pub`.
2. Find out which key signed each release by verifying the digests with the exported public keys.
3. Write the Transit key name that signed 6.15.0 into `/work/report/signer-6.15.0.txt` and the one that signed 6.14.1 into `/work/report/signer-6.14.1.txt`. Each file holds only the key name, for example `cosign-audit-a`.

## Constraints

- Do not sign, re-sign or delete anything. This task only reads.
- Do not write a private key file. A KMS key has none.

## Done when

- Both public key files match the keys in OpenBao.
- Each report file names the key that verifies that release.
- `/work/keys` holds no `.key` file.
