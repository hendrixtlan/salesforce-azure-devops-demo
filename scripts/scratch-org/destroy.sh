#!/usr/bin/env bash
set -u

SCRATCH_ALIAS="${SCRATCH_ALIAS:-ci-scratch}"

echo "Cleaning up scratch org ${SCRATCH_ALIAS}..."
if sf org display --target-org "$SCRATCH_ALIAS" --json >/dev/null 2>&1; then
  sf org delete scratch \
    --target-org "$SCRATCH_ALIAS" \
    --no-prompt || {
      echo "WARNING: scratch org cleanup failed; inspect Dev Hub active scratch orgs." >&2
      exit 0
    }
  echo "Scratch org deleted."
else
  echo "Scratch org alias is not locally authenticated; nothing to delete."
fi
