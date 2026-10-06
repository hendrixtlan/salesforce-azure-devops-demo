# Rollback and roll-forward strategy

## Before Production

`scripts/rollback/capture.sh` records:

- installed package inventory;
- current governed unpackaged metadata in Metadata API format;
- target org alias, release ID and Git commit;
- an explicit recovery policy.

## Fast mitigation

If new behavior is harmful but the deployment itself succeeded, disable the operational feature flag:

```bash
export SF_ALIAS=production
FEATURE_STATE=disabled ./scripts/feature-flags/set.sh
```

## Restore unpackaged metadata

```bash
export SF_ALIAS=production
export ROLLBACK_SNAPSHOT_DIR=artifacts/rollback/<release-id>
export ALLOW_ROLLBACK=true
./scripts/rollback/restore-unpackaged.sh
```

## Package-owned application metadata

Use a corrective package version (roll-forward). V4 intentionally does not automate downgrading an installed unlocked package version because dependency and data semantics can make a blind downgrade unsafe.
