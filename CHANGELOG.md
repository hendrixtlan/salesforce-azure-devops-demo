# Changelog

## 3.0.0 - Hybrid Salesforce release engineering

- Added unlocked-package release model for `force-app` with build-once/promote-many semantics.
- Added Salesforce-aware delta generation/deployment with SFDX-Git-Delta for `unpackaged` metadata only.
- Added explicit full-deployment fallback with `DELTA_MODE=false`.
- Added Lightning Web Component metadata plus Jest unit tests, JUnit publication, and code-coverage publication.
- Added record-triggered Flow metadata and extended behavioral smoke testing to validate Flow + Apex interaction.
- Expanded Azure DevOps PR validation with full Git history, delta review evidence, and multi-surface test publishing.
- Added optional SonarQube Azure DevOps template/pipeline without making the core pipeline depend on the commercial extension.
- Added a unified V3 package release pipeline: Build -> Integration -> UAT -> Promote -> Production.
- Added package release evidence and installed-package capture.
- Added Gearset and Copado comparison blueprints.

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
