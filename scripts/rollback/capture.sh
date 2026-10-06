#!/usr/bin/env bash
set -euo pipefail
SF_ALIAS="${SF_ALIAS:-production}"
MANIFEST="${ROLLBACK_MANIFEST:-manifest/rollback-unpackaged.xml}"
RELEASE_ID="${RELEASE_ID:-manual-$(date -u +%Y%m%dT%H%M%SZ)}"
OUT="${ROLLBACK_OUTPUT_DIR:-artifacts/rollback/${RELEASE_ID}}"
mkdir -p "$OUT/metadata"

sf package installed list --target-org "$SF_ALIAS" --json > "$OUT/installed-packages-before.json"
sf project retrieve start \
  --manifest "$MANIFEST" \
  --target-org "$SF_ALIAS" \
  --target-metadata-dir "$OUT/metadata" \
  --unzip \
  --wait 30 \
  --json > "$OUT/retrieve-before.json"

python - "$OUT" "$SF_ALIAS" "$RELEASE_ID" "${BUILD_SOURCEVERSION:-$(git rev-parse HEAD 2>/dev/null || echo unknown)}" <<'PY'
import datetime, json, sys
from pathlib import Path
out=Path(sys.argv[1]); alias=sys.argv[2]; release=sys.argv[3]; sha=sys.argv[4]
payload=json.load(open(out/'installed-packages-before.json',encoding='utf-8'))
packages=[]
for item in payload.get('result') or []:
    version=None
    for key in ('SubscriberPackageVersionId','subscriberPackageVersionId','Id','id'):
        v=item.get(key)
        if isinstance(v,str) and v.startswith('04t'):
            version=v; break
    name=item.get('SubscriberPackageName') or item.get('subscriberPackageName') or item.get('Name') or item.get('name')
    if version:
        packages.append({'name':name,'subscriberPackageVersionId':version})
manifest={
  'releaseId':release,
  'capturedAtUtc':datetime.datetime.now(datetime.timezone.utc).isoformat(),
  'targetOrgAlias':alias,
  'gitCommit':sha,
  'installedPackagesBefore':packages,
  'unpackagedSnapshot':'metadata/',
  'packageRecoveryPolicy':'roll-forward; package downgrades are not automated',
}
json.dump(manifest, open(out/'rollback-manifest.json','w',encoding='utf-8'), indent=2)
print(json.dumps(manifest,indent=2))
PY

echo "$OUT" > artifacts/rollback/latest-path.txt
