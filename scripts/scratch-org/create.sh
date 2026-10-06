#!/usr/bin/env bash
set -euo pipefail

DEV_HUB_ALIAS="${DEV_HUB_ALIAS:-devhub}"
SCRATCH_ALIAS="${SCRATCH_ALIAS:-ci-scratch}"
SCRATCH_DEF="${SCRATCH_DEF:-config/project-scratch-def.json}"
SCRATCH_DURATION_DAYS="${SCRATCH_DURATION_DAYS:-1}"
SCRATCH_WAIT_MINUTES="${SCRATCH_WAIT_MINUTES:-15}"

mkdir -p artifacts/scratch-org
TMP_ORG_JSON="$(mktemp)"
trap 'rm -f "$TMP_ORG_JSON"' EXIT

echo "Creating ephemeral scratch org: ${SCRATCH_ALIAS}"
sf org create scratch \
  --definition-file "$SCRATCH_DEF" \
  --alias "$SCRATCH_ALIAS" \
  --target-dev-hub "$DEV_HUB_ALIAS" \
  --duration-days "$SCRATCH_DURATION_DAYS" \
  --wait "$SCRATCH_WAIT_MINUTES"

# Keep only non-secret org metadata as pipeline evidence. Never publish access tokens.
sf org display --target-org "$SCRATCH_ALIAS" --json > "$TMP_ORG_JSON"
python - "$TMP_ORG_JSON" "artifacts/scratch-org/org-summary.json" "$SCRATCH_ALIAS" <<'PY'
import json
import sys

source, destination, alias = sys.argv[1:]
with open(source, encoding="utf-8") as handle:
    payload = json.load(handle)
result = payload.get("result") or {}
safe = {
    "alias": alias,
    "orgId": result.get("id") or result.get("orgId"),
    "username": result.get("username"),
    "instanceUrl": result.get("instanceUrl"),
}
with open(destination, "w", encoding="utf-8") as handle:
    json.dump(safe, handle, indent=2)
    handle.write("\n")
PY

echo "Scratch org ${SCRATCH_ALIAS} is ready."
