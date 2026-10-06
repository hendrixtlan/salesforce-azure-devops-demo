#!/usr/bin/env bash
set -euo pipefail

SF_ALIAS="${SF_ALIAS:-target-org}"
STATE="${FEATURE_STATE:-${1:-}}"
WAIT_MINUTES="${DEPLOY_WAIT_MINUTES:-20}"

if [[ "$STATE" != "enabled" && "$STATE" != "disabled" ]]; then
  echo "Usage: FEATURE_STATE=enabled|disabled $0  (or pass enabled|disabled as arg 1)" >&2
  exit 2
fi

SOURCE_DIR="ops/feature-flags/${STATE}"
if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "Feature-flag source not found: $SOURCE_DIR" >&2
  exit 1
fi

echo "Setting Case priority automation to ${STATE} in ${SF_ALIAS}."
sf project deploy start \
  --source-dir "$SOURCE_DIR" \
  --target-org "$SF_ALIAS" \
  --wait "$WAIT_MINUTES"

echo "Feature flag deployed: ${STATE}."
