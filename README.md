# Salesforce DevOps with Azure DevOps

Portfolio-grade Salesforce DevOps project demonstrating **Salesforce DX**, **Salesforce CLI (`sf`)**, **Azure Repos**, **Azure Pipelines**, Git/YAML delivery controls, disposable scratch-org validation, Apex testing, Salesforce Code Analyzer, JWT-based automation, environment promotion, production validation, and controlled deployment.

## Current version: V2 - Ephemeral PR environments

V1 validated pull requests against a shared Integration sandbox. V2 isolates every PR in a newly created Salesforce scratch org, deploys the proposed metadata, runs unit and behavioral tests, publishes evidence, and destroys the org at the end of the run.

```text
Feature branch
      |
      v
Pull Request
      |
      +--> Salesforce Code Analyzer
      |
      +--> Authenticate Dev Hub
      |
      +--> Create ephemeral scratch org
      |
      +--> Deploy repository metadata
      |
      +--> Assign permission set
      |
      +--> Apex tests + coverage gate
      |
      +--> Publish JUnit results
      |
      +--> Seed synthetic Case
      |
      +--> Behavioral smoke test
      |
      +--> Publish pipeline evidence
      |
      +--> Destroy scratch org (always)
      v
Merge to main
      |
      v
Integration -> UAT -> Production validation -> Approval -> Quick Deploy
```

## Business feature

The repository intentionally keeps the Salesforce application small so the DevOps lifecycle remains the primary artifact.

A custom Case field, `Escalation_Level__c`, supports three values:

- Standard
- Priority
- Critical

`CaseEscalationTrigger` delegates to `CaseEscalationService`. A Critical Case is automatically promoted to Salesforce Priority `High`. Apex tests verify the behavior, and V2 adds an integration smoke test that creates an actual Case in the scratch org and queries it back to verify that the trigger executed correctly.

## Repository layout

```text
force-app/                         Salesforce metadata in source format
config/                            Scratch-org definition
manifest/                          Metadata deployment manifest
scripts/
  auth-jwt.sh                      Non-interactive Salesforce authentication
  scratch-org/
    create.sh                      Provision isolated PR environment
    deploy.sh                      Deploy metadata + assign permission set
    run-tests.sh                   Apex + test-run coverage quality gate
    seed.sh                        Create synthetic test data
    smoke-test.sh                  Verify persisted business behavior
    destroy.sh                     Idempotent cleanup
  quality/
    static-analysis.sh             Salesforce Code Analyzer gate
pipelines/
  pr-validation.yml               V2 PR pipeline
  deploy-integration.yml           Main -> Integration deployment
  release.yml                      UAT + Production validate/quick-deploy
  templates/                       Reusable Azure Pipeline templates
docs/
  azure-devops-setup.md            CI/CD configuration runbook
  v2-pr-ephemeral-environments.md  V2 architecture and operating model
  rollback-strategy.md             Metadata/data rollback guidance
CHANGELOG.md                       Version history
sfdx-project.json                  Salesforce DX project definition
```

## V2 quality gates

### 1. Static analysis

Salesforce Code Analyzer executes before a scratch org is created. This is deliberate: a code-quality failure should not consume a Dev Hub scratch-org allocation.

The gate uses Recommended rules and fails on violations meeting the configured `High` threshold. It also generates:

```text
artifacts/code-analyzer/results.sarif
artifacts/code-analyzer/results.html
```

Both files are published as pipeline evidence.

### 2. Isolated metadata deployment

After authenticating the Dev Hub, the PR pipeline creates an org with a one-day lifetime:

```bash
sf org create scratch \
  --definition-file config/project-scratch-def.json \
  --alias <pipeline-generated-alias> \
  --target-dev-hub devhub \
  --duration-days 1
```

The complete `force-app` source is then deployed into the clean environment.

### 3. Apex test + coverage gate

Apex tests execute in the scratch org and produce JSON evidence plus JUnit output for Azure DevOps test reporting.

The repository sets:

```text
MIN_TEST_RUN_COVERAGE=75
```

This is a **repository CI test-run coverage threshold**. It should not be confused with all Salesforce production-deployment and org-wide coverage rules.

### 4. Synthetic integration data

CI never copies production/customer data. `seed.sh` creates a synthetic Critical Case after the source has been deployed.

### 5. Behavioral smoke test

The smoke test queries that Case and asserts:

```text
Escalation_Level__c = Critical
Priority             = High
```

This verifies that the deployed trigger/service works against persisted Salesforce data, rather than only compiling successfully.

### 6. Unconditional cleanup

