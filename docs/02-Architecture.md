# 02 - Power Platform Architecture

**Solution:** Governor365 / M365 Governance AI Agent  
**Architecture status:** Approved target  
**Last updated:** 2026-09-21

## 1. Decision

The solution uses a Power Platform-first architecture:

- **Microsoft Dataverse** is the application system of record.
- **Power Automate** is the workflow, integration, approval, and notification
  engine.
- **Power Apps** provides the primary owner and administrative experience,
  combining visual governance workflows with an embedded assistant.
- **Copilot Studio** hosts the integrated custom agent, orchestrator,
  operational agents, and specialist advisors.
- **Microsoft Teams** provides app discovery, optional conversational access,
  approvals, and proactive notifications.
- **Microsoft Graph and SharePoint Online APIs** remain authoritative source
  systems for Microsoft 365 resource metadata and approved resource changes.

Azure SQL, SharePoint lists, Logic Apps, and Function Apps are excluded from the
target application architecture. They may appear in historical assets only as
migration sources.

## 2. Logical architecture

```mermaid
flowchart TB
    Users["Site owners and governance admins"] --> Apps["Governor365 Canvas app<br/>primary UI"]
    Apps --> PCF["Embedded AgentChat PCF"]
    PCF --> Agents["Copilot Studio custom agent"]
    Apps --> Dataverse
    Users --> Teams["Microsoft Teams<br/>discovery, chat, approvals, notifications"]
    Teams --> Apps
    Teams --> Agents

    Agents --> Owner["Governance User & Owner Agent"]
    Agents --> Admin["Governance Admin Agent"]
    Agents --> Advisors["Specialist advisor agents"]

    Owner --> Tools["Bounded Power Automate tools"]
    Admin --> Tools
    Advisors --> Evidence["Evidence broker flow"]
    Evidence --> Tools

    Tools --> Dataverse["Microsoft Dataverse<br/>operational system of record"]
    Tools --> Approvals["Power Automate approvals"]
    Tools --> Cards["Teams and Adaptive Cards"]
    Tools --> Sources["Microsoft Graph and SharePoint APIs"]
    Sources --> M365["Microsoft 365 workloads"]

    Inventory["Scheduled inventory cloud flow"] --> Sources
    Inventory --> Dataverse
    Dataverse --> Events["Dataverse-triggered flows"]
    Events --> Cards
    Events --> Approvals

    Solutions["Managed solutions, connection references,<br/>environment variables, DLP"] -. governs .-> Agents
    Solutions -. governs .-> Tools
    Solutions -. governs .-> Dataverse
```

## 3. Runtime components

| Component | Platform | Responsibility |
|---|---|---|
| Governor365 Canvas app | Power Apps | Primary owner/admin UI for visual triage, record details, and governed actions |
| Governor365.AgentChat | Power Apps component framework | Embeds Web Chat and exchanges versioned Canvas context and allowlisted actions |
| M365 Governance Agent | Copilot Studio | Integrated assistant, optional channel front door, and intent router |
| Governance User & Owner Agent | Copilot Studio | General-user guidance plus owner-scoped portfolio, explanations, and requests when assignments exist |
| Governance Admin Agent | Copilot Studio | Admin-verified tenant review and governed actions |
| Specialist advisors | Copilot Studio | Policy, readiness, protection, identity, and assurance guidance |
| Agent tool flows | Power Automate | Stable input/output contracts, identity validation, and Dataverse operations |
| Inventory orchestration | Power Automate | Scheduled collection, paging, work-item creation, and reconciliation |
| Request processor | Power Automate | Authorization, request creation, approvals, execution, callbacks, and status |
| Notification flows | Power Automate | Owner digests, admin summaries, reminders, and Adaptive Card responses |
| Dataverse tables | Dataverse | Canonical operational data, relationships, state, and audit evidence |
| Governance dashboards | Power Apps | Delegable owner and admin views over Dataverse with proactive AI briefings and selected-record grounding |
| Teams application package | Microsoft Teams | Organizational discovery, dashboard tab, agent entry point, and governed deep links |

## 4. Core request path

1. Copilot Studio obtains the signed-in identity from
   `System.User.PrincipalName`.
2. The agent invokes a solution-aware Power Automate tool with the caller
   identity, operation, and stable record identifier.
3. The flow validates the input and rechecks an exact owner assignment or an
   active Governance Role Assignment. Model-supplied identity is never trusted.
4. The flow reads or writes Dataverse using connection references.
5. Write operations create a `Governance Action Request` and append one or more
   `Governance Action Event` records.
6. High-impact operations enter a Power Automate approval before any Microsoft
   365 change is attempted.
7. The agent receives a structured response with a tracking ID and truthful
   state such as `PENDING`, `APPROVED`, `COMPLETED`, or `FAILED`.

## 5. Inventory path

1. A scheduled cloud flow creates a `Governance Scan Run`.
2. The flow obtains Microsoft 365 site metadata through approved Microsoft
   Graph or SharePoint administration endpoints.
3. Pagination is mandatory. The parent flow creates bounded `Scan Work Item`
   records rather than processing the entire tenant in one run.
