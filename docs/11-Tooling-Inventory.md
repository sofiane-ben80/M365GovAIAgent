# 11 - Tooling Inventory

> **Legacy inventory:** The approved target standardizes application data on
> Dataverse and automation on Power Automate. Azure Automation, Functions, SQL,
> and governance SharePoint lists below are historical options only. See
> [02-Architecture.md](02-Architecture.md).

Document: Implementation tool map for the M365 Governance AI Agent
Solution: M365 Governance AI Agent
Date: 2026-07-05
Status: Draft

---

## 1. Purpose

This document converts the requirements in docs/01-Requirements.md into the concrete runtime tools that still need to be built.

The solution does not need a standalone app service for phase 1. The required tools are mostly:

1. Power Automate flows
2. Copilot Studio topic wiring
3. PowerShell scheduling / orchestration
4. A small set of support contracts for audit and notification handling

---

## 2. Tool Inventory

### 2.1 Conversational Entry and Identity

| Tool | Type | Purpose | Inputs | Outputs | Depends On |
|------|------|---------|--------|---------|------------|
| Check-AdminRole | Power Automate flow | Determines whether the caller belongs to the Governance Admin group | callerUPN | isAdmin boolean | Governance Config, Microsoft Graph |
| Orchestrator Start / Greeting | Copilot Studio topic | Resolves persona and routes to owner or admin branch | caller identity | persona branch | Check-AdminRole |

### 2.2 Data Refresh

| Tool | Type | Purpose | Inputs | Outputs | Depends On |
|------|------|---------|--------|---------|------------|
| Invoke-GovernanceScan | PowerShell script | Refreshes Contoso Sites with compliance, owner, attestation, and group metadata | CSV or tenant query, Governance Config | Upserted list rows | SharePoint, PnP.PowerShell |
| Scheduled Scan Runner | Recurrence / automation | Runs the scan on a schedule | Schedule config | Fresh site inventory | Power Automate or Azure Automation |

### 2.3 Owner Read Path

| Tool | Type | Purpose | Inputs | Outputs | Depends On |
|------|------|---------|--------|---------|------------|
| My Sites | Copilot Studio topic | Returns only the caller's sites | callerUPN | site list card | SharePoint connector |
| Sites Needing Attention | Copilot Studio topic | Returns non-compliant caller-owned sites | callerUPN | at-risk list card | SharePoint connector, triage data |
| Site Detail | Copilot Studio topic | Shows full site context and recommendation | selected site | detail card | Triage sub-agent, SharePoint connector |
| Certify Site | Copilot Studio topic | Self-service recertification | site context, callerUPN | updated site row + audit log | Action Callback Flow, SharePoint connector (read) |
| Request Archival | Copilot Studio topic | Owner requests archival | site context, callerUPN | action log entry | Action Callback Flow, SharePoint connector (read) |
| Flag for Deletion | Copilot Studio topic | Owner requests deletion review | site context, callerUPN, confirmation token | action log entry | Action Callback Flow, SharePoint connector (read) |

### 2.4 Admin Read Path

| Tool | Type | Purpose | Inputs | Outputs | Depends On |
|------|------|---------|--------|---------|------------|
| Admin Dashboard | Copilot Studio topic | Tenant-wide governance summary | callerUPN | summary card | SharePoint connector |
| Orphaned Sites | Copilot Studio topic | Lists sites with no effective owners | callerUPN | orphaned list card | SharePoint connector |
| Not Attested Sites | Copilot Studio topic | Lists expired or missing-attestation sites | callerUPN | attestation review card | SharePoint connector |
| Action Status | Copilot Studio topic | Returns latest action state for caller | callerUPN / site context | status card | Governance Action Log |

### 2.5 Action Execution

| Tool | Type | Purpose | Inputs | Outputs | Depends On |
|------|------|---------|--------|---------|------------|
| Action Callback Flow | Power Automate flow | Central write path for certify/archive/delete/assign-owner | action payload, site payload, callerUPN | update result, audit result | SharePoint lists |
| Execute Certify | Copilot Studio action topic | Confirms and submits recertification | site context | updated site row | Action Callback Flow |
| Execute Archive | Copilot Studio action topic | Confirms and submits archive request | site context | updated site row | Action Callback Flow |
| Execute Delete | Copilot Studio action topic | Double-confirmed delete request | site context, confirmation text | delete request row | Action Callback Flow |
| Execute Assign Owners | Copilot Studio action topic | Admin owner assignment flow | target owner UPN, site context | updated owner list | Action Callback Flow |

### 2.6 Workflow Stub Automation

| Tool | Type | Purpose | Inputs | Outputs | Depends On |
|------|------|---------|--------|---------|------------|
| Sync-WorkflowStubs | PowerShell script | Creates or verifies the exported workflow stub folders and files | project root, dry-run flag, force flag | workflow stub export files | Export package layout |

### 2.7 Proactive Notifications

| Tool | Type | Purpose | Inputs | Outputs | Depends On |
|------|------|---------|--------|---------|------------|
| Owner Notification Flow | Power Automate flow | Sends individualized owner digests | site rows grouped by owner | Teams adaptive card | Contoso Sites |
| Admin Digest Flow | Power Automate flow | Sends tenant summary to admins | grouped tenant metrics | Teams adaptive card | Contoso Sites |
| Adaptive Card Response Flow | Power Automate flow | Handles button clicks from notification cards | card submit payload | write/update result | SharePoint lists |

---

## 3. Build Priority

1. Check-AdminRole
2. Invoke-GovernanceScan schedule runner
3. Action Callback Flow
4. Owner Notification Flow
5. Admin Digest Flow
6. Adaptive Card Response Flow
7. Copilot Studio wiring for My Sites and Sites Needing Attention
8. Copilot Studio wiring for Admin Dashboard, Orphaned Sites, and Not Attested Sites
9. Copilot Studio wiring for certify/archive/delete/assign-owner action topics

---

## 4. Recommended Delivery Split

### Phase A - Core runtime tools

Build the flows and scheduled runner first so the agent has live data and write capability.

### Phase B - Conversation wiring

Wire the Copilot topics to the read and write tools using the already documented OData filter contracts.

### Phase C - Proactive surfaces

Add owner and admin notification flows only after the live read/write paths are stable.

### Phase D - Hardening

Add audit, deduplication, and delete approval follow-up flows if needed.

---

## 5. Explicit Non-Goals for Phase 1

1. No standalone web app.
2. No custom Azure Function unless a future centralized HTTP endpoint becomes necessary.
3. No direct automated delete of SharePoint sites.
4. No cross-tenant governance.
