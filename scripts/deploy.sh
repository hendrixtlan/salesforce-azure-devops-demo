#!/usr/bin/env bash
set -euo pipefail
SF_ALIAS="${SF_ALIAS:-target-org}"

sf project deploy start \
  --source-dir force-app \
  --source-dir unpackaged \
  --target-org "$SF_ALIAS" \
  --test-level RunLocalTests \
  --wait 45
