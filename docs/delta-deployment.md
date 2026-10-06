# Salesforce-aware Delta Deployment

This repository uses SFDX-Git-Delta (SGD) only for `unpackaged/` metadata.

## Generate a delta

```bash
export DELTA_FROM_REF=origin/main
export DELTA_TO_REF=HEAD
./scripts/delta/generate.sh
```

The result includes `package/package.xml`, `destructiveChanges/destructiveChanges.xml`, changed source files, and `changes.manifest.json`.

## Deploy the delta

```bash
export SF_ALIAS=integration
./scripts/delta/deploy.sh
```

Set `DELTA_MODE=false` to bypass incremental deployment and use the full `unpackaged/` source directory. This is the operational fallback when the incremental path is unsuitable.

## CI requirement

SGD requires the relevant Git history. Azure Pipelines therefore checks out with `fetchDepth: 0` before generating deltas.

## Tooling posture

SGD is a community Salesforce CLI plugin, not an officially supported Salesforce product. Treat it as an optimization layer, never as the only recovery path.
