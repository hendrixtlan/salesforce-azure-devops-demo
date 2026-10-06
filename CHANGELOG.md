# Changelog

## V4 — Enterprise release operations

- Added release-train pipeline for `release/*` and `hotfix/*` branches.
- Added Custom Metadata feature control to separate Production deployment from activation.
- Added independent Production feature activation/deactivation pipeline.
- Added post-deployment synthetic verification for package state, feature state, Apex behavior and Flow behavior.
- Added scheduled org-drift pipeline with Git-owned metadata, installed-package and operational-state checks.
- Added pre-deployment Production recovery capture and guarded unpackaged restore.
- Explicitly adopted package roll-forward rather than blind unlocked-package downgrade automation.
- Added JSONL/CSV release telemetry and final release evidence manifest generation.
- Added sandbox refresh/bootstrap pipeline and runbook.
- Added release-train branching conventions and last-Production-ref delta guidance.
- Preserved V3 unlocked packages, SGD delta delivery, LWC/Flow validation, Apex/Jest test publishing, Code Analyzer, optional SonarQube, and Gearset/Copado comparison material.

## V3 — Release engineering

- Added package/unpackaged ownership boundary.
- Added unlocked-package build-once/promote-many release model.
- Added Salesforce-aware SFDX-Git-Delta deployment for unpackaged metadata.
- Added LWC + Jest and record-triggered Flow validation surfaces.
- Added richer Azure DevOps test/coverage evidence and optional SonarQube pipeline.
- Added Gearset and Copado comparison documentation.

## V2 — Ephemeral PR validation

- Added scratch org per pull request.
- Added Apex coverage gate, synthetic test data and behavioral smoke validation.
- Added JUnit publishing and pipeline evidence.
- Added unconditional scratch-org cleanup.
