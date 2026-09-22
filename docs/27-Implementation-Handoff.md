# 27 - Governor365 Implementation Handoff

**As of:** 2026-09-19  
**Purpose:** Canonical cross-thread implementation context for continuing work
without repeating discovery or reversing approved decisions.

## 1. Start here

Use this document first in every implementation thread, then consult:

1. [Architecture](02-Architecture.md) for the approved runtime boundaries.
2. [Data model](04-DataModel.md) for table, key, choice, and security details.
3. [Power Automate build guide](12-PowerAutomate-Build-Guide.md) for flow
   contracts.
4. [Deployment status and runbook](25-Deployment-Status-and-Runbook.md) for
   tenant evidence and safe release steps.
5. [Development backlog](26-Development-Backlog.md) for issue dependencies and
   acceptance criteria.

The canonical solution artifacts are:

- `../M365Governance_2_0_0_0.zip` - latest unmanaged tenant export.
- `../M365Governance_2_0_0_0/` - latest unpacked source.
- `../archive/legacy-2026-09-19/M365Governance_1_0_0_1/` - legacy Canvas
  migration source only.
- `../.azure/power-platform-settings.template.json` - safe deployment settings
  template with no environment connection IDs.

Do not treat the legacy SQL Canvas package, SharePoint role list, historical
topics, or design-only flow specifications as deployed 2.0 capability.

### 1.1 Canvas status verified on 2026-09-19

- The pre-implementation `M365Governance` 2.0 export had no Canvas App
  component.
- `Governor365 Site Owner Read` is the intentional Governance Site access-team
  template, not an app. CQAS in its edit URL is only the model-driven app shell
  displaying the Team Template record.
- Every live dashboard app inspected is bound to legacy SharePoint or Azure
  SQL data. None is a valid 2.0 starting artifact to add to the solution.
- `Governor365 Dashboard` was created directly inside `M365Governance`, saved,
  and published as tablet app ID
  `86045adc-9862-4d7e-b14e-25831abf4fc0`.
- The app uses only the Dataverse `Governance Sites` and `Governance Action
  Requests` sources. Its first slice provides live site-name search, a site
  gallery, selection, and a ten-field read-only detail form.
- Preview testing rendered 11 sites, filtered to two for `M365`, and populated
  the selected-site detail. The final solution export contains type `300`
  component `sb_governor365dashboard_b39d0` and the Canvas payload.
- The unpacked published app contains no SQL or SharePoint connector reference.
  Use `../canvas-app/README.md` for formula, connection, and continuation
  details.
- The published screen is named `scrDashboard`; required accessible labels and
  the gallery keyboard tab stop are present. A fresh published download
  returned zero App Checker results.

### 1.2 Persona dashboard status verified on 2026-09-19

- The same solution-owned app now has two screens: `scrDashboard` for
  site/team owners and `scrAdminDashboard` for tenant-wide administration.
- Startup routing checks the signed-in Entra object ID against active,
  currently valid Governance Role Assignment rows. Any valid assignment
  currently selects the administrator experience, matching the approved first
  release scope.
- The Role Assignment query fails closed to the owner screen. This preserves
  the Owner App User role's intentional lack of organization-wide read on the
  role table. Prefer the existing Get Caller Capabilities flow for future
  routing hardening rather than broadening table privileges.
- Owner rows are still determined by Governance Site ownership/access-team
  sharing. Administrators receive tenant-wide rows from the Administrator
  security role. Canvas filtering is navigation, not authorization.
- Owner cards: all accessible sites, needs owners, stale review, external
  sharing, noncompliant, and attestation due.
- Administrator cards: all sites, ownerless, needs owners, stale review,
  external sharing, and noncompliant.
- Published-player admin validation returned 31 all sites, 17 ownerless, 29
  needs owners, 0 stale review, 26 external sharing, and 31 noncompliant.
- All six administrator cards were exercised in the published player. Search
  composed correctly with the Ownerless filter. App Checker reports no formula
  errors and no accessibility findings; five direct Role Assignment lookup
  delegation warnings remain until capability-flow routing is adopted.
- Oversharing by broad principals, actual external-user presence, and
  memberless sites/teams are intentionally deferred until inventory refresh
  stores exact server-derived classifications.
- Owner-route acceptance testing still requires a signed-in user with no
  Governance Role Assignment.
- The final published solution was re-exported to the canonical ZIP and
  unpacked folder. A round-trip unmanaged pack succeeded, and unpacking the
  Canvas payload verified both persona screens, the role data source, startup
  routing, and no SQL or SharePoint connector references.

## 2. Decisions that must be preserved

### 2.1 Experience and hosting

- Governor365 is a required dual experience: conversational agents plus a
  Canvas dashboard.
