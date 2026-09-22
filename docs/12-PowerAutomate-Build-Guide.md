# 12 - Power Automate Build Guide

**Target:** Solution-aware cloud flows backed by Microsoft Dataverse  
**Last updated:** 2026-09-17

## 1. Build standards

- Create every production flow inside the Governor365 solution.
- Use connection references for Dataverse, Microsoft Teams, Approvals,
  Microsoft 365 Users, SharePoint, and approved HTTP/custom connectors.
- Use environment variables for tenant ID, optional role-source group IDs, base
  URLs, batch size, notification schedule, and feature flags.
- Use child flows for reusable authorization, response, event, and error logic.
- Return structured failures; never turn connector errors into empty successful
  responses.
- Enable secure inputs/outputs on identity, evidence, and connector actions.
- Use concurrency controls and alternate keys to make retries idempotent.

## 2. Flow catalog

The current 2.0 release contains **11 distinct cloud flows**. The package also
contains **22 unique flow-bound agent topics/components** and 23 topic-to-flow
relationships; `OwnerSiteReview` accounts for two relationships because it
invokes both site-detail and request-submission flows. These are references
from agent topics to reusable flows, not additional cloud flows. Do not use
either agent-binding count as the flow inventory.

The catalog below is the target design. Five cataloged flows remain design-only
and are not in the current export: `Inventory - Process Work Item`,
`Inventory - Finalize Scan`, `Notify - Owner Digest`, `Notify - Admin Summary`,
and `Notify - Card Response`. The current package also retains
`GovernanceAgent-CheckAdminRole` for an existing agent binding and packages the
implemented request processor as `Governor365 - Request - Process Pending`.
Consequently, the target-catalog row count is not expected to equal the current
package count until the remaining automation is implemented and the retained
compatibility flow is retired.

| Flow | Trigger | Purpose |
|---|---|---|
| `Governor365 - Agent - List Owner Sites` | Copilot Studio | Return only sites assigned to signed-in owner |
| `Governor365 - Agent - Get Site Detail` | Copilot Studio | Return authorized live Dataverse detail |
| `Governor365 - Agent - List Admin Sites` | Copilot Studio | Return tenant views after admin verification |
| `Governor365 - Agent - Submit Request` | Copilot Studio | Authorize and create governed action request |
| `Governor365 - Agent - Get Request Status` | Copilot Studio | Return caller-authorized request status |
| `Governor365 - Child - Get Caller Capabilities` | Child flow | Resolve immutable caller identity and return minimized general/owner/admin capabilities |
| `Governor365 - Child - Verify Admin` | Child flow | Verify one active GovernanceAdmin Dataverse role assignment |
| `Governor365 - Child - Append Action Event` | Child flow | Create immutable audit event |
| `Governor365 - Inventory - Start Scan` | Recurrence/manual | Create scan run and enumerate source pages |
| `Governor365 - Inventory - Process Work Item` | Dataverse row added | Process bounded inventory batch |
| `Governor365 - Inventory - Finalize Scan` | Dataverse row changed | Complete/reconcile scan |
| `Governor365 - Request - Process` | Dataverse request added | Approval and M365 operation orchestration |
| `Governor365 - Notify - Owner Digest` | Recurrence | Personalized Teams digest |
| `Governor365 - Notify - Admin Summary` | Recurrence | Governance summary and orphan focus |
| `Governor365 - Notify - Card Response` | Teams/Card trigger | Validate and process inline response |

## 3. Agent tool response contract

All Copilot Studio tool flows return:

```json
{
  "success": true,
  "status": "COMPLETED",
  "correlationId": "guid",
  "message": "User-safe summary",
  "recordCount": 0,
  "dataJson": "[]"
}
```

For failures, set `success` to `false`, use a stable status such as
`VALIDATION_FAILED`, `UNAUTHORIZED`, or `CONNECTOR_FAILED`, omit protected data,
and preserve the correlation ID.

## 4. List owner sites

