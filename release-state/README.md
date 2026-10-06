# Release state

Production desired state is intentionally split:

- Git owns application source and governed unpackaged metadata.
- The release artifact owns the immutable unlocked-package version (`04t...`).
- Azure DevOps operational variables can own runtime expectations such as `EXPECTED_PACKAGE_VERSION_ID` and `EXPECTED_FEATURE_ENABLED` for scheduled drift checks.

Do not commit credentials or access tokens here. A mature implementation can update desired-state pointers through an approved PR after each Production release, or store them in a governed release registry.
