# M365 Governor Selected Agent Portfolio

## Decision

Select **eight source-agent designs** for integration planning. Treat the first six as the minimum portfolio and the last two as second-wave additions.

These are source designs to rebuild or merge in the destination tenant. They are not assumed to be directly portable, and they should not become eight separate connected agents.

## Selection criteria

The portfolio prioritizes capabilities that:

1. Directly govern SharePoint Online or Microsoft Teams.
2. Improve Microsoft 365 Copilot readiness.
3. Detect oversharing, sensitive-data exposure, or access risk.
4. Support federal, GCC, compliance, and audit scenarios.
5. Produce actionable governance findings and recommendations.
6. Complement rather than duplicate the existing Governor launcher, Governance Owner Agent, and Governance Admin Agent.

## Core six

| Priority | Selected source agent | Role in M365 Governor | Primary products/domains | Selection rationale |
|---:|---|---|---|---|
| 1 | Tenant Sensitive Data Scout/Hound | Discover overshared, externally accessible, unlabeled, or policy-uncovered content. | SharePoint, Teams, OneDrive, Exchange, Purview, Copilot readiness | Most direct match for identifying content that Microsoft 365 Copilot could expose. |
| 2 | VA Copilot Data Guard | Evaluate classification, sensitivity labels, DLP, retention, privacy, and safe output handling. | SharePoint, Teams, Purview, Copilot | Complements discovery with policy analysis and protection recommendations. |
| 3 | Copilot GCC Implementation Advisor | Assess Copilot prerequisites and create a phased readiness plan. | Copilot, Entra, Purview, endpoints, licensing, GCC/GCC High | Provides the principal Copilot-readiness capability and federal deployment context. |
| 4 | RACI & RBAC Designer family | Evaluate administrative roles, least privilege, PIM, access reviews, and separation of duties. | Entra, SharePoint, Teams, Purview, Power Platform | Establishes who can govern resources and identifies excessive or conflicting privilege. |
| 5 | Copilot Governance Strategist | Assess governance maturity and define the operating model, KPIs, risk framework, and roadmap. | M365-wide governance | Supplies the unifying governance framework for the other selected capabilities. |
| 6 | Copilot Security & Compliance Audit | Map configuration and evidence to controls, identify gaps, and prioritize remediation. | SharePoint, Teams, Purview, Entra, Copilot, federal controls | Adds audit readiness, evidence lineage, and NIST/FedRAMP alignment. |

## Second-wave additions

| Priority | Selected source agent | Role in M365 Governor | Primary products/domains | Selection rationale |
|---:|---|---|---|---|
| 7 | Copilot Governance Policy Writer | Turn approved findings into draft policies, standards, and procedures. | M365 governance, Copilot policy, federal controls | Converts assessment results into governance artifacts while retaining human approval. |
| 8 | Copilot Feature Governance | Assess service changes, release risk, training impact, compliance impact, and rollout gates. | Copilot, Teams, SharePoint, M365 roadmap and Message Center | Extends readiness into continuous lifecycle governance after deployment. |

## Recommended implementation grouping

The eight source designs should be consolidated into five domain agents.

| Proposed Governor domain agent | Selected source designs | Purpose |
|---|---|---|
| Data Protection Advisor | Tenant Sensitive Data Scout/Hound; VA Copilot Data Guard | Discover exposure and evaluate classification, sharing, DLP, labels, privacy, and remediation. |
| Copilot Readiness Advisor | Copilot GCC Implementation Advisor; Copilot Feature Governance | Assess initial readiness and continuously govern product and service changes. |
| Identity Governance Advisor | RACI & RBAC Designer family | Assess roles, privileges, PIM, access reviews, RACI, and separation of duties. |
| Governance Policy Advisor | Copilot Governance Strategist; Copilot Governance Policy Writer | Assess maturity, define the operating model, and prepare draft governance artifacts. |
| Security & Compliance Assurance | Copilot Security & Compliance Audit | Perform authorized, read-only control and evidence assessment. |

