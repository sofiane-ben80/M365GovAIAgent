# Live Agent Reconciliation - 2026-09-16

## Scope

This reconciliation inventories the target Copilot Studio environment and
compares freshly extracted live templates with the checked-in agent source.
The extraction was stored under the ignored `agents/exports` directory so no
tracked source was overwritten.

| Item | Value |
| --- | --- |
| Environment | `9417045e-87bb-eac8-bda1-850674b11405` |
| Authenticated account | `sofianeb@MngEnvMCAP733570.onmicrosoft.com` |
| PAC version | `2.2.1+g666525f` |
| Capture method | `pac copilot list` and `pac copilot extract-template` |
| Capture folder | `agents/exports/live-compare-20260916` |
| Deployment changes made | None |

The installed PAC build can list agents and extract complete component
templates, but it does not expose `pac copilot pull`. Full source pull remains
blocked until the newer CLI used for the September 14 baseline is restored.

## Live inventory

| Display name | Bot ID | State | Status |
| --- | --- | --- | --- |
| Governor M365 | `d610fa66-3e1e-f111-8341-6045bd088c4f` | Published | Active |
| Governance Owner Agent | `18c2cb08-2014-47a3-8c0c-5baeecf4f5e3` | Published | Active |
| Governance Admin Agent | `c7eea6a2-3fc0-4e3a-8ebb-56ff7a390033` | Published | Active |
| Contoso Customer Assistant | `c04ab830-695b-4fc9-9db0-bfae94eae490` | Published | Active |
| TestMA1 | `c91f125c-456c-4c95-bea2-271f6594e8fd` | Published | Active |

All five agents are unmanaged and currently report the default solution ID.
Only the three governance agents are in scope for this repository.

## Reconciliation result

### Governor M365

The live template contains 23 topics, two connected-agent actions, and the
content-moderation component. After normalizing the template namespace
(`template-content`) to the checked-in schema namespace, all launcher topics
and connected-agent actions match local source. No online-only launcher change
needs to be imported.

### Governance Owner Agent

Live contains older classic behavior that conflicts with the Power
Platform-first local target:

- online-only `CertifySite` and `ActionCertify` components allow owner
  certification through hard-coded placeholders rather than the approved
  Dataverse request contract;
- `ProcessUserRequest` is online-only and must be reviewed before adoption;
- the live greeting, conversation start, status, archive, deletion, escalation,
  site list, and site detail paths retain certification and routing scaffolds;
- the live `MySites` topic lacks the newer local adaptive-card list and live
  owner-scoped flow wiring;
- the live `SiteDetail` still contains hard-coded sample records.

Decision: preserve the extracted template as evidence. Owner certification is
supported by the target only through a fresh owner check, explicit confirmation,
and `GovernanceAgent-SubmitRequest`; hard-coded completion behavior is not
accepted.

### Governance Admin Agent

Live contains six Owner-oriented components that are absent from the local
Admin package: `SitesNeedingAttention`, `SiteDetail`, `RequestArchival`,
`MySites`, `FlagForDeletion`, and `CertifySite`. Its conversation-start topic
also behaves like a launcher and offers owner certification.

The live `AdminDashboard` includes a richer Adaptive Card design. The matching
card asset exists at the workspace-level `adaptive-cards/admin-dashboard-card.json`.
Its `${...}` values are placeholders and must be bound to an authorized live
dashboard tool before production use.

Decision: do not import the mixed Owner/launcher components. Preserve the
dashboard card as an authoring asset and wire it only when the admin
authorization check and live dashboard data contract are active.

## New advisor readiness

After the reconciliation capture, all five domain advisor shells were created
and published in the target environment:

| Agent | Bot ID |
| --- | --- |
| Governance Policy Advisor | `0af1ffd3-d69a-4313-9bcb-05c91c19ffd6` |
| Copilot Readiness Advisor | `a303e7c0-110d-4f10-9736-53dd7c51b040` |
| Data Protection Advisor | `7f9c6873-cf91-455e-95f7-86321e2f84a3` |
| Identity Governance Advisor | `7f385fc4-d4a2-42f0-b9e7-0890096b6fed` |
| Security & Compliance Assurance | `ad57f320-41aa-4e1b-8b85-e432ba139ebc` |

PAC list/status reports each shell as published, active, and provisioned.
Template extraction round-trip verification confirmed that all five live
descriptions and instructions match their source Markdown. Production tools
remain disabled until audience, authorization, evidence, and failure-path
tests pass.

## Safe next deployment sequence

1. Restore a PAC build that supports guarded source pull, then repeat the pull
   into ignored comparison folders.
2. Review and commit existing local documentation changes before modifying
   deployable classic packages.
3. Keep the five published advisor shells free of production connectors until
   audience and mismatch tests pass.
4. Complete each audience group, owner, and sharing policy in
   `new-agents/advisor-manifest.yml`.
5. Add launcher connected-agent declarations only after the shells are
   connectable and routing tests pass.
6. Keep conversation-history transfer disabled for advisors and verify one
   response owner per turn.
7. Bind Policy and Readiness tools first; add evidence-rich domains only in
   their approved release waves.
