# 26 - Development Backlog

**Baseline date:** 2026-09-18  
**Purpose:** GitHub-ready implementation backlog for the approved Power
Platform target  
**Source of truth:** [Requirements](01-Requirements.md), [data model](04-DataModel.md),
[roadmap](05-Roadmap.md), [flow build guide](12-PowerAutomate-Build-Guide.md),
[refactor decision](23-Power-Platform-Refactor.md), and
[deployment status](25-Deployment-Status-and-Runbook.md)

## 1. Current state

### Complete or reusable

- The Power Platform-first architecture and migration decision are approved.
- The live Governor365 2.0 solution was exported and unpacked on 2026-09-18.
- Ten target Dataverse tables are provisioned, including the new application
  role registry, with the documented columns,
  local choices, and alternate keys.
- Required auditing is enabled and re-export verified for Governance Site,
  Site Owner Assignment, Governance Action Request, and Governance Policy
  Setting.
- Governance Role Assignment is provisioned with an active uniqueness key,
  auditing, validity/provenance fields, and one approved development admin.
- Ten environment-variable definitions, six connection references, and a
  deployment-settings template are source controlled.
- Nine Dataverse-backed flows are solution-aware, connection-bound, and active:
  seven agent tools, Append Action Event, and Process Pending. Start Scan is a
  validated draft until its worker and finalizer are complete.
- Authorization, owner isolation, request idempotency, confirmation, terminal
  state, and action-event predicates have repeatable live Dataverse tests.
- Governor M365 and the classic Owner and Admin agents are published.
- Owner/Admin target instructions, eight reusable skills, Adaptive Card assets,
  and Dataverse flow contracts are source controlled.
- Five specialist advisor shells are published with production tools disabled.
- A bootstrap Dataverse scanner exists for migration, comparison, and
  break-glass use.

### Partially complete

- Dataverse lookup relationships, views, roles, and the access-team template
  still need managed-import verification. Two owner assignments remain
  unmapped until their principals receive Dataverse user rows.
- Owner/Admin source instructions are aligned to the target, but the live
  agent packages still contain legacy topics and embedded workflows.
- Agent publishing helpers exist, but the installed PAC CLI cannot perform the
  guarded pull/push workflow required by the release process.
- The legacy `M365Governance_1_0_0_1` export remains migration evidence only
  under `../archive/legacy-2026-09-19/`.
  The solution-owned `Governor365 Dashboard` now uses Dataverse and contains
  separate owner and administrator screens with clickable summary filters.

### Not implemented

- The active read/request flows are unpacked in source control, but Copilot
  Studio tool binding and trigger-level execution transcripts remain open.
- Request submission, status, event append, certification processing, and
  support queueing are active. Approval-dependent processing is blocked on a
  connected Approvals connection; privileged operations, the inventory
  worker/finalizer, notifications, and reconciliation flows are not built.
- Canvas request entry/status, exact oversharing/external-user/memberless
  classifications, target-volume delegation tests, and owner-account
  acceptance testing remain open. Browse/detail, persona routing, and initial
  server-backed summary cards are included in 2.0.
- A unified Teams app/tab package, agent-to-dashboard links, and validated
  Microsoft 365 entry point do not exist.
- A verified managed solution has not been imported into test.
- Production cutover, legacy retirement, and the advisor evidence broker remain
  open.

## 2. Recommended GitHub structure

Use one GitHub Project with these fields:

| Field | Values |
|---|---|
| Status | Backlog, Ready, In progress, In review, Blocked, Done |
| Priority | P0 - pilot blocker, P1 - pilot enhancement, P2 - later |
| Milestone | M0 Foundation, M1 Unified experience, M2 Requests, M3 Inventory, M4 Notifications, M5 Release, M6 Advisors |
| Size | S, M, L, XL |
| Workstream | Platform/ALM, Dataverse, Power Automate, Copilot Studio, Power Apps, Test, Migration, Advisor |

Recommended labels:

- `type:epic`, `type:feature`, `type:test`, `type:chore`
- `priority:p0`, `priority:p1`, `priority:p2`
- `area:alm`, `area:dataverse`, `area:flow`, `area:agent`, `area:power-app`,
  `area:migration`, `area:advisor`
- `blocked`, `security`, `needs-tenant`, `good-first-task`

Every issue should include the backlog ID in its title, preserve the listed
dependencies, link its requirement IDs, and attach evidence before closure.

## 2.1 Implementation progress