## Integration boundary decision

The five domain agents should be evaluated as **connected agents**, because they have different audiences, authorization rules, data sources, and release lifecycles. Focused functions within each domain should use child agents, topics, prompts, or tools when they share the parent domain's authorization and deployment boundary.

The following boundaries remain unchanged:

- **Governor M365 launcher:** routing and help only.
- **Governance Owner Agent:** only the signed-in user's governed SharePoint sites and owner requests.
- **Governance Admin Agent:** admin-verified, tenant-wide SharePoint governance.

The selected capabilities must not be inserted into Owner or Admin merely to reduce the number of agents. Purview, Entra, security, policy-authoring, and readiness access require their own authorization decisions.

## Persona and access model

Use personas to define the user experience, but use authorization boundaries,
connector identities, data classification, ownership, and release lifecycle to
decide where agents split. A person can hold several personas, and a persona can
use several agents. Therefore, do not create one agent for every job title and
do not treat the launcher as a security boundary.

| Persona | Appropriate operations | Agent entry | Boundary |
|---|---|---|---|
| Authenticated employee | Discover capabilities, ask for help, and route to an eligible specialist. | Governor M365 launcher | No business-data tools or privileged results. Routing does not prove authorization. |
| Site owner | Read only sites currently owned by the caller; explain findings; submit governed archive, deletion-review, or support requests; check the caller's request status. | Governance Owner Agent | Resource-scoped authorization is recalculated from the signed-in identity and live site record on every read and write request. Owner confirmation is not compliance certification or final disposition approval. |
| SharePoint governance admin/operator | Review tenant-wide site governance, orphaned sites, and attestation; assign owners; initiate governed site actions. | Governance Admin Agent | Membership in the approved SharePoint governance group is verified at runtime. It grants no automatic Purview, Entra, security-evidence, policy-approval, or ATO authority. |
| Governance lead or policy steward | Run maturity and policy-gap assessments and prepare draft policies, standards, RACI, and roadmaps from approved inputs. | Governance Policy Advisor | Draft and aggregate evidence only. Publication, policy approval, and enforcement remain human workflow steps. |
| Copilot program, service, or change lead | Assess GCC readiness, prerequisites, capability availability, rollout dependencies, and service-change impact. | Copilot Readiness Advisor | Advisory access only. It cannot purchase licenses, change tenant configuration, approve rollout, or grant an ATO. |
| Data protection analyst | Review authorized sharing, guest, label, DLP, retention, and Copilot-exposure findings; prioritize remediation proposals. | Data Protection Advisor | Separate data-protection group and evidence scope. No bulk content export, unrestricted content search, or direct remediation in the initial release. |
| Identity governance analyst | Review authorized role, PIM, access-review, RACI, least-privilege, and separation-of-duties evidence. | Identity Governance Advisor | Separate identity-governance group and person-data controls. No assignment, revocation, activation, approval, or risky-user investigation. |
| ISSO, security assessor, or authorized auditor | Map approved evidence to controls, assess evidence sufficiency, and prepare remediation proposals or workpapers. | Security & Compliance Assurance | ISSO/security audience and isolated evidence. The agent cannot make compliance determinations, accept risk, authorize an ATO, close findings, or enforce controls. |
| Human approver or accountable official | Approve policy publication, risk acceptance, ATO decisions, final disposition, privileged-access changes, or remediation closure. | Governed approval workflow, not a general chat-agent privilege | Separation of duties, explicit approval record, current evidence, and audit trail are required. Holding another persona must not imply approval authority. |
| Agent maker, platform operator, connector owner, or data steward | Build, publish, monitor, operate, consent, curate sources, and respond to incidents. | Administrative and ALM surfaces | These are management-plane roles, not end-user chat personas. Use least-privilege environment roles and keep maker, publisher, connector-consent, and production-operator duties separable. |
| Service or collector identity | Collect, normalize, score, or execute an approved backend operation. | No conversational entry | Nonhuman identities receive only source-specific permissions and never inherit a user's or agent's broad role. |