Scratch-org deletion is configured with Azure Pipelines `condition: always()` so cleanup is attempted even after a validation failure.

## Prerequisites

### Local

- Node.js 22+
- Salesforce CLI
- Git
- Salesforce Dev Hub for scratch-org development

### Azure DevOps

- Azure DevOps project with Azure Repos and Azure Pipelines
- Variable group `salesforce-devhub`
- Variable groups for Integration, UAT, and Production
- Salesforce connected app / OAuth client configured for JWT authentication
- JWT private keys stored as Azure DevOps Secure Files
- Salesforce deployment users for long-lived environments

See [`docs/azure-devops-setup.md`](docs/azure-devops-setup.md).

## Local V2 walkthrough

Authenticate a Dev Hub:

```bash
sf org login web --alias devhub --set-default-dev-hub
```

Create an ephemeral scratch org:

```bash
export DEV_HUB_ALIAS=devhub
export SCRATCH_ALIAS=local-pr-demo
./scripts/scratch-org/create.sh
```

Deploy the repository:

```bash
./scripts/scratch-org/deploy.sh
```

Run Apex tests and the coverage gate:

```bash
export MIN_TEST_RUN_COVERAGE=75
./scripts/scratch-org/run-tests.sh
```

Seed data and execute the behavioral test:

```bash
./scripts/scratch-org/seed.sh
./scripts/scratch-org/smoke-test.sh
```

Destroy the environment:

```bash
./scripts/scratch-org/destroy.sh
```

Run static analysis separately:

```bash
sf plugins install @salesforce/plugin-code-analyzer
./scripts/quality/static-analysis.sh
```

## Azure DevOps delivery flow

### Pull requests

`pipelines/pr-validation.yml` is attached to `main` as an Azure Repos **Build Validation** branch policy.

The YAML intentionally contains:

```yaml
trigger: none
pr: none
```

Azure Repos invokes it through branch policy rather than a YAML PR trigger.

### Merge to main

`pipelines/deploy-integration.yml` deploys to the long-lived Integration org after a successful merge.

### UAT and Production

`pipelines/release.yml`:

1. Deploys to UAT.
2. Validates the same source against Production.
3. Stores the successful validation deployment ID.
4. Waits for the Azure DevOps `salesforce-production` environment approval.
5. Performs `sf project deploy quick` using the validated job.

## Authentication model

```text
Azure Pipeline
      |
      | OAuth client ID
      | Salesforce username
      | instance URL
      | protected JWT private key
      v
Salesforce Connected App
      |
      +--> Dev Hub user       -> creates scratch orgs
      +--> Integration user   -> deploys main
      +--> UAT user           -> deploys release candidate
      +--> Production user    -> validates / deploys release
```

Private keys are never committed to Git.

## Pipeline evidence

A V2 PR run can retain:

- Code Analyzer SARIF and HTML reports.
- Sanitized scratch-org identity metadata (no access tokens).
- Apex test JSON.
- JUnit test files rendered by Azure DevOps.
- Seeded record ID/summary.
- Smoke-test query result.

This gives a reviewer both a pass/fail signal and auditable technical evidence of what was validated.

## Rollback

See [`docs/rollback-strategy.md`](docs/rollback-strategy.md). Metadata rollback is Git-driven and reviewed. Data remediation is treated as a separate concern because reverting Salesforce metadata does not automatically reverse records changed by Apex, Flow, integrations, or migration jobs.

## What V2 demonstrates in an interview

A candidate can now explain that the pipeline:

- Treats Git as the source of truth.
- Uses source-driven Salesforce DX development.
- Authenticates non-interactively through JWT.
- Uses a Dev Hub to create an isolated Salesforce environment for each PR.
- Fails fast on static-analysis violations.
- Deploys metadata into a clean environment.
- Executes Apex unit tests with a project-specific coverage quality gate.
- Publishes test and analysis evidence to Azure DevOps.
- Creates synthetic integration data rather than copying production data.
- Runs an end-to-end behavioral smoke test.
- Cleans up ephemeral infrastructure even on failure.
- Promotes merged code through Integration, UAT, and controlled Production deployment.

## Next enterprise increment (V3)

The logical next version is **artifact-based Salesforce release engineering**:

```text
PR scratch-org validation
        |
        v
merge to main
        |
        v
create unlocked package version
        |
        v
promote the same immutable package
        |
Integration -> UAT -> Production
```

V3 would add second-generation unlocked packages, versioning, package dependency management, release manifests, deployment metrics, and stronger rollback/version promotion controls.
