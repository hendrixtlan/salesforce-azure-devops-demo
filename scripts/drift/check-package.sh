#!/usr/bin/env bash
set -euo pipefail
SF_ALIAS="${SF_ALIAS:-production}"
EXPECTED="${EXPECTED_PACKAGE_VERSION_ID:-}"
OUT="${DRIFT_OUTPUT_DIR:-artifacts/drift/${SF_ALIAS}}"
mkdir -p "$OUT"
sf package installed list --target-org "$SF_ALIAS" --json > "$OUT/installed-packages.json"
if [[ -z "$EXPECTED" ]]; then
  echo "EXPECTED_PACKAGE_VERSION_ID is not set; package inventory captured without enforcing a desired 04t."
  exit 0
fi
python - "$OUT/installed-packages.json" "$EXPECTED" <<'PY'
import json, sys
items=(json.load(open(sys.argv[1],encoding='utf-8')).get('result') or [])
expected=sys.argv[2]
found=[]
for item in items:
    for key in ('SubscriberPackageVersionId','subscriberPackageVersionId','Id','id'):
        value=item.get(key)
        if isinstance(value,str) and value.startswith('04t'):
            found.append(value); break
if expected not in found:
    raise SystemExit(f'Package drift: expected {expected}; installed 04t IDs: {found}')
print(f'Package state matches desired version {expected}.')
PY
