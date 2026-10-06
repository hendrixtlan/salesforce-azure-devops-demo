# Salesforce DevOps with Azure DevOps — V3

Portfolio-grade Salesforce release-engineering project demonstrating Salesforce DX, Salesforce CLI (`sf`), Azure Repos/Pipelines, ephemeral scratch-org validation, Apex + Flow + LWC delivery, Salesforce Code Analyzer, JUnit/coverage publication, Salesforce-aware delta deployment, unlocked packages, immutable release promotion, JWT automation, environment approvals, and specialized-platform comparison.

## Architecture

```text
Feature branch / PR
        |
        +--> LWC Jest + coverage
        +--> Salesforce Code Analyzer
        +--> optional SonarQube
        +--> SGD delta report for unpackaged metadata
        +--> ephemeral scratch org
               |-- deploy package-owned source
               |-- deploy unpackaged source
               |-- Apex tests + coverage gate
               |-- seed synthetic Case
               |-- behavioral smoke test: Apex + Flow
               '-- always destroy org
        |
        v
      main
        |
        +--> build unlocked package version (04t...)
        +--> generate unpackaged delta
        |
        v
  Integration
        |  install SAME 04t + delta
        v
      UAT
        |  install SAME 04t + delta
        v
 promote package version
        |
        v
 Production approval
        |
        v
 Production
      install SAME released 04t + delta
```

## Ownership boundary

### `force-app/` — packaged application

The coherent feature is delivered as an unlocked package:

- `CaseEscalationService` + tests
- `CaseEscalationTrigger`
- `Case.Escalation_Level__c`
- `Case.Escalation_Source__c`
- `Case_Escalation_Audit` record-triggered Flow
- `caseEscalationPanel` LWC

### `unpackaged/` — org-specific metadata

The demo keeps `Case_DevOps_Demo` Permission Set outside the package. SFDX-Git-Delta is scoped **only** to this directory. A component is never deployed by both the unlocked package and SGD.

## Application behavior

A Critical Case exercises two automation models:

1. Apex trigger/service sets `Priority = High`.
2. Before-save Flow sets `Escalation_Source__c = Record-Triggered Flow`.

The LWC surfaces escalation level and priority and has local Jest tests.

## Repository layout

```text
force-app/                       package-owned Salesforce source
unpackaged/                      org-specific source eligible for delta deployment
config/                          scratch-org/package definition
manifest/                        full-source fallback manifest
scripts/
  delta/                         SGD generation + safe deployment fallback
  package/                       create/build/install/promote package versions
  quality/                       Salesforce Code Analyzer
  scratch-org/                   ephemeral environment lifecycle
  tests/                         LWC Jest execution
pipelines/
  pr-validation.yml              standard V3 PR quality pipeline
  pr-validation-sonarqube.yml    optional commercial SonarQube gate
  package-build.yml              standalone package build
  release-v3.yml                 build-once/promote-many release pipeline
  templates/                     reusable Azure Pipelines logic
docs/                            V2/V3 architecture and runbooks
comparisons/
  gearset/                       specialized-platform mapping
  copado/                        specialized-platform mapping
```

## Local developer validation

Install dependencies:

```bash
npm install
npm run test:unit:coverage
```

Authenticate and create a scratch org:

```bash
sf org login web --alias devhub --set-default-dev-hub
export DEV_HUB_ALIAS=devhub
export SCRATCH_ALIAS=local-v3
./scripts/scratch-org/create.sh
./scripts/scratch-org/deploy.sh
./scripts/scratch-org/run-tests.sh
./scripts/scratch-org/seed.sh
./scripts/scratch-org/smoke-test.sh
./scripts/scratch-org/destroy.sh
```

## Delta deployment

Install the community plugin:

```bash
sf plugins install sfdx-git-delta
```

Generate an unpackaged delta:

```bash
export DELTA_FROM_REF=origin/main
export DELTA_TO_REF=HEAD
./scripts/delta/generate.sh
```

Deploy it:

```bash
export SF_ALIAS=integration
./scripts/delta/deploy.sh
```

Fallback to full unpackaged deployment:

```bash
export DELTA_MODE=false
./scripts/delta/deploy.sh
```

## Unlocked-package lifecycle

Authenticate the Dev Hub, then:

```bash
export DEV_HUB_ALIAS=devhub
./scripts/package/find-or-create.sh
./scripts/package/build-version.sh
```

The build writes the immutable subscriber package version ID (`04t...`) to:

```text
artifacts/package/package-version-id.txt
```

Install that exact version in a sandbox:

```bash
export SF_ALIAS=integration
./scripts/package/install-version.sh
```

After UAT succeeds, promote it:

```bash
export DEV_HUB_ALIAS=devhub
./scripts/package/promote-version.sh
```

Production receives the same promoted `04t` artifact.

## Azure DevOps test evidence

V3 publishes:

- LWC Jest JUnit results
- LWC code coverage
- Apex JUnit results
- Apex test-run coverage gate
- Code Analyzer SARIF + HTML
- SGD manifests/change inventory
- package 0Ho/04t identifiers and release manifest
- installed-package evidence per environment
- scratch-org smoke-test evidence

## SonarQube

The default pipeline stays portable and uses Salesforce Code Analyzer. `pipelines/pr-validation-sonarqube.yml` demonstrates SonarQube Server integration with Azure DevOps tasks after the SonarQube extension/service connection is installed. See `docs/sonarqube.md`.

## Commercial Salesforce DevOps platforms

The native implementation is intentionally visible first. See:

- `comparisons/gearset/README.md`
- `comparisons/copado/README.md`
- `docs/platform-comparison.md`

These map the hand-built Salesforce/Azure DevOps mechanics to specialized Salesforce DevOps platforms without pretending the workflows are identical.

Primary implementation references are collected in `docs/official-references.md`.

## Suggested interview narrative

> I separated package-owned application metadata from org-specific metadata. Pull requests were validated in disposable scratch orgs across Apex, Flow, and LWC surfaces. After merge, the pipeline created one immutable unlocked-package version and promoted the same 04t artifact through Integration, UAT, and Production. Unpackaged metadata used Salesforce-aware delta deployment with a documented full-deploy fallback. Azure DevOps retained tests, quality results, delta manifests, package IDs, approvals, and deployment evidence for each release.
