#!/usr/bin/env bash
set -euo pipefail

DEV_HUB_ALIAS="${DEV_HUB_ALIAS:-devhub}"
PACKAGE_NAME="${PACKAGE_NAME:-CaseEscalationCore}"
PACKAGE_PATH="${PACKAGE_PATH:-force-app}"
OUTPUT_DIR="${PACKAGE_OUTPUT_DIR:-artifacts/package}"
mkdir -p "$OUTPUT_DIR"

LIST_JSON="$OUTPUT_DIR/package-list.json"
sf package list --target-dev-hub "$DEV_HUB_ALIAS" --json > "$LIST_JSON"

PACKAGE_ID=$(python - "$LIST_JSON" "$PACKAGE_NAME" <<'PY'
import json, sys
with open(sys.argv[1], encoding='utf-8') as handle:
    payload = json.load(handle)
name = sys.argv[2]
for item in payload.get('result') or []:
    if item.get('Name') == name or item.get('name') == name:
        print(item.get('Id') or item.get('id') or '')
        break
PY
)

if [[ -z "$PACKAGE_ID" ]]; then
  echo "Unlocked package ${PACKAGE_NAME} not found; creating it in Dev Hub."
  CREATE_JSON="$OUTPUT_DIR/package-create.json"
  sf package create \
    --name "$PACKAGE_NAME" \
    --package-type Unlocked \
    --path "$PACKAGE_PATH" \
    --no-namespace \
    --target-dev-hub "$DEV_HUB_ALIAS" \
    --json > "$CREATE_JSON"
  PACKAGE_ID=$(python - "$CREATE_JSON" <<'PY'
import json, sys
with open(sys.argv[1], encoding='utf-8') as handle:
    payload = json.load(handle)
result = payload.get('result') or {}
print(result.get('Id') or result.get('id') or '')
PY
)
fi

if [[ -z "$PACKAGE_ID" || "$PACKAGE_ID" != 0Ho* ]]; then
  echo "Unable to resolve a valid 0Ho package ID for ${PACKAGE_NAME}." >&2
  exit 1
fi

printf '%s\n' "$PACKAGE_ID" > "$OUTPUT_DIR/package-id.txt"
echo "Package ID: $PACKAGE_ID"
