# 24 - Hackathon Project Summary

## Project name

**Governor365 - AI-Powered Microsoft 365 Governance**

## One-line pitch

Governor365 combines a clean Canvas app with an integrated Copilot agent so
Microsoft 365 site owners and governance teams can see risk, understand it,
and take governed action from one intelligent workspace.

## Problem

Microsoft 365 governance is often fragmented across spreadsheets, scripts,
lists, administrative portals, and manual follow-up. Site owners do not know
which workspaces need attention, while governance teams spend time identifying
orphaned sites, chasing certifications, and reconstructing action history.

At enterprise scale, inactive sites, missing or outdated owners, excessive
external sharing, stale permissions, incomplete governance metadata, policy
gaps, and Microsoft 365 Copilot readiness issues can remain hidden across
thousands of collaboration workspaces. Finding the risk is only the first
challenge: users must still interpret the evidence, identify the right action,
and navigate a separate process to remediate it.

## Solution

Governor365 makes the Canvas app the main experience and embeds a Copilot
Studio custom agent directly beside the governance workspace:

- owners get a focused view of their sites, risks, evidence, and next actions;
- admins get tenant-wide visual triage for ownerless, under-owned, stale,
  externally shared, noncompliant, and unattested sites;
- proactive AI briefings summarize the live portfolio when each role enters
  the app;
- selecting a site safely grounds the agent in the current record, avoiding
  repetitive prompts and disconnected answers;
- Canvas actions can ask the agent for a site review, while agent events can
  drive allowlisted navigation and interactions in the app;
- specialist advisors explain policy, readiness, data protection, identity, and
  assurance implications;
- Power Automate validates identity, processes requests and approvals, refreshes
  inventory, and sends Teams notifications;
- Dataverse provides a normalized, auditable operational record.

Instead of navigating multiple reports and administration portals, users can
ask questions such as:

- Which of my sites require attention, and why?
- Which workspaces have no accountable owner?
- Where does external sharing create the greatest risk?
- Which sites require certification, archival, or another governed action?
- What evidence is missing for this policy requirement?
- What should we address before expanding Microsoft 365 Copilot?

Governor365 combines contextual findings, supporting evidence, prioritized
recommendations, and guided next steps. The Canvas workspace makes the
portfolio easy to scan, while the agent explains complex governance signals in
natural language and helps move from insight to controlled action. Structured
responses and Adaptive Cards make complex findings easier to review and act
upon.

The current implementation focuses on SharePoint-backed collaboration
workspaces, including sites associated with Microsoft 365 Groups and Teams.
Its normalized data model and specialist-agent pattern are designed to extend
to additional Microsoft 365 workloads without redesigning the user experience.

## Multi-agent architecture

Behind the integrated assistant is a modular Copilot Studio architecture with
eight agents. **Governor M365** is the parent orchestrator and common
Canvas-facing conversational entry point. It identifies intent and delegates
the request to exactly one of seven local child agents. It does not query
tenant data or perform governance actions itself.

Two operational agents provide role-specific capabilities:

- **Owner Operations** provides self-service capabilities for signed-in site
  owners. It helps users review their portfolio, understand governance health,
  complete certification, request support, and initiate governed archival or
  disposition workflows.
- **Admin Operations** supports authorized tenant-level governance. It helps
  administrators review sites requiring attention, investigate ownerless
  workspaces, coordinate ownership remediation, monitor requests and approvals,
  and follow governance actions through completion.

Specialized advisor agents extend the platform with focused expertise:

- **Governance Policy Advisor** interprets governance requirements and connects
  policy expectations to available evidence.
- **Copilot Readiness Advisor** evaluates technical and organizational
  readiness for Microsoft 365 Copilot and identifies rollout prerequisites and
  risks.
- **Data Protection Advisor** evaluates classification, sharing, permissions,
  and information-protection concerns.
- **Identity Governance Advisor** examines ownership, access, roles, and
  identity-governance risks.
- **Security and Compliance Assurance Agent** reviews control evidence,
  highlights assurance gaps, and recommends remediation activities.

Each child has a bounded purpose, focused instructions, and only the tools
appropriate to its role. The local-child topology preserves the manually
authenticated Canvas session, conversation, and signed-in system context.
Operational children use authorized Power Automate tools for live data and
actions. Advisor children use governed evidence capabilities to produce
evidence-based recommendations.

The five specialist agent designs are also maintained as separately publishable
assets for future reuse, but the Canvas-facing Governor M365 agent invokes its
local children rather than crossing an unsupported authentication boundary.
This separation makes the solution easier to maintain, test, secure, and
extend. New specialist capabilities can be introduced without redesigning the
Canvas experience, while the orchestrator continues to provide one consistent
assistant.

