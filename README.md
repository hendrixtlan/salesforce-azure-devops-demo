# Salesforce DevOps with Azure DevOps

Portfolio project demonstrating a production-shaped Salesforce delivery lifecycle using **Salesforce DX**, **Salesforce CLI (`sf`)**, **Azure Repos**, **Azure Pipelines**, **Git**, **YAML**, JWT-based CI authentication, automated Apex testing, static analysis, environment promotion, production validation, and controlled deployment.

## Business feature

The repository includes a deliberately small Service Cloud-oriented feature so the project stays focused on DevOps. A custom Case field, `Escalation_Level__c`, drives a trigger/service that promotes Critical cases to High priority. Apex tests verify the behavior.

The feature is intentionally simple; the delivery lifecycle is the main artifact.

## Architecture

```text
Developer / Feature Branch
          |
          v
     Azure Repos
          |
          | Pull Request
          v
+---------------------------+
| PR Validation Pipeline    |
| - Node 22                 |
| - Salesforce CLI          |
| - Code Analyzer           |
| - JWT Authentication      |
| - Dry-run metadata deploy |
| - Apex tests              |
+-------------+-------------+
              |
              v
            main
              |
              v
       Integration Org
              |
              v
           UAT Org
              |
              v
   Production Validation
              |
        Manual Approval
              |
              v
  Salesforce Quick Deploy
```

## Repository layout

```text
force-app/                 Salesforce metadata in source format
config/                    Scratch org definition
manifest/                  Metadata manifest
scripts/                   Reusable CI shell scripts
pipelines/                 Azure Pipelines YAML
pipelines/templates/       Shared pipeline templates
docs/                      Azure DevOps and rollback runbooks
sfdx-project.json          Salesforce DX project definition
```

## Prerequisites

Local development:

- Node.js 22+
- Salesforce CLI
- A Salesforce Developer/Dev Hub org or sandbox for practice
- Git

CI/CD:

- Azure DevOps project with Azure Repos and Pipelines
- Salesforce deployment users for the target environments
- A Salesforce connected app configured for JWT bearer authentication
- Environment-specific JWT private keys stored as Azure DevOps Secure Files

## Local setup

Install Salesforce CLI:

```bash
npm install --global @salesforce/cli
sf version
```

Authenticate interactively for local development:

```bash
sf org login web --alias dev --set-default
```

Or, with a Dev Hub, create a scratch org:

```bash
sf org login web --alias devhub --set-default-dev-hub
sf org create scratch --definition-file config/project-scratch-def.json --alias dev --set-default --duration-days 7
```

Deploy the sample feature:

```bash
sf project deploy start --source-dir force-app --target-org dev --test-level RunLocalTests --wait 45
```

Run tests:

```bash
sf apex run test --target-org dev --test-level RunLocalTests --code-coverage --wait 20
```

Run static analysis:

```bash
sf plugins install @salesforce/plugin-code-analyzer
sf code-analyzer run --workspace . --target force-app --view table
```

## CI/CD flow

### 1. Pull request validation

`pipelines/pr-validation.yml`

The pipeline performs static analysis, authenticates to the Integration org, executes a dry-run deployment, and runs Apex tests. In Azure Repos, configure this pipeline as a required **Build Validation branch policy** on `main`.

### 2. Integration deployment

`pipelines/deploy-integration.yml`

A successful merge to `main` deploys the metadata to the Integration environment and runs local Apex tests.

### 3. UAT and Production release

`pipelines/release.yml`

The release pipeline:

1. Deploys to UAT.
2. Validates the same source against Production with `sf project deploy validate`.
3. Captures the validated deployment job ID.
4. Waits for the Azure DevOps Environment approval/check configured on `salesforce-production`.
5. Executes `sf project deploy quick` using the successful validation job.

## Authentication model

The pipeline uses JWT bearer authentication:

```text
Azure Pipeline
     |
     | client id + username + instance URL
     | protected private key (Secure File)
     v
Salesforce Connected App
     |
     v
Salesforce Deployment User
```

The private key never belongs in Git. Store it as an Azure DevOps Secure File and scope access to the required pipeline only.

## Azure DevOps configuration

See [`docs/azure-devops-setup.md`](docs/azure-devops-setup.md) for variable groups, Secure Files, environments, approvals, and branch-policy configuration.

## Rollback

See [`docs/rollback-strategy.md`](docs/rollback-strategy.md). The project treats rollback as a governed Git-driven deployment rather than an unreviewed emergency script.

## Branching model

For this portfolio project, keep the strategy intentionally simple:

```text
feature/* -> PR -> main -> Integration -> UAT -> Production
```

A larger organization may introduce `develop`, release branches, or package-based delivery. The important point is that protected branches, automated validation, approvals, and environment promotion are explicit and auditable.

## What this project demonstrates in an interview

- Salesforce source-driven development and Salesforce DX project structure.
- Modern Salesforce CLI usage rather than relying on legacy command names.
- Azure Repos branching, pull requests, and Build Validation.
- YAML-based CI/CD pipelines.
- Secure non-interactive authentication for CI.
- Salesforce deployment validation and Apex testing.
- Static-analysis quality gates.
- Environment promotion and production approvals.
- Validate-then-quick-deploy release strategy.
- Rollback planning and separation of metadata rollback from data remediation.

## Suggested next increments

- Delta deployment using Git diff / a Salesforce-aware delta tool.
- Dedicated package-based release model.
- LWC and Flow metadata to broaden validation scenarios.
- Test-result publishing into Azure DevOps.
- SonarQube or additional quality/security gates.
- Copado or Gearset comparison branch to show how a specialized Salesforce DevOps platform changes the workflow.
