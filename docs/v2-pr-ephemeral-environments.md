# V2 - Ephemeral PR environments

## Goal

Every pull request is validated in a fresh Salesforce scratch org instead of sharing a long-lived Integration sandbox. This makes PR validation isolated, reproducible, source-driven, and disposable.

## Flow

```text
Feature branch
    |
    v
Pull request
    |
    +--> Install Salesforce CLI + Code Analyzer
    |
    +--> Static analysis quality gate
    |
    +--> Authenticate Dev Hub (JWT)
    |
    +--> Create scratch org (1-day lifetime)
    |
    +--> Deploy force-app metadata
    |
    +--> Assign permission set
    |
    +--> Run Apex tests + coverage gate
    |
    +--> Publish JUnit test results
    |
    +--> Seed synthetic Case data
    |
    +--> Behavioral smoke test
    |
    +--> Publish evidence
    |
    +--> Destroy scratch org (always)
    v
PR can merge only when validation succeeds
```

## Why this is stronger than V1

V1 validated proposed metadata against a shared sandbox. V2 creates a fresh environment from the repository's scratch-org definition for each PR run. A failed or partially configured previous deployment therefore cannot silently make the next PR pass.

The scratch org contains no sample business data by default. The pipeline explicitly creates synthetic data after deployment, which keeps tests deterministic and prevents personal or production data from entering CI.

## Quality gates

### Static analysis

`scripts/quality/static-analysis.sh` runs Salesforce Code Analyzer using Recommended rules and fails the build at the configured `High` severity threshold. It emits SARIF and HTML reports as pipeline evidence.

### Apex tests

`scripts/scratch-org/run-tests.sh` runs local Apex tests with code coverage. The default project-specific gate requires at least 75% **test-run coverage**. This is a CI quality gate for this repository; it is not a substitute for evaluating Salesforce's production deployment coverage rules and org-wide coverage.

The script writes JSON evidence and converts the completed run to JUnit so Azure DevOps can render test results natively.

### Behavioral smoke test

The pipeline creates one synthetic Critical Case. The repository trigger must change that record's Priority to High. The smoke test queries the saved record and fails if the business behavior is not present.

This catches a class of errors that a compilation-only deployment check would miss.

## Cleanup behavior

Scratch-org destruction uses an Azure Pipelines `always()` condition. The cleanup script is also idempotent: if the alias was never created or no longer exists locally, it exits successfully.

An interrupted build can still leave an active scratch org in exceptional circumstances. The team should periodically inspect active scratch orgs in the Dev Hub and remove abandoned CI environments.

## Required Azure DevOps configuration

Create a variable group named `salesforce-devhub` with:

- `SF_CLIENT_ID`
- `SF_USERNAME`
- `SF_INSTANCE_URL`

Upload `salesforce-devhub-jwt.key` under Pipeline Library > Secure files and authorize the PR validation pipeline to use it.

The Salesforce user represented by `SF_USERNAME` must be able to use the Dev Hub and create scratch orgs.

## Branch policy

Create the YAML pipeline from `pipelines/pr-validation.yml` and attach it to `main` as a required Azure Repos Build Validation policy. The YAML intentionally keeps `trigger` and `pr` set to `none`; Azure Repos PR execution is driven by the branch policy.

## What to explain in an interview

The key design point is environment isolation. Each proposed change is evaluated from source in a fresh org, then the org is destroyed. Static analysis runs before org creation to fail fast and conserve scratch-org allocations. Unit-test evidence, static-analysis output, seed information, and smoke-test query results are retained as pipeline artifacts for traceability.
