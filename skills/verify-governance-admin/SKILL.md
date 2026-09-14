---
name: verify-governance-admin
description: Verify that the signed-in user belongs to the configured Governance Admin group before any tenant-wide governance query or admin write. Use whenever an admin dashboard, tenant-wide list, orphaned-site review, attestation review, owner assignment, or admin disposition is requested.
---

# Verify governance admin access

Call `GovernanceAgent-CheckAdminRole` with `System.User.PrincipalName`. Never accept a UPN supplied in the user's message.

- Treat only `isAdmin: true` from a successful call in the current conversation as authorization.
- If false, deny the tenant-wide operation and direct the user to the Governance Owner Agent for owner-scoped work.
- If the tool is unavailable, times out, or returns an invalid result, fail closed. State that admin access couldn't be verified.
- Recheck before a high-impact admin write if the prior result is unavailable or stale.

Authorization permits the requested admin workflow; it does not remove confirmation requirements or allow direct writes outside governance tools.