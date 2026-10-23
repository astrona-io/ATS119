# Overview: Attach Attestations To Images (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with a registry and the workstation pod, copies two example images, writes two example predicates, and then waits. There is no task, no `astrona submit` and no pass or fail.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- An OCI registry at `registry.localtest.me:5001` inside the cluster (plain HTTP, lab-only) with `inventory/podinfo:6.15.0` and `inventory/podinfo:6.14.1`.
- The **workstation** pod with `cosign` v3.1.4, `regctl`, `jq` and `vi`. Open a shell with `kubectl -n workstation exec -it deploy/workstation -- sh`; it starts in `/work`.
- `/work/predicates/provenance.json`, a SLSA v1 provenance predicate whose builder is `https://ci.inventory.example/builders/release`.
- `/work/predicates/vuln.json`, a Trivy scan in cosign's vulnerability format with one low-severity finding.
- `/setup/offline-signing-config.json`, a signing configuration with no Fulcio, Rekor or timestamp service.

No key pair exists yet; create one with `cosign generate-key-pair`.

## Helpers

Paste these once in each new workstation shell. `attest_as` attaches a predicate of a given type to the release digest with `/work/keys/release.key`. `read_attestation` verifies the attestations of a type and prints the first decoded statement. `remove_referrers` deletes every signature and attestation attached to the release digest.

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
DIGEST=$(regctl image digest $REPO:6.15.0)
attest_as() { cosign attest --key /work/keys/release.key --signing-config $SC --allow-http-registry -y --type "$1" --predicate "$2" $REPO@$DIGEST; }
read_attestation() { cosign verify-attestation --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry --type "$1" $REPO@$DIGEST | jq -r '.payload' | head -1 | base64 -d | jq .; }
remove_referrers() {
  for referrer in $(regctl artifact list $REPO@$DIGEST --format '{{range .Descriptors}}{{.Digest}} {{end}}'); do
    regctl manifest delete --referrers $REPO@$referrer
  done
}
```

`remove_referrers` uses `regctl` because `cosign clean` does this job, but cosign 3.1.4 ignores `--allow-http-registry` for it, so it only works against an HTTPS registry.

Use them like this: `attest_as vuln /work/predicates/vuln.json`, then `read_attestation vuln`.

## Practice tasks

- Attest the provenance with `--type custom` instead of `slsaprovenance1`, then try to verify it with `--type slsaprovenance1` and read the error.
- Remove `runDetails` from a copy of the provenance and try to attest it as `slsaprovenance1`.
- Write a Rego policy that allows only scans finished after a given time, using `input.predicate.metadata.scanFinishedOn`.
- Attach a second scan with a `CRITICAL` finding, run your scan policy, and then remove the attestations with `remove_referrers` and attach the clean scan again.
- Compare `cosign tree` before and after each attestation.
