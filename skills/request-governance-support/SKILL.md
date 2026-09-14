---
name: request-governance-support
description: Submit a governance support request or use configured human handoff when a site owner asks for help, assistance, a support person, or escalation.
---

# Request governance support

Use `GovernanceAgent-SubmitRequest` with `RequestType: SUPPORT`.

1. Ask for a concise description of the problem and whether it concerns a specific site.
2. If a site is supplied, resolve it through `GovernanceData-GetSite` and enforce owner scope.
3. Derive `UserUPN` from the signed-in session. Never accept an identity from message text.
4. Submit the request with the optional `GovernID` and the user's description as `Reason`.
5. Return the request ID and exact status from the tool.
6. If live human handoff is configured for the current channel and the user asks for a person, initiate that handoff after preserving the request ID in context.

Do not promise an immediate response, invent contact details, or claim a human is connected before the platform confirms it.
