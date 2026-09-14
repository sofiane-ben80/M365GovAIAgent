---
name: check-governance-action-status
description: Check an archive, deletion-review, or support request submitted by the signed-in user. Use when a user asks whether a request finished, is pending, failed, or was rejected.
---

# Check governance action status

Use `GovernanceData-GetRequestStatus` with the request ID or canonical site URL and signed-in user's principal name. The tool must enforce requester scope unless current-session admin authorization is supplied.

1. Resolve the site if the request doesn't include an unambiguous canonical URL.
2. Request the latest matching action, optionally filtered by action type.
3. Report action type, requested time, requester, current status, and the safe user-facing notes returned by the tool.
4. Distinguish `PENDING`, `COMPLETED`, `REJECTED`, `CANCELLED`, and `FAILED` exactly.

Do not expose approval secrets, connector diagnostics, or audit entries for unauthorized sites. If no matching audit entry exists, say so rather than inferring status from the site's current compliance fields.