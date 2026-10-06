# From V2 to V3

V2 proved isolated source-driven validation. V3 changes the release model without discarding that CI foundation.

```text
V2
PR -> scratch org -> full source validation -> merge -> source deployments

V3
PR -> scratch org + multi-surface tests -> merge
   -> immutable unlocked package + unpackaged delta
   -> Integration -> UAT -> package promotion -> Production
```

Key differences:

1. `force-app/` now has a package ownership contract.
2. `unpackaged/` contains metadata intentionally outside the package.
3. LWC Jest tests execute before scratch-org creation.
4. Flow metadata broadens the Salesforce deployment surface.
5. SGD generates reviewable deltas only for unpackaged metadata.
6. Long-lived environments receive the same `04t` package version; they do not rebuild source independently.
7. SonarQube is an optional complementary gate, not a replacement for Salesforce Code Analyzer.
8. Gearset/Copado are evaluated as workflow abstractions over known release primitives.

The V2 release YAML files remain under `pipelines/legacy-v2/` for learning/comparison only. The V3 production path is `pipelines/release-v3.yml`.
