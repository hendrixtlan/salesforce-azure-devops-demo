# V3 Rollback and Recovery Strategy

V3 has two different deployment contracts, so rollback is handled separately for packaged and unpackaged metadata.

## Package-owned application metadata

Every release candidate has an immutable subscriber package version ID (`04t...`). Record the currently approved production package version and the previous known-good version as release evidence.

For a failed release:

1. Stop promotion if the candidate is still in Integration or UAT.
2. If Production has already changed, prefer a corrective package version when the change includes schema/data evolution or when a direct downgrade is not safe/supported.
3. Where package upgrade/install semantics permit the required recovery path, use the known package lineage and prior release evidence rather than attempting to reverse individual metadata files manually.
4. Run the recovery through the same approval and evidence process.

Package rollback is not equivalent to rolling back a container image; Salesforce metadata/data dependencies must be evaluated before changing versions.

## Unpackaged metadata

Unpackaged metadata is Git-owned. Tag every production release and retain the SGD manifests used for deployment.

To recover:

1. Revert the offending Git change or branch from the last known-good release tag.
2. Run PR validation again.
3. Generate the appropriate delta, or set `DELTA_MODE=false` and deploy the full unpackaged boundary.
4. Review destructive changes explicitly.

## Data rollback

Neither a package rollback nor metadata redeployment automatically reverses data mutations performed by Apex, Flow, integrations, or migrations. Data remediation requires a separate backup/export, transformation, approval, and audit procedure.

## Evidence to retain

- Git commit/tag
- `0Ho...` package ID
- deployed `04t...` package version ID
- previous production `04t...`
- SGD `package.xml` and `destructiveChanges.xml`
- changes manifest
- test/quality results
- environment approvals
- installed-package report after deployment
