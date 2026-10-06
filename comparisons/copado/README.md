# Copado Comparison Blueprint

Use this folder as the design branch for a Copado implementation.

Evaluate how the native concepts map to Copado:

- Git feature work and pull requests -> Copado user-story/repository model.
- Integration/UAT/Production stages -> Copado pipeline environments and promotions.
- Azure approvals -> Copado release governance and approvals.
- CLI deployments -> Copado Salesforce-aware deployment orchestration.
- Azure test evidence -> Copado test/quality gates plus retained Azure evidence where the enterprise requires it.

The comparison should document what custom Bash/YAML disappears, what governance Copado adds, and what vendor/platform dependencies are introduced.
