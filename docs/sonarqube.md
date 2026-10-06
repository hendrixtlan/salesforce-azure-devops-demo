# SonarQube Quality Gate

`pipelines/pr-validation-sonarqube.yml` demonstrates an optional SonarQube gate in addition to Salesforce Code Analyzer.

Prerequisites:

1. Install the SonarQube Server Azure DevOps extension.
2. Create a service connection named `salesforce-sonarqube` or change the template parameter.
3. Create the project key `salesforce-azure-devops-demo`.
4. Use a SonarQube edition/license that supports the languages/features you intend to analyze. Apex analysis is not available in every edition.

The main `pr-validation.yml` deliberately has no hard dependency on SonarQube so the project remains runnable without a commercial SonarQube installation.

The recommended model is complementary:

- Salesforce Code Analyzer: Salesforce-specific static analysis and metadata-aware rules.
- SonarQube: portfolio-wide quality/security policy, JavaScript/LWC metrics, duplication, maintainability, and—where licensed—Apex analysis.
