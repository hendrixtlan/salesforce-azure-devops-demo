#!/usr/bin/env bash
set -euo pipefail

DEV_HUB_ALIAS="${DEV_HUB_ALIAS:-devhub}"
PACKAGE_NAME="${PACKAGE_NAME:-CaseEscalationCore}"
PACKAGE_PATH="${PACKAGE_PATH:-force-app}"
PACKAGE_OUTPUT_DIR="${PACKAGE_OUTPUT_DIR:-artifacts/package}"
PACKAGE_ID_FILE="$PACKAGE_OUTPUT_DIR/package-id.txt"
RELEASE_BRANCH="${RELEASE_BRANCH:-main}"
VERSION_NUMBER="${PACKAGE_VERSION_NUMBER:-1.0.0.NEXT}"
WAIT_MINUTES="${PACKAGE_CREATE_WAIT_MINUTES:-45}"
mkdir -p "$PACKAGE_OUTPUT_DIR"

if [[ ! -f "$PACKAGE_ID_FILE" ]]; then
  ./scripts/package/find-or-create.sh
fi
PACKAGE_ID=$(tr -d '\r\n' < "$PACKAGE_ID_FILE")
RESULT_JSON="$PACKAGE_OUTPUT_DIR/package-version-create.json"

sf package version create \
  --package "$PACKAGE_ID" \
  --path "$PACKAGE_PATH" \
  --definition-file config/project-scratch-def.json \
  --installation-key-bypass \
  --code-coverage \
  --branch "$RELEASE_BRANCH" \
  --version-number "$VERSION_NUMBER" \
  --wait "$WAIT_MINUTES" \
  --target-dev-hub "$DEV_HUB_ALIAS" \
  --json > "$RESULT_JSON"

VERSION_ID=$(python - "$RESULT_JSON" <<'PY'
import json, sys
with open(sys.argv[1], encoding='utf-8') as handle:
    payload = json.load(handle)
result = payload.get('result') or {}
keys = ('SubscriberPackageVersionId', 'subscriberPackageVersionId', 'Id', 'id')
for key in keys:
    value = result.get(key)
    if isinstance(value, str) and value.startswith('04t'):
        print(value)
        break
PY
)

if [[ -z "$VERSION_ID" || "$VERSION_ID" != 04t* ]]; then
  echo "Package version creation did not return a valid 04t ID." >&2
  cat "$RESULT_JSON" >&2
  exit 1
fi

printf '%s\n' "$VERSION_ID" > "$PACKAGE_OUTPUT_DIR/package-version-id.txt"
printf '{"packageName":"%s","packageId":"%s","subscriberPackageVersionId":"%s","branch":"%s"}\n' \
  "$PACKAGE_NAME" "$PACKAGE_ID" "$VERSION_ID" "$RELEASE_BRANCH" > "$PACKAGE_OUTPUT_DIR/release-manifest.json"

echo "Built immutable package version: $VERSION_ID"
