# Azure DevOps setup

## Variable groups

Create these variable groups under **Pipelines > Library**:

- `salesforce-integration`
- `salesforce-uat`
- `salesforce-production`

Each group should expose:

- `SF_CLIENT_ID` - Salesforce connected app consumer key / OAuth client ID.
- `SF_USERNAME` - deployment user for the target org.
- `SF_INSTANCE_URL` - target login or My Domain URL.

Do not store the private key as a normal variable.

## Secure files

Upload one private key per environment under **Pipelines > Library > Secure files**:

- `salesforce-integration-jwt.key`
- `salesforce-uat-jwt.key`
- `salesforce-production-jwt.key`

Authorize only the pipelines that require each key.

## Azure Environments

Create:

- `salesforce-uat`
- `salesforce-production`

Configure approvals/checks on `salesforce-production`. A common portfolio configuration is one required manual approver before the deployment job begins.

## Branch policy

Create the `pipelines/pr-validation.yml` pipeline first. Then protect `main` under **Repos > Branches > main > Branch policies**:

- Require pull requests.
- Require at least one reviewer.
- Require comment resolution.
- Add the PR validation pipeline as a required Build Validation policy.
- Optionally require linked work items for traceability.

For a larger team, add a protected `develop` branch and apply the same validation pipeline there.
