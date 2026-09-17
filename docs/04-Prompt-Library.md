# M365 Governor Reusable Prompt Library

## Use conditions

These prompts are extracted or faithfully normalized from the build specifications. They are design assets, not production authorization. Before use:

- Bind prompts to approved, versioned knowledge and live tools.
- Enforce authorization in tools and services, not in prompt text.
- Require citations, source dates, confidence, and evidence sufficiency.
- Keep recommendations advisory unless a separately authorized and confirmed workflow performs an action.
- Replace agency-specific control baselines with the target tenant's approved profile.

## Top 10 prompts

### 1. Governance maturity assessment

**Purpose:** Assess governance maturity and prioritize improvement.

**Prompt:** "Assess Copilot governance maturity and recommend improvements using federal governance maturity models."

**Suggested use:** Governance Policy Advisor strategy topic. Return current level, evidence, gaps, target level, prioritized actions, owners, and dependencies.

**Source agent:** Copilot Governance Strategist.

### 2. Security and compliance audit

**Purpose:** Evaluate configuration against federal controls.

**Prompt:** "Conduct a compliance audit of Microsoft 365 Copilot configurations aligned with NIST 800-53 and FedRAMP Moderate controls."

**Suggested use:** Security Assurance with read-only evidence. Identify the exact baseline revision and distinguish verified evidence from assumptions.

**Source agent:** Copilot Security & Compliance Audit.

### 3. RBAC review

**Purpose:** Find least-privilege and separation-of-duty gaps.

**Prompt:** "Evaluate existing RBAC assignments for Microsoft 365 Copilot and identify least privilege gaps and separation-of-duty conflicts."

**Suggested use:** Identity Governance Advisor using authorized role assignments and PIM/access-review evidence.

**Source agent:** VA RBAC Governance Designer family.

### 4. Output oversharing review

**Purpose:** Review generated content before sharing.

**Prompt:** "Analyze this Copilot output for potential data oversharing and recommend mitigation steps."

**Suggested use:** Data Protection Advisor. Prefer metadata and excerpts minimized to the authorized user.

**Source agent:** VA Copilot Data Guard.

### 5. External-sharing risk

**Purpose:** Prioritize exposed sensitive content.

**Prompt:** "Evaluate externally shared files containing possible PII or CUI."

**Suggested use:** Sensitive Data Scout with site-scoped, read-only evidence. Return counts and locations rather than full sensitive content.

**Source agent:** Tenant Sensitive Data Scout/Hound.

### 6. DLP coverage

**Purpose:** Find policy coverage gaps.

**Prompt:** "Analyze tenant data exposure against current DLP policies."

**Suggested use:** Data Protection Advisor. Compare observed evidence with current, versioned policy configuration.

**Source agent:** Tenant Sensitive Data Scout/Hound.

### 7. Integration trust boundaries

**Purpose:** Detect identity and authorization design risks.

**Prompt:** "Analyze authentication and authorization flows for this Copilot integration and identify potential privilege escalation or boundary violations."

**Suggested use:** Integration Assurance, initially against submitted diagrams, manifests, connector inventories, and data-flow records.

**Source agent:** Copilot Integration Validator.

### 8. GCC readiness

**Purpose:** Assess deployment readiness.

**Prompt:** "Evaluate tenant configuration, identity posture, and compliance readiness."

**Suggested use:** Copilot Readiness Advisor. Qualify every result by target cloud and verify feature availability from current official sources.

**Source agent:** Copilot GCC Implementation Advisor ("Assess Copilot Readiness in GCC").

### 9. Policy gap analysis

**Purpose:** Draft a policy remediation backlog.

**Prompt:** "Evaluate Copilot governance policies for compliance gaps against NIST 800-53 and FedRAMP Moderate requirements."

**Suggested use:** Governance Policy Advisor. Produce draft changes only; legal, privacy, records, security, and policy owners approve.

**Source agent:** Copilot Policy Writer VA.

### 10. Evaluation and self-correction

**Purpose:** Improve factual quality and uncertainty disclosure.

**Prompt:** "Review your previous answer for factual accuracy, missing assumptions, and completeness. List risks and uncertainties, then propose a corrected version with citations to the provided sources."

**Suggested use:** Agent Assurance evaluation cases and high-impact advisory responses.

**Source agent:** Copilot Performance Assessor saved examples.

## Reusable instruction patterns

1. Start with BLUF, followed by evidence, assumptions, risk, recommendation, owner, and next action.
2. Label verified facts, inference, preview, commercial-only, GCC, and GCC High claims separately.
3. Prefer the newest approved source; show its date and identify superseded guidance.
4. Never invent configuration, telemetry, policy, milestones, licenses, or tenant capabilities.
5. Return confidence and evidence sufficiency when evidence is incomplete.
6. Map recommendations to a control, accountable role, dependency, approval gate, and due date.
7. Minimize sensitive data; prefer counts, identifiers, and authorized links over raw content.
8. Require human approval for policy, access, remediation, publication, or risk acceptance.
9. State when a result is advisory and when a live tool was not available.
10. Never transform a failed tool call into a successful-looking answer.

## Recommended response contract

```text
BLUF:
Scope and audience:
Verified findings:
Evidence and source dates:
Control/policy mapping:
Risks and severity:
Assumptions and unknowns:
Confidence and evidence sufficiency:
Recommended actions:
Owner and approval gate:
Next review date:
```

