# 13 – Admin/Owner Split Implementation Plan

> **Migration note:** Retain the agent split and authorization boundaries, but
> implement all data and action tools as Dataverse-backed Power Automate flows.
> See [23-Power-Platform-Refactor.md](23-Power-Platform-Refactor.md).

**Document:** Two-Agent Deployment Plan  
**Solution:** M365 Governance AI Agent  
**Version:** 1.0  
**Date:** 2026-07-06  
**Status:** Working Plan

---

## 1. Decision Summary

Adopt two published entry agents:
- Governance Owner Agent (owner persona only)
- Governance Admin Agent (admin persona only)

Keep shared backend contracts:
- Triage logic remains shared
- Write path remains centralized via GovernanceAgent-ActionCallback
- Audit logging remains append-only in Governance Action Log

Optional:
- Keep a lightweight launcher/orchestrator only for discoverability

---

## 2. Why This Split

Expected gains:
- Lower topic/prompt complexity per agent
- Lower risk of persona leakage
- Faster iteration and safer releases
- Simpler testing matrix per persona

Accepted trade-offs:
- Two agent publish surfaces to manage
- Some duplicated UX/menu copy
- Users with both personas may switch between agents

---

## 3. Target Topology

1. Owner Agent (published to Teams)
- Owner-scoped queries only
- Owner actions (certify/archive/delete-request)
- Admin requests redirect to Admin Agent

2. Admin Agent (published to Teams)
- Startup admin verification via CheckAdminRole flow
- Tenant-wide dashboards and filters
- Admin actions (assign-owners and tenant-level dispositions)

3. Shared contracts
- GovernanceAgent-ActionCallback handles all writes
- Adaptive card response flow routes inline actions into callback
- Same Contoso Sites, Governance Action Log, Governance Config lists

---

## 4. Migration Plan

### Stage A — Prepare (no behavior break)

1. Create/publish Owner Agent from owner entry instructions.
2. Create/publish Admin Agent from admin entry instructions.
3. Keep current combined agent available during pilot.

### Stage B — Wire and Validate

1. Owner Agent:
- Validate owner-only site filtering
- Validate certify/archive/delete-request path via Action Callback

2. Admin Agent:
- Validate role-check on conversation start
- Validate non-admin denial path
- Validate dashboard/orphaned/not-attested flows

3. Shared callback:
- Validate action write + audit log consistency for both agents

### Stage C — Rollout

1. Pilot with small admin and owner cohorts.
2. Compare support incidents and completion rate vs combined agent.
3. If stable, retire combined agent or convert it to launcher-only.

---

## 5. Acceptance Criteria

- No owner request can access tenant-wide data.
- No admin data is shown without successful role verification.
- All writes are callback-mediated and logged.
- Both agents pass existing certify dry-run checklist with persona-specific scenarios.
- Combined agent either retired or reduced to launcher-only intent routing.

---

## 6. Operational Notes

- Keep shared prompt fragments (triage/action policy) in source-controlled files.
- Release owner and admin agents independently.
- Maintain separate smoke tests per agent plus shared callback regression tests.

---

## 7. Files Added for This Split

- `copilot/agents/owner-entry-instructions.txt`
- `copilot/agents/admin-entry-instructions.txt`
- `docs/13-Agent-Split-Implementation-Plan.md`