1. Trigger from Copilot Studio with `UserUPN`, `PageSize`, and optional
   `ContinuationToken`.
2. Bind `UserUPN` only to `System.User.PrincipalName`.
3. Normalize with `toLower(trim(...))`; validate shape and configured maximum
   page size.
4. List `Site Owner Assignment` rows where UPN equals the normalized caller and
   `Is Active` is true. Expand the related Governance Site columns required by
   the card.
5. Apply server-side ordering and pagination. Do not load all assignments and
   filter in Copilot Studio or Power Apps.
6. Return minimized fields and a continuation token.
7. On connector failure, return `CONNECTOR_FAILED`; do not return a zero-site
   success.

## 5. Submit request

1. Trigger from Copilot Studio with signed-in caller, request type, Dataverse
   site ID, reason, confirmation method, and idempotency key.
2. Validate allowed request types and required confirmation:
   - archive: explicit confirmation;
   - certify: fresh site read and explicit confirmation;
   - delete review: typed `CONFIRM` in the current turn;
   - assign owner: verified admin plus target owner;
   - support: non-empty reason, site optional.
3. For owner operations, query active Site Owner Assignment using exact caller
   identity and selected site ID.
4. For admin operations, invoke `Governor365 - Child - Verify Admin`.
5. Create or retrieve the request by idempotency key.
6. Create a `Submitted` action event.
7. Return the Dataverse request ID and `PENDING` status. Never claim that an
   archive, deletion, or owner update has already occurred.

Detailed agent contracts live in
`copilot/flows/list-owner-sites-dataverse-flow.txt` and
`copilot/flows/submit-governance-request-dataverse-flow.txt`.

## 6. Request processor

1. Trigger when a Governance Action Request is added.
2. Re-read the request and reject duplicate or terminal records.
3. Append `Authorized` or `Failed` event based on a fresh authorization check.
4. For destructive or privileged operations, create a Power Automate approval
   and set `AwaitingApproval`.
5. On approval, append `Approved`, set `InProgress`, and invoke the least-
   privilege Microsoft 365 operation.
6. Update the site snapshot only after source success.
7. Set the request terminal state and append `Completed`, `Rejected`, or
   `Failed`.
8. Trigger requestor/admin notification independently so notification failure
   cannot falsify the operation state.

## 7. Inventory orchestration

The production implementation is the three-flow contract in
`copilot/flows/inventory-dataverse-flow.txt`. Use
`scripts/Invoke-DataverseGovernanceScan.ps1` only for bootstrap, migration
comparison, manual reconciliation, or break-glass recovery. It writes the same
Dataverse keys and scan-run boundary but is not the recurring production
scheduler.

### Start Scan

1. Create a Governance Scan Run with `Running`.
2. Read policy and batch configuration from Dataverse/environment variables.
3. Enumerate sites through an approved paged Graph or SharePoint administration
   endpoint.
4. Create a Scan Work Item per bounded page/batch.
5. Record source watermark and discovery counts.

### Process Work Item

1. Lock a pending work item by setting it `InProgress`.
2. Fetch its source page.
3. Upsert Governance Site using `(Tenant ID, M365 Site ID)`.
4. Upsert observed owner assignments; deactivate assignments no longer present
   for that site only after the source read succeeds.
5. If direct owner Power Apps access is enabled, reconcile the site's read-only
   Dataverse access-team membership with active licensed owner assignments.
6. Apply deterministic policy rules and write compliance output.
7. Mark work item `Completed` with counts, or `Failed` with retry metadata.

### Finalize Scan

1. Run only when no work items remain pending or in progress.
2. If failures remain, set scan `CompletedWithErrors`; do not mark missing sites
   stale based on an incomplete scan.
3. On complete success, mark unobserved sites stale according to policy.
4. Persist summary counts and completion timestamp.

### Bootstrap and migration scanner

