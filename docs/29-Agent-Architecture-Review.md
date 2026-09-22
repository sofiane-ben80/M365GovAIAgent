# 29 - Current Agent Architecture Review

**Review date:** 2026-09-21  
**Environment:** Sofiane Benabderrahmane's Environment  
**Solution:** `M365Governance` 2.0.0.0  
**Decision:** Use local child agents beneath the manually authenticated
Governor M365 launcher. Retain the independently published agents for future
reuse, but do not connect them to the manual-authentication launcher.

## Executive assessment

Governor M365 now implements the intended multi-agent separation without
crossing the incompatible connected-agent authentication boundary:

- Governor M365 is the single Canvas-facing supervisor and uses manual Entra
  authentication.
- Seven local child agents are enabled beneath Governor M365.
- Governor's instructions are limited to authentication-context preservation,
  intent classification, child selection, minimized context transfer, and
  response coordination.
- Owner Operations owns the owner portfolio and exact-site review topics.
  Admin Operations owns the tenant dashboard topic. Each topic calls an
  authorization-enforcing Dataverse flow.
- The five advisor children are read-only and retain their bounded specialist
  instructions.
- Governor has zero active `InvokeConnectedAgentTaskAction` components.

This is the recommended topology for the current channel constraint. Local
children share Governor's authentication, conversation, settings, and
publication lifecycle, so the Canvas/PCF manual-authentication boundary is not
crossed.

## Live topology

```text
Canvas app
  -> Governor365.AgentChat PCF
    -> Direct Line + Entra token exchange
      -> Governor M365 (manual Entra authentication)
        -> Owner Operations
          -> child-owned My Sites topic
          -> List Owner Sites authorized flow
        -> Admin Operations
          -> child-owned Admin Dashboard topic
          -> List Admin Sites authorized flow
        -> Governance Policy Advisor
        -> Copilot Readiness Advisor
        -> Data Protection Advisor
        -> Identity Governance Advisor
        -> Security & Compliance Assurance
```

The independently published Owner, Admin, and advisor agents remain separate
environment records. They are not invoked as connected agents from Governor
M365.

## Evidence reviewed

### Live Copilot Studio

- Governor M365 is published, active, and provisioned.
- Its **Agents** area lists seven enabled local relationships:
  - Owner Operations
  - Admin Operations
  - Governance Policy Advisor
  - Copilot Readiness Advisor
  - Data Protection Advisor
  - Identity Governance Advisor
  - Security & Compliance Assurance
- Copilot Studio published the complete child graph successfully.
- An advisor routing test for GCC Copilot readiness followed the Copilot
  Readiness Advisor's evidence-freshness and no-static-claim guardrails.
- An explicit Owner Operations test reached the child-owned `My Sites` path
  and invoked its flow. Copilot Studio then requested the test channel's Office
  365 connection consent; that consent is separate from the Canvas PCF token
  exchange.

### Fresh solution export

- The seven `AgentDialog` child components and two child-owned operational
  topics are present in the `M365Governance` solution.
- Each child has its required routing description at
  `beginDialog.description`.
- Specialist behavior is stored under `settings.instructions`.
- The child-owned operational topics reference:
  - `68784ae7-b8b3-f111-aaac-000d3a367627` (`List Owner Sites`)
  - `364a1e5b-b9b3-f111-aaac-000d3a367627` (`List Admin Sites`)
- The package includes the matching bot-component/workflow relationships.
- The connected-agent guard reports zero active routes.
- The package-integrity guard reports zero missing dependencies and validates
  21 flow-bound components.

## Goal-by-goal assessment

| Architectural goal | Current state | Assessment |
|---|---|---|
| Governor performs handoffs to two operational and specialist agents | Seven local children are enabled beneath Governor | Aligned |
| Governor does not perform domain actions | Governor instructions are routing-only; operational execution is child-owned | Aligned |
| Follow recommended multi-agent architecture | Local children share the parent authentication and lifecycle as required by this channel | Aligned |
| Canvas PCF supports manual authentication, ideally SSO | Manual Entra token exchange and interactive popup fallback remain unchanged | Aligned |
| Canvas can trigger agent messages | Implemented through visible messages and bounded context | Aligned |
| Parent-child relationship is visible and intentional | Copilot Studio shows seven `Child` relationships | Aligned |

