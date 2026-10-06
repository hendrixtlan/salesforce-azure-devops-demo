# Azure DevOps Setup — V3

## 1. Variable groups

Create these groups under **Pipelines > Library**:

- `salesforce-devhub`
- `salesforce-integration`
- `salesforce-uat`
- `salesforce-production`

Each group contains environment-specific values:

- `SF_CLIENT_ID` — Salesforce connected-app consumer key.
- `SF_USERNAME` — automation/deployment user.
- `SF_INSTANCE_URL` — login or My Domain URL.

The Dev Hub user needs scratch-org and second-generation packaging permissions appropriate to the org.

## 2. Secure files

Upload the JWT private keys as Azure DevOps Secure Files:

- `salesforce-devhub-jwt.key`
- `salesforce-integration-jwt.key`
- `salesforce-uat-jwt.key`
- `salesforce-production-jwt.key`

Do not place private keys in Git, YAML variables, or pipeline artifacts.

## 3. Azure Environments and approvals

Create:

- `salesforce-integration`
- `salesforce-uat`
- `salesforce-production`

At minimum, configure a manual approval/check on `salesforce-production`. Teams can also place an approval on UAT or package promotion if required by release governance.

## 4. PR Build Validation

Create a pipeline from:

```text
pipelines/pr-validation.yml
```

Attach it to `main` as a required Azure Repos **Build Validation** policy. The YAML intentionally uses `trigger: none` and `pr: none`; Azure Repos branch policy starts the PR validation run.

The checkout uses full Git history because SFDX-Git-Delta requires the refs used for comparison.

The PR pipeline publishes:

```text
LWC Jest/JUnit + coverage
Salesforce Code Analyzer SARIF + HTML
unpackaged delta package.xml
unpackaged destructiveChanges.xml
SGD changes manifest
Apex JUnit + JSON results
scratch-org summary
seed evidence
Apex + Flow smoke-test evidence
```

## 5. V3 Release Pipeline

Create another pipeline from:

```text
pipelines/release-v3.yml
```

Its contract is:

```text
main
  -> build 04t package version once
  -> build unpackaged delta once
  -> Integration installs same 04t + delta
  -> UAT installs same 04t + delta
  -> Dev Hub promotes tested 04t
  -> Production approval
  -> Production installs same released 04t + delta
```

The release bundle is a pipeline artifact. Environment stages download the artifact instead of rebuilding the package.

## 6. Unlocked package bootstrap

The first package build calls `scripts/package/find-or-create.sh`. It searches the Dev Hub for `CaseEscalationCore` and creates an unlocked package when none exists. The Dev Hub then owns the long-lived `0Ho...` package ID.

The release pipeline creates a new immutable subscriber package version (`04t...`) for each candidate. The pipeline stores that ID under `artifacts/package/`.

For a production implementation, consider creating the package once as an explicit platform bootstrap step and committing its package alias/ID policy according to your team's governance model rather than allowing arbitrary build agents to create packages.

## 7. Delta deployment

The pipeline installs SFDX-Git-Delta only in jobs that generate deltas. Delta generation is scoped to:

```text
unpackaged/
```

Package-owned `force-app/` metadata is never sent through the delta path.

`DELTA_MODE=false` forces a full deployment of `unpackaged/` when incremental delivery should be bypassed.

## 8. Optional SonarQube

`pipelines/pr-validation-sonarqube.yml` is intentionally separate from the baseline PR pipeline. Before using it:

1. Install the SonarQube Server Azure DevOps extension.
2. Create the SonarQube service connection.
3. Update project/service-connection names if needed.
4. Confirm the SonarQube edition supports the languages and features you expect to analyze.

This keeps the default repo runnable without a commercial SonarQube dependency.

## 9. Scratch-org capacity

The PR pipeline creates one one-day scratch org per validation. Static analysis and local LWC tests run first so obvious failures do not consume a scratch-org allocation. Cleanup uses `condition: always()`.

An agent can still be terminated before cleanup executes, so teams should monitor active scratch orgs in the Dev Hub and remove abandoned CI environments.
