#!/usr/bin/env bash
set -euo pipefail
SF_ALIAS="${SF_ALIAS:-production}"
SNAPSHOT_DIR="${ROLLBACK_SNAPSHOT_DIR:-}"
ALLOW="${ALLOW_ROLLBACK:-false}"
if [[ "$ALLOW" != "true" ]]; then
  echo "Set ALLOW_ROLLBACK=true to restore captured unpackaged metadata." >&2
  exit 2
fi
if [[ -z "$SNAPSHOT_DIR" || ! -d "$SNAPSHOT_DIR/metadata" ]]; then
  echo "ROLLBACK_SNAPSHOT_DIR must point to a capture created by scripts/rollback/capture.sh." >&2
  exit 2
fi
PACKAGE_XML=$(find "$SNAPSHOT_DIR/metadata" -name package.xml -print | head -1 || true)
if [[ -z "$PACKAGE_XML" ]]; then
  echo "No package.xml found in rollback snapshot." >&2
  exit 1
fi
MDAPI_ROOT=$(dirname "$PACKAGE_XML")
echo "Restoring captured unpackaged metadata to ${SF_ALIAS} from ${MDAPI_ROOT}."
sf project deploy start --metadata-dir "$MDAPI_ROOT" --target-org "$SF_ALIAS" --wait 45
cat <<'MSG'
Unpackaged metadata restore completed.
Package-owned application code is intentionally not downgraded automatically. Use a corrective package version (roll-forward) or disable the feature flag while remediation is prepared.
MSG
