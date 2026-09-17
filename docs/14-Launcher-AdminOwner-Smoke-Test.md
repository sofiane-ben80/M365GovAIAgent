# 14 - Launcher + Admin/Owner Smoke Test Runbook

> **Migration note:** Run this role-routing test together with Dataverse owner
> assignment and Power Automate admin-verification tests from the target
> [requirements](01-Requirements.md).

Document: Split-entry smoke test runbook  
Solution: M365 Governance AI Agent  
Date: 2026-07-06  
Status: Draft

---

## 1. Purpose

Validate the split deployment model where:
1. Orchestrator acts as launcher only.
2. Owner Agent handles owner-scoped workflows.
3. Admin Agent handles tenant-wide workflows with explicit admin verification.

---

## 2. Preconditions

1. Latest instructions applied in Copilot Studio:
   - copilot/agents/orchestrator-instructions.txt
   - copilot/agents/owner-entry-instructions.txt
   - copilot/agents/admin-entry-instructions.txt
2. CheckAdminRole flow is callable and returns `isAdmin` correctly.
3. Action callback flow is available for certify/archive/delete-request/assign-owner.
4. Test users:
   - Admin user
   - Owner-only user
   - Non-admin/non-owner user (optional hardening)
5. Bots are published and reachable in Teams.
6. Verify whether launcher routes are implemented as real "Transfer to agent" nodes or temporary text-routing guidance in topic messages.

### 2.1 Transfer Wiring Checklist (Launcher)

In `M365 Governance Agent`, wire each launcher route topic with a **Transfer to agent** node.

Required mapping:

| Launcher Topic | Transfer Target | Starter Prompt | Context to Pass |
|--------|------|-------------|--------|
| MySites | Governance Owner Agent | show my sites | Topic.CallerUPN = System.User.PrincipalName |
| SitesNeedingAttention | Governance Owner Agent | show sites needing attention | Topic.CallerUPN = System.User.PrincipalName |
| SiteDetail | Governance Owner Agent | site details [site name] | Topic.CallerUPN = System.User.PrincipalName |
| CertifySite | Governance Owner Agent | certify [site name] | Topic.CallerUPN = System.User.PrincipalName |
| RequestArchival | Governance Owner Agent | request archival for [site name] | Topic.CallerUPN = System.User.PrincipalName |
| FlagForDeletion | Governance Owner Agent | flag [site name] for deletion | Topic.CallerUPN = System.User.PrincipalName |
| AdminDashboard | Governance Admin Agent | admin dashboard | Topic.CallerUPN = System.User.PrincipalName |
| OrphanedSites | Governance Admin Agent | show orphaned sites | Topic.CallerUPN = System.User.PrincipalName |
| NotAttestedSites | Governance Admin Agent | show not attested sites | Topic.CallerUPN = System.User.PrincipalName |
| ActionAssignOwners | Governance Admin Agent | assign owner for [site name] | Topic.CallerUPN = System.User.PrincipalName |

Notes:
1. Keep a fallback send-message node only as a temporary safety net while wiring, then remove it once transfer is confirmed.
2. Do not perform SharePoint reads/writes in launcher topics.

---

## 3. Test Matrix

| Case ID | User | Entry Point | Prompt | Expected Result |
|--------|------|-------------|--------|-----------------|
| SMK-01 | Owner | Launcher | show my sites | Routed to Owner Agent flow, owner-scoped list only |
| SMK-02 | Admin | Launcher | admin dashboard | Routed to Admin Agent flow, dashboard shown |
| SMK-03 | Owner | Launcher | admin dashboard | Routed toward Admin Agent, denied by admin check |
| SMK-04 | Non-admin | Admin Agent direct | admin dashboard | Access denied with clear guidance |
| SMK-05 | Owner | Owner Agent direct | certify [owned site] | Confirmation + callback success + write/log |
| SMK-06 | Non-owner | Owner Agent direct | certify [other site] | Denied, no write, no completed action log |
| SMK-07 | Admin | Admin Agent direct | assign owner [site] | Confirmation + callback success + audit log |
| SMK-08 | Any | Launcher | help | Launcher menu + handoff guidance only |

---

## 4. Detailed Checks

### SMK-01 Launcher -> Owner route

Steps:
1. Sign in as owner user.
2. Open launcher bot.
3. Send: show my sites.

Expected:
1. Launcher routes to Owner Agent quickly.
2. Owner Agent returns only owned sites.
3. No tenant-wide list exposure.

Evidence:
1. Chat screenshot of launcher handoff.
2. Chat screenshot of owner list response.

---

### SMK-02 Launcher -> Admin route (authorized)

Steps:
1. Sign in as admin user.
2. Open launcher bot.
3. Send: admin dashboard.

Expected:
1. Launcher routes to Admin Agent.
2. Admin Agent verifies role and shows dashboard.

Evidence:
1. Chat screenshot of route.
2. Screenshot of dashboard response.

---

### SMK-03 Launcher route + admin denial for owner

Steps:
1. Sign in as owner-only user.
2. Open launcher bot.
3. Send: admin dashboard.

Expected:
1. Route reaches Admin Agent path.
2. Admin Agent denies tenant-wide access.
3. User receives guidance to continue in Owner Agent.

Evidence:
1. Screenshot of denial message.

---

### SMK-04 Admin direct hard-deny

Steps:
1. Sign in as non-admin user.
2. Open Admin Agent directly.
3. Send: show all non-compliant sites.

Expected:
1. Deny message is immediate and clear.
2. No admin data returned.

Evidence:
1. Screenshot of deny response.

---

### SMK-05 Owner certify success

Steps:
1. Sign in as owner with known owned site.
2. Open Owner Agent.
3. Send: certify [site].
4. Confirm action.

Expected:
1. Callback executes successfully.
2. Contoso Sites row updated for certify path.
3. Action log row created with completed status.

Evidence:
1. Chat success screenshot.
2. Contoso Sites before/after evidence.
3. Governance Action Log row screenshot.

---

### SMK-06 Owner authorize guard

Steps:
1. Sign in as user who does not own target site.
2. Open Owner Agent.
3. Attempt certify target site.

Expected:
1. Authorization deny response.
2. No data write.
3. No completed action entry.

Evidence:
1. Deny screenshot.
2. Data/log no-change evidence.

---

### SMK-07 Admin assign owner

Steps:
1. Sign in as admin user.
2. Open Admin Agent.
3. Send assign owner request.
4. Confirm request.

Expected:
1. Callback branch ASSIGN-OWNERS executed.
2. Site owner field updated as expected.
3. Action log captures previous/new owner values.

Evidence:
1. Chat success screenshot.
2. Site row before/after.
3. Action log row screenshot.

---

### SMK-08 Launcher behavior guard

Steps:
1. Open launcher bot.
2. Send: help.
3. Send: certify site.

Expected:
1. Launcher does not execute certify logic directly.
2. Launcher provides handoff/menu behavior.

Evidence:
1. Chat screenshots showing routing-only behavior.

---

## 5. Exit Criteria

All required:
1. SMK-01 through SMK-08 pass.
2. No unauthorized admin data exposure.
3. No launcher direct-write behavior observed.
4. Callback-based writes produce expected audit records.

---

## 6. Result Template

- Date/Time (UTC):
- Environment:
- Build/Export Version:
- Tester:
- Passed Cases:
- Failed Cases:
- Blocking Issues:
- Follow-up Actions:
