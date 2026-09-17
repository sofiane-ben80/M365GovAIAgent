# 23 - Power Platform Refactor Decision and Migration

**Decision date:** 2026-09-17  
**Status:** Approved target architecture

## Context

The repository evolved through two proof-of-concept data paths:

1. SharePoint lists held site inventory, configuration, and action logs.
2. Azure SQL later provided a scalable owner inventory and request table.

Both paths used Power Automate in places, but the split introduced duplicate
schemas, inconsistent agent contracts, multiple security models, and confusing
deployment guidance. Some documents also proposed Azure-hosted APIs, Logic
Apps, or Function Apps for future integrations.

## Decision

Adopt a Power Platform-first target:

- Dataverse replaces Azure SQL and SharePoint lists for application data.
- Power Automate replaces Logic Apps, Function Apps, Azure Automation, and
  recurring PowerShell for application automation.
- Copilot Studio agents use Power Automate tool contracts rather than direct
  data connectors.
- Power Apps uses delegable Dataverse views for owner and admin dashboards.
- SharePoint/Graph remain governed source systems, not the application database.

## Why this design

| Goal | Power Platform response |
|---|---|
| Consistency | One solution, data platform, workflow engine, and ALM model |
| Relational data | Native lookups, choices, alternate keys, and normalized owner assignments |
| Security | Dataverse roles/teams plus flow-level identity revalidation |
| Auditability | Dataverse auditing plus append-only business action events |
| Agent integration | Solution-aware Power Automate tools with stable contracts |
| Maker maintainability | Low-code tables, views, flows, apps, and environment variables |
| Deployment | Managed solutions and connection references across environments |
| Scale | Delegable queries, server-side filters, paging, and asynchronous work items |

## Current-to-target mapping

| Current artifact | Target component | Migration treatment |
|---|---|---|
| `Contoso Sites` SharePoint list | Governance Site + Site Owner Assignment | Transform and upsert; split owner strings |
| `Governance Action Log` SharePoint list | Governance Action Request + Governance Action Event | Preserve historical timestamps and actor; separate state from events |
| `Governance Config` SharePoint list | Governance Policy Setting | Import active key/value settings |
| `[ECS_M365].[DOI-SP-Sites]` | Governance Site | Upsert by tenant and M365 site ID; use URL only as fallback |
| SQL normalized owner table | Site Owner Assignment | Import exact normalized UPN and source |
| `[ECS_M365].[GovernanceRequests]` | Governance Action Request | Preserve request IDs as external migration references |
| SQL stored procedures | Solution-aware Power Automate flows | Recreate validation, authorization, and idempotency |
| PowerShell governance scan | Scheduled + Dataverse-triggered Power Automate flows | Rebuild as paged scan/work-item pattern |
| SharePoint/SQL Canvas connector | Dataverse connector | Rebind formulas to delegable Dataverse views |
| Direct SharePoint agent actions | Power Automate agent tools | Replace with bounded contracts |
| Azure API/Function/Logic App proposal | Power Automate/custom connector only when required | Do not implement in target |

## Deliberate boundaries

- A custom connector is acceptable when an approved Microsoft connector does
  not expose the required Graph or SharePoint admin endpoint. Its operations
  are still invoked by Power Automate and governed by DLP.
- Dataverse stores normalized metadata and evidence, not full document content
  or access tokens.
- Direct site deletion remains out of scope. The solution submits and approves
  governed requests before a least-privilege operation is invoked.
- Existing SQL, Bicep, SharePoint-list scripts, and Canvas packages remain in
  the repository as migration evidence until cutover. They are not production
  target artifacts.

## Migration phases

### Phase A - Foundation

1. Create a development Power Platform environment with Dataverse.
2. Create the Governor365 solution, publisher, environment variables, and
   connection references.
3. Add tables, choices, alternate keys, relationships, views, auditing, and
   security roles from [04-DataModel.md](04-DataModel.md).
4. Apply DLP and service-account ownership standards.

Exit criteria: managed solution imports into test with no missing dependencies.

### Phase B - Read path

1. Import a representative subset from SQL/SharePoint into Dataverse.
2. Build owner and admin list/detail tool flows.
3. Rebind Copilot Studio tools and Power Apps views.
4. Validate exact owner isolation, admin verification, delegation, paging, and
   response time.

Exit criteria: owner/admin read journeys use Dataverse only.

### Phase C - Request and audit path

1. Create submit/status tools and request processor.
2. Configure approvals and action events.
3. Rebind owner/admin action topics.
4. Run duplicate, unauthorized, failure, and approval tests.

Exit criteria: all new requests and audit events are Dataverse-backed.

### Phase D - Inventory and notifications

1. Build scan-run/work-item Power Automate flows.
2. Compare Power Automate results to the legacy scan for two full cycles.
3. Build owner digest, admin summary, and card-response flows.
4. Validate retry, suppression, incomplete-scan, and duplicate-delivery cases.

Exit criteria: scheduled production automation has no SQL/list/PowerShell
dependency.

### Phase E - Cutover and retirement

1. Freeze writes to legacy stores.
2. Run final delta migration and reconcile row/request counts.
3. Switch production agents/apps to managed Dataverse components.
4. Monitor and retain a rollback window.
5. Remove legacy connection references and archive historical infrastructure.

Exit criteria: telemetry shows no production call to legacy SQL or governance
SharePoint lists for one agreed retention window.

## Migration controls

- Use a `Migration Source ID` field or protected migration map to retain
  traceability without making legacy IDs the primary key.
- Normalize UPNs to lowercase and resolve Entra object IDs where available.
- Reject duplicate site identities for manual resolution before cutover.
- Reconcile source and target counts by table, status, and owner relationship.
- Sample records across active, orphaned, group-connected, attested, archived,
  and pending-request states.
- Do not decommission a source until read, write, audit, retry, and rollback
  acceptance tests pass.

## Consequences

Positive:

- simpler architecture and story for makers, reviewers, and judges;
- fewer connection/security models;
- better relational data and delegable Power Apps behavior;
- native Power Platform ALM and auditing.

Tradeoffs:

- Dataverse capacity and premium licensing must be budgeted;
- high-volume inventory must use paging and asynchronous work-item flows;
- some tenant administration APIs may require an approved custom connector;
- legacy assets require a controlled data and agent-tool migration.
