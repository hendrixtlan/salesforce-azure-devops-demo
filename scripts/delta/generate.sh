#!/usr/bin/env bash
set -euo pipefail

FROM_REF="${DELTA_FROM_REF:-origin/main}"
TO_REF="${DELTA_TO_REF:-HEAD}"
SOURCE_DIR="${DELTA_SOURCE_DIR:-unpackaged}"
OUTPUT_DIR="${DELTA_OUTPUT_DIR:-artifacts/delta}"

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

echo "Generating Salesforce-aware delta: ${FROM_REF}..${TO_REF} (scope: ${SOURCE_DIR})"
sf sgd source delta \
  --from "$FROM_REF" \
  --to "$TO_REF" \
  --source-dir "$SOURCE_DIR" \
  --output-dir "$OUTPUT_DIR" \
  --generate-delta \
  --changes-manifest "$OUTPUT_DIR/changes.manifest.json"

echo "Delta generated under ${OUTPUT_DIR}."