## Governed evidence and automation

The agents share a governed evidence and automation layer rather than
connecting independently to tenant systems:

- reusable Power Automate tools expose bounded, stable contracts for owner and
  administrator operations;
- a governed evidence path supplies normalized policy, readiness, protection,
  identity, and assurance evidence to specialist advisors;
- Dataverse provides the shared operational record for sites, ownership,
  policy, requests, events, scan runs, and evidence;
- Microsoft Graph and SharePoint APIs provide approved live Microsoft 365
  metadata and execute approved workload changes;
- Power Automate retrieves inventory, validates identity and role, creates
  governance requests, manages approvals, tracks status, issues notifications,
  and returns structured results to the agent.

This design promotes reuse, traceability, least-privilege access, and
consistent transaction behavior. The orchestrator's routing decision and the
Canvas context never grant permission: every operational flow independently
derives caller identity and rechecks authorization.

## From insight to intelligent remediation

Governor365 goes beyond dashboards and reporting. Site owners can investigate
governance health, review sharing and ownership concerns, certify sites,
request support, and initiate archival or disposition workflows. Authorized
administrators gain a centralized view of organizational risk and can
coordinate owner assignment, approvals, and remediation across the tenant.

Human accountability remains central. Recommendations are tied to evidence;
privileged actions remain role-aware; destructive changes require explicit
confirmation and approval; and requests, decisions, state transitions, and
outcomes are recorded through auditable workflows. The agents help people make
better decisions and complete work without removing the oversight required for
enterprise governance.

## What makes it Power Platform-native

| Capability | Power Platform component |
|---|---|
| Primary user experience | Power Apps Canvas app |
| Embedded intelligent assistant | Copilot Studio custom agent through a PCF Web Chat control |
| Operational database | Microsoft Dataverse |
| Workflow and integration | Power Automate |
| Human approval | Power Automate Approvals |
| Role-aware visual triage | Owner and administrator Canvas screens |
| Notifications | Teams connector and Adaptive Cards |
| Deployment | Managed solutions, connection references, environment variables |
| Governance | Dataverse security, auditing, DLP, and Power Platform environments |

The target design does not require Azure SQL, SharePoint lists, Logic Apps, or
Function Apps.

## User journey

1. A site owner opens Governor365 and sees visual risk summaries, a searchable
   site list, site details, and the integrated assistant on one screen.
2. The assistant proactively briefs the owner on the most urgent live risks and
   recommends three next actions.
3. The owner filters the portfolio, selects a site, and chooses **Review
   selected site**.
4. The Canvas app sends an explicit prompt with approved site context to the
   agent; the prompt remains visible in the conversation.
5. Copilot Studio invokes bounded Power Automate tools, which independently
   revalidate the signed-in identity before reading Dataverse.
6. The agent explains the evidence and recommendation in plain language.
7. If the owner requests archival, Power Automate creates an auditable request,
   starts human approval, and returns a tracking ID.
8. The app, agent, and Teams notifications expose truthful status without
   claiming completion before the operation succeeds.

## Innovation

- **Canvas-first AI experience:** visual triage and conversational intelligence
  work together instead of forcing users to choose between a dashboard and a
  chatbot.
- **Context-aware assistance:** the embedded agent understands the active
  persona, screen, and selected site while every backend operation remains
  independently authorized.
- **Proactive intelligence:** role-specific briefings identify urgent patterns
  and recommend high-value actions as soon as the user enters the workspace.
- **Role-aware multi-agent design:** the custom agent routes to operational and
  advisory child agents without weakening authorization or losing the
  authenticated Canvas session.
- **Normalized governance graph:** sites, owners, requests, events, and evidence
  are related in Dataverse instead of embedded in text fields.
- **Secure low-code tools:** agents never trust model-provided identity and do
  not connect directly to unrestricted tables.
- **Explainable action lifecycle:** recommendations, approvals, state changes,
  and outcomes remain traceable to evidence and human decisions.
- **Asynchronous scale pattern:** scan runs and work items let Power Automate
  process large tenants safely with retries and reconciliation.

## Responsible AI and security

- Recommendations are advisory; destructive changes require confirmation and
  human approval.
- Owner and admin authorization is rechecked inside every tool flow.
- Responses expose only minimized fields authorized for the caller.
- Failures are explicit and correlated; connector errors never appear as
  successful empty results.
- Dataverse audit and append-only action events preserve accountability.
- DLP and managed solutions control connectors and deployment.

## Demo script

1. Open the Governor365 Canvas app in the owner experience.
2. Show the proactive AI portfolio briefing beside the visual risk cards.
3. Filter to sites needing attention and select a site from the results.
4. Choose **Review selected site** and show how the integrated agent uses the
   selected Canvas context to explain live evidence and recommendations.
