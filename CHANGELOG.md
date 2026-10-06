# Changelog

## 2.0.0 - Ephemeral PR validation

- Replaced shared-sandbox PR validation with one scratch org per pipeline run.
- Added Dev Hub JWT authentication for CI scratch-org provisioning.
- Added fail-fast Salesforce Code Analyzer quality gate with SARIF and HTML evidence.
- Added Apex test execution with JUnit publication and configurable test-run coverage gate.
- Added synthetic Case test-data seeding.
- Added behavioral smoke test that validates trigger behavior against persisted Salesforce data.
- Added unconditional scratch-org cleanup and PR validation artifact publication.
- Added V2 architecture/runbook documentation.

## 1.0.0 - Baseline CI/CD

- Salesforce DX source project.
- Azure Repos PR validation against a shared sandbox.
- Integration, UAT, and Production promotion.
- JWT authentication, static analysis, Apex testing, production validation, approval, and quick deploy.
