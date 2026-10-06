# Release train conventions

Recommended branch model for the reference implementation:

- `feature/*` — short-lived development branches validated by PR pipeline.
- `main` — continuously integrated source of truth.
- `release/YYYY.MM.N` — release candidate branch that invokes `release-v4.yml`.
- `hotfix/*` — urgent corrective release path that uses the same gates, evidence and Production approval.

For delta calculation, pass `deltaFromRef` as the Git tag or commit corresponding to the last Production release. `HEAD~1` is only a demo fallback, not a reliable enterprise baseline for a multi-commit release train.

After Production, create/update an approved release tag such as `prod-2026.10.1`. In a production implementation this tag update should itself be governed rather than silently pushed by a pipeline with broad repository credentials.
