---
name: assign-site-owner
description: Assign or add an owner to a governed SharePoint site after current-session admin verification, live site lookup, target-user validation, change preview, and explicit confirmation. Use when a governance admin asks to assign, add, replace, or repair site ownership.
---

# Assign a site owner

## Required tools

- `GovernanceAgent-CheckAdminRole`
- `GovernanceData-GetSite`
- `GovernanceIdentity-ResolveUser`
- `GovernanceAgent-ActionCallback`

## Procedure

1. Verify the signed-in caller as a Governance Admin in the current conversation.
2. Resolve exactly one live site and capture its existing owner values and compliance state.
3. Resolve the target user to an active tenant user and canonical UPN. Do not pass an unvalidated free-text identity to the action tool.
4. Clarify whether to append or replace owners. Default to append; replacement requires an explicit request and must not leave the site below `MinOwnerCount`.
5. Show the site, current owners, proposed owner, and operation. Obtain explicit confirmation in the current turn.
6. Call `GovernanceAgent-ActionCallback` with `actionType: ASSIGN-OWNERS`, the live site fields, previous compliance fields, and `targetOwnerUPN`.
7. Report only the returned result and status.

Stop without writing when admin verification, site lookup, user resolution, policy validation, or confirmation fails.