| Issue | Status | Evidence |
|---|---|---|
| DEV-003 | Done - 2026-09-18 | Live 2.0 export, unpacked source, successful round-trip pack |
| DEV-004 | In progress | Ten-table schema present; application-role registry, local choices, alternate keys, and required auditing imported, published, and re-export verified |
| DEV-005 | In progress | Five security roles and read-only site access-team template deployed; 14 memberships across 13 site teams reconcile idempotently; two active principals have no Dataverse user row and remain explicitly unmapped |
| DEV-006 | In progress | Ten environment-variable definitions, six unbound connection references, and deployment-settings template created |
| DEV-007 | In progress | Active flows use structured responses, correlation IDs, explicit failures, and run-after handling; shared child-flow extraction remains |
| DEV-008 | Done - 2026-09-18 | Verify Admin and Get Caller Capabilities active; positive, missing, inactive, expired, future, and duplicate-role cases pass |
| DEV-009 | Done - 2026-09-19 | List Owner Sites active; exact owner isolation, bounded output, continuation-token input, and live skip-token round-trip pass |
| DEV-010 | Done - 2026-09-18 | Get Site Detail active; exact owner/admin authorization and protected-data denial verified |
| DEV-011 | In progress | List Admin Sites active with ALL, ORPHANED, NONCOMPLIANT, ATTESTATION, office, recommended-action, freshness, and continuation filters; Canvas binding remains |
| DEV-014 | In progress | Submit Request and Get Request Status active; idempotency, exact confirmation, truthful status, caller authorization, and Submitted event verified; Copilot binding remains |
| DEV-015 | In progress | Submission and processor append required action events; Flow Service role has create/read but no Action Event update/delete; shared child-flow extraction remains |
| DEV-016 | In progress | Active processor reauthorizes every request; certification and support paths pass; connector failures persist explicit failure state/events; approval-dependent paths fail closed until Approvals is connected |
| DEV-018 | In progress | Lifecycle harness passes six authorization, confirmation, idempotency, transition-event, and terminal-state cases; live processor certification, revoked-authorization, support, approval-unavailable, and scoped-regression cases pass; approval/rejection/retry remain |
| DEV-019 | In progress | Start Scan draft successfully discovered 30 SharePoint sites and created one deterministic page work item in an isolated live test; worker/finalizer are not yet deployed |
| DEV-027 | In progress | Unmanaged round-trip and Dataverse-generated managed packages build; both pass Solution Checker with zero findings; managed test import is blocked by the absence of a dedicated test environment |

## 3. Delivery milestones

| Milestone | Exit gate | Issues |
|---|---|---|
| M0 - Foundation | Target solution imports into test with schema, security, references, and variables | DEV-001 through DEV-006 |
| M1 - Unified experience | Owner/Admin agents and dashboard use Dataverse only; isolation, paging, delegation, Teams launch, and deep links pass | DEV-007 through DEV-013, DEV-033 |
| M2 - Requests | New requests, approvals, status, and audit events are Dataverse-backed | DEV-014 through DEV-018 |
| M3 - Inventory | Two complete scans reconcile with legacy results; incomplete scans preserve state | DEV-019 through DEV-023 |
| M4 - Notifications | Teams delivery, response, suppression, idempotency, and retry tests pass | DEV-024 through DEV-026 |
| M5 - Release | Managed test import and end-to-end acceptance pass; production has no legacy calls | DEV-027 through DEV-029 |
| M6 - Advisors | Evidence lineage, audience authorization, and connected-agent tests pass | DEV-030 through DEV-032 |

M0 through M3, including DEV-033, are the minimum production-pilot path. M4 is required by the
approved requirements before general production. M6 can proceed after the
operational foundation is stable and does not block the initial governance
pilot.

## 4. GitHub-ready development issues

### M0 - Platform foundation

