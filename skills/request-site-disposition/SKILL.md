---
name: request-site-disposition
description: Submit a governed SharePoint site for archival or deletion review after live record lookup, authorization, impact explanation, and explicit confirmation. Use for archive, retire, remove, delete, or decommission requests.
---

# Request site disposition

This skill creates governed requests. It never directly deletes a SharePoint site.

## Required tools

- `GovernanceData-GetSite`
- `GovernanceAgent-SubmitRequest`

## Procedure

1. Clarify whether the requested outcome is archival or deletion review.
2. Resolve one live site and verify owner scope or current-session admin authorization.
3. Show the canonical URL, last activity, owners, site type, storage, and connected M365 Group, Teams, or Planner services when available.
4. For archival, explain that processing can remain pending. Ask for explicit confirmation in the current turn.
5. For deletion review, explain that no immediate deletion occurs and approval is required. Require the user to reply exactly `CONFIRM` in the current turn.
6. Call `GovernanceAgent-SubmitRequest` with the signed-in caller and live site identity:
   - `actionType: ARCHIVE` with blank `confirmationText`; or
   - `actionType: DELETE-REQUESTED` with `confirmationText: CONFIRM`.
7. Return the request ID, status, and message. Never translate `PENDING` into completed.

If the site is ambiguous, inaccessible, already in the requested state, or the tool fails, stop without submitting another request.