# 01 - Requirements

**Solution:** Governor365 / M365 Governance AI Agent  
**Version:** 2.0 target  
**Last updated:** 2026-09-17

## 1. Business context

Microsoft 365 governance is frequently manual and fragmented. Sites become
stale, lose owners, or miss certification while owners and governance teams
work across spreadsheets, scripts, lists, and administration portals.
Governor365 provides a role-aware conversational experience for identifying
risk, explaining recommendations, and completing governed actions, plus a
visual dashboard for browsing, filtering, and acting without starting in chat.

## 2. Scope

### In scope

- owner and admin Copilot Studio experiences in Microsoft Teams;
- site inventory, ownership, compliance, attestation, requests, and audit data
  in Dataverse;
- Power Automate inventory, action, approval, notification, and reconciliation
  flows;
- a required Power Apps dashboard for owner and admin interactive journeys;
- organizational deployment of the agent and dashboard in Microsoft Teams,
  with browser/Microsoft 365 entry points where supported;
- Microsoft Graph and SharePoint API integration through approved connectors;
- configurable policy rules, human approval, audit, and managed-solution ALM.

### Out of scope

- automatic site deletion without explicit confirmation and human approval;
- using SharePoint lists or Azure SQL as the target application database;
- using Logic Apps or Function Apps for target workflow automation;
- storing full document content or connector secrets in Dataverse;
- cross-tenant governance in the first production release.

## 3. Roles

| Role | Description |
|---|---|
| Site Owner | User with an active normalized owner assignment for a governed site |
| Governance Admin | User with an active, in-window GovernanceAdmin assignment in Dataverse |
| Auditor | Read-only reviewer of requests, events, evidence, and scan outcomes |
| Platform Maker | Authorized developer of solution components in development |
| Flow Service Account | Least-privilege owner of production connection references and flows |

## 4. Functional requirements

### Owner experience

| ID | Requirement | Priority |
|---|---|---|
| FR-OWN-01 | Show all active sites assigned to the signed-in owner. | Must |
| FR-OWN-02 | Show only owned sites needing attention. | Must |
| FR-OWN-03 | Explain risk and recommended action in plain language. | Must |
| FR-OWN-04 | Show live site detail authorized for the caller. | Must |
| FR-OWN-05 | Certify an owned site after explicit confirmation and evidence refresh. | Must |
| FR-OWN-06 | Submit an archive request after explicit confirmation. | Must |
| FR-OWN-07 | Submit a deletion-review request after typed confirmation. | Must |
| FR-OWN-08 | Submit a governance support request with optional site context. | Must |
| FR-OWN-09 | Track the status of the caller's requests. | Must |
| FR-OWN-10 | Receive and respond to actionable Teams notifications. | Should |
| FR-OWN-11 | Browse, filter, inspect, and initiate governed actions from an owner-scoped Power Apps dashboard. | Must |

### Admin experience

| ID | Requirement | Priority |
|---|---|---|
| FR-ADM-01 | Show tenant-wide compliance and action summaries after admin verification. | Must |
| FR-ADM-02 | Show orphaned and under-owned sites. | Must |
| FR-ADM-03 | Filter by action, office, attestation, status, and evidence freshness. | Must |
| FR-ADM-04 | Review, approve, reject, and track governed requests. | Must |
| FR-ADM-05 | Assign an owner through an approved request path. | Should |
| FR-ADM-06 | Trigger a bounded site re-evaluation. | Should |
| FR-ADM-07 | Receive scheduled Teams summaries with suppression and retry controls. | Must |
| FR-ADM-08 | Review scan failures, stale evidence, and reconciliation exceptions. | Must |
| FR-ADM-09 | Use a Power Apps dashboard for tenant summaries, filters, site detail, requests, and operational exceptions. | Must |

### Triage and evidence

| ID | Requirement | Priority |
|---|---|---|
| FR-TRI-01 | Classify each site as Compliant, NonCompliant, or Unknown. | Must |
| FR-TRI-02 | Recommend None, Certify, Archive, DeleteReview, or AssignOwners. | Must |
| FR-TRI-03 | Apply deterministic, ordered rules before generative explanation. | Must |
| FR-TRI-04 | Store rule outputs and evidence timestamps in Dataverse. | Must |
| FR-TRI-05 | Keep thresholds editable without code deployment. | Must |
| FR-TRI-06 | Mark missing or stale evidence explicitly; never invent status. | Must |

### Requests and audit