| ID | Issue title | Pri | Size | Depends on | Suggested owner | Acceptance criteria |
|---|---|---:|:---:|---|---|---|
| DEV-001 | Create the Governor365 GitHub Project, labels, milestones, and issue conventions | P0 | S | None | Delivery lead | Project fields and labels match section 2; all DEV items are entered or linked; dependencies and milestone views are visible to the team. |
| DEV-002 | Restore and validate guarded Copilot Studio source pull/push tooling | P0 | M | None | Copilot/ALM engineer | A supported PAC workflow can pull, compare, push, publish, and pull again; dry-run and rollback are documented; no live package is overwritten without comparison. |
| DEV-003 | Export and unpack the Governor365 2.0 solution as the source baseline | P0 | M | DEV-002 | Power Platform ALM engineer | The unpacked baseline contains the nine target tables and five advisor shells reported in the release record; operational-agent and Canvas app solution membership are inventoried for DEV-012/DEV-013/DEV-027; the legacy 1.0 solution is retained as the dashboard migration source but not treated as the target baseline; export/unpack is repeatable and contains no secrets. |
| DEV-004 | Complete and verify the Dataverse schema and application-role registry | P0 | XL | DEV-003 | Dataverse engineer | All columns, choices, alternate keys, relationships, views, and required fields in [04-DataModel](04-DataModel.md) exist, including Governance Role Assignment; retry-safe keys are active; approved privileged users are migrated from the legacy role source; missing/inactive/expired role rows fail closed; schema differences are documented and approved. |
| DEV-005 | Implement Dataverse security roles, auditing, and owner row-access control | P0 | L | DEV-004 | Dataverse/security engineer | Owner, admin, auditor, flow-service, and maker roles are deployed; action events cannot be updated/deleted by application identities; auditing is enabled; the access-team approach or flow-only owner app decision is implemented and tested. |
| DEV-006 | Configure solution connection references, environment variables, DLP, and service identities | P0 | L | DEV-003 | Platform admin | All values listed in [12-PowerAutomate-Build-Guide](12-PowerAutomate-Build-Guide.md) are environment-specific; references use approved least-privilege identities; DLP permits only approved connector groupings; test import prompts for no hard-coded tenant IDs. |

### M1 - Unified owner/admin agent and dashboard experience

| ID | Issue title | Pri | Size | Depends on | Suggested owner | Acceptance criteria |
|---|---|---:|:---:|---|---|---|
| DEV-007 | Build shared Power Automate response, correlation, and error child flows | P0 | M | DEV-004, DEV-006 | Flow engineer | Tools return the documented structured contract; validation, connector, timeout, and authorization failures are explicit; every outcome has a correlation ID; secure inputs/outputs and run-after paths are configured. |
| DEV-008 | Build caller capability and Verify Admin child flows | P0 | M | DEV-004, DEV-006, DEV-007 | Identity/flow engineer | Caller identity resolves to immutable Entra object ID; owner capability comes from active site assignments; admin capability requires exactly one active, in-window GovernanceAdmin role row; missing/inactive/expired/duplicate assignments and connector failures deny access; capability discovery never substitutes for destination authorization. |
| DEV-009 | Build List Owner Sites with exact authorization and paging | P0 | L | DEV-004, DEV-007 | Flow engineer | Active exact normalized assignments are filtered server-side; response fields are minimized; page size and continuation are bounded; partial/model-provided identities expose no records; connector failure is not returned as an empty success. |
| DEV-010 | Build authorized Get Site Detail | P0 | M | DEV-008, DEV-009 | Flow engineer | Owners can read only actively assigned sites; verified admins can read permitted tenant detail; stale/missing evidence is explicit; unauthorized and nonexistent IDs return no protected data. |
| DEV-011 | Build List Admin Sites and admin dashboard queries | P0 | L | DEV-008, DEV-010 | Flow engineer | Server-side filters cover action, office, attestation, status, and freshness; orphan/under-owned summaries are live and paged; all results require fresh admin verification; the admin card receives typed live values. |
| DEV-012 | Rebuild and bind Owner/Admin agents to the Dataverse read tools | P0 | XL | DEV-009, DEV-010, DEV-011 | Copilot Studio engineer | Legacy sample/scaffold topics are removed or disabled; target skills and tools are bound; missing tools fail closed; Owner/Admin routing has one response owner; live output contains no hard-coded records or counts. |
| DEV-013 | Modernize the 1.0 Canvas app as the required Dataverse-backed 2.0 dashboard | P0 | XL | DEV-004, DEV-005, DEV-010, DEV-011 | Power Apps engineer | Useful 1.0 browse, search, filter, sort, detail, and site-launch UX is retained; all SQL connections/formulas are removed; owner and admin role-aware views, request entry/status, and exception views use Dataverse and governed flows; queries are delegable at target volume; formula/URL manipulation cannot bypass access; accessibility and data-row-limit tests pass; the app is included in the 2.0 solution. |
| DEV-033 | Package and validate the unified Governor365 Teams and Microsoft 365 experience | P0 | L | DEV-012, DEV-013 | Teams/Power Apps engineer | The dashboard is published as an organizational Teams personal app/tab for approved audiences; agent and dashboard are discoverable from one experience; bidirectional environment-specific deep links open the intended record/context; the Power Apps web player is a tested fallback; a tenant spike records whether Microsoft 365 Copilot can host the app directly or must link to Teams/web; packaging assets are included in release source. |

### M2 - Request, approval, and audit path

