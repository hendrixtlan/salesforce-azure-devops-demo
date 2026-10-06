# Salesforce DevOps with Azure DevOps — V4

Portfolio-grade Salesforce release-engineering project demonstrating Salesforce DX, Salesforce CLI (`sf`), Azure Repos/Pipelines, ephemeral scratch-org validation, Apex + Flow + LWC delivery, Code Analyzer, optional SonarQube, Salesforce-aware delta deployment, unlocked packages, immutable promotion, controlled feature activation, production drift detection, recovery capture, post-deployment verification, release telemetry, and Salesforce DevOps platform comparisons.

## V4 operating model

```text
feature/*
   |
   v
Pull Request
   |-- LWC Jest + coverage
   |-- Salesforce Code Analyzer
   |-- optional SonarQube
   |-- SGD change analysis
   '-- ephemeral scratch org
          |-- deploy source
          |-- Apex tests
          |-- synthetic data
          '-- behavioral verification
   |
   v
main
   |
   +---------------------- release/* or hotfix/* ---------------------+
                                                                      |
                                                                      v
                                                               Build candidate
                                                          04t package + delta
                                                                      |
                                                      +---------------+---------------+
                                                      |                               |
                                                      v                               v
                                                Integration                         UAT
                                               feature ON                        feature ON
                                                verify OK                         verify OK
                                                      \                               /
                                                       +-------------+---------------+
                                                                     v
                                                            promote same 04t
                                                                     |
                                                                     v
                                                        capture Production state
                                                                     |
                                                                     v
                                                             Production deploy
                                                              feature OFF
                                                                     |
                                                             post-deploy verify
                                                                     |
                                                    release manifest + telemetry
                                                                     |
                                                                     v
                                                        separate approved activation
                                                              feature ON
```

## Key design decisions

### Package-owned vs org-owned metadata

`force-app/` contains the coherent application and is released as an unlocked package. `unpackaged/` contains org-specific metadata and runtime configuration. SFDX-Git-Delta is scoped only to the unpackaged boundary; the same component is never delivered by both mechanisms.

### Deployment is not activation

V4 adds `Case_Escalation_Config__mdt.Priority_Automation_Enabled__c`. The Custom Metadata **type** is package-owned; the `Default` record is operational configuration outside the package. Production deployment explicitly leaves the priority automation disabled. `pipelines/activate-feature.yml` changes the state later through a separately governable Azure DevOps Environment.

### Recovery favors safe roll-forward

Before Production deployment, `scripts/rollback/capture.sh` records installed packages and retrieves governed unpackaged metadata. `restore-unpackaged.sh` can restore that metadata only when `ALLOW_ROLLBACK=true`. Package-owned code is not blindly downgraded; mitigation is feature disablement followed by a corrective package version.

### Drift is ownership-aware

`pipelines/org-drift.yml` runs a scheduled Production check:

- Git-owned unpackaged metadata is retrieved and compared with the same Git manifest after conversion to Metadata API format.
- Installed package state is recorded and can enforce `EXPECTED_PACKAGE_VERSION_ID`.
- Runtime feature state is queried independently and can enforce `EXPECTED_FEATURE_ENABLED`.

This prevents an intentional feature activation from being confused with unauthorized source drift.

## Repository layout

```text
force-app/                     unlocked-package application
unpackaged/                    org-specific metadata + default runtime config
ops/feature-flags/             explicit enabled/disabled operational states
manifest/                      full, drift and rollback manifests
scripts/
  delta/                       Salesforce-aware delta generation/deploy
  package/                     package create/build/install/promote
  scratch-org/                 ephemeral PR environments
  quality/                     Salesforce Code Analyzer
  tests/                       LWC Jest
  drift/                       Production drift controls
  rollback/                    pre-deploy snapshot + unpackaged restore
  feature-flags/               controlled runtime activation
  verify/                      synthetic post-deployment checks
  telemetry/                   release event telemetry
  release/                     evidence manifest generation
  environment/                 sandbox rebuild/bootstrap
pipelines/
  pr-validation.yml            V3/V4 PR validation
  pr-validation-sonarqube.yml  optional SonarQube overlay
  release-v4.yml               release-train pipeline
  org-drift.yml                scheduled Production drift detection
  activate-feature.yml         separate Production activation/deactivation
  sandbox-bootstrap.yml        post-refresh Integration bootstrap
  legacy-v2/                   earlier implementation retained for learning
comparisons/                   Gearset/Copado workflow mapping
```

