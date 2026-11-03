#!/usr/bin/env bash
# Creates the starting state for ats-119-lab-030-03.
# The task's answer is NOT created here — producing it is the task.
set -euo pipefail

REGISTRY="registry.localtest.me:5001"
REPO="$REGISTRY/inventory/podinfo"
LAB_PASSWORD="lab-only-password"
OFFLINE_SC="/setup/offline-signing-config.json"

# ws CMD...: runs a command in the workstation pod. ws_sh SCRIPT: runs a shell
# script there, in /work.
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
ws_sh() { kubectl -n workstation exec -i deploy/workstation -- sh -c "cd /work && $1"; }

# manifest_dir: prints the folder that holds this environment's manifests.
manifest_dir() {
  local here
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  for candidate in "$here/../manifests" "./manifests" "$here/manifests"; do
    [ -d "$candidate" ] && { echo "$candidate"; return 0; }
  done
  echo "manifests"
}

# record_baseline KEY VALUE / baseline KEY: values the graders compare
# against, kept outside the workstation so the task cannot change them.
record_baseline() {
  kubectl -n workstation create configmap "lab-baseline-$1" \
    --from-literal=value="$2" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
}
baseline() { kubectl -n workstation get configmap "lab-baseline-$1" -o jsonpath='{.data.value}'; }

# grader_file NAME: copies stdin to /tmp/grader/NAME in the workstation.
grader_file() { ws sh -c "mkdir -p /tmp/grader && cat > /tmp/grader/$1"; }

# digest_of TAG: prints the digest the tag points at.
digest_of() { ws regctl image digest "$REPO:$1" 2>/dev/null; }

# verify_key PUBFILE REF [extra args...]: exit 0 when cosign verifies REF with
# the public key PUBFILE (a path in the workstation).
verify_key() {
  local pub="$1" ref="$2"; shift 2
  ws cosign verify --key "$pub" --insecure-ignore-tlog --allow-http-registry "$@" "$ref" >/dev/null 2>&1
}

# sign_with KEYFILE REF [extra args...]: signs REF in the workstation with a
# key file and the offline signing configuration.
sign_with() {
  local key="$1" ref="$2"; shift 2
  ws env COSIGN_PASSWORD="$LAB_PASSWORD" cosign sign -y --key "$key" \
    --signing-config "$OFFLINE_SC" --allow-http-registry "$@" "$ref" >/dev/null
}

# make_key PREFIX: creates /work/keys/PREFIX.key and .pub with the lab-only
# password.
make_key() {
  ws_sh "mkdir -p /work/keys && cd /work/keys && rm -f $1.key $1.pub && COSIGN_PASSWORD=$LAB_PASSWORD cosign generate-key-pair --output-key-prefix $1 >/dev/null"
}

pass() { echo "PASS: $*"; exit 0; }
fail() { echo "FAIL: $*"; exit 1; }

echo "[lab] Creating the release key and attaching an SBOM to each release..."
make_key release
record_baseline release-pub "$(ws cat /work/keys/release.pub)"
record_baseline digest-6150 "$(digest_of 6.15.0)"
record_baseline digest-6141 "$(digest_of 6.14.1)"
ws sh -c 'mkdir -p /work/sbom /work/policies && cat > /work/sbom/podinfo-6.15.0.spdx.json' <<'JSON_EOF'
{"spdxVersion":"SPDX-2.3","dataLicense":"CC0-1.0","SPDXID":"SPDXRef-DOCUMENT","name":"podinfo-6.15.0","documentNamespace":"https://inventory.example/spdx/podinfo-6.15.0","creationInfo":{"created":"2026-10-20T09:20:00Z","creators":["Tool: syft-1.55.0"]},"packages":[{"name":"podinfo","SPDXID":"SPDXRef-Package-podinfo","versionInfo":"6.15.0","downloadLocation":"NOASSERTION"}]}
JSON_EOF
ws sh -c 'cat > /work/sbom/podinfo-6.14.1.spdx.json' <<'JSON_EOF'
{"spdxVersion":"SPDX-2.3","dataLicense":"CC0-1.0","SPDXID":"SPDXRef-DOCUMENT","name":"podinfo-6.14.1","documentNamespace":"https://inventory.example/spdx/podinfo-6.14.1","creationInfo":{"created":"2026-10-20T09:20:00Z","creators":["Tool: spreadsheet-1"]},"packages":[{"name":"podinfo","SPDXID":"SPDXRef-Package-podinfo","versionInfo":"6.14.1","downloadLocation":"NOASSERTION"}]}
JSON_EOF
for pair in "6.15.0" "6.14.1"; do
  ws_sh "COSIGN_PASSWORD=$LAB_PASSWORD cosign attest -y --key /work/keys/release.key --signing-config $OFFLINE_SC --allow-http-registry --type spdxjson --predicate /work/sbom/podinfo-$pair.spdx.json $REPO@$(digest_of $pair) >/dev/null"
done
echo "[lab] Starting state ready: both releases have an SPDX attestation; no policy exists yet."