| ID | Issue title | Pri | Size | Depends on | Suggested owner | Acceptance criteria |
|---|---|---:|:---:|---|---|---|
| DEV-014 | Build Submit Request and Get Request Status agent tools | P0 | L | DEV-007, DEV-008, DEV-010 | Flow engineer | Owner/admin authorization and confirmation rules are enforced; support permits optional site context; repeated idempotency keys return one request; status is caller-authorized and truthful; request ID and correlation ID are returned. |
| DEV-015 | Build the append-only Action Event child flow | P0 | M | DEV-004, DEV-007 | Flow engineer | Submitted, authorization, approval, execution, terminal, and notification events use the documented schema; create/read-only permissions prevent mutation; failures do not silently omit required events. |
| DEV-016 | Build request processing, approvals, and least-privilege M365 operations | P0 | XL | DEV-014, DEV-015 | Automation engineer | Fresh authorization precedes processing; destructive/privileged actions require approval; state changes and events remain consistent; source snapshots update only after source success; retries do not repeat the business operation. |
| DEV-017 | Bind certification, archive, deletion-review, support, assignment, and status experiences | P0 | L | DEV-014, DEV-016 | Copilot Studio engineer | Certification and archive require current-turn confirmation; deletion requires exact typed `CONFIRM`; owner assignment requires resolved target plus admin verification; `PENDING` is never reported as completed; ambiguous sites are disambiguated. |
| DEV-018 | Automate request lifecycle authorization, idempotency, and audit tests | P0 | L | DEV-014 through DEV-017 | Test engineer | Positive, unauthorized, duplicate, approval, rejection, connector-failure, retry, and terminal-state cases pass; every transition has exactly one corresponding event; evidence is attached to the issues. |

### M3 - Inventory, triage, and migration

| ID | Issue title | Pri | Size | Depends on | Suggested owner | Acceptance criteria |
|---|---|---:|:---:|---|---|---|
| DEV-019 | Build the Start Scan orchestration flow | P0 | L | DEV-004, DEV-006, DEV-007 | Inventory flow engineer | A run record and bounded page work items are created; source watermark and discovery counts are retained; paging uses an approved Graph/SharePoint operation; retries do not duplicate work items. |
| DEV-020 | Build the Process Work Item flow and deterministic triage rules | P0 | XL | DEV-005, DEV-019 | Inventory flow engineer | Sites and normalized assignments upsert by alternate key; owner removals occur only after a successful site read; policy settings drive ordered compliance/recommendation rules; access-team membership is reconciled when enabled; member count, actual external-user count, broad-sharing principal count, overshared, stale, below-owner-standard, has-external-users, and memberless classifications are written from successful authoritative observations; unknown/partial reads are not represented as zero or false; the one-owner historical default versus requested two-owner threshold is resolved; failures remain retryable. |
| DEV-021 | Build the Finalize Scan flow and stale-state safeguards | P0 | L | DEV-020 | Inventory flow engineer | Finalization waits for all work items; failures yield `CompletedWithErrors`; incomplete runs never mark unseen sites stale; complete runs persist terminal counts and timestamps and apply approved stale policy. |
| DEV-022 | Build legacy-to-Dataverse migration and reconciliation reporting | P0 | XL | DEV-004, DEV-020 | Data migration engineer | Sites, owners, requests, events, and settings are transformed with legacy trace IDs; duplicates are quarantined; counts reconcile by table/status/relationship; representative state samples and delta migration are repeatable. |
| DEV-023 | Run inventory reliability, reconciliation, and 50,000-site scale tests | P0 | L | DEV-021, DEV-022 | Performance/test engineer | Two complete scans reconcile to the legacy baseline; retry, partial failure, paging, owner deactivation, and no-false-stale cases pass; target-volume processing and interactive read targets are measured and recorded. |

### M4 - Teams notifications

| ID | Issue title | Pri | Size | Depends on | Suggested owner | Acceptance criteria |
|---|---|---:|:---:|---|---|---|
| DEV-024 | Implement Notification Delivery persistence, suppression, and retry controls | P1 | M | DEV-004, DEV-007 | Flow engineer | Period/idempotency keys prevent duplicates; suppression dates, delivery state, Teams activity ID, response state, and sanitized failures persist independently from operation state. |
| DEV-025 | Build Owner Digest and Admin Summary flows | P1 | L | DEV-011, DEV-024 | Teams/flow engineer | Owner digests contain only active assignments; admin summaries require approved recipients and cover orphan/failure/freshness views; scheduling is environment-configured; delivery failure does not alter governance outcomes. |
| DEV-026 | Build and secure Adaptive Card response handling | P1 | L | DEV-016, DEV-024 | Teams/flow engineer | Caller, current request state, and authorization are revalidated; hidden card values are not trusted; duplicate and expired responses are safe; retry and notification events are recorded. |

