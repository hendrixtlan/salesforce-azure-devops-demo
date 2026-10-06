#!/usr/bin/env bash
set -euo pipefail

mkdir -p artifacts/lwc-test-results artifacts/lwc-coverage
export JEST_JUNIT_OUTPUT_DIR="artifacts/lwc-test-results"
export JEST_JUNIT_OUTPUT_NAME="junit.xml"

npm run test:unit:ci -- --coverage
