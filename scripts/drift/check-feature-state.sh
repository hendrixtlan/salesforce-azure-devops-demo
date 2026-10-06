#!/usr/bin/env bash
set -euo pipefail
SF_ALIAS="${SF_ALIAS:-production}"
EXPECTED="${EXPECTED_FEATURE_ENABLED:-}"
OUT="${DRIFT_OUTPUT_DIR:-artifacts/drift/${SF_ALIAS}}"
mkdir -p "$OUT"
sf data query --target-org "$SF_ALIAS" --query "SELECT DeveloperName, Priority_Automation_Enabled__c FROM Case_Escalation_Config__mdt WHERE DeveloperName='Default'" --json > "$OUT/feature-state.json"
python - "$OUT/feature-state.json" "$EXPECTED" <<'PY'
import json, sys
payload=json.load(open(sys.argv[1],encoding='utf-8'))
expected=sys.argv[2].strip().lower()
records=((payload.get('result') or {}).get('records') or [])
if len(records) != 1:
    raise SystemExit(f'Expected one Default feature config record, found {len(records)}')
actual='true' if bool(records[0].get('Priority_Automation_Enabled__c')) else 'false'
print(f'Production feature state: {actual}')
if expected:
    if expected not in ('true','false'):
        raise SystemExit('EXPECTED_FEATURE_ENABLED must be true or false when set.')
    if actual != expected:
        raise SystemExit(f'Feature-state drift: expected {expected}, actual {actual}')
    print('Feature state matches the declared operational expectation.')
else:
    print('EXPECTED_FEATURE_ENABLED is not set; state captured without enforcement.')
PY