- Microsoft Teams is the primary unified host.
- Power Apps web is the fallback.
- Microsoft 365 Copilot direct hosting remains a compatibility spike; do not
  assume it can host the Canvas app.
- One Canvas app initially serves general, owner, and admin areas with
  role-aware navigation. UI visibility is not an authorization boundary.

### 2.2 Agent boundaries

- Use a separate **Governance User & Owner Agent** and **Governance Admin
  Agent**.
- An optional **M365 Governance Agent** may act only as a thin launcher/router.
- Capability discovery controls navigation only. Every destination tool must
  independently reauthorize the caller.
- The Admin agent is the privileged trust boundary; do not collapse privileged
  admin operations into the general agent.

### 2.3 Authorization

- `sb_governanceroleassignment` is the runtime authority for application
  roles.
- The legacy SharePoint admin-role list is retired.
- No role row means no privileged role.
- Admin checks use exact immutable Entra object ID, role value, active state,
  and validity window; duplicates fail closed.
- `sb_siteownerassignment` remains the resource-level owner authority.
- Regular signed-in user access is implicit, but owner/admin operations require
  fresh destination authorization.
- Role writes must not be self-service or self-approved.

### 2.4 Data and operations

- Dataverse is the only 2.0 application database.
- Do not add SQL or governance SharePoint list fallbacks.
- Governed writes use durable requests, idempotency keys, explicit
  confirmation, state transitions, and action events.
- `PENDING` and `IN_PROGRESS` must never be described as completed.
- Destructive or privileged operations require human approval.
- If Approvals or another required dependency is unavailable, fail visibly and
  do not execute the operation.
- Action Events are append-only for application identities. The Flow Service
  role has create/read but no update/delete privilege on that table.

### 2.5 Canvas security

- Governance Site is user/team owned and automatic access teams are enabled.
- `Governor365 Site Owner Read` grants Read only.
- Direct owner app access depends on per-site access-team membership plus the
  Owner App User role.
- App formulas and URL parameters never grant row access.
- Summary-card filters must use inventory-populated Dataverse columns for
  expensive or nuanced classifications. Do not calculate broad-principal
  membership or site membership client-side.

## 3. Environment and solution identity

| Item | Value |
|---|---|
| Environment | Sofiane Benabderrahmane's Environment |
| Environment ID | `9417045e-87bb-eac8-bda1-850674b11405` |
| Dataverse URL | `https://orgaa73b06e.crm.dynamics.com` |
| Tenant ID | `8221c52a-2c7f-4da0-8b1f-34c6f692d915` |
| Solution | `M365Governance` |
| Friendly name | Governor365 Power Platform |
| Version | `2.0.0.0` |
| Publisher prefix | `sb` |

Use the connection owner when activating flows. Activating with the
environment-admin token previously failed with `ConnectionAuthorizationFailed`.
The cached tenant-level Azure CLI context for Sofiane can obtain the required
Dataverse token. Restore the normal subscription context after tenant-level
operations.

## 4. Implemented solution inventory

### 4.1 Dataverse

Ten tables are deployed:

1. Governance Site
2. Site Owner Assignment
3. Governance Action Request
4. Governance Action Event
5. Governance Policy Setting
6. Governance Scan Run
7. Scan Work Item
8. Notification Delivery
9. Evidence Snapshot
10. Governance Role Assignment

Documented local choices and alternate keys are present. Required auditing is
enabled and tenant re-export verified for the business-critical tables and
columns.

Governance Role Assignment includes:

- `GovernanceAdmin` = `126390000`
- `GovernanceAuditor` = `126390001`
- `GovernanceOperator` = `126390002`
- `RequestApprover` = `126390003`
- `SupportAgent` = `126390004`

Its active alternate key is principal object ID plus role. One approved
development GovernanceAdmin assignment exists; environment role data is not
embedded in the solution.

### 4.2 Security roles and access teams

The solution contains:

- Governor365 Owner App User
- Governor365 Administrator
- Governor365 Auditor
- Governor365 Flow Service
- Governor365 Maker

The read-only site access-team template is exported with the solution.
`../scripts/Sync-GovernanceSiteAccessTeams.ps1` is idempotent and currently
reconciles 14 memberships across 13 site teams. Two active assignments remain
unmapped because their principals have no Dataverse system-user row:

- `alim@mngenvmcap733570.onmicrosoft.com`
- `ms-breakglass@mngenvmcap733570.onmicrosoft.com`

### 4.3 Environment variables

- `sb_Governor365TenantId`
- `sb_GovernanceAdminGroupId`
- `sb_SharePointAdminUrl`
- `sb_InventoryBatchSize`
- `sb_MaximumAgentPageSize`
- `sb_NotificationSchedule`
- `sb_EnableDirectOwnerAppAccess`
- `sb_EnableAdvisorTools`
- `sb_PowerAppBaseUrl`
- `sb_GovernorAgentUrl`

