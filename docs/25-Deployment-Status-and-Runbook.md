# 25 - Deployment Status and Runbook

**Release date:** 2026-09-17  
**Target environment:** Sofiane Benabderrahmane's Environment  
**Environment ID:** `9417045e-87bb-eac8-bda1-850674b11405`

For a self-contained continuation package suitable for another chat or
workstream, start with
[27-Implementation-Handoff.md](27-Implementation-Handoff.md).

## PCF agent chat implementation - 2026-09-19

- Added PCF SSO token exchange in version 0.3.0. The control uses the signed-in
  Power Apps user's UPN as an MSAL login hint, silently requests App A's
  `access_as_user` scope through App B, intercepts Copilot Studio OAuth cards,
  and posts `signin/tokenExchange`. It preserves the login card as a secure
  fallback when silent SSO isn't available.
- App B must register `https://runtime-app.powerplatform.com/` as a SPA
  redirect URI. The PCF executes on that origin; using the outer Canvas player
  URL causes MSAL hidden-iframe token acquisition to time out.
- Version 0.3.1 keeps the Direct Line polling transport alive when Web Chat
  transiently disconnects during Canvas host composition. The transport is
  still closed when the owning React effect is disposed.
- Version 0.3.2 intercepts the OAuth Login card and uses an MSAL popup to
  complete manual authentication when silent SSO cannot reuse the Power Apps
  session. Version 0.3.3 treats an MSAL hidden-iframe timeout as an expected
  interactive fallback and recognizes the rendered Login action.
- Live validation confirmed that the Login action opens the MSAL popup. The
  first attempt exposed `AADSTS50011` because App B contained only the outer
  Canvas player URI. On September 21, 2026,
  `https://runtime-app.powerplatform.com/` was added as a **Single-page
  application** redirect URI while preserving the existing player URI. Entra
  and Azure CLI both confirm the two registered SPA redirect URIs. A
  session-authenticated authorization-code probe then returned through the
  runtime URI with an authorization code and no AADSTS error.
- The two Entra registrations and delegated consent were verified on
  2026-09-20. The implicit access-token and ID-token issuance switches are not
  required for the authorization-code-with-PKCE flow. Set the Copilot Studio
  token exchange URL to
  `api://5ed8c4be-0464-434a-b2b6-55bc6953ce3b/access_as_user`.
- Implemented `Governor365.AgentChat`, a React PCF control that hosts Bot
  Framework Web Chat and obtains short-lived Direct Line tokens from the
  Copilot Studio Mobile App channel endpoint.
- Added versioned Canvas context synchronization, connection diagnostics, and
  validated agent-to-Canvas action events.
- Added `pcf/M365GovernanceSolution/M365GovernanceSolution.cdsproj` to inject
  the PCF into the canonical `M365Governance_2_0_0_0.zip` package. The package
  now keeps the Canvas app, agents, flows, Dataverse components, environment
  variables, and code component in one solution boundary.
- Retained the control-only `Governor365AgentChatSolution` project for isolated
  development diagnostics only; it is not a Governor365 release artifact.
- Added `sb_CopilotMobileTokenEndpoint` to the canonical solution source and
  deployment settings template.
- Production dependencies report zero known vulnerabilities. Protocol tests,
  lint, optimized build, and the integrated canonical solution build pass.
- Verified the canonical package contains the type-66
  `sb_Governor365.AgentChat` root component alongside the type-300
  `sb_governor365dashboard_b39d0` Canvas app, 16 bot files, 210 bot-component
  files, 11 workflows, and 11 environment-variable files.
- Imported and published the integrated unmanaged package successfully in the
  development environment. Import operation
  `394cc2d4-30b4-f111-aaac-000d3a367627` completed successfully.
- Removed the unused Fluent platform-library declaration after the first import
  showed that Fluent 9.68.0 is not an accepted manifest version in the target
  environment. React 16.14.0 remains platform-provided, and the corrected
  package imports successfully.
- Enabled Canvas code components at the organization level, imported the
  control, and wired `AgentChatOwner` and `AgentChatAdmin` into the owner and
  administrator screens. Power Apps Studio reports no formula errors.
