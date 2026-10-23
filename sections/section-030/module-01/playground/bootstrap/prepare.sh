#!/usr/bin/env bash
# OS prep for the "Attach Attestations To Images" playground (`ats-119-playground-030-01`).
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
OPENBAO="no"
ENABLE_TRANSIT="no"
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

# Example files for the module.
ws sh -c 'mkdir -p "$(dirname /work/predicates/provenance.json)" && cat > /work/predicates/provenance.json' <<'JSON_EOF'
{
  "buildDefinition": {
    "buildType": "https://ci.inventory.example/build-types/container/v1",
    "externalParameters": {
      "repository": "https://git.inventory.example/inventory/podinfo",
      "ref": "refs/tags/6.15.0"
    },
    "internalParameters": {},
    "resolvedDependencies": [
      {
        "uri": "git+https://git.inventory.example/inventory/podinfo@refs/tags/6.15.0",
        "digest": {"gitCommit": "8c1d0f4a4d2b6e3f9a7c5b1e0d9f8a7b6c5d4e3f"}
      }
    ]
  },
  "runDetails": {
    "builder": {"id": "https://ci.inventory.example/builders/release"},
    "metadata": {
      "invocationId": "release-6.15.0-build-412",
      "startedOn": "2026-10-20T09:12:00Z",
      "finishedOn": "2026-10-20T09:19:40Z"
    }
  }
}
JSON_EOF
ws sh -c 'mkdir -p "$(dirname /work/predicates/vuln.json)" && cat > /work/predicates/vuln.json' <<'JSON_EOF'
{
  "invocation": {
    "parameters": null,
    "uri": "https://ci.inventory.example/pipelines/scan",
    "event_id": "scan-6.15.0",
    "builder.id": "https://ci.inventory.example/builders/release"
  },
  "scanner": {
    "uri": "pkg:github/aquasecurity/trivy@0.76.1",
    "version": "0.76.1",
    "db": {
      "uri": "pkg:oci/trivy-db@sha256:4f1c3a0e9d2b7c6a5f8e1d0c9b8a7f6e5d4c3b2a1f0e9d8c7b6a5f4e3d2c1b0a",
      "version": "2"
    },
    "result": {
      "SchemaVersion": 2,
      "ArtifactName": "registry.localtest.me:5001/inventory/podinfo:6.15.0",
      "Results": [
        {
          "Target": "podinfo (alpine)",
          "Class": "os-pkgs",
          "Vulnerabilities": [
              {"VulnerabilityID": "CVE-2026-1101", "PkgName": "busybox", "InstalledVersion": "1.37.0-r18", "Severity": "LOW"}
          ]
        }
      ]
    }
  },
  "metadata": {
    "scanStartedOn": "2026-10-20T09:21:00Z",
    "scanFinishedOn": "2026-10-20T09:21:42Z"
  }
}
JSON_EOF

echo "[playground] Open a shell with the tools: kubectl -n workstation exec -it deploy/workstation -- sh"
