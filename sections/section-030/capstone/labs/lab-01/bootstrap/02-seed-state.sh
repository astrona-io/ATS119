#!/usr/bin/env bash
# Creates the starting state for ats-119-capstone-030.
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

echo "[lab] Creating the release key pair and the predicates..."
make_key release
record_baseline release-pub "$(ws cat /work/keys/release.pub)"
record_baseline digest-6150 "$(digest_of 6.15.0)"
record_baseline digest-6141 "$(digest_of 6.14.1)"
ws sh -c 'mkdir -p "$(dirname /work/predicates/provenance-dev.json)" && cat > /work/predicates/provenance-dev.json' <<'JSON_EOF'
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
    "builder": {"id": "https://ci.inventory.example/builders/dev"},
    "metadata": {
      "invocationId": "dev-6.15.0-build-17",
      "startedOn": "2026-10-20T09:12:00Z",
      "finishedOn": "2026-10-20T09:19:40Z"
    }
  }
}
JSON_EOF
ws sh -c 'mkdir -p "$(dirname /work/predicates/provenance-release.json)" && cat > /work/predicates/provenance-release.json' <<'JSON_EOF'
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
ws sh -c 'mkdir -p "$(dirname /work/predicates/vuln-stale.json)" && cat > /work/predicates/vuln-stale.json' <<'JSON_EOF'
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
              {"VulnerabilityID": "CVE-2026-0420", "PkgName": "openssl", "InstalledVersion": "3.5.1-r0", "Severity": "CRITICAL"},
              {"VulnerabilityID": "CVE-2026-0533", "PkgName": "zlib", "InstalledVersion": "1.3.1-r2", "Severity": "CRITICAL"},
              {"VulnerabilityID": "CVE-2026-1101", "PkgName": "busybox", "InstalledVersion": "1.37.0-r18", "Severity": "LOW"}
          ]
        }
      ]
    }
  },
  "metadata": {
    "scanStartedOn": "2026-09-02T07:00:00Z",
    "scanFinishedOn": "2026-09-02T07:00:38Z"
  }
}
JSON_EOF
ws sh -c 'mkdir -p "$(dirname /work/predicates/vuln-rescan.json)" && cat > /work/predicates/vuln-rescan.json' <<'JSON_EOF'
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
    "scanStartedOn": "2026-10-21T06:30:00Z",
    "scanFinishedOn": "2026-10-21T06:30:41Z"
  }
}
JSON_EOF
ws sh -c 'mkdir -p "$(dirname /work/predicates/vuln-6.14.1.json)" && cat > /work/predicates/vuln-6.14.1.json' <<'JSON_EOF'
{
  "invocation": {
    "parameters": null,
    "uri": "https://ci.inventory.example/pipelines/scan",
    "event_id": "scan-6.14.1",
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
      "ArtifactName": "registry.localtest.me:5001/inventory/podinfo:6.14.1",
      "Results": [
        {
          "Target": "podinfo (alpine)",
          "Class": "os-pkgs",
          "Vulnerabilities": [
              {"VulnerabilityID": "CVE-2026-0420", "PkgName": "openssl", "InstalledVersion": "3.4.0-r3", "Severity": "CRITICAL"},
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

echo "[lab] Attaching the stale scan and the developer provenance..."
attest() { ws_sh "COSIGN_PASSWORD=$LAB_PASSWORD cosign attest -y --key /work/keys/release.key --signing-config $OFFLINE_SC --allow-http-registry --type $1 --predicate /work/predicates/$2 $REPO@$3 >/dev/null"; }
attest vuln vuln-stale.json "$(digest_of 6.15.0)"
attest slsaprovenance1 provenance-dev.json "$(digest_of 6.15.0)"
attest vuln vuln-6.14.1.json "$(digest_of 6.14.1)"
attest slsaprovenance1 provenance-dev.json "$(digest_of 6.14.1)"
ws mkdir -p /work/policy
echo "[lab] Starting state ready."