Persona membership should be represented by approved Entra security groups or
equivalent authoritative claims. Resource relationship, purpose, data
classification, and operation risk are evaluated in addition to group
membership. Free-text claims such as "I am an admin" and caller identifiers
provided by the model are never accepted as authorization evidence.

### Front-door and deployment decision

Adopt a **single discovery front door with separate security-domain
destinations**, not a single all-powerful agent and not one deployment per
persona:

1. Publish the Governor M365 launcher broadly to authenticated users. It
   performs help, intent classification, one clarification when needed, and one
   handoff. It has no domain knowledge, evidence connector, or write tool.
2. Publish Owner, Admin, and each of the five advisors as independently
   disableable connected agents. Share each destination only with its intended
   audience where the channel supports audience restriction.
3. Treat destination sharing as defense in depth and user-experience trimming,
   not the final authorization control. Every destination and every backend
   tool reauthorizes the signed-in caller, tenant/profile, purpose, resource
   scope, and requested operation and fails closed.
4. Use child agents, topics, prompts, and tools inside a destination only when
   they share the parent's audience, connector identity, classification, owner,
   and release boundary. Split again when any of those boundaries differ.
5. Do not send privileged results back to the launcher for synthesis. The
   destination owns the response, and cross-domain reporting uses
   audience-trimmed normalized findings rather than peer-agent calls.

This yields one convenient user entry without creating one security gate whose
failure exposes every domain. It also avoids duplicating nearly identical
agents for job titles that share the same operational boundary.

### Authorization layers

| Layer | Purpose | Required behavior |
|---|---|---|
| Channel and sharing | Reduce discoverability and accidental use. | Require Microsoft Entra authentication; share destinations with security groups; prohibit anonymous and unapproved channels through data policy. |
| Launcher routing | Select the likely destination. | Pass only minimal task context and a correlation ID. Never infer or assert the caller's role. Disable conversation-history transfer by default and permit only reviewed fields when required. |
| Destination admission | Verify that the caller may use the domain. | Check the authoritative audience on entry and again for privileged operations; deny on lookup or connector failure. |
| Tool and broker authorization | Enforce the actual data/action boundary. | Derive identity from the authenticated session; enforce tenant, audience, purpose, resource, field, and operation scope; ignore model-supplied identity or role claims. |
| Source system | Preserve native security trimming and least privilege. | Prefer end-user credentials when native permissions should flow through. When a service identity is necessary, scope it narrowly and reproduce caller authorization in the broker. |
| Approval and execution | Control consequential changes. | Fresh-read the target, reauthorize, require current-turn confirmation, create a pending request, apply separation of duties where required, and append an audit record. |
| Monitoring and governance | Detect misuse and configuration drift. | Correlate launcher, destination, tool, and approval events; review denials, connector changes, agent audiences, service identities, and stale evidence. |

### Operation classification

- **Open reference:** approved, audience-appropriate help or policy guidance;
  still authenticated, but no tenant-state claim.
- **Scoped read:** live or normalized tenant evidence filtered to caller,
  audience, resource, fields, and purpose.
- **Assessment:** deterministic, versioned scoring over authorized evidence;
  the model explains but does not invent or alter the score.
- **Draft/proposal:** policy, readiness, or remediation output that is visibly
  nonauthoritative and cannot change a source system.
- **Request:** a confirmed, audited pending operation such as disposition or
  remediation; acceptance is never reported as completion.
- **Approval/execution:** a separate, explicitly authorized workflow with
  stronger controls and separation of duties; not granted merely because a
  person can chat with an advisor.

### Copilot Studio design alignment

The design follows current Copilot Studio guidance:

