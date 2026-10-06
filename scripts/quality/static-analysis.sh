#!/usr/bin/env bash
set -euo pipefail

OUTPUT_DIR="${CODE_ANALYZER_OUTPUT_DIR:-artifacts/code-analyzer}"
SEVERITY_THRESHOLD="${CODE_ANALYZER_SEVERITY_THRESHOLD:-High}"
mkdir -p "$OUTPUT_DIR"

sf code-analyzer run \
  --workspace . \
  --target force-app \
  --target unpackaged \
  --rule-selector Recommended \
  --severity-threshold "$SEVERITY_THRESHOLD" \
  --include-suggestions \
  --output-file "$OUTPUT_DIR/results.sarif" \
  --output-file "$OUTPUT_DIR/results.html" \
  --view table
