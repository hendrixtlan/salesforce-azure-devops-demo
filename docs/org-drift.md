# Production org drift detection

`pipelines/org-drift.yml` runs daily and performs three checks.

1. `scripts/drift/check.sh` compares governed unpackaged metadata in Git with Production.
2. `scripts/drift/check-package.sh` records installed package versions and enforces `EXPECTED_PACKAGE_VERSION_ID` when configured.
3. `scripts/drift/check-feature-state.sh` records the operational feature flag and enforces `EXPECTED_FEATURE_ENABLED` when configured.

The pipeline always publishes `artifacts/drift` so a failed drift gate leaves evidence.