- Added selected-site context synchronization, user and locale inputs,
  connection-error handling, and allowlisted `openSite` and `refreshSites`
  actions. The published app source is retained under `canvas-app/src`.
- Fixed a Direct Line lifecycle defect by not passing the token endpoint's
  unstarted `conversationId` to the SDK. Version 0.1.1 was imported, selected
  through Studio's **Update code components** prompt, saved, and published.
  Both controls now report `Connectivity Status: Connected`; the old reconnect
  404 and deprecated upload-setting warning are gone.
- The `Governor M365` agent now uses **Authenticate manually** with Microsoft
  Entra ID. The exported solution preserves the manual-authentication
  connection and the **Always** authentication trigger. End-to-end Direct Line
  validation is still required after each import and publish.
- The manually authenticated `Governor M365` launcher contains no connected
  Copilot chat actions. Copilot Studio permits those actions to publish only
  with Integrated authentication, which is incompatible with the PCF channel's
  required manual authentication. The solution build runs
  `scripts/Test-ConnectedAgentAuthentication.ps1` before packaging to prevent
  `ConnectedAgentAuthMismatch` from being reintroduced by later agent exports
  or parallel workstreams.
- Direct Canvas reads of the environment-variable definition/value system
  tables returned `Error: Network`. The development app therefore binds the
  verified non-secret Mobile App token endpoint directly. Production ALM must
  substitute the environment endpoint during deployment or expose it through
  a supported configuration API/flow.
- Copilot Studio context topics and authenticated end-to-end action tests
  remain environment-specific release steps. Follow
  [28-PCF-Agent-Chat-Integration.md](28-PCF-Agent-Chat-Integration.md).
- Final canonical unmanaged package:
  `M365Governance_2_0_0_0.zip`; SHA-256
  `ACDA175EEFC648157A36D41CAE9BA50EA158B91572C48E7EDFDA204549806F12`.
- Exact-site review is owned by the Owner Operations child for both active
  site owners and GovernanceAdmin callers. Canvas submits only the selected
  record ID; the child flow retrieves and authorizes the live Dataverse row.
- Persona screen startup does not automatically request a portfolio or admin
  dashboard. Those list operations run only when explicitly requested.
- Live selected-site validation returned the exact
  `c409b1c0-a8b2-f111-aaac-000d3a367627` record without an ID prompt or an
  admin dashboard response.
- **Start governed action** uses the same exact-site authorization path and
  renders buttons for Certify, Archive, Deletion review, Assign owners, and
  Cancel. Each non-cancel choice now collects a business reason and current-turn
  confirmation, then invokes `Governor365 - Agent - Submit Request`. Deletion
  review requires typed `CONFIRM`; owner assignment also collects the target
  owner's work email and requires GovernanceAdmin authorization. Successful
  submission creates a Governance Action Request plus its Submitted event and
  returns durable tracking identifiers. Submission never claims the underlying
  Microsoft 365 operation is complete.
- The expanded action graph imported successfully and Governor M365 published
  at `2026-09-22T04:32:34Z`. Dataverse reported publish status `Succeeded`
  with zero diagnostics. The deployed Site Review component contains the
  Submit Request binding and all four request types, with no mock-only branch.
- The recurring request processor is active in both the live environment and
  canonical workflow metadata. The build guard fails if a future export marks
  it inactive.
- A release-readiness review on 2026-09-22 confirmed that the solution contains
  11 distinct cloud flows. The integrity guard's earlier count of 22 referred
  to unique flow-bound agent topics/components, where several topics reuse the
  same flow; it did not indicate 22 separate cloud flows. There are 23
  topic-to-flow relationships because `OwnerSiteReview` invokes two flows.
- The review found and deleted the superseded active
  `OwnerGovernedAction` mock-only topic from the development environment. The
  production `OwnerSiteReview` path remains and submits governed requests
  through `Governor365 - Agent - Submit Request`.
- After publishing the deletion, fresh Dataverse-generated unmanaged and
  managed exports were created. Share
  `M365Governance_2_0_0_0_managed.zip` with downstream environments; retain
  `M365Governance_2_0_0_0.zip` for development/source synchronization.
