# M365 Governance AI Agent – Design Documentation Index

This folder contains all design and planning documents for the M365 Governance AI Agent solution.
Each document maps to a specific aspect of the solution and serves as both a blueprint and a development tracking artifact.

---

## Documents

| # | File | Description | Status |
|---|------|-------------|--------|
| 1 | [01-Requirements.md](01-Requirements.md) | Power Platform functional, security, ALM, and acceptance requirements | Approved target |
| 2 | [02-Architecture.md](02-Architecture.md) | Dataverse, Power Automate, Copilot Studio, Power Apps, and Teams architecture | Approved target |
| 3 | [03-AgentDesign.md](03-AgentDesign.md) | Per-agent design: purpose, triggers, topics, actions | Draft |
| 4 | [04-DataModel.md](04-DataModel.md) | Dataverse tables, relationships, keys, security, and retention | Approved target |
| 5 | [05-Roadmap.md](05-Roadmap.md) | Power Platform migration and delivery roadmap | Approved target |
| 6 | [06-Requirements-Feature-Matrix.md](06-Requirements-Feature-Matrix.md) | Current-to-target feature and evidence matrix | Working baseline |
| 7 | [07-SPO-Connector-Attestation-Contract.md](07-SPO-Connector-Attestation-Contract.md) | Historical SharePoint connector/attestation contract | Legacy reference |
| 8 | [08-CopilotStudio-OwnerTopic-Wiring.md](08-CopilotStudio-OwnerTopic-Wiring.md) | Historical owner-topic wiring guide | Legacy reference |
| 9 | [09-Certify-DryRun-Verification-Checklist.md](09-Certify-DryRun-Verification-Checklist.md) | Historical certify verification checklist | Legacy reference |
| 10 | [10-Owner-UI-Wiring-Evidence-Log.md](10-Owner-UI-Wiring-Evidence-Log.md) | Historical owner UI evidence template | Legacy reference |
| 11 | [11-Tooling-Inventory.md](11-Tooling-Inventory.md) | Historical mixed-platform tooling inventory | Legacy reference |
| 12 | [12-PowerAutomate-Build-Guide.md](12-PowerAutomate-Build-Guide.md) | Dataverse-backed Power Automate implementation guide | Approved target |
| 13 | [13-Agent-Split-Implementation-Plan.md](13-Agent-Split-Implementation-Plan.md) | Historical Admin/Owner split migration plan | Legacy reference |
| 14 | [14-Launcher-AdminOwner-Smoke-Test.md](14-Launcher-AdminOwner-Smoke-Test.md) | Role-routing smoke-test patterns | Adapt for target |
| 15 | [15-Action-Design-Implementation-Plan.md](15-Action-Design-Implementation-Plan.md) | Historical SharePoint-backed action design | Legacy reference |
| 16 | [16-Sprint-A-Implementation-Guide.md](16-Sprint-A-Implementation-Guide.md) | Historical topic implementation guide | Legacy reference |
| 17 | [17-Sprint-A-Completion-Summary.md](17-Sprint-A-Completion-Summary.md) | Historical Sprint A completion evidence | Legacy reference |
| 18 | [18-Sprint-A-Checklist.md](18-Sprint-A-Checklist.md) | Historical Sprint A checklist | Legacy reference |
| 19 | [19-UI-Wiring-Quickstart.md](19-UI-Wiring-Quickstart.md) | Historical UI wiring guide | Legacy reference |
| 20 | [20-Skills-Based-Agent-Migration.md](20-Skills-Based-Agent-Migration.md) | New Copilot Studio harness migration, skill catalog, tool gaps, build procedure, and acceptance tests | Authoring package ready |
| 21 | [21-SQL-Canvas-Design-Audit.md](21-SQL-Canvas-Design-Audit.md) | Live SQL and latest Canvas package audit for large-inventory owner/all-site filtering | SQL remediated; Canvas rebind pending |
| 22 | [22-Agent-Orchestration-Architecture.md](22-Agent-Orchestration-Architecture.md) | GitHub- and portal-ready Power Platform orchestration overview | Approved target |
| 23 | [23-Power-Platform-Refactor.md](23-Power-Platform-Refactor.md) | Architecture decision, current-to-target mapping, and migration controls | Approved |
| 24 | [24-Hackathon-Project-Summary.md](24-Hackathon-Project-Summary.md) | Hackathon pitch, demo story, innovation, and success measures | Ready for submission |
| 25 | [25-Deployment-Status-and-Runbook.md](25-Deployment-Status-and-Runbook.md) | Current tenant/GitHub release status, safe deployment sequence, validation, and rollback | Active release record |
| 26 | [26-Deployment-Guide.md](26-Deployment-Guide.md) | Package validation, solution import, configuration, inventory bootstrap, acceptance tests, and rollback | Ready; package export gated |

---

## Solution Overview

**Name:** M365 Governance AI Agent  
**Platform:** Microsoft Copilot Studio (multi-agent)  
**Data Platform:** Microsoft Dataverse  
**Automation:** Power Automate solution-aware cloud flows  
**Governed Sources:** Microsoft Graph and SharePoint Online APIs  
**Channels:** Microsoft Teams (chat + proactive notifications)  
**Publisher / Prefix:** SofianeB / `sb`  
**Current Version:** Legacy proof of concept plus approved 2.0 Power Platform target

---

## Key Stakeholders

| Role | Responsibility |
|------|---------------|
| Site Owner | Certified owner of one or more SPO sites |
| Tenant Admin | M365/SharePoint admin with visibility across all sites |
| Governance Bot | The Copilot Studio agent serving as the primary interface |
| Automation Service | Power Automate flows that inventory, authorize, approve, notify, and reconcile |

---

## Architecture Status

Documents 1-6, 12, and 22-26 describe the approved Power Platform target.
Documents 7-11 and 13-21 contain useful implementation evidence from the
legacy SharePoint/SQL proof of concept. Where they conflict, the target
architecture and migration decision in document 23 take precedence.
