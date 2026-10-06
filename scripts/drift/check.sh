#!/usr/bin/env bash
set -euo pipefail

SF_ALIAS="${SF_ALIAS:-production}"
MANIFEST="${DRIFT_MANIFEST:-manifest/drift-unpackaged.xml}"
OUT="${DRIFT_OUTPUT_DIR:-artifacts/drift/${SF_ALIAS}}"
EXPECTED="$OUT/expected-mdapi"
ACTUAL="$OUT/actual-mdapi"
REPORT_JSON="$OUT/drift-report.json"
REPORT_MD="$OUT/drift-report.md"

rm -rf "$OUT"
mkdir -p "$EXPECTED" "$ACTUAL"

echo "Converting Git-owned unpackaged source to Metadata API format."
sf project convert source --manifest "$MANIFEST" --output-dir "$EXPECTED" >/dev/null

echo "Retrieving the governed metadata surface from ${SF_ALIAS}."
sf project retrieve start \
  --manifest "$MANIFEST" \
  --target-org "$SF_ALIAS" \
  --target-metadata-dir "$ACTUAL" \
  --unzip \
  --wait 30 \
  --json > "$OUT/retrieve.json"

set +e
python - "$EXPECTED" "$ACTUAL" "$REPORT_JSON" "$REPORT_MD" <<'PY'
import datetime, hashlib, json, os, sys
from pathlib import Path
import xml.etree.ElementTree as ET

expected_dir, actual_dir, report_json, report_md = map(Path, sys.argv[1:])

def package_root(base: Path) -> Path:
    candidates = sorted(base.rglob('package.xml'), key=lambda p: (len(p.parts), str(p)))
    if not candidates:
        raise SystemExit(f'No package.xml found under {base}')
    return candidates[0].parent

def normalized_bytes(path: Path) -> bytes:
    raw = path.read_text(encoding='utf-8')
    if path.suffix.lower() in {'.xml', '.md'} or path.name.endswith(('.permissionset', '.object', '.field', '.flow')):
        try:
            return ET.canonicalize(raw, strip_text=True).encode('utf-8')
        except Exception:
            pass
    return raw.replace('\r\n','\n').strip().encode('utf-8')

def inventory(root: Path):
    result={}
    for p in sorted(root.rglob('*')):
        if not p.is_file() or p.name == 'package.xml':
            continue
        rel=p.relative_to(root).as_posix()
        data=normalized_bytes(p)
        result[rel]={
            'sha256': hashlib.sha256(data).hexdigest(),
            'size': len(data),
        }
    return result

exp_root=package_root(expected_dir)
act_root=package_root(actual_dir)
expected=inventory(exp_root)
actual=inventory(act_root)
all_paths=sorted(set(expected) | set(actual))
added=[p for p in all_paths if p not in expected]
missing=[p for p in all_paths if p not in actual]
changed=[p for p in all_paths if p in expected and p in actual and expected[p]['sha256'] != actual[p]['sha256']]
passed=not (added or missing or changed)
report={
    'timestampUtc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
    'expectedRoot': str(exp_root),
    'actualRoot': str(act_root),
    'scope': 'unpackaged governed metadata',
    'addedInOrg': added,
    'missingFromOrg': missing,
    'changedInOrg': changed,
    'passed': passed,
}
Path(report_json).write_text(json.dumps(report, indent=2), encoding='utf-8')
lines=['# Salesforce org drift report','',f"Result: **{'PASS' if passed else 'DRIFT DETECTED'}**",'',
       f"- Added in org: {len(added)}",f"- Missing from org: {len(missing)}",f"- Changed in org: {len(changed)}",'']
for title, values in [('Added in org', added), ('Missing from org', missing), ('Changed in org', changed)]:
    if values:
        lines += [f'## {title}', ''] + [f'- `{v}`' for v in values] + ['']
Path(report_md).write_text('\n'.join(lines), encoding='utf-8')
print('\n'.join(lines))
sys.exit(0 if passed else 2)
PY
STATUS=$?
set -e

if [[ "$STATUS" -eq 2 ]]; then
  echo "Salesforce org drift detected. See ${REPORT_MD}." >&2
  exit 2
elif [[ "$STATUS" -ne 0 ]]; then
  echo "Drift comparison failed unexpectedly." >&2
  exit "$STATUS"
fi

echo "No governed metadata drift detected."