- The distributable managed package SHA-256 is
  `41B18FAFE3A6576E1C89F3611FA1154CD7B3239D5F6692E33E852402700C731E`.
  Power Apps Solution Checker reports zero critical findings, zero high
  findings, and one medium aggregate finding for five Canvas formula issues.
  Review those five warnings in Power Apps Studio App Checker after import;
  the command-line Canvas validator is not a substitute because it applies an
  incompatible schema to this app's generated source format.

## Downstream managed deployment package

Distribute these two files together:

1. `M365Governance_2_0_0_0_managed.zip` - the Dataverse-generated managed
   solution for test and production imports.
2. `.azure/power-platform-settings.template.json` - the list of environment
   variables, connection references, and agent-sharing values that the
   receiving administrator must configure. Do not distribute a copy populated
   with connection IDs, tenant IDs, endpoints, or group IDs from another
   environment.

The managed package contains 10 Dataverse tables, five security roles, 11
distinct cloud flows, one Canvas app, eight Copilot Studio agents, 105 bot
components, 11 environment variables, six connection references, one access
team template, and the `Governor365.AgentChat` PCF control. Twenty-two unique
agent topics/components reference those 11 flows through 23 relationships.

For each receiving environment:

1. Import the managed ZIP into an environment with Dataverse.
2. Bind all six connection references to receiving-environment connections.
   The Approvals reference must be bound before approval-backed request types
   can succeed.
3. Set every receiving-environment URL, tenant/group ID, schedule, and feature
   flag represented in the settings template. Keep advisor tools and direct
   owner app access disabled until their authorization prerequisites pass.
4. Publish all customizations, verify the Canvas app and eight agents are
   present, and update the PCF control in Power Apps Studio if prompted.
5. Review the five medium Canvas formula warnings in Studio App Checker, then
   save and publish the app.
6. Turn on only the flows whose connectors and configuration are ready.
   `Governor365 - Inventory - Start Scan` intentionally remains off until its
   Process Work Item and Finalize Scan flows are implemented.
7. Run the functional cutover validation below before sharing the app or
   agents with users.

## Canvas dashboard and Team Template verification - 2026-09-19

- The pre-implementation live export of `M365Governance` version `2.0.0.0`
  contained the `Governor365 Site Owner Read` access-team template and no
  Canvas App root component or `CanvasApps/` payload.
- The Team Template is intentional. It grants Read-only access to individual
  Governance Site rows and supports the owner dashboard security model.
- The `appid` in a Team Template edit URL selects the model-driven app shell
  used to render the generic Dataverse record form. Seeing the record in CQAS
  does not mean that the template belongs to CQAS and does not indicate a
  Canvas App.
- Live Canvas Apps named `GovDash`, `SPO-Remediation-Dashboard`,
  `SPO Sites Gov Dashboard`, `MySites Dashboard v3`, and related variants are
  legacy SharePoint or Azure SQL implementations. They must not be added to
  the Power Platform-first 2.0 solution.
- Created the tablet app `Governor365 Dashboard` directly inside
  `M365Governance`. Its app ID is
  `86045adc-9862-4d7e-b14e-25831abf4fc0`.
- Bound the app to the current-environment Dataverse tables `Governance Sites`
  and `Governance Action Requests`; the final unpacked app contains no
  `shared_sql` or `shared_sharepointonline` connection.
- Added and published the initial read-only dashboard slice: site-name prefix
  search, site gallery, selection, and a ten-field Governance Site detail
  form. Preview validation rendered 11 records, reduced the gallery to two for
  `M365`, and populated the detail form after selecting a result.
- Renamed the screen, added accessible labels and gallery keyboard navigation,
  and verified a fresh published download with zero App Checker results.
- Re-exported and unpacked the live solution after publishing. `Solution.xml`
  contains the type `300` root component
  `sb_governor365dashboard_b39d0`, and `CanvasApps/` contains the packaged app.
- Formula and connection verification details are documented in
  `../canvas-app/README.md`.

### Persona dashboard update - 2026-09-19

- Added Governance Role Assignments as a current-environment Dataverse source.
- Added `scrAdminDashboard` while retaining `scrDashboard` for site/team
  owners.
