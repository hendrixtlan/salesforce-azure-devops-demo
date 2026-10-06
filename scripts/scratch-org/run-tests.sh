#!/usr/bin/env bash
set -euo pipefail

SCRATCH_ALIAS="${SCRATCH_ALIAS:-ci-scratch}"
MIN_TEST_RUN_COVERAGE="${MIN_TEST_RUN_COVERAGE:-75}"
RESULT_DIR="${RESULT_DIR:-artifacts/test-results}"
JSON_RESULT="$RESULT_DIR/apex-test-results.json"
JUNIT_DIR="$RESULT_DIR/junit"

mkdir -p "$RESULT_DIR" "$JUNIT_DIR"

set +e
sf apex run test \
  --target-org "$SCRATCH_ALIAS" \
  --test-level RunLocalTests \
  --code-coverage \
  --wait 20 \
  --json > "$JSON_RESULT"
TEST_EXIT_CODE=$?
set -e

# Generate JUnit from the already-completed test run so Azure DevOps can render it.
TEST_RUN_ID=$(python - "$JSON_RESULT" <<'PY'
import json
import sys
with open(sys.argv[1], encoding="utf-8") as handle:
    payload = json.load(handle)
summary = ((payload.get("result") or {}).get("summary") or {})
print(summary.get("testRunId") or "")
PY
)

if [[ -n "$TEST_RUN_ID" ]]; then
  set +e
  sf apex get test \
    --target-org "$SCRATCH_ALIAS" \
    --test-run-id "$TEST_RUN_ID" \
    --code-coverage \
    --result-format junit \
    --output-dir "$JUNIT_DIR"
  JUNIT_EXIT_CODE=$?
  set -e
else
  JUNIT_EXIT_CODE=1
  echo "No Apex test run ID was returned; JUnit output cannot be generated." >&2
fi

set +e
python - "$JSON_RESULT" "$MIN_TEST_RUN_COVERAGE" <<'PY'
import json
import sys

path, minimum = sys.argv[1], float(sys.argv[2])
with open(path, encoding="utf-8") as handle:
    payload = json.load(handle)
summary = ((payload.get("result") or {}).get("summary") or {})
outcome = summary.get("outcome")
coverage_raw = summary.get("testRunCoverage")
if coverage_raw is None:
    raise SystemExit("Apex tests did not return testRunCoverage; failing the coverage gate.")
coverage = float(str(coverage_raw).rstrip("%"))
print(f"Apex outcome: {outcome}")
print(f"Test-run coverage: {coverage:.2f}% (minimum: {minimum:.2f}%)")
if outcome != "Passed":
    raise SystemExit("Apex test outcome was not Passed.")
if coverage < minimum:
    raise SystemExit(f"Test-run coverage {coverage:.2f}% is below required {minimum:.2f}%.")
PY
COVERAGE_EXIT_CODE=$?
set -e

if [[ $TEST_EXIT_CODE -ne 0 || $JUNIT_EXIT_CODE -ne 0 || $COVERAGE_EXIT_CODE -ne 0 ]]; then
  echo "Apex quality gate failed." >&2
  exit 1
fi

echo "Apex tests and coverage gate passed."
