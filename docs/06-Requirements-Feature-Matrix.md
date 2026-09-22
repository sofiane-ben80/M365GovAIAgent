# 06 - Requirements and Feature Matrix

**Baseline date:** 2026-09-17  
**Target architecture:** Power Platform-first

## Status legend

- **Existing POC:** repository asset exists but uses a legacy SQL/list path.
- **Reusable:** behavior or UI can be retained with a Dataverse flow rebind.
- **Target designed:** target contract/schema is documented but not yet deployed.
- **Target implemented:** deployed Power Platform target behavior is verified.

## Platform matrix

| Capability | Current evidence | Target | Status | Required work |
|---|---|---|---|---|
| Owner/Admin agents | Exported Copilot Studio agents; deployable instructions aligned on 2026-09-17 | Retain and rebind to Dataverse tools | Reusable | Build and bind tools, update cards, run persona tests |
| Orchestrator/advisors | Exported/design assets | Retain role-aware multi-agent model | Reusable | Rebind evidence broker |
| Site inventory | SharePoint lists and Azure SQL artifacts | Governance Site table | Target designed | Create table and migrate |
| Owner mapping | Delimited strings plus SQL normalization | Site Owner Assignment table | Target designed | Migrate normalized assignments |
| Application roles | SharePoint admin-role list / Entra group design | Governance Role Assignment table keyed by immutable Entra object ID | Target designed | Create table, migrate approved roles, restrict writes, rebind verification |
| Action requests | SharePoint action log and SQL request design | Request + append-only Event tables | Target designed | Create flows and migrate history |
| Policy settings | SharePoint config list | Governance Policy Setting | Target designed | Import settings |
| Inventory automation | PowerShell/SQL import assets | Power Automate scan/work-item flows | Target designed | Build and reconcile |
| Agent read tools | SharePoint/SQL flow contracts | Dataverse tool flows | Target designed | Implement documented contracts |
| Approvals | Design assets | Power Automate Approvals | Target designed | Implement request processor |
| Notifications | Power Automate specs | Dataverse-backed Power Automate flows | Reusable | Rebind and add delivery table |
| Canvas dashboard | SQL-backed 1.0 package with reusable browse/detail UX | Required Dataverse-backed owner/admin Power App in the 2.0 solution | Reusable POC | Modernize data model and UX, secure owner/admin access, validate delegation |
| Experience distribution | Separate agent and Power App artifacts | Organizational Teams experience with dashboard tab, agent entry, and bidirectional deep links | Target designed | Package for Teams; validate Microsoft 365 Copilot/app-launcher compatibility and fallback links |
| ALM | Mixed packages/Bicep/scripts | Power Platform managed solution | Target designed | Consolidate solution assets |

## Requirement traceability

| Requirement group | Design evidence | Implementation evidence required |
|---|---|---|
| Owner experience | [01-Requirements.md](01-Requirements.md), [03-AgentDesign.md](03-AgentDesign.md) | Agent test transcript, flow runs, owner-isolation results |
| Admin experience | [01-Requirements.md](01-Requirements.md), [03-AgentDesign.md](03-AgentDesign.md) | Admin/unauthorized persona tests |
| Dataverse model | [04-DataModel.md](04-DataModel.md) | Unpacked solution tables, keys, roles, managed import |
| Power Automate | [12-PowerAutomate-Build-Guide.md](12-PowerAutomate-Build-Guide.md) | Exported flows and acceptance run history |
| Security and audit | [02-Architecture.md](02-Architecture.md) | Access matrix, DLP export, event reconciliation |
| Migration | [23-Power-Platform-Refactor.md](23-Power-Platform-Refactor.md) | Source/target count and relationship report |
| Hackathon | [24-Hackathon-Project-Summary.md](24-Hackathon-Project-Summary.md) | Demo video/screenshots and solution package |

## Critical gaps before production

1. Dataverse target tables and security roles are not yet present in a verified
   managed solution export.
2. Current agent tools still require tenant-side rebinding to the new Dataverse
   Power Automate flows.
3. The required Canvas dashboard remains a legacy SQL proof of concept and is
   not yet included as a Dataverse-backed 2.0 solution component.
4. The scheduled scan/work-item and request processor flows must be built and
   tested in the target environment.
5. Teams packaging, agent/app deep links, and Microsoft 365 entry-point
   validation have not been completed.
6. Legacy-to-Dataverse reconciliation and cutover evidence does not yet exist.

These gaps are explicit so the target design is not confused with current
deployment state.
