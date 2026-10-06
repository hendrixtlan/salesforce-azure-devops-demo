#!/usr/bin/env bash
set -euo pipefail

SCRATCH_ALIAS="${SCRATCH_ALIAS:-ci-scratch}"
SEED_DIR="${SEED_DIR:-artifacts/seed-data}"
RESULT_DIR="${SMOKE_RESULT_DIR:-artifacts/smoke-test}"
CASE_ID_FILE="$SEED_DIR/case-id.txt"
mkdir -p "$RESULT_DIR"

if [[ ! -f "$CASE_ID_FILE" ]]; then
  echo "Seed Case ID not found at $CASE_ID_FILE" >&2
  exit 1
fi

CASE_ID=$(tr -d '\r\n' < "$CASE_ID_FILE")
QUERY_RESULT="$RESULT_DIR/case-query.json"

sf data query \
  --target-org "$SCRATCH_ALIAS" \
  --query "SELECT Id, Subject, Priority, Escalation_Level__c FROM Case WHERE Id = '${CASE_ID}'" \
  --json > "$QUERY_RESULT"

python - "$QUERY_RESULT" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    payload = json.load(handle)
records = ((payload.get("result") or {}).get("records") or [])
if len(records) != 1:
    raise SystemExit(f"Expected exactly one seeded Case, found {len(records)}.")
record = records[0]
priority = record.get("Priority")
escalation = record.get("Escalation_Level__c")
print(f"Smoke test Case: {record.get('Id')}")
print(f"Escalation level: {escalation}")
print(f"Priority after trigger: {priority}")
if escalation != "Critical":
    raise SystemExit(f"Expected Escalation_Level__c=Critical, got {escalation!r}.")
if priority != "High":
    raise SystemExit(f"Expected trigger to set Priority=High, got {priority!r}.")
print("Behavioral smoke test passed.")
PY
