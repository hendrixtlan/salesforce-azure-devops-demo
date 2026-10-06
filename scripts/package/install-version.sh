#!/usr/bin/env bash
set -euo pipefail

SF_ALIAS="${SF_ALIAS:-target-org}"
PACKAGE_OUTPUT_DIR="${PACKAGE_OUTPUT_DIR:-artifacts/package}"
PACKAGE_VERSION_ID="${PACKAGE_VERSION_ID:-}"

if [[ -z "$PACKAGE_VERSION_ID" && -f "$PACKAGE_OUTPUT_DIR/package-version-id.txt" ]]; then
  PACKAGE_VERSION_ID=$(tr -d '\r\n' < "$PACKAGE_OUTPUT_DIR/package-version-id.txt")
fi

if [[ -z "$PACKAGE_VERSION_ID" || "$PACKAGE_VERSION_ID" != 04t* ]]; then
  echo "PACKAGE_VERSION_ID (04t...) is required." >&2
  exit 1
fi

sf package install \
  --package "$PACKAGE_VERSION_ID" \
  --target-org "$SF_ALIAS" \
  --publish-wait 10 \
  --wait 30 \
  --security-type AdminsOnly \
  --upgrade-type Mixed \
  --no-prompt
