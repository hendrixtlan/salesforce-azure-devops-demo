# V4 — Enterprise Salesforce release operations

V4 changes the question from **can we deploy?** to **can we operate releases safely?**

## Production operating model

1. Cut `release/*` or `hotfix/*` from an approved commit.
2. Build one unlocked-package version and one unpackaged delta bundle.
3. Install the same `04t` into Integration and UAT with the feature enabled.
4. Promote the tested package version.
5. Before Production, capture installed-package inventory and retrieve governed unpackaged metadata as a recovery artifact.
6. Deploy Production, explicitly keep the priority feature disabled, and execute a synthetic post-deployment verification.
7. Publish release manifest, telemetry, package inventory, rollback snapshot, delta evidence and verification evidence.
8. Activate the feature later through `pipelines/activate-feature.yml`, with a separate Azure DevOps Environment approval if desired.

## Recovery policy

The project does **not** automate an unlocked-package downgrade. Package-owned application changes use roll-forward: disable the feature if needed, prepare a corrective package version, validate it, and deploy that version. The rollback tooling restores only captured unpackaged metadata. This avoids pretending Salesforce package recovery is equivalent to a container rollback.

## Drift model

Scheduled drift detection is split by ownership:

- Governed Git metadata: retrieve from Production and compare against Git after conversion to Metadata API format.
- Immutable package state: capture installed packages and optionally enforce `EXPECTED_PACKAGE_VERSION_ID`.
- Runtime feature state: query Custom Metadata and optionally enforce `EXPECTED_FEATURE_ENABLED`.

The split matters because runtime activation is intentionally not the same thing as source drift.

## Release telemetry

`telemetry/run.sh` emits JSONL events for package installation, delta deployment and verification. `render-summary.py` produces JSON and CSV suitable for later ingestion into Power BI or another observability platform. A single pipeline run is raw release telemetry; DORA metrics require aggregation across historical releases.