The optional admin group is a reconciliation input only. Dataverse remains the
runtime role authority.

### 4.4 Connection references

- `sb_sharedcommondataserviceforapps`
- `sb_sharedoffice365users`
- `sb_sharedsharepointonline`
- `sb_sharedteams`
- `sb_sharedapprovals`
- `sb_sharedmicrosoftcopilotstudio`

All available development connections are bound except Approvals. Do not enable
approval-dependent execution until that reference has a connected Approvals
connection.

### 4.5 Power Automate flows

| State | Flow | Workflow ID | Implemented behavior |
|---|---|---|---|
| Active | Governor365 - Agent - Verify Admin | `03fcfb0f-b6b3-f111-aaac-000d3a367627` | Exact active/in-window GovernanceAdmin verification |
| Active | Governor365 - Agent - Get Caller Capabilities | `16ec72cb-b8b3-f111-aaac-000d3a367627` | Minimized owner/admin navigation capabilities |
| Active | Governor365 - Agent - List Owner Sites | `68784ae7-b8b3-f111-aaac-000d3a367627` | Exact active owner isolation, bounded paging, continuation input/output |
| Active | Governor365 - Agent - Get Site Detail | `4190243f-b9b3-f111-aaac-000d3a367627` | Fresh exact owner or admin authorization |
| Active | Governor365 - Agent - List Admin Sites | `364a1e5b-b9b3-f111-aaac-000d3a367627` | Admin-only filters for summary, office, action, freshness, and continuation |
| Active | Governor365 - Agent - Submit Request | `7f675f00-bab3-f111-aaac-000d3a367627` | Validation, confirmation, authorization, idempotency, durable request, Submitted event |
| Active | Governor365 - Agent - Get Request Status | `e8e5cfdb-b9b3-f111-aaac-000d3a367627` | Requester/admin-authorized minimized status |
| Active | Governor365 - Child - Append Action Event | `da5804b2-bdb3-f111-aaac-000d3a367627` | Internal event validation and append; not an agent tool |
| Active | Governor365 - Request - Process Pending | `a14ed1e0-bbb3-f111-aaac-000d3a367627` | Fresh authorization, certification, support queueing, explicit dependency/connector failures |
| Draft/off | Governor365 - Inventory - Start Scan | `2e7ba87e-bfb3-f111-aaac-000d3a367627` | SharePoint count discovery and deterministic bounded page work items |

Process Pending runs every 15 minutes. Current safe behavior:

- certification: authorize, start, update site attestation, complete, append
  ordered events;
- support: authorize and move to `IN_PROGRESS`;
- revoked authorization: fail with `AUTHORIZATION_REVOKED`;
- archive, deletion review, and owner assignment: fail with
  `APPROVAL_CONNECTION_UNAVAILABLE` until Approvals is connected;
- connector/persistence failure: fail with `PROCESSOR_CONNECTOR_FAILED`.

Start Scan remains off. Its isolated live test discovered 30 SharePoint sites
and created one page-0 work item. The worker and finalizer do not yet exist.

## 5. Verification evidence

The following were run successfully against live Dataverse:

- `../scripts/Test-GovernanceRoleAuthorization.ps1`
  - 6/6 passed: approved, missing, inactive, expired, future, duplicate.
- `../scripts/Test-GovernanceRequestLifecycle.ps1`
  - 6/6 passed: admin, unauthorized, confirmation, idempotency, transition
    events, terminal state.
- `../scripts/Sync-GovernanceSiteAccessTeams.ps1`
  - second run: zero added, zero removed, two explicitly unmapped principals.
- live processor scenarios:
  - certification completed with Submitted, Authorized, ExecutionStarted, and
    Completed events;
  - revoked authorization failed;
  - support moved to InProgress;
  - approval dependency failed closed;
  - scoped run-after regression passed.
- owner/admin direct-query isolation and filter tests.
- a 361-character Dataverse skip token returned the next distinct row.
- Start Scan discovered 30 sites and created one deterministic work item.
- all request/scan test fixtures were removed; the pending request queue and
  test scan rows were verified empty.

Fresh unmanaged and Dataverse-generated managed packages both passed Solution
Checker with zero critical, high, medium, low, or informational findings. The
managed package is a session artifact and should be freshly exported before a
test import.

## 6. Known boundaries and blockers

