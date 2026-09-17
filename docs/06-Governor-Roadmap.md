# M365 Governor Integration Roadmap

> Portfolio decision: the selected six-agent minimum and two second-wave additions are recorded in `07-Selected-Agents.md`.
>
> The executable component backlog, orchestration topology, agent build
> specifications, connector sequence, ALM plan, and release gates are defined
> in [09-Advisor-Implementation-Roadmap.md](09-Advisor-Implementation-Roadmap.md).

## Executive recommendation

Do not import the downloaded agents wholesale and do not attach all of them to the launcher. Treat the specifications as reusable designs and rebuild selected capabilities inside explicit security and lifecycle boundaries.

Retain the current three-agent design:

1. **Governor M365 launcher:** route and explain only.
2. **Governance Owner Agent:** signed-in user's SharePoint sites and governed owner requests only.
3. **Governance Admin Agent:** admin-verified tenant-wide SharePoint governance only.

Add domain agents only when the audience, data, connector identity, lifecycle, or reusable purpose differs. The recommended first additions are:

1. **Governance Policy Advisor** - strategy, maturity, policy drafting, and governed knowledge.
2. **Copilot Readiness Advisor** - GCC/GCC High readiness, rollout gates, current capability verification, and feature governance.
3. **Data Protection Advisor** - Data Guard plus Sensitive Data Scout/Hound under isolated read-only evidence access.
4. **Identity Governance Advisor** - RACI/RBAC, PIM, access review, and separation-of-duty assessment.
5. **Security Assurance** - control/evidence mapping, compliance audit, and ATO sustainment under ISSO/security authorization.

Add **Governance Intake**, **Integration Assurance**, **Agent Assurance**, **Governance Operations**, and **Governance Insights** as later boundaries or noninteractive evaluation services.

## Why connected agent versus child agent

Microsoft's current Copilot Studio guidance recommends child agents for focused tasks that share a parent's team, settings, authentication, deployment, and reuse boundary. Connected agents are appropriate when teams, settings, publication, ALM, channels, or reuse differ. Microsoft also warns that multi-agent designs add latency and governance/test surface.

For Governor:

- Use **connected agents** for Policy, Readiness, Data Protection, Identity, Integration, and Security because their audiences and authorization/data planes differ.
- Use **child agents/topics** inside those domains for tightly related methods such as policy gap analysis, feature governance, Data Guard review, or sensitive-data scoring.
- Use **tools/topics** for deterministic status checks and confirmed workflows.
- Use **offline/CI evaluation** for Agent Evaluator whenever interactive orchestration adds no value.
- Keep support, training, labs, SOC investigations, engineering automation, and agency mission agents standalone.

References reviewed September 15, 2026:

