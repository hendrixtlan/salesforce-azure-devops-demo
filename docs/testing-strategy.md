# Testing Strategy

V3 publishes multiple validation surfaces into Azure DevOps.

| Layer | Execution | Evidence |
| --- | --- | --- |
| LWC unit | `sfdx-lwc-jest` | JUnit + LCOV/Cobertura coverage |
| Salesforce static analysis | Code Analyzer | SARIF + HTML |
| Apex unit | Scratch org | JUnit + JSON + test-run coverage gate |
| Flow deploy validation | Scratch org metadata deployment | Salesforce deployment result |
| Behavioral integration | Seed + SOQL assertion | JSON query evidence |
| Package release | 2GP package version creation/install | 0Ho/04t IDs + release manifest |
| Unpackaged delta | SGD | package.xml + destructiveChanges + changes manifest |

The smoke test proves both automation models on the same persisted Case:

- Apex sets `Priority = High`.
- Flow sets `Escalation_Source__c = Record-Triggered Flow`.