The Dataverse scanner discovers non-OneDrive tenant sites with PnP.PowerShell,
normalizes owner assignments, resolves Dataverse choice values from table
metadata, and writes through the Dataverse Web API. It never writes access
tokens to disk and never updates certification or notification-suppression
columns.

Prerequisites:

1. Create the tables, columns, choices, relationships, and alternate keys from
   `docs/04-DataModel.md`.
2. Install PnP.PowerShell.
3. Grant the operator SharePoint Administrator access for discovery.
4. Grant the operator or automation identity create/read/write on Governance
   Site, Site Owner Assignment, and Governance Scan Run.
5. Sign in with Az.Accounts or Azure CLI for a Dataverse token, or supply a
   short-lived secure string with `-DataverseAccessToken`.

The scanner persists the PnP interactive login in the operating system's secure
token cache so that scanning each site does not require another prompt. Use
`Disconnect-PnPOnline -ClearPersistedLogin` to remove that cached login.

Example:

```powershell
.\scripts\Invoke-DataverseGovernanceScan.ps1 `
  -AdminUrl "https://contoso-admin.sharepoint.com" `
  -DataverseUrl "https://contoso.crm.dynamics.com" `
  -TenantId "00000000-0000-0000-0000-000000000000" `
  -ClientId "00000000-0000-0000-0000-000000000000"
```

Run once with `-WhatIf`, then use `-SiteLimit 5` for a bounded development
write before the first full scan. Keep `IncludeSiteOwnerGroups` enabled for any
inventory used by Owner agent authorization. Disabling it intentionally
captures only M365 group owners and is not an authorization-complete inventory.
Bounded scans never change lifecycle state for unobserved sites.

The scanner marks absent sites `Unknown` only when every discovered site was
processed successfully. Any site or dependency failure closes the scan as
`CompletedWithErrors` and preserves all unobserved lifecycle state.

## 8. Notifications

- Query Dataverse using server-side filters for actionable sites and suppression
  dates.
- Group owner digests by active owner assignment.
- Use Notification Delivery idempotency keys to prevent duplicate sends.
- Store Teams activity IDs and response state.
- Revalidate caller and request state when an Adaptive Card action is received.
- Do not trust hidden card values as authorization.

## 9. Error pattern

Use `Try`, `Catch`, and `Finally` scopes:

- **Try:** validation, authorization, Dataverse/M365 operations, normal response.
- **Catch:** stable error code, sanitized message, durable failure event/work
  item update, failed response.
- **Finally:** telemetry and correlation update that runs for all outcomes.

Configure run-after explicitly for failed, timed-out, and skipped actions.
Operational details go to flow history and protected audit fields, not to the
agent response.

### Caller capability and role verification

1. Resolve system-provided caller identity to an immutable Entra object ID.
2. Determine owner capability from active Site Owner Assignment rows.
3. Determine privileged capabilities from exact active Governance Role
   Assignment rows whose validity window includes the current time.
4. Return only minimized booleans and permitted destination names to the
   orchestrator or Canvas app. Do not return the full role table.
5. Every destination tool repeats its own authorization check; capability
   discovery is navigation, not authorization.
6. Zero role rows denies privileged access. Duplicate, unreadable, or invalid
   rows fail closed and return a correlation ID.

## 10. Acceptance tests

1. Exact owner sees only active assigned sites.
2. Another user's UPN, a partial UPN, and model-provided identity cannot expose
   records.
3. Admin operations fail closed when the role assignment is absent, inactive,
   expired, duplicated, or cannot be read.
4. Duplicate submissions with the same idempotency key produce one request.
5. Delete review requires typed confirmation and approval.
6. Every request state transition has one corresponding action event.
7. Connector failure returns `success=false` with a correlation ID.
8. Inventory retries do not duplicate sites or assignments.
9. Incomplete scans do not incorrectly mark unseen sites stale.
10. Notification retries do not duplicate a delivery for the same period key.
11. Owner Power Apps users cannot read unshared site rows even if app formulas
    or URLs are modified.
