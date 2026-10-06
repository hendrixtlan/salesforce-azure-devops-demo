#!/usr/bin/env bash
set -euo pipefail

DEV_HUB_ALIAS="${DEV_HUB_ALIAS:-devhub}"
PACKAGE_OUTPUT_DIR="${PACKAGE_OUTPUT_DIR:-artifacts/package}"
PACKAGE_VERSION_ID="${PACKAGE_VERSION_ID:-}"

if [[ -z "$PACKAGE_VERSION_ID" && -f "$PACKAGE_OUTPUT_DIR/package-version-id.txt" ]]; then
  PACKAGE_VERSION_ID=$(tr -d '\r\n' < "$PACKAGE_OUTPUT_DIR/package-version-id.txt")
fi

if [[ -z "$PACKAGE_VERSION_ID" || "$PACKAGE_VERSION_ID" != 04t* ]]; then
  echo "PACKAGE_VERSION_ID (04t...) is required." >&2
  exit 1
fi

sf package version promote \
  --package "$PACKAGE_VERSION_ID" \
  --target-dev-hub "$DEV_HUB_ALIAS" \
  --no-prompt