- Added fail-closed startup routing by immutable Entra object ID, active flag,
  and assignment validity window. Any currently valid Governance Role
  Assignment selects the administrator screen; an absent row or denied role
  query selects the owner screen.
- Preserved Dataverse as the authorization boundary. Owner App User has Basic
  Governance Site read and no Governance Role Assignment read; Administrator
  has organization-wide read for both tables.
- Added clickable owner and administrator summary cards backed by existing
  inventory fields. Cards compose with the existing site-name search.
- Published-player validation routed the assigned test administrator to the
  tenant-wide screen and rendered live counts: 31 all sites, 17 ownerless, 29
  below the two-owner standard, 0 stale-review recommendations, 26 with
  external-sharing capability, and 31 noncompliant.
- Clicking **Ownerless** replaced the all-site gallery with the ownerless
  result set. All six administrator cards were exercised in the published
  player; the zero-count stale card returned an empty gallery and the other
  cards returned their expected result sets. An Ownerless-plus-Communication
  search returned the single matching site.
- App Checker reports no formula errors and no accessibility findings after
  adding tab stops and visible focus borders to the persona labels. Five
  startup-lookup delegation warnings remain documented technical debt.
- Exact broad-principal oversharing, actual external-user presence, and
  memberless-site/team classifications remain inventory-enrichment work; the
  dashboard does not approximate them from sharing capability.
- The requested two-owner standard differs from the historical
  `MinOwnerCount = 1` initialization and must be reconciled before introducing
  a persisted below-standard flag.
- A no-role owner account is still required for an end-to-end owner-route and
  row-scope acceptance test. The current test identity has an active role
  assignment.
- Re-exported the final published live solution, replaced
  `M365Governance_2_0_0_0.zip` and its unpacked source, and successfully packed
  the canonical source back into an unmanaged solution.

### Dashboard visual refresh - 2026-09-19

- Published a dark, Teams-oriented visual treatment for both owner and
  administrator screens.
- Rebalanced the main workspace to a compact 320-pixel site-results column, a
  wider detail pane, and a 422-pixel Copilot panel.
- Reduced gallery rows from 104 to 72 pixels, removed the unused image slot,
  and tightened typography without changing the existing search or selection
  behavior.
- Restyled summary cards with distinct severity colors: red for ownerless and
  noncompliant conditions, orange/amber for ownership and stale review,
  cyan for external sharing, and indigo for the all-sites baseline.
- Updated the Agent Chat PCF to version `0.1.2` with matching dark Web Chat
  surfaces and accessible high-contrast text.
- The PCF test suite, lint, production build, unified solution build, solution
  import, explicit Canvas publish, and live-player rendering all succeeded.
- Analytics remains intentionally separate from the operational workspace.
  Add a dedicated Analytics screen or Teams tab when reporting requirements
  are finalized; use Power BI for historical/drill-through reporting and
  native Canvas charts only for lightweight current-state metrics.

## Implementation update - 2026-09-18

- Exported the live unmanaged `M365Governance` solution version `2.0.0.0` to
  `M365Governance_2_0_0_0.zip`.
- Unpacked the verified source to `M365Governance_2_0_0_0/`.
- Confirmed the initial package contained nine Dataverse tables plus five
  advisor bots and matching bot components.
- Verified all documented table columns, local choice values, and alternate
  keys are present.
- Enabled table and business-column auditing for Governance Site, Site Owner
  Assignment, Governance Action Request, and Governance Policy Setting.
- Power Apps Solution Checker reported zero findings for the auditing update.
- Imported and published the update successfully, then re-exported it and
  verified that auditing persisted. Dataverse correctly kept platform-managed
  ownership and time-zone fields non-auditable.
- Verified that the unpacked solution can be packed back into a valid unmanaged
  package.
- Added Governance Role Assignment as the tenth table and made it the
  authoritative application-role registry. Its immutable-principal-plus-role
  alternate key is active, auditing is enabled, and one approved development
  GovernanceAdmin assignment was migrated. Role data is environment data and
  is not embedded in the solution package.
