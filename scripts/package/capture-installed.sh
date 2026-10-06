#!/usr/bin/env bash
set -euo pipefail
SF_ALIAS="${SF_ALIAS:-target-org}"
OUTPUT_DIR="${PACKAGE_OUTPUT_DIR:-artifacts/package}"
mkdir -p "$OUTPUT_DIR"
sf package installed list --target-org "$SF_ALIAS" --json > "$OUTPUT_DIR/installed-${SF_ALIAS}.json"
