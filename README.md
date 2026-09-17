# Governor365 - Power Platform Governance Agents

Governor365 is a role-aware Microsoft 365 governance solution built primarily
on the Power Platform. Copilot Studio agents help site owners and governance
administrators understand risk, submit governed actions, and track outcomes.
Dataverse is the operational system of record, and Power Automate implements
inventory, request, approval, notification, and audit workflows.

## Power Platform architecture

| Layer | Technology | Responsibility |
|---|---|---|
| Experience | Microsoft Teams, Copilot Studio, Adaptive Cards, Power Apps | Conversational and dashboard experiences |
| Agent orchestration | Copilot Studio | Intent routing, role-aware conversations, specialist agents |
| Automation | Power Automate cloud flows and solution-aware child flows | Inventory, authorization, requests, approvals, notifications, reconciliation |
| Data | Microsoft Dataverse | Sites, owner assignments, policy settings, action requests, audit events, scan runs |
| Source systems | Microsoft Graph and SharePoint Online APIs | Authoritative Microsoft 365 workload metadata and approved remediation operations |
| Governance | Managed solutions, connection references, environment variables, DLP policies | ALM, configuration, connector controls, and deployment |

Azure SQL, SharePoint lists, Logic Apps, and Function Apps are not part of the
target application architecture. Existing SQL and SharePoint-list artifacts in
this repository are migration sources and historical proof-of-concept assets.

## Start here

- [Documentation index](docs/00-Index.md)
- [Target architecture](docs/02-Architecture.md)
- [Dataverse data model](docs/04-DataModel.md)
- [Power Automate build guide](docs/12-PowerAutomate-Build-Guide.md)
- [Dataverse inventory flow contract](flows/inventory-dataverse-flow.txt)
- [Step-by-step deployment guide](docs/26-Deployment-Guide.md)
- [Power Platform refactor decision and migration](docs/23-Power-Platform-Refactor.md)
- [Hackathon project summary](docs/24-Hackathon-Project-Summary.md)
- [Agent orchestration overview](docs/22-Agent-Orchestration-Architecture.md)

## Design principles

1. Dataverse is the single operational source of truth.
2. Agents call bounded Power Automate tools instead of connecting directly to
   application tables.
3. Caller identity comes from Copilot Studio system context and is revalidated
   in every privileged flow.
4. Destructive operations require explicit confirmation and human approval.
5. Every request and state transition produces an auditable Dataverse record.
6. All components ship in a managed Power Platform solution.

## Repository layout

| Path | Purpose |
|---|---|
| `agents` | Deployable Copilot Studio source and guarded deployment helpers |
| `flows` | Power Automate contracts and implementation notes |
| `new-agents` | Skills-based Owner/Admin targets and advisor definitions |
| `skills` | Reusable agent procedures and safety rules |
| `connectors` | Governed connector and evidence-broker contracts |
| `adaptive-cards` | Source-controlled owner/admin presentation assets |
| `scripts` | Solution-package preflight and Dataverse inventory bootstrap tools |
| `docs` | Canonical architecture, implementation, release, and hackathon documentation |

## Current state

The repository contains the reviewed agent source, Dataverse schema,
Power Automate contracts, deployment tools, and a working proof of concept.
Tenant implementation follows the phased migration in the
[roadmap](docs/05-Roadmap.md). Do not treat legacy SQL or SharePoint-list
deployment artifacts as the production target.

The 2026-09-17 release aligns the deployable Owner and Admin agent instructions
with the Dataverse and Power Automate target and removes legacy fallback
behavior. The target Dataverse tables and replacement tool flows must still be
provisioned and acceptance-tested before the functional cutover. See the
[deployment status and runbook](docs/25-Deployment-Status-and-Runbook.md).

For inventory bootstrap and migration testing, use
`scripts/Invoke-DataverseGovernanceScan.ps1`. Recurring production inventory
uses the solution-aware three-flow pipeline documented in the Power Automate
build guide.

The repository does not yet contain a managed 2.x solution ZIP. Follow the
[deployment guide](docs/26-Deployment-Guide.md), including its mandatory
package-content validation. The solution export remains blocked until the
documented target tables and flows are implemented and tested in the
development environment.
