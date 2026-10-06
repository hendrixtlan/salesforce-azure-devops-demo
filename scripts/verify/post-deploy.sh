#!/usr/bin/env bash
set -euo pipefail

SF_ALIAS="${SF_ALIAS:-target-org}"
EXPECTED_PACKAGE_VERSION_ID="${EXPECTED_PACKAGE_VERSION_ID:-}"
EXPECTED_FEATURE_ENABLED="${EXPECTED_FEATURE_ENABLED:-true}"
OUT="${VERIFY_OUTPUT_DIR:-artifacts/post-deploy/${SF_ALIAS}}"
mkdir -p "$OUT"

INSTALLED_JSON="$OUT/installed-packages.json"
CONFIG_JSON="$OUT/feature-config.json"
CREATE_JSON="$OUT/synthetic-case-create.json"
QUERY_JSON="$OUT/synthetic-case-query.json"
RESULT_JSON="$OUT/verification-summary.json"

sf package installed list --target-org "$SF_ALIAS" --json > "$INSTALLED_JSON"

if [[ -n "$EXPECTED_PACKAGE_VERSION_ID" ]]; then
  python - "$INSTALLED_JSON" "$EXPECTED_PACKAGE_VERSION_ID" <<'PY'
import json, sys
payload=json.load(open(sys.argv[1], encoding='utf-8'))
expected=sys.argv[2]
items=(payload.get('result') or [])
ids=[]
for item in items:
    for key in ('SubscriberPackageVersionId','subscriberPackageVersionId','Id','id'):
        value=item.get(key)
        if isinstance(value,str) and value.startswith('04t'):
            ids.append(value)
            break
if expected not in ids:
    raise SystemExit(f'Expected package version {expected} is not installed. Installed 04t IDs: {ids}')
print(f'Confirmed installed package version: {expected}')
PY
fi

sf data query \
  --target-org "$SF_ALIAS" \
  --query "SELECT DeveloperName, Priority_Automation_Enabled__c FROM Case_Escalation_Config__mdt WHERE DeveloperName = 'Default'" \
  --json > "$CONFIG_JSON"

FEATURE_ENABLED=$(python - "$CONFIG_JSON" <<'PY'
import json, sys
payload=json.load(open(sys.argv[1], encoding='utf-8'))
records=((payload.get('result') or {}).get('records') or [])
if len(records) != 1:
    raise SystemExit(f'Expected one Case_Escalation_Config__mdt Default record, found {len(records)}')
print('true' if bool(records[0].get('Priority_Automation_Enabled__c')) else 'false')
PY
)

if [[ "$FEATURE_ENABLED" != "$EXPECTED_FEATURE_ENABLED" ]]; then
  echo "Feature flag mismatch: expected=${EXPECTED_FEATURE_ENABLED}, actual=${FEATURE_ENABLED}" >&2
  exit 1
fi

sf data create record \
  --target-org "$SF_ALIAS" \
  --sobject Case \
  --values "Subject='V4 post-deploy verification' Status='New' Origin='Web' Priority='Low' Escalation_Level__c='Critical'" \
  --json > "$CREATE_JSON"

CASE_ID=$(python - "$CREATE_JSON" <<'PY'
import json, sys
payload=json.load(open(sys.argv[1], encoding='utf-8'))
result=payload.get('result') or {}
value=result.get('id') or result.get('Id')
if not value:
    raise SystemExit('Synthetic Case creation did not return an ID.')
print(value)
PY
)

cleanup() {
  sf data delete record --target-org "$SF_ALIAS" --sobject Case --record-id "$CASE_ID" >/dev/null 2>&1 || true
}
trap cleanup EXIT

sf data query \
  --target-org "$SF_ALIAS" \
  --query "SELECT Id, Priority, Escalation_Level__c, Escalation_Source__c FROM Case WHERE Id = '${CASE_ID}'" \
  --json > "$QUERY_JSON"

python - "$QUERY_JSON" "$FEATURE_ENABLED" "$RESULT_JSON" "$EXPECTED_PACKAGE_VERSION_ID" <<'PY'
import json, sys, datetime
query_path, enabled_text, out_path, package_id = sys.argv[1:]
payload=json.load(open(query_path, encoding='utf-8'))
records=((payload.get('result') or {}).get('records') or [])
if len(records) != 1:
    raise SystemExit(f'Expected one synthetic Case, found {len(records)}')
r=records[0]
enabled=enabled_text.lower() == 'true'
expected_priority='High' if enabled else 'Low'
checks={
    'criticalLevel': r.get('Escalation_Level__c') == 'Critical',
    'priorityAutomation': r.get('Priority') == expected_priority,
    'flowAutomation': r.get('Escalation_Source__c') == 'Record-Triggered Flow',
}
summary={
    'timestampUtc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
    'packageVersionId': package_id or None,
    'featureEnabled': enabled,
    'expectedPriority': expected_priority,
    'observed': {
        'priority': r.get('Priority'),
        'escalationLevel': r.get('Escalation_Level__c'),
        'escalationSource': r.get('Escalation_Source__c'),
    },
    'checks': checks,
    'passed': all(checks.values()),
}
json.dump(summary, open(out_path,'w',encoding='utf-8'), indent=2)
print(json.dumps(summary, indent=2))
if not summary['passed']:
    raise SystemExit('Post-deployment verification failed.')
PY