| ID | Requirement | Priority |
|---|---|---|
| FR-ACT-01 | Revalidate caller identity and owner/application-role authorization inside every tool flow. | Must |
| FR-ACT-02 | Create a Dataverse request before an asynchronous operation. | Must |
| FR-ACT-03 | Require approval for destructive or privileged changes. | Must |
| FR-ACT-04 | Record every state transition as an append-only action event. | Must |
| FR-ACT-05 | Use idempotency keys to prevent duplicate requests. | Must |
| FR-ACT-06 | Return truthful state and a tracking ID to the agent. | Must |
| FR-ACT-07 | Keep notification state independent from operation state. | Must |

### Inventory and automation

| ID | Requirement | Priority |
|---|---|---|
| FR-DAT-01 | Power Automate shall collect approved Microsoft 365 site metadata. | Must |
| FR-DAT-02 | Inventory shall use paging and bounded asynchronous work items. | Must |
| FR-DAT-03 | Dataverse shall be the single operational source of truth. | Must |
| FR-DAT-04 | Owner relationships shall be normalized into assignment rows. | Must |
| FR-DAT-05 | Upserts shall use alternate keys and be safe to retry. | Must |
| FR-DAT-06 | Incomplete scans shall not mark unseen sites stale. | Must |
| FR-DAT-07 | Flow failures shall remain visible and retryable. | Must |
| FR-DAT-08 | Legacy SQL/list data shall be reconciled before cutover. | Must |

### Platform and ALM

| ID | Requirement | Priority |
|---|---|---|
| FR-PLT-01 | All target components shall reside in a Power Platform solution. | Must |
| FR-PLT-02 | Dataverse tables, flows, agents, apps, references, and variables shall deploy together. | Must |
| FR-PLT-03 | Test and production shall receive managed solutions. | Must |
| FR-PLT-04 | Tenant-specific values shall use environment variables. | Must |
| FR-PLT-05 | Connectors shall comply with environment DLP policy. | Must |
| FR-PLT-06 | Production connection references shall use approved least-privilege identities. | Must |
| FR-PLT-07 | The Canvas app shall be modernized from the 1.0 proof of concept, included in the 2.0 managed solution, and use Dataverse only. | Must |
| FR-PLT-08 | The dashboard and agent shall be distributed as one discoverable Microsoft Teams experience, with tested deep links between chat and app. | Must |

## 5. Non-functional requirements

| ID | Requirement | Target |
|---|---|---|
| NFR-01 | Availability | Power Platform service availability; documented degraded behavior |
| NFR-02 | Interactive response | Under 5 seconds p95 for normal paged Dataverse reads |
| NFR-03 | Authorization | 100% owner-isolation and admin-verification tests pass |
| NFR-04 | Freshness | Weekly full scan minimum; visible last-observed timestamp |
| NFR-05 | Scale | At least 50,000 sites using delegable queries and paged work items |
| NFR-06 | Auditability | 100% request transitions represented by action events |
| NFR-07 | Reliability | Idempotent retries with no duplicate site/request records |
| NFR-08 | Maintainability | Policy and deployment settings change without code edits |
| NFR-09 | Data minimization | No secrets/tokens/full raw API payloads in Dataverse |
| NFR-10 | Portability | Managed solution imports without hard-coded environment IDs |
| NFR-11 | Observability | Every tool and workflow exposes a correlation ID and explicit state |
| NFR-12 | Accessibility | Teams cards and Power Apps meet organizational accessibility standards |

## 6. Security and responsible AI

- Identity comes from Copilot Studio system context, not user prose.
- Routing to the Admin Agent does not grant authorization.
- Power Automate rechecks active owner assignment or an active, in-window
  Governance Role Assignment by immutable Entra object ID.
- Role assignments cannot be self-granted through the agent or Canvas app.
- Tools return minimized, caller-authorized records.
- Recommendations identify their evidence and are not represented as executed
  actions.
- Archive, deletion review, and owner changes require explicit confirmation;
  destructive operations require approval.
- Connector failures and stale evidence are surfaced explicitly.
- Dataverse auditing and append-only action events provide accountability.

## 7. Acceptance gates

1. Owner, admin, auditor, and unauthorized test personas pass access tests.
2. Dataverse queries remain delegable at target data volume.
3. Duplicate tool invocations create one business request.
4. Every request has a complete state-transition event trail.
5. Failed and incomplete scans preserve correct prior state.
6. Managed solution deploys development to test with environment-specific
   values supplied at import.
7. Production agents, apps, and flows have no dependency on Azure SQL or
   governance SharePoint lists.
8. No target recurring workflow uses Logic Apps, Function Apps, Azure
   Automation, or scheduled PowerShell.
