# 24 - Hackathon Project Summary

## Project name

**Governor365 - Power Platform Governance Agents**

## One-line pitch

Governor365 gives Microsoft 365 site owners and governance teams a secure,
conversational way to understand risk and complete governed actions using
Copilot Studio, Dataverse, Power Automate, Power Apps, and Teams.

## Problem

Microsoft 365 governance is often fragmented across spreadsheets, scripts,
lists, administrative portals, and manual follow-up. Site owners do not know
which workspaces need attention, while governance teams spend time identifying
orphaned sites, chasing certifications, and reconstructing action history.

## Solution

Governor365 provides one role-aware agent experience:

- owners see only their governed sites and can request support or disposition;
- admins review tenant-wide risk, orphaned sites, attestations, and requests;
- specialist advisors explain policy, readiness, data protection, identity, and
  assurance implications;
- Power Automate validates identity, processes requests and approvals, refreshes
  inventory, and sends Teams notifications;
- Dataverse provides a normalized, auditable operational record.

## What makes it Power Platform-native

| Capability | Power Platform component |
|---|---|
| Conversational front door | Copilot Studio |
| Operational database | Microsoft Dataverse |
| Workflow and integration | Power Automate |
| Human approval | Power Automate Approvals |
| Dashboards | Power Apps |
| Notifications | Teams connector and Adaptive Cards |
| Deployment | Managed solutions, connection references, environment variables |
| Governance | Dataverse security, auditing, DLP, and Power Platform environments |

The target design does not require Azure SQL, SharePoint lists, Logic Apps, or
Function Apps.

## User journey

1. A site owner asks, "Which of my sites need attention?"
2. Copilot Studio passes the signed-in identity to a bounded Power Automate tool.
3. The flow revalidates identity and queries normalized Dataverse owner
   assignments.
4. The agent presents an Adaptive Card with risk and recommendation.
5. The owner requests archival.
6. Power Automate creates a Dataverse request and audit event, starts approval,
   and returns a tracking ID.
7. Teams notifications and the agent expose status without claiming completion
   before the operation succeeds.

## Innovation

- **Role-aware multi-agent design:** one front door routes to operational and
  advisory specialists without weakening authorization.
- **Normalized governance graph:** sites, owners, requests, events, and evidence
  are related in Dataverse instead of embedded in text fields.
- **Secure low-code tools:** agents never trust model-provided identity and do
  not connect directly to unrestricted tables.
- **Explainable action lifecycle:** recommendations, approvals, state changes,
  and outcomes remain traceable to evidence and human decisions.
- **Asynchronous scale pattern:** scan runs and work items let Power Automate
  process large tenants safely with retries and reconciliation.

## Responsible AI and security

- Recommendations are advisory; destructive changes require confirmation and
  human approval.
- Owner and admin authorization is rechecked inside every tool flow.
- Responses expose only minimized fields authorized for the caller.
- Failures are explicit and correlated; connector errors never appear as
  successful empty results.
- Dataverse audit and append-only action events preserve accountability.
- DLP and managed solutions control connectors and deployment.

## Demo script

1. Open the Governor365 agent in Teams.
2. Ask for owned sites needing attention.
3. Open a site detail card and show the plain-language recommendation.
4. Submit an archive request and display the Dataverse tracking ID.
5. Switch to the admin experience and review the pending request.
6. Show the Power Automate approval and resulting action-event timeline.
7. Open the Power App dashboard to show the same Dataverse-backed state.
8. Highlight the solution package, connection references, environment
   variables, security roles, and DLP controls.

## Success measures

| Measure | Target |
|---|---|
| Owner data isolation tests | 100% pass |
| Requests with complete event trail | 100% |
| Duplicate requests for same idempotency key | 0 |
| Inventory records processed without manual handling | >= 99% per complete scan |
| Time to identify and submit an action | Under 3 minutes in demo |
| Production dependencies outside Power Platform/M365 | 0 in target architecture |

## Submission description

Governor365 is a Power Platform-native, role-aware multi-agent solution for
Microsoft 365 governance. Copilot Studio gives owners and administrators a
conversational front door; Dataverse stores normalized sites, ownership,
requests, policy, evidence, and audit events; Power Automate implements secure
tools, approvals, inventory, notifications, and reconciliation; and Power Apps
provides governed dashboards. The result replaces fragmented scripts, SQL, and
lists with a consistent low-code architecture that is explainable, auditable,
and deployable through managed solutions.
