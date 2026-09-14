# M365 Governance Copilot Studio Agents

Source-controlled definitions and authoring assets for the M365 governance agents built with Microsoft Copilot Studio.

This repository intentionally contains only agent-related material. The remediation dashboard Power App, infrastructure, SQL, sample data, and tenant administration scripts live outside this repository.

## Start here

Hackathon team members should begin with the [team review packet](docs/team-review-packet.md). It summarizes the problem, current implementation status, design decisions, open questions, review scenarios, and contribution workflow. Detailed architecture and live comparison evidence are linked from that packet.

## Repository layout

| Path | Purpose |
| --- | --- |
| `agents/Governance Owner Agent` | Owner-scoped Copilot Studio agent package |
| `agents/Governance Admin Agent` | Administrator Copilot Studio agent package |
| `agents/M365 Governance Agent` | Combined agent retained as an optional launcher and migration fallback |
| `agents/*.ps1` | Export, deployment, and source-sync helpers |
| `flows` | Power Automate flow contracts and implementation notes used by the agents |
| `new-agents` | Instructions for the skills-based Copilot Studio agent experience |
| `skills` | Reusable governance skill definitions |
| `docs/team-review-packet.md` | Teammate orientation, project status, and review checklist |
| `docs/architecture.md` | Target architecture, responsibilities, and security invariants |
| `docs/live-baseline-2026-09-14.md` | Verified local-to-live orchestrator comparison |

The local `agents/exports` directory is ignored because it contains timestamped backups and generated packages rather than source of record.

## Prerequisites

- PowerShell 7 or Windows PowerShell 5.1
- [Microsoft Power Platform CLI](https://learn.microsoft.com/power-platform/developer/cli/introduction)
- A PAC authentication profile with access to the target Power Platform environment
- Copilot Studio permissions to update and publish the target agents

## Deploy agent definitions

Set the target environment for the current shell. Set the bot ID only when opening the publish page for the combined agent.

```powershell
$env:POWER_PLATFORM_ENVIRONMENT_ID = '<environment-id>'
$env:COPILOT_STUDIO_BOT_ID = '<bot-id>'

Set-Location .\agents
.\deploy-governance-agents.ps1 -DryRun
.\deploy-governance-agents.ps1
```

Add `-Publish` to open Copilot Studio after pushing the projects. Publishing remains a deliberate browser action.

To deploy one project only:

```powershell
.\deploy-copilot-agent.ps1 `
    -ProjectDir '.\Governance Owner Agent' `
    -EnvironmentId '<environment-id>'
```

## Export and sync

Use `agents/export-copilot-agent.ps1` to pull and package an agent into the ignored `agents/exports` directory. Use `agents/sync-copilot-agent.ps1` or `agents/sync-copilot-agent-full.ps1` for the guarded pull, publish, pull, and commit workflow.

Always pull and review the live agent before pushing. Copilot Studio stores connected-agent declarations and invocation actions in generated source files; a stale local push can remove working handoffs even when the launcher instructions look correct.

The checked-in `.mcs.yml` and workflow files are Copilot Studio source exports. They include environment resource identifiers and connection references required by the packages, but must never contain passwords, client secrets, access tokens, or exported connection credentials.

## Release workflow

1. Create a feature branch before changing or pulling agent definitions.
2. Pull the latest Copilot Studio source and review the diff.
3. Commit the source changes.
4. Push the project with the deployment helper and publish it in Copilot Studio.
5. Pull once more to capture server-generated metadata, then commit and push the final state.