#!/usr/bin/env bash
set -euo pipefail

SCRATCH_ALIAS="${SCRATCH_ALIAS:-ci-scratch}"
SEED_DIR="${SEED_DIR:-artifacts/seed-data}"
mkdir -p "$SEED_DIR"

TMP_RESULT="$(mktemp)"
trap 'rm -f "$TMP_RESULT"' EXIT

SUBJECT="CI seeded critical case"

sf data create record \
  --target-org "$SCRATCH_ALIAS" \
  --sobject Case \
  --values "Subject='${SUBJECT}' Status=New Origin=Web Escalation_Level__c=Critical" \
  --json > "$TMP_RESULT"

CASE_ID=$(python - "$TMP_RESULT" <<'PY'
import json
import sys
with open(sys.argv[1], encoding="utf-8") as handle:
    payload = json.load(handle)
result = payload.get("result") or {}
record_id = result.get("id")
if not record_id:
    raise SystemExit("Seed record was created without a returned record ID.")
print(record_id)
PY
)

printf '%s\n' "$CASE_ID" > "$SEED_DIR/case-id.txt"
printf '{\n  "caseId": "%s",\n  "subject": "%s"\n}\n' "$CASE_ID" "$SUBJECT" > "$SEED_DIR/seed-summary.json"
echo "Seeded Case record: $CASE_ID"
