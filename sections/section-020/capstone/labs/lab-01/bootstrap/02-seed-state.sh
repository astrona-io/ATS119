#!/usr/bin/env bash
# Creates the starting state for ats-119-capstone-020.
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

echo "[lab] Creating the release key pair and a build key pair..."
make_key release
make_key build
record_baseline release-pub "$(ws cat /work/keys/release.pub)"
ws_sh 'mkdir -p /tmp/src/inventory-1.5.0 /work/release && printf "Inventory service 1.5.0\n" > /tmp/src/inventory-1.5.0/README && tar -C /tmp/src -czf /work/release/inventory-1.5.0.tar.gz inventory-1.5.0'
ws sh -c 'mkdir -p "$(dirname /work/release/inventory-1.5.0.spdx.json)" && cat > /work/release/inventory-1.5.0.spdx.json' <<'JSON_EOF'
{
  "spdxVersion": "SPDX-2.3",
  "dataLicense": "CC0-1.0",
  "SPDXID": "SPDXRef-DOCUMENT",
  "name": "inventory-1.5.0",
  "documentNamespace": "https://inventory.example/spdx/inventory-1.5.0",
  "creationInfo": {"created": "2026-10-20T10:00:00Z", "creators": ["Tool: release-script"]},
  "packages": [
    {"name": "inventory", "SPDXID": "SPDXRef-Package-inventory", "versionInfo": "1.5.0", "downloadLocation": "NOASSERTION"}
  ]
}
JSON_EOF

ws_sh 'cd /work/release && sha256sum inventory-1.5.0.tar.gz > SHA256SUMS'
echo "[lab] Signing the archive with the wrong key and the SBOM before its last change..."
ws_sh "COSIGN_PASSWORD=$LAB_PASSWORD cosign sign-blob -y --key /work/keys/build.key --signing-config $OFFLINE_SC --bundle /work/release/inventory-1.5.0.tar.gz.sigstore.json /work/release/inventory-1.5.0.tar.gz >/dev/null"
ws_sh "COSIGN_PASSWORD=$LAB_PASSWORD cosign sign-blob -y --key /work/keys/release.key --signing-config $OFFLINE_SC --bundle /work/release/inventory-1.5.0.spdx.json.sigstore.json /work/release/inventory-1.5.0.spdx.json >/dev/null"
ws_sh 'cd /work/release && jq ".packages += [{\"name\": \"busybox\", \"SPDXID\": \"SPDXRef-Package-busybox\", \"versionInfo\": \"1.37.0\", \"downloadLocation\": \"NOASSERTION\"}]" inventory-1.5.0.spdx.json > /tmp/sbom && mv /tmp/sbom inventory-1.5.0.spdx.json'
record_baseline tarball-sha "$(ws sha256sum /work/release/inventory-1.5.0.tar.gz | cut -d' ' -f1)"
record_baseline sbom-sha "$(ws sha256sum /work/release/inventory-1.5.0.spdx.json | cut -d' ' -f1)"
echo "[lab] Starting state ready."
