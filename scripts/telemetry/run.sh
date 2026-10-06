#!/usr/bin/env bash
set -uo pipefail
if [[ "$#" -lt 2 ]]; then
  echo "Usage: $0 <step-name> <command> [args...]" >&2
  exit 2
fi
STEP="$1"; shift
OUT="${TELEMETRY_FILE:-artifacts/telemetry/events.jsonl}"
mkdir -p "$(dirname "$OUT")"
START_EPOCH=$(date +%s)
START_ISO=$(date -u +%Y-%m-%dT%H:%M:%SZ)
set +e
"$@"
STATUS=$?
set -e
END_EPOCH=$(date +%s)
END_ISO=$(date -u +%Y-%m-%dT%H:%M:%SZ)
DURATION=$((END_EPOCH-START_EPOCH))
python - "$OUT" "$STEP" "$START_ISO" "$END_ISO" "$DURATION" "$STATUS" "${SF_ALIAS:-}" "${RELEASE_ID:-}" <<'PY'
import json, sys
path, step, start, end, duration, status, alias, release=sys.argv[1:]
event={'step':step,'startUtc':start,'endUtc':end,'durationSeconds':int(duration),'exitCode':int(status),'status':'passed' if status=='0' else 'failed','targetOrgAlias':alias or None,'releaseId':release or None}
with open(path,'a',encoding='utf-8') as f: f.write(json.dumps(event,separators=(',',':'))+'\n')
PY
exit "$STATUS"
