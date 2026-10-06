# Sandbox refresh runbook

A refreshed sandbox can lose or invalidate assumptions used by CI/CD. Re-establish the baseline instead of treating the refreshed org as ready automatically.

1. Refresh/reconnect the CI authentication principal and JWT configuration if required.
2. Identify the released package version (`04t...`) that the sandbox should mirror.
3. Run `pipelines/sandbox-bootstrap.yml` with that package version ID.
4. The bootstrap installs the released package, deploys the full unpackaged baseline, assigns the demo Permission Set, enables the feature for Integration, and runs post-deployment verification.
5. Publish and review the resulting evidence before returning the sandbox to the delivery pool.