5. Ask a policy, readiness, or assurance question and show the orchestrator
   handing the request to the appropriate specialist advisor.
6. Submit an archive request and display its Dataverse tracking ID and pending
   approval state.
7. Switch to the administrator screen and show tenant-wide risk filters plus
   the proactive admin briefing.
8. Review the pending request, Power Automate approval, and action-event
   timeline.
9. Highlight the managed solution, PCF agent integration, connection
   references, environment variables, security roles, and DLP controls.

## How we built it

- **Power Apps Canvas** provides role-specific dashboards, search, filters,
  detail views, semantic risk indicators, and action entry points.
- **A React PCF control** hosts Bot Framework Web Chat inside Canvas and uses
  the Copilot Studio Mobile app channel with short-lived tokens.
- **A versioned context contract** synchronizes approved persona, screen, and
  selected-site context from Canvas to the agent.
- **Copilot Studio** provides a thin orchestrator, separate owner and admin
  operational children, and five specialist governance advisor children.
- **Power Automate** exposes bounded tools for identity validation, inventory,
  requests, approvals, notifications, and reconciliation.
- **Dataverse** stores the normalized governance graph and append-only action
  history.
- **Managed Power Platform solutions** package the app, agent, flows, PCF
  control, tables, connection references, and environment variables.

## Challenges

- Embedding a useful assistant without treating model or Canvas context as an
  authorization claim.
- Keeping the conversation synchronized with changing app selections without
  sending sensitive evidence or credentials.
- Making the chat connection reliable in both Studio and the published Power
  Apps player; Direct Line HTTP polling provided stable behavior where the
  embedded WebSocket did not.
- Combining rich visual triage with AI assistance without overcrowding the
  operational workspace.

## Accomplishments and lessons

- We turned separate dashboard and chat concepts into one coherent,
  context-aware experience.
- Proactive role-specific briefings make the solution feel intelligent before
  the user writes a prompt.
- Visible Canvas-initiated prompts preserve user understanding and control.
- A strict separation between experience context and backend authorization is
  essential for secure enterprise AI.
- A parent/child agent model preserves one authenticated Canvas conversation
  while still separating operational and advisory responsibilities.
- Low-code components can support a sophisticated agent experience when their
  contracts, identity boundaries, and ALM model are explicit.

## Innovation and impact

Governor365 transforms Microsoft 365 governance from a reactive,
report-driven process into a proactive, visual, conversational, and AI-assisted
operating model. Its architecture combines specialized reasoning, governed
enterprise evidence, reusable automation, and human oversight in one extensible
Power Platform solution.

The expected impact is clearer accountability, faster remediation, less
administrative effort, stronger owner participation, improved security and
compliance, and better Microsoft 365 Copilot readiness. By bringing governance
insight and action together in one intelligent Canvas experience, Governor365
makes continuous governance practical for administrators and the people who
own collaboration workspaces.

## What is next

- Complete end-to-end tenant acceptance testing and managed deployment.
- Expand governed agent-to-Canvas actions using a strict action allowlist.
- Add measured usability and time-to-action results from owner and admin tests.
- Enhance analytics without competing with the core triage and assistant
  experience.

## Success measures

| Measure | Target |
|---|---|
| Owner data isolation tests | 100% pass |
| Requests with complete event trail | 100% |
| Duplicate requests for same idempotency key | 0 |
| Inventory records processed without manual handling | >= 99% per complete scan |
| Time to identify, understand, and submit an action | Under 3 minutes in demo |
| Selected-site review grounded without re-entering site details | 100% |
| Production dependencies outside Power Platform/M365 | 0 in target architecture |

## Submission description

Governor365 is an AI-powered Microsoft 365 governance solution that brings the
best of visual apps and conversational intelligence into one experience. A
role-aware Power Apps Canvas app gives site owners and administrators fast,
focused visual triage, while an integrated Copilot Studio custom agent provides
proactive briefings and context-aware guidance grounded in the selected site.
Behind that assistant, a thin parent orchestrator delegates to owner and admin
operational children or one of five specialist advisors for governance policy,
Copilot readiness, data protection, identity governance, and security and
compliance assurance. Dataverse stores normalized sites, ownership, requests,
policy, evidence, and audit events. Power Automate implements secure tools,
approvals, inventory, notifications, and reconciliation. The result replaces
fragmented scripts, spreadsheets, portals, and disconnected chat with a clean,
intelligent, explainable, extensible, and auditable Power Platform solution.

**GitHub:** [github.com/sofiane-ben80/M365GovAIAgent](https://github.com/sofiane-ben80/M365GovAIAgent)