- Added ten environment-variable definitions and six unbound connection
  references. Generated `.azure/power-platform-settings.template.json` for
  environment-specific deployment values and connection IDs.
- Added and activated seven solution-aware Dataverse-backed flows under the
  connection owner: Verify Admin, Get Caller Capabilities, List Owner Sites,
  Get Site Detail, List Admin Sites, Submit Request, and Get Request Status.
- Submit Request enforces exact request tokens and confirmation, authorizes
  owner/admin/support paths, returns an existing request for a repeated
  idempotency key, creates one durable request, and appends its Submitted
  action event. Get Request Status reauthorizes requester/admin access and
  returns no protected data on denial.
- `scripts/Test-GovernanceRoleAuthorization.ps1` passes six positive and
  negative role cases. `scripts/Test-GovernanceRequestLifecycle.ps1` passes
  six live request authorization, exact-confirmation, idempotency, event
  completeness, and terminal-state cases and removes its fixtures.
- All privileged flow definitions now authorize against Governance Role
  Assignment by immutable Entra object ID. The Admin Dashboard flow resolves
  its system-derived UPN through Office 365 Users before querying the role
  table using the environment's embedded connection, so Canvas users are not
  prompted for separate Office 365 connector consent. The legacy
  CheckAdminRole flow no longer reads the SharePoint configuration list.
  `scripts/Test-PrivilegedFlowAuthorization.ps1` enforces this contract during
  every solution build.
- Re-exported the tenant solution after activation and corrections. Solution
  Checker reported zero critical, high, medium, low, or informational findings.
- Approval-dependent processing remains fail-closed because the target
  environment does not yet have a connected Approvals connector connection.
- Added five solution-aware security roles: Owner App User, Administrator,
  Auditor, Flow Service, and Maker. Flow Service has no update/delete privilege
  on Action Event.
- Enabled automatic access teams on Governance Site and added the
  `Governor365 Site Owner Read` template with Read access only. The
  idempotent access-team sync currently reconciles 14 memberships across 13
  site teams. Two active assignments (Alim and the break-glass principal)
  cannot be shared because they do not have a Dataverse system-user row.
- Added and activated `Governor365 - Request - Process Pending` on a 15-minute
  recurrence. It performs fresh authorization, completes certification with
  ordered events, moves support into progress, persists connector failures,
  and fails archive/delete/owner-assignment requests explicitly with
  `APPROVAL_CONNECTION_UNAVAILABLE` rather than executing without approval.
- The child-owned exact-site action experience now submits all four governed
  request types through this lifecycle. Certification can complete through the
  existing Dataverse processor. Archive, deletion review, and owner assignment
  remain fail-closed until the Approvals connection and their least-privilege
  Microsoft 365 execution connectors are provisioned and validated.
- Live processor fixtures passed certification, revoked authorization, support,
  missing-Approvals, and scoped run-after regression cases. Test requests and
  events were removed, the modified site snapshot was restored, and the
  pending queue was verified empty.
- Added continuation-token input and output handling to List Owner Sites and
  List Admin Sites. A live 361-character Dataverse skip token returned the
  next distinct row. List Admin Sites now also supports exact office,
  recommended-action, and bounded stale-observation filters.
- Added and activated the internal Append Action Event child flow. It validates
  event values and request existence and is not exposed as an agent tool.
- Added Start Scan as a draft flow. Its isolated live test discovered 30
  SharePoint sites and created one deterministic page-0 work item; all test
  scan rows were removed. The flow remains off until Process Work Item and
  Finalize Scan are implemented and tested.
- Produced a Dataverse-generated managed solution package in session artifacts
  and ran Solution Checker with zero findings. No dedicated test environment
  is available; the visible alternatives are default/development or
  production-named environments, so managed import was not attempted there.

## Current external blockers

- The target environment has no connected Approvals connector connection.
  Archive, deletion-review, and owner-assignment processing therefore fail
  closed with `APPROVAL_CONNECTION_UNAVAILABLE`.
- The installed PAC CLI can extract/create/publish agents but cannot update an
  existing agent or bind cloud-flow tools. The live Owner template still
  contains scaffold topics, so interactive Copilot Studio binding is required.
