# Rollback strategy

Salesforce metadata deployments are not identical to immutable application-image releases, so rollback must be deliberate.

## Preferred strategy

1. Tag every production release in Git.
2. Keep `main` aligned with the intended production state.
3. If a release must be reverted, create a dedicated revert branch from the last known-good tag or revert the offending commit(s).
4. Open a pull request so the rollback itself passes the same static analysis and deployment validation gates.
5. Validate the rollback against Production.
6. Quick deploy the successful validation after approval.

## Destructive changes

Deleting metadata requires special handling through destructive manifests and should never be treated as a blind inverse of a deployment. Review dependencies and data impact before removal.

## Data rollback

Metadata rollback does not automatically undo data mutations caused by automation, Apex, integrations, or migrations. Data remediation must have its own runbook, backup/export strategy, and audit trail.
