#!/usr/bin/env bash
set -euo pipefail

SF_ALIAS="${SF_ALIAS:-target-org}"
OUTPUT_FILE="${1:-production-validation.json}"

sf project deploy validate \
  --source-dir force-app \
  --target-org "$SF_ALIAS" \
  --test-level RunLocalTests \
  --wait 45 \
  --json > "$OUTPUT_FILE"

JOB_ID=$(python - "$OUTPUT_FILE" <<'PY2'
import json, sys
with open(sys.argv[1], encoding='utf-8') as f:
    payload = json.load(f)
result = payload.get('result') or {}
job_id = result.get('id') or result.get('jobId')
if not job_id:
    raise SystemExit('Validation completed but no deployment job ID was returned.')
print(job_id)
PY2
)

echo "Production validation job: $JOB_ID"
echo "$JOB_ID" > production-validation-job-id.txt
