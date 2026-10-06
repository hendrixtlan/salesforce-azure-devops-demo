#!/usr/bin/env bash
set -euo pipefail

SF_ALIAS="${SF_ALIAS:-target-org}"
OUTPUT_DIR="${DELTA_OUTPUT_DIR:-artifacts/delta}"
FULL_SOURCE_DIR="${FULL_UNPACKAGED_SOURCE_DIR:-unpackaged}"
DELTA_MODE="${DELTA_MODE:-true}"
PACKAGE_XML="$OUTPUT_DIR/package/package.xml"
DESTRUCTIVE_XML="$OUTPUT_DIR/destructiveChanges/destructiveChanges.xml"

full_deploy() {
  echo "Running full unpackaged deployment to ${SF_ALIAS}."
  sf project deploy start \
    --source-dir "$FULL_SOURCE_DIR" \
    --target-org "$SF_ALIAS" \
    --wait 45
}

if [[ "$DELTA_MODE" != "true" ]]; then
  full_deploy
  exit 0
fi

if [[ ! -f "$PACKAGE_XML" ]]; then
  echo "Delta manifest not found; falling back to full deployment." >&2
  full_deploy
  exit 0
fi

COMPONENT_COUNT=$(python - "$PACKAGE_XML" <<'PY'
import sys
import xml.etree.ElementTree as ET
root = ET.parse(sys.argv[1]).getroot()
ns = {"m": "http://soap.sforce.com/2006/04/metadata"}
print(len(root.findall(".//m:members", ns)))
PY
)

DESTRUCTIVE_COUNT=0
if [[ -f "$DESTRUCTIVE_XML" ]]; then
  DESTRUCTIVE_COUNT=$(python - "$DESTRUCTIVE_XML" <<'PY'
import sys
import xml.etree.ElementTree as ET
root = ET.parse(sys.argv[1]).getroot()
ns = {"m": "http://soap.sforce.com/2006/04/metadata"}
print(len(root.findall(".//m:members", ns)))
PY
)
fi

if [[ "$COMPONENT_COUNT" -eq 0 && "$DESTRUCTIVE_COUNT" -eq 0 ]]; then
  echo "No unpackaged Salesforce metadata changes detected; deployment skipped."
  exit 0
fi

echo "Deploying unpackaged delta to ${SF_ALIAS}: ${COMPONENT_COUNT} changed components, ${DESTRUCTIVE_COUNT} destructive components."
ARGS=(project deploy start --manifest "$PACKAGE_XML" --target-org "$SF_ALIAS" --wait 45)
if [[ "$DESTRUCTIVE_COUNT" -gt 0 ]]; then
  ARGS+=(--post-destructive-changes "$DESTRUCTIVE_XML")
fi
sf "${ARGS[@]}"