### M5 - Managed release and cutover

| ID | Issue title | Pri | Size | Depends on | Suggested owner | Acceptance criteria |
|---|---|---:|:---:|---|---|---|
| DEV-027 | Establish solution checker, export/unpack, managed build, and test import | P0 | L | DEV-003 through DEV-006, DEV-012, DEV-013, DEV-016, DEV-021, DEV-033 | Power Platform ALM engineer | Solution checker has no release-blocking findings; generated source is reviewed; the managed solution includes agents, dashboard, flows, tables, roles, references, and variables; managed import to test succeeds with environment values and connection references; import/export steps are repeatable. |
| DEV-028 | Execute end-to-end persona, performance, accessibility, and failure-path acceptance | P0 | XL | DEV-018, DEV-023, DEV-026, DEV-027, DEV-033 | Test lead | Owner, admin, auditor, and unauthorized personas pass in chat and dashboard; p95 read, scale, audit, portability, accessibility, Teams launch, and deep-link targets are evidenced; unavailable dependencies fail visibly; no target journey invokes SQL or governance lists. |
| DEV-029 | Perform production cutover, observation, rollback verification, and legacy retirement | P0 | XL | DEV-022, DEV-027, DEV-028 | Release lead | Legacy writes are frozen; final delta reconciles; managed production components are activated; rollback is rehearsed; monitoring shows no legacy production calls for the agreed window; retirement receives explicit approval. |

### M6 - Specialist advisors

| ID | Issue title | Pri | Size | Depends on | Suggested owner | Acceptance criteria |
|---|---|---:|:---:|---|---|---|
| DEV-030 | Implement the Dataverse evidence broker, evidence lifecycle, and telemetry contract | P2 | XL | DEV-004, DEV-006, DEV-007 | Advisor platform engineer | Broker authorization is caller- and audience-aware; evidence records preserve source, observation, freshness, classification, and correlation; restricted artifacts remain in approved stores; denial/stale/partial/timeout tests pass. |
| DEV-031 | Release Policy and Readiness advisor tools as the first read-only wave | P2 | XL | DEV-030 | Advisor engineers | Approved policy and capability sources are security-trimmed; deterministic rubric versions are returned; both advisors pass audience, freshness, groundedness, paging, and safe-failure tests before tools are enabled. |
| DEV-032 | Release Data Protection, Identity, and Assurance advisors and Governor routes | P2 | XL | DEV-030, DEV-031 | Advisor engineers | Domain-specific source consent and person-data controls are approved; each advisor passes its release gate; route ambiguity and audience mismatch tests pass; conversation-history transfer remains disabled unless separately approved. |

## 5. Parallel work plan

After DEV-003 establishes the source baseline:

1. **Dataverse lane:** DEV-004 and DEV-005.
2. **Platform lane:** DEV-006 and the test-environment preparation for DEV-027.
3. **Copilot lane:** DEV-002, then package comparison and nonfunctional cleanup
   needed for DEV-012.
4. **Test lane:** create fixtures, personas, and test data for DEV-018, DEV-023,
   and DEV-028 without marking execution complete before the features exist.

After DEV-007, read tools can be split among multiple flow engineers. DEV-013
can proceed in parallel once the secured Dataverse views and read contracts are
stable, with DEV-033 following agent and app integration. After
DEV-019, work-item processing and migration mapping can also proceed in
parallel. Keep DEV-016 with one accountable owner because request state,
approval state, source operations, and event ordering form one transactional
workflow.

## 6. First sprint recommendation

Start with DEV-001 through DEV-007. DEV-003 is the first concrete release
artifact: export and unpack 2.0 before further solution work. Pull DEV-008,
DEV-009, and a DEV-013 Canvas UX/data-source inventory into the sprint if
capacity remains. This sequence removes the current release-tooling ambiguity,
puts the actual 2.0 solution under source control, preserves the 1.0 dashboard
features that must be modernized, completes the security/deployment
foundation, and establishes the shared flow behavior needed by every
operational tool.

Do not start recurring production inventory, agent write actions, or live
advisor connections before their listed authorization, schema, and ALM
dependencies are complete.

## 7. Issue definition of done

In addition to each issue's acceptance criteria, implementation issues are done
only when:

1. the component is solution-aware and contains no hard-coded environment
   identifiers;
2. positive, unauthorized, empty, duplicate, timeout, and connector-failure
   behavior relevant to the component has been tested;
3. durable state and action events are correct;
4. contracts and documentation match deployed behavior;
5. the managed solution still imports into test; and
6. test output, screenshots, flow run IDs, or reconciliation reports are linked
   from the GitHub issue.
