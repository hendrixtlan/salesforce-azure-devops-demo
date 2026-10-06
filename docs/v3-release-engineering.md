# V3 Release Engineering Model

V3 separates Salesforce delivery into two explicit contracts.

## 1. Packaged application boundary

`force-app/` contains cohesive application metadata that is versioned as an unlocked package:

- Apex classes and triggers
- custom fields owned by the feature
- Lightning Web Components
- record-triggered Flow

The pipeline creates one subscriber package version (`04t...`) and promotes that exact version through Integration, UAT, and Production. This is the **build once, promote many** artifact.

## 2. Unpackaged/org-specific boundary

`unpackaged/` contains metadata that is intentionally managed outside the package. In this demo it contains the environment permission set.

SFDX-Git-Delta (SGD) generates a Salesforce-aware delta only for this boundary. The same components are never simultaneously delivered through both SGD and the unlocked package.

## Release sequence

```text
main
  -> quality gates
  -> build unlocked package version (04t)
  -> generate unpackaged delta
  -> Integration: install 04t + delta
  -> UAT: install SAME 04t + delta
  -> promote package version
  -> Production approval
  -> Production: install SAME 04t + delta
```

## Failure strategy

- Package install failure: stop promotion. The immutable version remains traceable.
- Delta generation failure: operators can set `DELTA_MODE=false` and perform a full deployment of the unpackaged boundary.
- Production rollback: reinstall the previously approved package version where package semantics permit, or create a corrective version; revert unpackaged metadata from the prior Git tag/commit and redeploy it. Data migration/backout is handled separately.

## Why the split matters

Packages provide versioning, dependency boundaries, repeatable installation, and immutable release identity. Delta deployment optimizes legacy or org-specific metadata that is not yet package-owned. Mixing both mechanisms over the same metadata creates ambiguous ownership and unsafe rollback behavior, so V3 enforces a clear boundary.
