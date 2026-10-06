# Azure DevOps setup

## 1. Variable groups

Create these variable groups under **Pipelines > Library**:

- `salesforce-devhub`
- `salesforce-integration`
- `salesforce-uat`
- `salesforce-production`

Each group exposes environment-specific values:

- `SF_CLIENT_ID` - Salesforce connected app consumer key / OAuth client ID.
- `SF_USERNAME` - Salesforce automation/deployment username.
- `SF_INSTANCE_URL` - Salesforce login or My Domain URL.

For `salesforce-devhub`, the Salesforce user must have access to the Dev Hub functionality required to create and delete scratch orgs.

Do not store JWT private keys as ordinary pipeline variables.

## 2. Secure files

Upload private keys under **Pipelines > Library > Secure files**:

- `salesforce-devhub-jwt.key`
- `salesforce-integration-jwt.key`
- `salesforce-uat-jwt.key`
- `salesforce-production-jwt.key`

Authorize only the pipelines that require each key.

V2 PR validation needs only the Dev Hub key because the PR is validated in an ephemeral scratch org rather than in the shared Integration org.

## 3. Connected app / JWT authentication

Configure the Salesforce connected app and certificate/public key corresponding to each CI private key. The pipeline authenticates using `sf org login jwt`.

Treat the client ID, usernames, URLs, and private-key access as environment-scoped configuration. Do not embed them in repository YAML.

## 4. Scratch-org capacity

V2 creates one scratch org per active PR validation run. Dev Hub scratch-org allocations are finite, so teams should:

- Keep CI scratch-org duration short (this repo uses one day).
- Delete each scratch org at the end of the pipeline.
- Avoid creating the org until static analysis has passed.
- Periodically inspect the Dev Hub for abandoned CI scratch orgs after canceled/aborted agents.
- Control pipeline concurrency if the organization has a low active-scratch-org allocation.

## 5. Azure Environments

Create:

- `salesforce-uat`
- `salesforce-production`

Configure approvals/checks on `salesforce-production`. A suitable portfolio configuration requires at least one manual approver before the production deployment job begins.

## 6. PR validation pipeline

Create an Azure Pipeline pointing to:

```text
pipelines/pr-validation.yml
```

The pipeline consumes:

```text
variable group: salesforce-devhub
secure file:    salesforce-devhub-jwt.key
```

It generates a scratch alias from the Azure DevOps build ID, such as:

```text
pr-1842
```

This makes parallel validation runs independent of each other.

## 7. Branch policy

Protect `main` under **Repos > Branches > main > Branch policies**:

- Require pull requests.
- Require at least one reviewer.
- Require comment resolution.
- Add `pipelines/pr-validation.yml` as a required **Build Validation** policy.
- Reset reviewer votes when new changes are pushed if desired.
- Optionally require linked work items for auditability.

The YAML keeps `trigger: none` and `pr: none` because Azure Repos PR validation is driven through the Build Validation policy.

## 8. PR test evidence

Azure DevOps receives native JUnit Apex test results through `PublishTestResults@2` and also stores the broader `artifacts/` directory as a pipeline artifact.

The evidence includes:

```text
artifacts/
  code-analyzer/
    results.sarif
    results.html
  scratch-org/
    org-summary.json
  test-results/
    apex-test-results.json
    junit/
      ...xml
  seed-data/
    case-id.txt
    seed-summary.json
  smoke-test/
    case-query.json
```

`org-summary.json` is intentionally sanitized and does not contain Salesforce access tokens.

## 9. Quality thresholds

The PR YAML currently defines:

```yaml
MIN_TEST_RUN_COVERAGE: '75'
```

Raise the repository threshold as the codebase matures. This number represents the coverage measured by the CI test run; production release policy should separately account for Salesforce deployment requirements and org-wide coverage.

The Salesforce Code Analyzer script uses a `High` severity failure threshold by default. Both thresholds can be changed without rewriting the scripts.

## 10. Long-lived environments

After merge, the existing pipelines still use separate variable groups and Secure Files:

```text
main
  -> salesforce-integration
  -> salesforce-uat
  -> salesforce-production
```

This separates ephemeral PR validation credentials from release/deployment credentials and keeps least-privilege boundaries clearer.