## Release workflow

Create a release branch such as:

```bash
git checkout -b release/2026.10.1
```

Run `pipelines/release-v4.yml`. For a real release train, set `deltaFromRef` to the Git tag or commit corresponding to the last Production release, for example `prod-2026.09.3`. `HEAD~1` exists only as a demo fallback.

The pipeline builds one subscriber package version (`04t...`), deploys that same artifact to Integration and UAT, promotes it, captures Production recovery state, deploys Production with the feature disabled, runs synthetic verification, and publishes the release evidence bundle.

## Controlled activation

After Production deployment and review:

```text
Azure DevOps Environment approval
        |
        v
pipelines/activate-feature.yml
        |
        +--> deploy Custom Metadata state
        +--> query actual state
        +--> create synthetic Critical Case
        +--> verify Apex + Flow behavior
        '--> remove synthetic record
```

Locally, the same control is:

```bash
export SF_ALIAS=production
FEATURE_STATE=enabled ./scripts/feature-flags/set.sh
EXPECTED_FEATURE_ENABLED=true ./scripts/verify/post-deploy.sh
```

## Drift detection

```bash
export SF_ALIAS=production
./scripts/drift/check.sh

# Optional desired-state enforcement
export EXPECTED_PACKAGE_VERSION_ID=04t...
./scripts/drift/check-package.sh

export EXPECTED_FEATURE_ENABLED=true
./scripts/drift/check-feature-state.sh
```

Drift evidence is written under `artifacts/drift/`.

## Recovery snapshot

```bash
export SF_ALIAS=production
export RELEASE_ID=2026.10.1
./scripts/rollback/capture.sh
```

To restore captured unpackaged metadata:

```bash
export SF_ALIAS=production
export ROLLBACK_SNAPSHOT_DIR=artifacts/rollback/2026.10.1
export ALLOW_ROLLBACK=true
./scripts/rollback/restore-unpackaged.sh
```

For package-owned behavior, use feature disablement plus a corrective package version rather than assuming a package downgrade is safe.

## Post-deployment verification

The verifier checks:

1. expected `04t` is installed when supplied;
2. runtime feature state matches expectation;
3. a synthetic Critical Case can be created;
4. Apex sets `Priority = High` when enabled and leaves `Low` when disabled;
5. the record-triggered Flow sets `Escalation_Source__c = Record-Triggered Flow`;
6. the synthetic Case is deleted afterward.

## Release telemetry and evidence

`telemetry/run.sh` records step duration and status as JSONL. `render-summary.py` emits JSON + CSV. `generate-manifest.py` produces a release manifest containing Git identity, Azure build identity, package IDs, delta evidence hashes, Production verification, rollback snapshot reference, and telemetry evidence.

This is raw release telemetry suitable for later aggregation. Metrics such as deployment frequency, lead time, change failure rate, and recovery time require history across many releases rather than one pipeline run.

## Sandbox refresh

Run `pipelines/sandbox-bootstrap.yml` with the released `04t` that Integration should mirror. It reinstalls the package, deploys the complete unpackaged baseline, assigns the Permission Set, enables the feature for Integration, and executes post-refresh verification.

## Recommended study order

1. Explain the V1 shared-sandbox CI model.
2. Explain why V2 moved PRs to ephemeral scratch orgs.
3. Explain V3 package/delta ownership and immutable promotion.
4. Explain why V4 separates deployment, activation, runtime state, drift, rollback evidence, verification and release telemetry.
5. Compare the native implementation with Gearset or Copado under `comparisons/`.

## Interview narrative

> I evolved the Salesforce pipeline from source deployment into a production release-operating model. Application metadata is versioned as an immutable unlocked package, while org-specific metadata uses Salesforce-aware delta delivery. Before Production the pipeline captures recovery state; after deployment it performs synthetic verification and publishes release evidence. Runtime activation is separated from deployment through Custom Metadata, scheduled jobs detect org drift, and package recovery uses controlled roll-forward rather than assuming an unsafe downgrade. The same delivery primitives can then be compared with Gearset or Copado abstractions.

See `docs/v4-release-operations.md`, `docs/org-drift.md`, `docs/rollback-and-roll-forward.md`, `docs/sandbox-refresh-runbook.md`, and `docs/release-train.md` for the operating runbooks.
