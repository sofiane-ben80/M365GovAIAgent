# Orchestrator Live Baseline - 2026-09-14

## Scope

This baseline compares the checked-in `agents/M365 Governance Agent` package at commit `4b70c6a` with the live Copilot Studio bot pulled on 2026-09-14.

| Item | Value |
| --- | --- |
| Environment | `9417045e-87bb-eac8-bda1-850674b11405` |
| Bot | `d610fa66-3e1e-f111-8341-6045bd088c4f` |
| Local package | `agents/M365 Governance Agent` |
| PAC version | `2.11.2+g47bc199` |
| Pull result | 12 Copilot Studio changes applied |

The live pull was first performed in ignored storage and compared without changing tracked files. It was then pulled into the tracked package on a feature branch after the differences were classified.

## Verified live configuration

| Area | Live value |
| --- | --- |
| Display name | Governor M365 |
| Schema name | `copilots_header_04c70` |
| Authentication | Integrated; always triggered |
| Access policy | Group membership |
| Channels | Microsoft Teams and Microsoft 365 Copilot |
| Connected agents | `copilots_gov_owner_01`, `copilots_gov_admin_01` |
| Generative orchestration | Enabled |
| Web browsing | Disabled |
| Code interpreter | Disabled |
| File analysis | Disabled |
| Semantic search | Enabled |
| Model knowledge | Enabled |
| Content moderation | High |
| Latest-model opt-in | Disabled |
| Connection references | SharePoint Online only |
| Topics | 23 |
| Embedded workflows | 1: `GovernanceAgent-CheckAdminRole` |
| Published timestamp reported by PAC | 2026-07-25 22:38:14 UTC |

## Material differences found

### Connected-agent routing

The local `AdminDashboard` and `MySites` topics set `Topic.CallerUPN`, printed handoff text, and ended the dialog. They did not invoke another agent.

The live topics include these connected-agent actions:

- `AdminDashboard` invokes `InvokeConnectedAgentTaskAction.GovernanceAdminAgent`.
- `MySites` invokes `InvokeConnectedAgentTaskAction.GovernanceOwnerAgent`.

The live pull also added the corresponding declarations under `agents/M365 Governance Agent/agents`. This is functional live source and must remain checked in. Pushing the previous local package would have removed working orchestration.

### Launcher capabilities and display

The previous local package differed from live as follows:

| Setting | Previous local | Live baseline |
| --- | --- | --- |
| Display name | M365 Governance Agent | Governor M365 |
| Web browsing | Enabled | Disabled |
| Code interpreter | Unspecified | Disabled |
| File analysis | Enabled | Disabled |
| Model hint | GPT41 | No custom model hint |
| Content moderation | Unspecified | High |

The live values better match the intended narrow launcher role and are adopted as the baseline.

### Workflows and connections

The previous local package contained five embedded workflows. Live contains only `GovernanceAgent-CheckAdminRole`; ActionCallback, AdaptiveCardResponse, AdminDigest, and OwnerNotification are no longer embedded in this launcher package.

The surviving role-check workflow has the same behavior. Live metadata marks it active, declares the SharePoint connection reference, and serializes apostrophes as Unicode escapes. Those are server-generated representation and activation differences.

The previous local package declared SharePoint and Teams connections. Live declares SharePoint only.

### Unchanged surfaces

- Launcher description and instruction text are unchanged.
- Topic names and count are unchanged at 23.
- Authentication mode, access policy, channels, generative orchestration, and published timestamp are unchanged.
- No credentials, secrets, or tokens were introduced by the pull.

## Known design debt

1. The launcher still carries 23 classic topics even though its target role is only menu, clarification, and connected-agent routing. Review each topic before removing it; some may still provide trigger coverage or system behavior.
2. The connected Owner declaration says the agent allows certification, while the current target Owner design explicitly prohibits owner certification and attestation. Align the connected-agent description with the target policy.
3. The classic Owner and Admin packages enable web browsing and use a GPT41 model hint. Reassess these settings against the least-capability target design.
4. Launcher instructions say to pass `System.User.PrincipalName`, but connected-agent invocation uses conversation history and no explicit input mapping is visible in the exported task declarations. Verify identity propagation in a focused end-to-end test; authorization must remain server-side regardless.
5. The launcher retains an embedded admin-role workflow even though the architecture assigns authorization to the Admin agent. Confirm whether any launcher topic still invokes it, then remove it from the launcher if unused.
6. The skills-based definitions and classic deployable packages are not yet equivalent. Treat `new-agents` as target design and `agents` as operational source until migration acceptance tests pass.

## Regression checks

Before publishing a launcher change:

1. `show my sites` invokes Governance Owner Agent.
2. `admin dashboard` invokes Governance Admin Agent.
3. An ambiguous request asks one clarification question.
4. The launcher does not query site inventory or invoke write workflows.
5. A non-admin cannot obtain tenant-wide data after routing to Admin.
6. Owner requests cannot return another owner's sites.
7. Missing connected agents or tools produce a safe failure, not fabricated data.
8. A PAC pull after publish produces only reviewed server metadata changes.