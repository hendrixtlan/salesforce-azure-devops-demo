# Native Azure DevOps vs Gearset vs Copado

The executable reference implementation uses Azure DevOps + Salesforce CLI so the underlying mechanics stay visible. The comparison folders document where specialized Salesforce DevOps platforms replace custom orchestration.

| Capability | Native Azure DevOps + CLI | Gearset | Copado |
| --- | --- | --- | --- |
| Git/PR policy | Azure Repos branch policies | Connects to Git + PR CI | Git-based promotion model |
| Salesforce dependency handling | CLI + custom policy/SGD | Built-in metadata comparison/problem analysis | Salesforce-aware deployment automation |
| Delta delivery | SGD community plugin | Delta CI capability | Promotion/deployment automation |
| Scratch environments | CLI scripted | Supported in CI workflows | Platform-specific environment strategy |
| Test evidence | Azure `PublishTestResults` | Integrated CI testing/reporting | Integrated pipeline/test orchestration |
| Release governance | Azure Environments/approvals | Gearset pipelines/governance | Copado user stories/promotions/pipelines |
| Portability | Highest | Vendor-specific | Vendor-specific |

The portfolio recommendation is to demonstrate the native implementation first, then explain how a specialized platform reduces custom YAML/scripts while adding Salesforce-specific governance and UX.