| Blocker | Effect | Required owner action |
|---|---|---|
| No Approvals connection | Privileged request operations cannot proceed | Create/connect Approvals and bind `sb_sharedapprovals` |
| Power Apps Studio interactive sign-in required | Canvas cannot be rebound from SQL to native Dataverse through PAC | Open Studio, add secured Dataverse sources/flows, save, export |
| PAC cannot update existing agents or bind flow tools | Live agents still contain legacy/scaffold topics | Bind the active flows in Copilot Studio, remove/disable scaffold topics, publish |
| No dedicated test environment | Managed import and portable connection validation cannot be completed safely | Provision or identify a non-production test environment |
| Two principals lack Dataverse users | They cannot receive direct Canvas site sharing | Provision/license users or deactivate obsolete assignments |
| Workspace is not a Git repository | Backlog cannot be created as actual GitHub issues here | Open the repository workspace or supply repository identity |

The Canvas SQL package is intentionally not in the 2.0 solution. Do not publish
it as a workaround.

## 7. Remaining implementation order

### Thread A - Approvals and privileged request processing

1. Create and bind the Approvals connection.
2. Add AwaitingApproval, Approved, Rejected, execution, terminal, and
   notification events.
3. Implement least-privilege archive, deletion-review, and owner-assignment
   operations.
4. Add approval, rejection, retry, duplicate-operation, and connector-failure
   tests.

### Thread B - Inventory

1. Implement Process Work Item using the validated SharePoint HTTP search
   response at
   `body.PrimaryQueryResult.RelevantResults.Table.Rows`.
2. Upsert Governance Site by tenant ID plus SharePoint SiteId.
3. Reconcile owners and access teams without deactivating owners after a
   partial/failed page.
4. Implement Finalize Scan and `CompletedWithErrors`.
5. Run two-scan reconciliation and scale tests.

### Thread C - Canvas and Teams

1. Open the legacy app in Power Apps Studio.
2. Remove every SQL data source.
3. Add Governance Site and governed flow bindings.
4. Preserve browse/search/filter/sort/detail UX.
5. Add general, owner, and admin areas with role-aware navigation.
6. Verify delegated queries and row-access bypass resistance.
7. Add the app to 2.0, publish it, and package the Teams personal app/tab.
8. Add bidirectional app/agent deep links.

### Thread D - Copilot Studio

1. Bind User/Owner tools: capabilities, owner sites, detail, submit, status.
2. Bind Admin tools: verify admin, admin sites, detail, submit, status.
3. Remove or disable hard-coded scaffold topics.
4. Preserve separate User/Owner and Admin trust boundaries.
5. Publish and capture positive/negative execution transcripts.

### Thread E - Notifications

1. Implement Notification Delivery idempotency, suppression, and retry.
2. Build owner digest and admin summary flows.
3. Build authenticated Adaptive Card response handling.
4. Keep notification state independent from request operation state.

### Thread F - ALM and release

1. Export fresh unmanaged and managed packages.
2. Import managed into a dedicated test environment with settings.
3. Run persona, paging, delegation, accessibility, failure, and portability
   acceptance.
4. Package Teams and validate links.
5. Rehearse rollback before production cutover.

Advisors remain disabled until the operational foundation is stable.

## 8. Copy-ready prompts for other chat threads

### Approvals thread

> Read `docs/27-Implementation-Handoff.md`, `docs/12-PowerAutomate-Build-Guide.md`,
> and DEV-015 through DEV-018 in `docs/26-Development-Backlog.md`. Continue the
> request lifecycle from the current active flows. Preserve Dataverse role
> authorization, fail-closed behavior, idempotency, and append-only events.
> Do not use SQL or the legacy SharePoint admin list.

### Inventory thread

> Read `docs/27-Implementation-Handoff.md` and DEV-019 through DEV-023. Start
> from the validated draft Start Scan flow. Implement Process Work Item and
> Finalize Scan using bounded SharePoint pages, retryable work-item state, safe
> owner reconciliation, and no false stale marking after incomplete scans.

### Canvas/Teams thread

> Read `docs/27-Implementation-Handoff.md`, `canvas-app/README.md`, and DEV-013
> plus DEV-033. Modernize the 1.0 Canvas UX using native secured Dataverse and
> governed flows only. Do not retain SQL. Implement owner/admin experiences,
> delegation and bypass tests, solution inclusion, Teams packaging, and deep
> links.

### Copilot thread

> Read `docs/27-Implementation-Handoff.md`, `docs/03-AgentDesign.md`, and
> `docs/22-Agent-Orchestration-Architecture.md`. Bind the already-active tools
> to separate User/Owner and Admin agents, remove scaffold topics, preserve
> destination reauthorization, publish, and capture positive/negative
> transcripts.

### Release thread

> Read `docs/27-Implementation-Handoff.md` and
> `docs/25-Deployment-Status-and-Runbook.md`. Use a dedicated non-production
> environment. Export a fresh managed package, import with environment
> settings, run the acceptance matrix, and do not cut over while Canvas,
> Copilot bindings, Approvals, inventory, or notification gates remain open.
