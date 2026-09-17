# New Agent Authoring Assets

This folder contains source-controlled authoring definitions for the Copilot
Studio new agent experience.

## Agent portfolio

| Agent | Release wave | Initial state |
| --- | --- | --- |
| Governance Owner Agent | Foundation | Existing migration target |
| Governance Admin Agent | Foundation | Existing migration target |
| Governance Policy Advisor | Wave 1 | Shell ready; tools and knowledge not bound |
| Copilot Readiness Advisor | Wave 1 | Shell ready; tools and knowledge not bound |
| Data Protection Advisor | Wave 2 | Shell ready; tools and knowledge not bound |
| Identity Governance Advisor | Wave 3 | Shell ready; tools and knowledge not bound |
| Security & Compliance Assurance | Wave 4 | Shell ready; tools and knowledge not bound |

`advisor-manifest.yml` is the review and deployment inventory for the five
advisor shells. Each agent file contains the description, launcher route
description, production instructions, internal composition, required tools,
knowledge boundaries, and shell acceptance checks.

## Safe authoring sequence

1. Create the five shells in the target environment without production tools.
2. Apply the description and instructions from the matching Markdown file.
3. Configure the audience group, owner, sharing, and connectability.
4. Keep conversation-history transfer disabled.
5. Publish the shell and record its bot ID and schema name in the manifest.
6. Add the connected-agent declaration to Governor M365 only after mismatch,
   ambiguity, authorization, and single-response tests pass.
7. Bind tools and knowledge in release-wave order. A shell must report that
   live evidence is unavailable until its authorized tools are configured.

## CLI deployment

From `copilot/agents`, preview or run the repeatable shell deployment:

```powershell
.\publish-advisor-agents.ps1 `
    -EnvironmentId '9417045e-87bb-eac8-bda1-850674b11405' `
    -Create `
    -Publish `
    -DryRun

.\publish-advisor-agents.ps1 `
    -EnvironmentId '9417045e-87bb-eac8-bda1-850674b11405' `
    -Create `
    -Publish
```

Use `-AgentKey governance-policy-advisor` to deploy one canary. Generated PAC
templates are written under the ignored `agents/exports/advisor-publish`
directory. The script never places credentials in source.

Do not deploy the classic Owner/Admin live definitions over the hardened local
packages without reviewing the dated live-baseline report. Live currently
contains legacy components that conflict with the target security boundaries.
