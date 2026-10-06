#!/usr/bin/env bash
set -euo pipefail

SCRATCH_ALIAS="${SCRATCH_ALIAS:-ci-scratch}"

echo "Deploying packaged application source to ${SCRATCH_ALIAS}..."
sf project deploy start \
  --source-dir force-app \
  --target-org "$SCRATCH_ALIAS" \
  --wait 30

echo "Deploying unpackaged/org-specific metadata..."
sf project deploy start \
  --source-dir unpackaged \
  --target-org "$SCRATCH_ALIAS" \
  --wait 30

echo "Assigning application permission set..."
sf org assign permset \
  --name Case_DevOps_Demo \
  --target-org "$SCRATCH_ALIAS"
