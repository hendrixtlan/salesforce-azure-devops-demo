#!/usr/bin/env bash
set -euo pipefail
SF_ALIAS="${SF_ALIAS:-integration}"
PACKAGE_VERSION_ID="${PACKAGE_VERSION_ID:-}"
if [[ -z "$PACKAGE_VERSION_ID" ]]; then
  echo "PACKAGE_VERSION_ID (04t...) is required after a sandbox refresh." >&2
  exit 2
fi
export PACKAGE_VERSION_ID SF_ALIAS
./scripts/package/install-version.sh
sf project deploy start --source-dir unpackaged --target-org "$SF_ALIAS" --wait 45
sf org assign permset --name Case_DevOps_Demo --target-org "$SF_ALIAS"
FEATURE_STATE="${FEATURE_STATE:-enabled}" ./scripts/feature-flags/set.sh "$FEATURE_STATE"
EXPECTED_PACKAGE_VERSION_ID="$PACKAGE_VERSION_ID" EXPECTED_FEATURE_ENABLED="$([[ "$FEATURE_STATE" == enabled ]] && echo true || echo false)" ./scripts/verify/post-deploy.sh