The implemented specialist count is five:

1. Governance Policy Advisor
2. Copilot Readiness Advisor
3. Data Protection Advisor
4. Identity Governance Advisor
5. Security & Compliance Assurance

Earlier documents also mention Triage and Action subagents. Those are
domain-internal responsibilities, not a sixth specialist-advisor domain.

## Authentication and authorization decision

The Canvas PCF channel requires Governor M365 to use manual Entra
authentication. In this environment:

- a manual launcher invoking an Integrated connected agent fails with
  `ConnectedAgentAuthMismatch`;
- changing a destination agent to manual authentication fails publication with
  `PublishNotAllowedException`;
- local child agents publish successfully and share Governor's authentication
  and conversation.

The child relationship solves composition, not authorization. Every
operational flow must continue to:

- derive caller identity from `System.User.PrincipalName`;
- resolve privileged callers to their immutable Entra object ID with the
  environment-owned Office 365 Users connection;
- ignore user-supplied UPNs and authorization claims;
- require exactly one active, in-window `GovernanceAdmin` row in Governance
  Role Assignment for the resolved object ID on every privileged operation;
- fail closed when authorization, live data, or required tools are unavailable;
- require current-turn confirmation for governed write requests.

Exact-site reviews route to Owner Operations for every supported persona. The
Canvas app sends only the selected Governance Site ID. `Governor365 - Agent -
Get Site Detail` retrieves the live row and permits the read only when the
caller has an active assignment to that exact site or one valid
`GovernanceAdmin` assignment. Admin Operations must not replace an exact-site
review with the tenant dashboard.

## Rollback topics

Published Canvas/PCF parity tests passed for both child-owned operational
routes. The original root `My Sites` and `Admin Dashboard` topics are now
disabled. They remain in the solution only as a time-bounded rollback path and
must not gain new capabilities.

Do not delete the disabled root topics until the post-cutover monitoring period
completes. Re-enabling either topic requires a documented rollback decision,
Governor republish, and repeat authorization tests.

## Release state

- Live child topology: published.
- Canonical unmanaged solution: refreshed.
- Connected-agent compatibility guard: passed, active routes `0`.
- Package-integrity guard: passed, missing dependencies `0`, flow-bound
  components `22`, topic-to-flow relationships `23`, distinct cloud flows
  `11`.
- Canonical ZIP SHA-256:
  `ACDA175EEFC648157A36D41CAE9BA50EA158B91572C48E7EDFDA204549806F12`.
- Published Canvas/PCF parity: passed for Owner Operations, Admin Operations,
  and advisor routing.
- Published exact-site review: passed for the admin Canvas entry point and
  direct ID `c409b1c0-a8b2-f111-aaac-000d3a367627`; no list operation or
  follow-up site-ID prompt occurred.
- Governed-action submission is child-owned and uses the existing five-button
  menu. Certify, Archive, Deletion review, and Assign owners collect
  action-specific input and explicit current-turn confirmation before invoking
  the authorization-enforcing Submit Request flow. Cancel performs no write.
- A successful submission records a Governance Action Request and Submitted
  event, not a completed site operation. Certification uses the scheduled
  Dataverse processor. Archive, deletion review, and owner assignment remain
  approval- and connector-gated and fail closed when those dependencies are
  unavailable.
- The expanded action graph was imported and published successfully on
  2026-09-22. The live bot synchronization record reports `Succeeded` with no
  diagnostics, and the deployed Site Review component contains both the
  exact-site read and Submit Request tool references. The recurring request
  processor is active.
- Root operational topics: disabled after successful parity tests.

## References

- [Agent orchestration architecture](22-Agent-Orchestration-Architecture.md)
- [Agent design](03-AgentDesign.md)
- [Deployment status and runbook](25-Deployment-Status-and-Runbook.md)
- [Add a child agent](https://learn.microsoft.com/microsoft-copilot-studio/add-agent-child-agent)
- [Add other agents](https://learn.microsoft.com/microsoft-copilot-studio/authoring-add-other-agents)