- [Connected agents overview](https://learn.microsoft.com/en-us/microsoft-copilot-studio/agents-experience/authoring-add-other-agents):
  use connected agents for specialized domains with their own instructions,
  knowledge, tools, ownership, and reuse boundaries.
- [Add a connected agent](https://learn.microsoft.com/en-us/microsoft-copilot-studio/agents-experience/add-agent-connected):
  keep names and route descriptions specific and nonoverlapping, and test both
  matching and out-of-domain requests.
- [Share agents with users and makers](https://learn.microsoft.com/en-us/microsoft-copilot-studio/agents-experience/authoring-share-agent):
  require Microsoft authentication and use security groups or named audiences;
  keep end-user access distinct from editing and environment roles.
- [Add tools to custom agents](https://learn.microsoft.com/en-us/microsoft-copilot-studio/add-tools-custom-agent):
  choose end-user versus maker-provided credentials deliberately and use
  explicit confirmation for consequential tools.
- [Copilot Studio security and governance](https://learn.microsoft.com/en-us/microsoft-copilot-studio/security-and-governance)
  and [data policies for agents](https://learn.microsoft.com/en-us/microsoft-copilot-studio/admin-data-loss-prevention):
  require authentication, govern connectors, knowledge, skills, HTTP endpoints,
  triggers, and publication channels, and monitor agent activity.

## Coverage

| Required outcome | Selected agents |
|---|---|
| SharePoint oversharing and external access | Sensitive Data Scout/Hound, Data Guard, RBAC Designer |
| Teams sharing and sensitive information | Sensitive Data Scout/Hound, Data Guard |
| Sensitivity labels and DLP | Data Guard, Sensitive Data Scout/Hound |
| Permission and privilege governance | RBAC Designer, Sensitive Data Scout/Hound |
| Copilot readiness | GCC Implementation Advisor, Feature Governance |
| Governance maturity and roadmap | Governance Strategist |
| Governance policy development | Policy Writer, Governance Strategist |
| Compliance gap analysis and audit readiness | Security & Compliance Audit |
| Federal and GCC scenarios | GCC Advisor, Security Audit, RBAC Designer, Policy Writer |
| Continuous M365 change governance | Feature Governance |

## Six-agent fallback

If schedule or capacity limits the portfolio to six source designs, implement only the core six. Temporarily incorporate:

- Policy Writer prompt and document patterns into the Governance Strategist implementation.
- Feature Governance assessment patterns into the GCC Implementation Advisor implementation.

Keep them as explicitly tracked consolidation debt so they can later be separated or expanded without changing the launcher, Owner, or Admin boundaries.

## Deferred candidates

| Agent | Disposition for this portfolio |
|---|---|
| Purview ITIL Advisor GAO | Defer to operations/remediation phase after the evidence and finding model exists. |
| Copilot Integration Validator | Use first as an engineering and release-assurance method; reconsider as a connected agent when live integration evidence is available. |
| Microsoft Internal Agent Evaluator | Implement as an evaluation harness or release gate rather than a user-facing Governor destination. |
| VA Copilot Knowledge Manager | Reuse its source lifecycle practices inside Governance Policy Advisor. |
| Copilot Adoption ROI Analyst | Defer until aggregate, privacy-approved adoption telemetry exists. |
| Risky User Management Copilot | Keep standalone under SOC authorization; Governor may consume approved summary findings only. |
| Training, helpdesk, lab, mission, script, SOW, and document-conversion agents | Keep standalone or use as build-time utilities. |

## Integration architecture

The shared evidence, tool, source, and implementation design for the five domain
agents is defined in
[08-Advisor-Agent-Integration-Architecture.md](08-Advisor-Agent-Integration-Architecture.md).
It treats the selected agents' instructions as the reasoning plane and grounds
tenant-specific conclusions through authorization-aware tools backed by direct
adapters, scheduled collectors, and governed knowledge.

Each domain implementation plan must define:

1. Included source-agent capabilities and excluded behavior.
2. Target users and authorization group.
3. Child agents, topics, prompts, tools, and knowledge sources.
4. Exact read and write permissions.
5. Data classification, minimization, retention, and audit requirements.
6. Handoff metadata and whether conversation history is permitted.
7. Evaluation and acceptance scenarios.
8. Dependencies, implementation sequence, and rollback approach.