- Two active owner principals lack Dataverse system-user rows and cannot be
  added to site access teams until they are provisioned/licensed.
- No dedicated test environment is available for the required managed import.

## Release objective

Publish the latest Power Platform-first design without representing
design-only Dataverse or Power Automate components as deployed capability, and
publish the matching source and documentation to GitHub.

## Release result

> **2026-09-21 authentication correction:** Governor M365 retains manual Entra
> authentication for the embedded PCF channel and contains no connected
> Copilot chat actions. Copilot Studio supports those actions only with
> Integrated authentication. The unmanaged solution was imported successfully,
> six stale connected-agent components were removed, all customizations were
> published, and Governor M365 was explicitly republished. Live Dataverse
> verification confirmed a successful synchronized launcher publication and
> zero connected-agent actions. The stale Owner topic-to-workflow relationship
> was subsequently removed, the final live export reports zero missing
> dependencies, and the canonical package was refreshed with PCF 0.3.3 and the
> published Canvas app. The build now enforces both connected-agent and package
> integrity guards. The MSAL popup is operational; after correcting App B's SPA
> redirect URI, the published Canvas app completed the final token-exchange and
> child-routing smoke tests.

> **2026-09-21 child-agent migration:** Governor M365 now has seven enabled
> local child agents: Owner Operations, Admin Operations, and five bounded
> advisors. Governor's instructions are handoff-only. Owner Operations owns a
> `My Sites` topic bound to `List Owner Sites`; Admin Operations owns an
> `Admin Dashboard` topic bound to `List Admin Sites`. The child graph
> published successfully under Governor's existing manual Entra
> authentication. An advisor routing test applied the specialist's
> evidence-freshness guardrails, and an Owner routing test reached the
> child-owned flow path. Canvas parity then passed for Owner Operations and
> Admin Operations, so the two root copies were disabled and retained only for
> rollback. The refreshed package has zero active connected-agent routes, zero
> missing dependencies, and 21
> validated flow-bound components.

- GitHub `main` was updated on 2026-09-17 with the reviewed agent source,
  Dataverse flow contracts, architecture media, canonical documentation, and
  hackathon materials.
- The Owner and Admin deployable source instructions were aligned and validated
  locally.
- Owner and Admin child publication is complete. Their current child-owned
  operational topics use the deployed Dataverse-backed list flows. Remaining
  site-detail and governed-request capabilities must be attached to the
  operational children before those broader scenarios are cut over.
- The installed PAC CLI can list, publish, and extract templates but does not
  provide the guarded `copilot pull`/`push` commands used by the repository
  deployment helper. A push-capable Copilot Studio source workflow must be
  restored before the reviewed package can be released.

## Solution consolidation

On 2026-09-17, the five domain advisor agents were added with their required
bot components to the `M365Governance` solution (`Governor365 Power Platform`,
version `2.0.0.0`). A fresh export verified that the solution contains the nine
Dataverse tables, five bots, and five bot components.

The superseded `Governor365` solution container was then deleted after retaining
an unmanaged backup export. Its legacy SharePoint table and model-driven app
were not added to the Power Platform-first solution. Tenant queries and exports
found no cloud-flow root component in that solution, so no flow was migrated
from it. Legacy flows in other historical packages must not be represented as
Dataverse-ready tools; only replacement flows implementing the reviewed
contracts belong in `M365Governance`.

## Verified tenant inventory

