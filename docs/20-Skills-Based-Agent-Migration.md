# 20 - Skills-Based Copilot Studio Agent Migration

**Target:** Copilot Studio new agent experience (GitHub Copilot harness)  
**Status:** Authoring package ready; live tools require configuration and verification  
**Date:** 2026-08-08

## 1. Decision

Recreate the Owner and Admin agents in the new agent experience. Keep the combined M365 Governance Agent only as an optional launcher. Do not import the legacy topic folders into the new agents.

In the new experience:

- agent instructions define global identity, security, and response behavior;
- skills define reusable task procedures and orchestration guidance;
- tools perform SharePoint, identity, Power Automate, and audit operations;
- knowledge is for reference content, not authorization or transactional state.

Skills do not replace tools. A skill tells the agent when and how to call a tool; it cannot make the legacy placeholder topics operational by itself.

## 2. Legacy Analysis

| Legacy surface | Finding | New surface |
| --- | --- | --- |
| `MySites`, `SitesNeedingAttention`, `SiteDetail` | Hard-coded samples/placeholders | `owner-site-portfolio` plus governance data tools |
| `AdminDashboard`, `OrphanedSites`, `NotAttestedSites` | Hard-coded counts/placeholders | `admin-governance-review` plus admin data tools |
| Triage instructions | Reusable deterministic policy | `site-governance-assessment` |
| `ActionCertify`, `ActionArchive`, `ActionDelete` | Handoff scaffolds; no execution | Three action-oriented skills using ActionCallback |
| `ActionAssignOwners` | Redirect-only scaffold | `assign-site-owner` |
| `ActionStatus` | Scaffold | `check-governance-action-status` |
| Check Admin Role | Defined Power Automate contract | Tool used by `verify-governance-admin` |
| System topics | Harness conversation mechanics | New harness plus global instructions |
| Trigger phrases | Classic NLU routing | Skill names/descriptions selected by orchestration |

## 3. Skill Catalog

| Skill | Owner | Admin | Required tool contracts |
| --- | :---: | :---: | --- |
| `owner-site-portfolio` | Yes | No | ListOwnerSites, GetSite |
| `verify-governance-admin` | No | Yes | CheckAdminRole |
| `admin-governance-review` | No | Yes | GetAdminDashboard, ListAdminSites, GetSite |
| `site-governance-assessment` | Yes | Yes | GetGovernanceConfig |
| `certify-governance-site` | Yes | Yes | GetSite, ActionCallback |
| `request-site-disposition` | Yes | Yes | GetSite, ActionCallback |
| `assign-site-owner` | No | Yes | CheckAdminRole, GetSite, ResolveUser, ActionCallback |
| `check-governance-action-status` | Yes | Yes | GetActionStatus |

Each folder under `copilot/skills` is directly uploadable by selecting its `SKILL.md`. It can also be zipped with `SKILL.md` at the package root if supporting files are added later.

## 4. Tool Gap

Existing repository contracts cover:

- `GovernanceAgent-CheckAdminRole`
- `GovernanceAgent-ActionCallback`
- `GovernanceAgent-AdaptiveCardResponse`

The following read/identity tools must be implemented or bound before the new agents are production-ready:

- `GovernanceData-ListOwnerSites` (Dataverse-backed Power Automate tool)
- `GovernanceData-GetSite`
- `GovernanceData-GetAdminDashboard`
- `GovernanceData-ListAdminSites`
- `GovernanceData-GetGovernanceConfig`
- `GovernanceData-GetActionStatus`
- `GovernanceIdentity-ResolveUser`

Tool descriptions must say when to use them, inputs must be typed, and every data tool must enforce authorization server-side. Prompt instructions are defense in depth, not the security boundary.

## 5. Build Procedure

1. In Copilot Studio, create an agent with the **new agent experience / GitHub Copilot harness**.
2. Create **Governance Owner Agent** and paste the description and instructions from `copilot/new-agents/governance-owner-agent.md`.
3. On **Build > Skills > Upload a skill**, upload the five Owner skills listed in that file.
4. Add and configure the Owner tool contracts. Use the signed-in user's connection or a secured service identity as policy requires.
5. Repeat for **Governance Admin Agent** using `copilot/new-agents/governance-admin-agent.md` and its seven skills.
6. Configure CheckAdminRole before adding any admin data tools. Verify that failures deny access.
7. Test each agent in Preview, then publish to a pilot audience. The new harness consumes Copilot Credits during building, testing, evaluation, and use.

The feature is production-ready preview as of June 2026. Keep the classic agents available during pilot and do not retire them until tool and authorization tests pass.

## 6. Acceptance Tests

| Scenario | Expected result |
| --- | --- |
| Owner asks for their sites | Live owner-scoped results only; no sample data |
| Owner asks for another user's site | Denied or no result |
| Owner asks for tenant dashboard | Directed to Admin Agent; no tenant data |
| Non-admin asks for admin dashboard | CheckAdminRole fails closed |
| Tool is unavailable | Agent reports inability; does not invent data |
| Certification without current-turn confirmation | No ActionCallback call |
| Delete request without exact `CONFIRM` | No ActionCallback call |
| ActionCallback returns `PENDING` | Agent reports pending, not completed |
| Ambiguous site title | Agent requests disambiguation before action |
| Owner assignment with unresolved target UPN | No write occurs |

## 7. Source References

- [Skills overview](https://learn.microsoft.com/microsoft-copilot-studio/agents-experience/skills-overview)
- [Create a skill](https://learn.microsoft.com/microsoft-copilot-studio/agents-experience/skills-create)
- [Add an existing skill](https://learn.microsoft.com/microsoft-copilot-studio/agents-experience/skills-add-existing)
- [Manage skills](https://learn.microsoft.com/microsoft-copilot-studio/agents-experience/skills-manage)
- [What's new in Copilot Studio](https://learn.microsoft.com/microsoft-copilot-studio/whats-new)