4. Dataverse-triggered worker flows upsert sites by alternate key and replace
   active owner assignments for each processed site.
5. Policy values are loaded from `Governance Policy Setting`.
6. Compliance status, recommended action, evidence timestamps, and scan
   outcomes are written to Dataverse.
7. A finalizer marks stale records, records counts and errors, and completes the
   scan only when all work items have reached a terminal state.

This design supports large tenants without non-delegable client scans or a
single long-running flow.

## 6. Security model

- Owners never receive unrestricted table access through an agent tool.
- Owner tools query active `Site Owner Assignment` rows for the exact normalized
  signed-in UPN or Entra object ID.
- Admin tools resolve the caller's immutable Entra object ID and verify an
  active, in-window `GovernanceAdmin` row in Governance Role Assignment on
  every privileged operation; routing alone is not authorization.
- The legacy SharePoint admin-role list is retired. Optional Entra groups may
  feed a controlled reconciliation flow, but Dataverse is the runtime
  application-role authority.
- Role assignments cannot be self-granted from the Admin agent or dashboard.
  Creation and changes require a restricted identity or approved,
  separation-of-duties workflow.
- Power Apps uses Dataverse security roles and admin teams. Direct owner app
  access additionally requires per-site read-only access teams synchronized
  from active owner assignments; an app filter is not authorization. Otherwise
  the owner app uses the same owner-scoped Power Automate tools as the agent.
- Destructive operations use least-privilege connection references, explicit
  confirmation, approval, and audit events.
- Secure inputs and outputs are enabled for flow actions carrying identities,
  evidence, or sensitive connector responses.
- DLP policies place Dataverse, Microsoft 365 Users, Teams, SharePoint, and
  approved HTTP/custom connectors in the business data group.

## 7. ALM and environment strategy

All target components belong to one Power Platform solution:

- Dataverse tables, columns, keys, relationships, choices, and security roles;
- Copilot Studio agents and tools;
- solution-aware cloud flows and child flows;
- Power Apps;
- the Teams application package and environment-specific app/agent deep-link
  configuration;
- connection references;
- environment variables;
- custom connectors when an approved standard connector is unavailable.

Use unmanaged solutions in development and managed solutions in test and
production. Deployment configuration must use environment variables, never
hard-coded tenant, environment, group, URL, or connection identifiers.

Recommended environments:

| Environment | Purpose |
|---|---|
| Development | Authoring and unit testing with non-production data |
| Test | Managed-solution deployment, integration tests, and user acceptance |
| Production | Controlled managed deployment with production DLP and service accounts |

## 8. Availability and failure behavior

- Every tool returns an explicit `success` flag, stable status, user-safe
  message, and correlation ID.
- Connector errors do not return empty success-shaped results.
- Failed work items remain visible and retryable in Dataverse.
- Idempotency keys prevent duplicate inventory rows, requests, and event
  processing.
- Notification failures update delivery state and are retried separately from
  the underlying governance request.
- Power Automate run history is operational telemetry; Dataverse stores the
  durable business audit trail.

## 9. Boundaries

SharePoint Online is still governed by the solution. It is not used as the
solution database. PowerShell may be retained temporarily for comparison or
one-time migration, but recurring production automation is implemented in
Power Automate.

See [23-Power-Platform-Refactor.md](23-Power-Platform-Refactor.md) for the
decision record and migration mapping.

## 10. Experience distribution

The first supported dashboard host is an organizational Microsoft Teams app:

1. publish the Canvas app from the managed Governor365 solution;
2. add it as a personal Teams app/tab for the approved audience;
3. expose the Copilot Studio agent from the same Teams experience where tenant
   capabilities permit, otherwise provide a governed agent launch link;
4. add signed-in, environment-specific deep links from agent cards to app site
   detail and from the app back to the agent; and
5. retain the standard Power Apps web player as a fallback entry point.

Direct Canvas app embedding inside Microsoft 365 Copilot is not assumed. A
release spike must validate the tenant's supported Microsoft 365 app and
Copilot extensibility surfaces. If direct hosting is unavailable, Microsoft
365 Copilot responses may link to the same Teams-hosted or web-hosted app
without creating a separate application or data path.

## 11. Agent and Canvas experience boundary

Use two operational agents with an optional thin launcher:

- **Governance User & Owner Agent:** available to signed-in users. It provides
  general governance guidance and support; owner portfolio and actions appear
  only when active Site Owner Assignment rows authorize them.
- **Governance Admin Agent:** a separate privileged agent. Every tenant-wide
  read and write invokes role verification against Governance Role Assignment.
- **M365 Governance Agent:** optional discovery/router only. It may use a
  minimized role-capability result to offer the right destination, but it never
  grants access or executes privileged work.

Keep one Canvas app to avoid duplicating shared navigation, components, and
Dataverse contracts. It has general/owner and admin areas selected from a
server-validated capability response. Hidden screens and formulas are UX only;
Dataverse roles, row sharing, and Power Automate checks enforce authorization.
A separate admin app is warranted only if future policy requires a distinct
audience, lifecycle, or environment.
