# 05 - Power Platform Delivery Roadmap

**Target:** Dataverse + Power Automate + Copilot Studio + Power Apps  
**Last updated:** 2026-09-17

## Guiding principles

1. Migrate vertically: make each read/write journey work end to end before
   broadening scope.
2. Keep the legacy proof of concept available for reconciliation, not as a
   second production path.
3. Use managed solutions, connection references, environment variables, and
   DLP from the first sprint.
4. Fail closed on authorization and fail visibly on connector/data errors.
5. Cut over only after count, relationship, behavior, and rollback validation.

## Phase overview

| Phase | Outcome | Exit gate |
|---|---|---|
| A - Platform foundation | Solution, Dataverse schema, security, ALM | Managed import to test succeeds |
| B - Owner read path | Owner agent and app read Dataverse only | Isolation, paging, and delegation pass |
| C - Admin and requests | Admin tools, requests, approvals, audit events | Authorization and lifecycle tests pass |
| D - Inventory | Power Automate scan/work-item pipeline | Two reconciled complete scans |
| E - Notifications | Owner/admin Teams notifications and responses | Retry and duplicate tests pass |
| F - Cutover | Legacy writes frozen and target activated | No production legacy calls during observation window |
| G - Advisors | Dataverse evidence broker and specialist integrations | Evidence lineage and access tests pass |

## Phase A - Platform foundation

- Create development, test, and production environment strategy.
- Create Governor365 solution and publisher.
- Add Dataverse tables, choices, keys, relationships, views, auditing, and
  security roles from [04-DataModel.md](04-DataModel.md).
- Add environment variables and connection references.
- Configure DLP and approved service accounts.
- Establish solution checker, export, unpack, source control, and managed import.

## Phase B - Owner read path

- Import representative sites and normalized owner assignments.
- Build `List Owner Sites` and `Get Site Detail` agent tool flows.
- Rebind owner agent topics and Adaptive Cards.
- Rebind the Canvas app to delegable Dataverse views.
- Configure and reconcile per-site read-only access teams for direct owner app
  access, or route owner app reads through the owner-scoped flow.
- Test exact/partial UPN, inactive assignment, renamed URL, paging, failure, and
  large-volume cases.

## Phase C - Admin and request lifecycle

- Build `Verify Admin`, `List Admin Sites`, `Submit Request`, and `Get Request
  Status`.
- Build request processor, approvals, action events, and notifications.
- Rebind Admin and Action agent topics.
- Add governance admin Power App views.
- Test unauthorized access, duplicate submission, typed delete confirmation,
  rejection, connector failure, retry, and event completeness.

## Phase D - Inventory automation

- Build scan run, work item, worker, and finalizer flows.
- Integrate approved paged Graph/SharePoint administration operations.
- Port deterministic compliance rules to solution-aware child flows.
- Compare site, owner, status, and recommendation results with legacy sources
  for two complete scans.
- Prove that an incomplete scan does not create stale/deleted false positives.

## Phase E - Notifications

- Build owner digest, admin summary, card response, and delivery retry flows.
- Use Dataverse suppression dates and delivery idempotency keys.
- Revalidate identity and current request state for card responses.
- Test Teams delivery failure independently from governance operation outcomes.

## Phase F - Cutover

- Freeze legacy SQL/list writes.
- Run final delta migration and reconciliation.
- Import and activate the managed production solution.
- Switch agent tools and Power Apps connections.
- Monitor correlations, failed work items, response time, and unauthorized tests.
- Retain rollback for the agreed observation window.
- Archive legacy Bicep, SQL, scripts, connectors, and source data after approval.

## Phase G - Specialist advisors

- Implement the Power Automate evidence broker.
- Store normalized, time-bound evidence snapshots in Dataverse.
- Rebind policy, readiness, data protection, identity, and assurance advisors.
- Preserve source, observation time, freshness, classification, and correlation.
- Keep large governed documents in an approved content repository and store
  references only.

## Backlog priorities

### Must have for production pilot

- owner/admin authorization;
- owner list/detail;
- admin dashboard and orphan review;
- request/status lifecycle;
- approval and action event trail;
- scan/work-item inventory;
- managed-solution deployment and DLP.

### Should have

- owner/admin Teams digests;
- Power Apps dashboards;
- owner assignment workflow;
- attestation integration;
- operational retry dashboard.

### Later

- expanded specialist advisor evidence;
- richer usage analytics;
- additional governed workloads;
- automated policy exception lifecycle.

## Definition of done

A feature is complete only when:

1. it is solution-aware and has no hard-coded environment identifiers;
2. positive, unauthorized, empty, duplicate, and connector-failure tests pass;
3. durable Dataverse state and business audit events are correct;
4. documentation and tool contracts match the deployed behavior;
5. the managed solution imports into test;
6. evidence is captured for GitHub and hackathon demonstration.
