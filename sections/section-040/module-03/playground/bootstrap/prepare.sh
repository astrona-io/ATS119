#!/usr/bin/env bash
# OS prep for the "Auditing KMS Keys" playground (`ats-119-playground-040-03`).
#
# Environment preparation only. There is no task and no grading.
set -euo pipefail
# grep -q stops reading at the first match; under pipefail the command
# writing into the pipe then fails with SIGPIPE and a match looks like a
# failure. This wrapper reads all input instead and keeps grep's exit status.
grep() {
  local arg quiet=0 args=()
  for arg in "$@"; do
    case "$arg" in
      --quiet|--silent) quiet=1 ;;
      --*) args+=("$arg") ;;
      -*q*) quiet=1; [ "$arg" = "-q" ] || args+=("${arg//q/}") ;;
      *) args+=("$arg") ;;
    esac
  done
  if [ "$quiet" = 1 ]; then command grep "${args[@]}" >/dev/null; else command grep "$@"; fi
}

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

REGISTRY_HOST="registry.localtest.me"
OPENBAO="yes"
ENABLE_TRANSIT="yes"
MANIFEST_DIR="$(manifest_dir)"

# One name for the registry everywhere in the cluster. The answer is rewritten
# back to the asked name: Go programs (cosign included) ignore DNS answers whose
# name differs from the question.
if ! kubectl -n kube-system get configmap coredns -o jsonpath='{.data.Corefile}' | grep -q "$REGISTRY_HOST"; then
  echo "[env] Adding the CoreDNS rewrite for ${REGISTRY_HOST}..."
  COREFILE="$(kubectl -n kube-system get configmap coredns -o jsonpath='{.data.Corefile}' \
    | awk '/^[[:space:]]*kubernetes / && !done {
        print "    rewrite stop {"
        print "        name regex registry\\.localtest\\.me registry.registry.svc.cluster.local"
        print "        answer name registry\\.registry\\.svc\\.cluster\\.local registry.localtest.me"
        print "    }"
        done=1
      } {print}')"
  kubectl -n kube-system create configmap coredns --from-literal=Corefile="$COREFILE" \
    --dry-run=client -o yaml | kubectl apply -f -
  kubectl -n kube-system rollout restart deployment/coredns
  kubectl -n kube-system rollout status deployment/coredns --timeout=120s
fi

# lab-start.yaml is also listed under bootstrap.manifests in config.yaml, so it
# may already be applied. kubectl apply is idempotent.
echo "[env] Starting the registry and the workstation pod..."
kubectl apply -f "$MANIFEST_DIR/lab-start.yaml"
if [ "$OPENBAO" = "yes" ]; then
  kubectl apply -f "$MANIFEST_DIR/openbao.yaml"
fi
kubectl -n registry rollout status deployment/registry --timeout=300s
kubectl -n workstation rollout status deployment/workstation --timeout=600s
for _ in $(seq 1 60); do
  ws sh -c 'command -v git >/dev/null && command -v syft >/dev/null' 2>/dev/null && break
  sleep 5
done

if [ "$OPENBAO" = "yes" ]; then
  kubectl -n kms rollout status deployment/openbao --timeout=300s
  if [ "$ENABLE_TRANSIT" = "yes" ]; then
    echo "[env] Enabling the Transit secrets engine at transit/..."
    ws curl -fsS -H "X-Vault-Token: root" -X POST -d '{"type":"transit"}' \
      http://openbao.kms:8200/v1/sys/mounts/transit >/dev/null || true
  fi
fi

echo "[env] Copying the example images into the registry..."
for tag in 6.15.0 6.14.1; do
  ws regctl image copy --platform linux/amd64 "ghcr.io/stefanprodan/podinfo:$tag" "$REPO:$tag" >/dev/null
done
echo "[env] Ready."

echo "[playground] Open a shell with the tools: kubectl -n workstation exec -it deploy/workstation -- sh"