| Component | ID | Verified state |
|---|---|---|
| Governor M365 | `d610fa66-3e1e-f111-8341-6045bd088c4f` | Published, active, provisioned |
| Governance Owner Agent | `18c2cb08-2014-47a3-8c0c-5baeecf4f5e3` | Published, active, provisioned |
| Governance Admin Agent | `c7eea6a2-3fc0-4e3a-8ebb-56ff7a390033` | Published, active, provisioned |
| Governance Policy Advisor | `0af1ffd3-d69a-4313-9bcb-05c91c19ffd6` | Published shell; production tools disabled |
| Copilot Readiness Advisor | `a303e7c0-110d-4f10-9736-53dd7c51b040` | Published shell; production tools disabled |
| Data Protection Advisor | `7f9c6873-cf91-455e-95f7-86321e2f84a3` | Published shell; production tools disabled |
| Identity Governance Advisor | `7f385fc4-d4a2-42f0-b9e7-0890096b6fed` | Published shell; production tools disabled |
| Security & Compliance Assurance | `ad57f320-41aa-4e1b-8b85-e432ba139ebc` | Published shell; production tools disabled |
| Owner Operations child | `8b46259c-40d3-4978-a2a1-3aa53951bf88` | Published beneath Governor M365; child-owned My Sites topic |
| Admin Operations child | `b3f1adcc-13b6-f111-aaac-000d3a367627` | Published beneath Governor M365; child-owned Admin Dashboard topic |
| Five advisor children | Governor-local bot components | Published beneath Governor M365; read-only bounded guidance |

## Source release

The Owner and Admin deployable instruction files now:

- use Dataverse-backed, solution-aware Power Automate tools as the only target
  data and request path;
- derive identity from `System.User.PrincipalName`;
- fail closed when authorization or a required tool is unavailable;
- prohibit fallback to Azure SQL and governance SharePoint lists;
- restore owner certification as a governed request after a fresh owner check
  and explicit confirmation;
- require typed `CONFIRM` for deletion review; and
- prohibit fabricated records, request IDs, and successful outcomes.

Flow contracts in `copilot/flows` are implementation specifications. They are
not evidence that corresponding flows are active in the target environment.

## Current cutover boundary

The Dataverse operational cutover and child-agent migration are deployed. The
following production-promotion gates remain open:

1. complete Dataverse security roles and the owner access-team template, then
   verify lookup relationships in a managed test import;
2. monitor the published child-only operational routes, then remove the two
   disabled root rollback topics after the rollback window;
3. bind any remaining site-detail, request-submission, and request-status tools
   directly beneath the operational children;
4. rerun owner-isolation, unauthorized-admin, confirmation, idempotency, error,
   and audit-event tests;
5. keep the exported/unpacked Governor365 2.0 source synchronized after each
   tenant change;
6. modernize the 1.0 Canvas app as the Dataverse-backed 2.0 owner/admin
   dashboard and include it in the solution;
7. package the dashboard and agent as a discoverable Teams experience, with
   tested deep links and a validated Microsoft 365 entry-point fallback; and
8. import the managed solution into test before production promotion.

Until those gates pass, an unavailable target tool must produce an explicit
service-unavailable response. It must not invoke a legacy data path.

## Safe deployment sequence

1. Export or pull each live agent into an ignored comparison folder.
2. Compare generated topics, connected-agent declarations, settings,
   workflows, and connection references with source control.
3. Push only the reviewed Owner/Admin instruction alignment.
4. Publish the changed agents.
5. Poll each deployment until it reports provisioned.
6. Extract each live template again and verify the released instructions.
7. Run failure-path smoke tests before enabling any new tool.
8. Commit the post-publish source and this release record to GitHub.

## Functional cutover validation

| Test | Required result |
|---|---|
| Owner A lists sites | Only active exact assignments for Owner A are returned |
| Owner A requests Owner B site | Request is denied and no other-owner data is returned |
| Non-admin requests dashboard | Admin verification fails closed and returns no tenant data |
| Tool dependency unavailable | Explicit error; no fabricated data or success |
| Duplicate request | Existing request ID is returned using the idempotency key |
| Certification | Fresh owner read, explicit confirmation, `PENDING` request |
| Deletion review | Typed `CONFIRM`, human approval path, no direct deletion |
| Audit | Request creation and every transition append action events |
| Dashboard owner access | Owner sees only actively assigned sites and cannot bypass row access by changing app filters or URLs |
| Dashboard admin access | Verified admin can use tenant summaries, filters, detail, requests, and exception views |
| Teams launch | Organizational Teams entry opens the correct dashboard and agent; agent/app deep links preserve the intended record context |

## Rollback

Retain pre-release live template exports. If routing, authorization, or tool
availability regresses, restore the previously verified agent definition,
publish it, and keep Dataverse-bound tools disabled until the failed gate is
corrected and retested.