- Microsoft Learn, [Add other agents overview](https://learn.microsoft.com/en-us/microsoft-copilot-studio/authoring-add-other-agents)
- Microsoft Learn, [Add a child agent](https://learn.microsoft.com/en-us/microsoft-copilot-studio/add-agent-child-agent)
- Microsoft Learn, [Connect to an existing Copilot Studio agent](https://learn.microsoft.com/en-us/microsoft-copilot-studio/add-agent-copilot-studio-agent)

## Phase 0 - Decide and baseline

**Goal:** Make the existing implementation safe and measurable before adding agents.

### Work

- Approve the launcher, Owner, and Admin responsibility boundaries.
- Resolve known migration debt documented in the live baseline:
  - Rebind Owner certification to the Dataverse request contract and remove
    hard-coded completion behavior.
  - Verify signed-in identity propagation end to end.
  - Verify authorization inside Owner/Admin tools.
  - Remove the launcher role-check workflow if unused.
  - Rationalize the 23 launcher topics without removing required system/routing behavior.
- Create the canonical agent registry and capability taxonomy.
- Obtain actual exports/instructions for link-only agents before reconsidering them.
- Define the target federal profiles: DOI, IRS, Census, Federal Reserve, and any hackathon demonstration profile.
- Validate GCC/GCC High availability, licensing, connectors, and sharing requirements in the target environment.

### Exit gates

- Owner A cannot read Owner B's sites.
- Non-admin cannot obtain tenant-wide data after handoff.
- Tool failure fails closed without fabricated data.
- Every accepted write is confirmed and audited.
- Launcher performs no business-data read or write.
- Canonical inventory has an accountable owner and lifecycle status for every integrated agent.

## Phase 1 - Shared governance foundation

**Goal:** Build a governed evidence and evaluation layer.

### Work

- Define a common finding schema:
  - finding ID and domain
  - target tenant/resource
  - severity and normalized risk score
  - source record and timestamp
  - control/policy mapping
  - classification and permitted audience
  - confidence and evidence sufficiency
  - recommendation, owner, approval gate, and status
- Establish approved, versioned policy and federal-control collections.
- Implement current-capability verification for GCC/GCC High claims.
- Build Agent Assurance golden tests for:
  - routing precision
  - groundedness and citation correctness
  - security trimming and cross-user leakage
  - refusal and fail-closed behavior
  - prompt injection and poisoned knowledge
  - current-turn write confirmation
  - accessibility and Section 508
- Adopt Reality Filter-derived uncertainty and source-date rules.

### Exit gates

- Every generated finding validates against the data contract.
- Superseded sources are excluded from grounding.
- Evaluation thresholds and blocking failures are approved.
- No production test relies on person-specific sample performance data.

## Phase 2 - Advisory MVP

**Goal:** Deliver high-value governance advice without expanding privileged actions.

### Governance Policy Advisor

- Merge Governance Strategist, Policy Writer, Knowledge Manager, and Quick Reference patterns.
- Provide maturity assessment, draft policy gaps, operating-model/RACI recommendations, and executive roadmap.
- Restrict access to governance-program and approved policy-author audiences.
- Make all policy output draft-only.

### Copilot Readiness Advisor

- Merge GCC Implementation Advisor and Feature Governance.
- Assess identity, endpoint, Purview, licensing, governance, training, rollout, and ATO dependencies.
- Verify feature availability rather than trusting static corpus claims.
- Evaluate service changes, release risk, training/compliance impact, and rollout gates.
- Produce a phased readiness plan; do not configure the tenant.

### Governance Intake Agent

- Merge FedOps Use Case Lab and VA Use Case Builder.
- Allow broad submission to a low-privilege intake list.
- Collect business value, data classification, risk, integrations, dependencies, owner, and approvals.
- Keep reviewer queues authorization-trimmed.

### Exit gates

- Policy output cannot publish or enforce.
- Readiness claims include cloud applicability and source date.
- Intake writes only to the approved intake system and returns a real request ID.
- Launcher routes directly to one destination without synthesizing privileged results.

## Phase 3 - Read-only evidence agents

**Goal:** Add tenant evidence using separate least-privilege boundaries.

### Data Protection Advisor

- Merge Data Guard and Sensitive Data Scout/Hound.
- Use site-scoped or tenant-approved read-only Graph/Purview/Search adapters.
- Assess labels, DLP coverage, sharing links, guests, nested groups, retention, and Copilot exposure.
- Return minimized evidence; avoid bulk content export.

### Identity Governance Advisor

- Merge the Cloud and VA RACI/RBAC designs.
- Use read-only Entra/PIM/access-review evidence.
- Detect excessive privilege, SoD conflicts, stale assignment, missing review, and control gaps.
- Never assign or revoke roles.

### Security Assurance

- Rebuild Security & Compliance Audit.
- Restrict to security/ISSO audiences.
- Use read-only Defender, Purview, audit, and approved control evidence.
- Produce findings and remediation packages, not enforcement or risk acceptance.

### Integration Assurance

- Start with artifact-only analysis of diagrams, manifests, connector inventory, OAuth design, and data flows.
- Add live read checks only after each system's consent and retention model is approved.

### Exit gates

- Each domain has a documented OAuth/Graph scope, consent owner, revocation procedure, and retention policy.
- Raw security, identity, investigation, and sensitive-content records never pass through the launcher.
- Cross-domain dashboards read normalized findings, not source-system data.
- Every agent passes authorization, leakage, and poisoned-knowledge tests.

## Phase 4 - Operations, reporting, and improvement

**Goal:** Turn approved findings into traceable governance work.

- Add Governance Operations patterns from Purview ITIL, Incident/Change, Process Automation, and Support Triage.
- Create tickets or governed requests only after approval; include assignment, rollback, closure, and evidence.
- Add Governance Insights using aggregate adoption, feedback, service health, and performance data.
- Enforce privacy purpose limitation, small-group suppression, retention, and labor/privacy review.
- Build the executive dashboard from the normalized finding and action schemas.
- Add records/eDiscovery treatment for prompts, outputs, evaluations, approvals, and agent configuration changes.

### Exit gates

- Every remediation has an owner, approval, due date, status, rollback plan, and closure evidence.
- Dashboards are reproducible from governed data contracts.
- Workforce reporting cannot be used for individual performance scoring.

## Standalone and deferred agents

Keep these outside Governor:

- Risky User Management (SOC investigation).
- HHS Mission Support and VA FOIA/Benefits (agency mission).
- Azure Lab Tenant Manager and Win365 deployment (infrastructure operations).
- Script Modernization and Skill MD Builder (developer tooling).
- Federal Academy, Champion, Roulette, and End-User Trainer (training).
- Support Triage and VA Helpdesk (service desk).
- SEC EnforceNet (case/legal hold).
- SOW Creator/Visual Designer and Federal Narrative Builder (content utilities).
- Performance Assessor unless aggregate privacy controls are approved.

Governor may route users to approved standalone destinations, but should not absorb their permissions or raw data.

## Integration backlog

| Priority | Deliverable | Dependencies | Acceptance evidence |
|---|---|---|---|
| P0 | Existing Owner/Admin security regression suite | Test identities and live tools | Passed isolation, role, failure, confirmation, and audit scenarios |
| P0 | Canonical agent registry | Owner assignments and environment inventory | All integrated agents have owner, risk, scopes, review, and retirement fields |
| P0 | Federal profile/source registry | Policy and security owners | Approved DOI/IRS/Census/Federal Reserve source separation |
| P1 | Common finding/action schemas | Data governance review | Schema validation and lineage demo |
| P1 | Agent Assurance harness | Golden questions and adversarial cases | Blocking evaluation report |
| P1 | Governance Policy Advisor | Approved policy corpus | Draft-only maturity and policy-gap demo |
| P1 | Copilot Readiness Advisor | Current GCC evidence | Source-dated readiness plan |
| P1 | Governance Intake | Approved list/workflow | Authorized submission and request tracking |
| P2 | Data Protection Advisor | Purview/Graph consent | Read-only oversharing assessment with minimized output |
| P2 | Identity Governance Advisor | Entra/PIM reader consent | Least-privilege/SoD report without write access |
| P2 | Security Assurance | ISSO authorization and evidence adapters | Control-evidence report with no enforcement |
| P2 | Integration Assurance | Artifact schema and reviewers | Trust-boundary review with actionable findings |
| P3 | Governance Operations | ITSM integration and approvals | Ticket lifecycle and closure evidence |
| P3 | Governance Insights | Privacy-approved aggregates | Reproducible dashboard with suppression controls |

## Missing capabilities to plan explicitly

1. Live tenant capability verification for GCC/GCC High.
2. Read-only Graph/Purview evidence adapters with exact consent scopes.
3. Permission graph and oversharing baseline.
4. Agent inventory/control plane with owner and lifecycle.
5. Prompt-injection and poisoned-knowledge testing.
6. Automated evaluation and regression harness.
7. Finding-to-control evidence lineage.
8. Approval, rollback, and closure-aware remediation workflow.
9. Reproducible governance maturity scoring.
10. Records/eDiscovery treatment for agent interactions and changes.
11. Strict multi-agency configuration profiles.
12. Cross-domain quantitative risk normalization.
13. Executive dashboard data contract.
14. Accessibility and Section 508 acceptance criteria.
15. Incident response for misuse, leakage, and compromised connectors.
16. Model/version change governance and rollback.

## Final architecture principles

1. One front door does not mean one authorization context.
2. Connected-agent routing is discoverability, never authorization.
3. Keep Owner and Admin meanings stable; do not repurpose "Owner" for enterprise policy ownership.
4. Prefer the smallest agent count that preserves distinct security and lifecycle boundaries.
5. Prefer child agents inside a domain over additional connected agents when credentials and ownership are identical.
6. Do not pass conversation history by default; prefer explicit, minimized task inputs.
7. Share normalized findings, not raw privileged evidence.
8. Rebuild integrations in the destination tenant; never assume downloaded agents are portable.
9. Recommendations remain advisory until a destination-owned, confirmed, audited workflow acts.
10. No agent is production-ready until it passes security, grounding, accessibility, and failure-path evaluations.
