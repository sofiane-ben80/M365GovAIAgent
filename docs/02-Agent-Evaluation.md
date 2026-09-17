# M365 Governor Agent Evaluation

## Scoring

- **Business Value (BV):** value to Microsoft 365 governance.
- **Relevance (Rel):** alignment to M365 Governor.
- **Reusability (Reuse):** reusable prompts, instructions, knowledge patterns, or methods.
- **Complexity (Cx):** difficulty of rebuilding safely.

Each score is 1 (low) through 5 (high). The required recommendation vocabulary describes disposition of the downloaded design:

- **Rebuild:** implement the capability in the target tenant with new authorization and connectors.
- **Merge:** incorporate logic into an existing or planned Governor domain agent.
- **Reuse Content Only:** reuse prompts, methods, or knowledge patterns without a runtime agent.
- **Standalone:** retain outside Governor and optionally route to it.
- **Ignore:** do not include in the Governor runtime.

## Evaluated build-spec agents

| # | Agent | BV | Rel | Reuse | Cx | Recommendation | Rationale |
|---|---|---:|---:|---:|---:|---|---|
| 1 | ACSM IP Repo Librarian | 3 | 2 | 4 | 2 | Reuse Content Only | Reuse approved-source discovery and gap patterns; do not reuse tenant URLs. |
| 2 | Microsoft Cloud RACI & RBAC Designer | 5 | 5 | 5 | 3 | Merge | Core least-privilege method for a separately authorized Identity Governance Advisor. |
| 3 | Azure Lab Tenant Manager | 2 | 1 | 3 | 4 | Standalone | Provisioning and teardown require a separate privileged engineering boundary. |
| 4 | VA RBAC Governance Designer | 5 | 5 | 5 | 3 | Merge | Merge federal RACI/PIM/access-review patterns with #2. |
| 5 | Copilot Adoption ROI Analyst | 4 | 4 | 4 | 4 | Rebuild | Useful reporting capability only with aggregate, privacy-approved telemetry. |
| 6 | Copilot Champion Assistant | 3 | 3 | 4 | 2 | Standalone | Enablement is adjacent to governance but not part of privileged control-plane work. |
| 7 | VA Copilot Data Guard | 5 | 5 | 5 | 4 | Merge | Core classification, DLP, privacy, and output-handling logic for Data Protection Advisor. |
| 8 | VA Copilot Incident & Change Agent | 3 | 3 | 4 | 3 | Reuse Content Only | Reuse change-risk and CAB patterns; integrate only after ITSM boundaries are defined. |
| 9 | VA Copilot Knowledge Manager | 4 | 4 | 5 | 3 | Merge | Supports governed source lifecycle and knowledge quality. |
| 10 | VA Copilot Service Monitor | 3 | 3 | 3 | 4 | Standalone | Needs service telemetry and operations authorization outside current Governor scope. |
| 11 | Microsoft Internal Agent Evaluator | 5 | 5 | 5 | 3 | Rebuild | Essential build/release assurance capability with no inherited business-data access. |
| 12 | Copilot Agent/Prompt Roulette Trainer | 2 | 1 | 4 | 2 | Ignore | Training game has little Governor runtime value. |
| 13 | Copilot End-User Trainer | 3 | 3 | 4 | 2 | Standalone | Reuse safe-use content but keep learning delivery outside the control plane. |
| 14 | Copilot Feedback Loop Agent | 3 | 3 | 4 | 4 | Rebuild | Later-phase maturity loop using aggregate, retention-controlled data. |
| 15 | Copilot GCC Implementation Advisor | 5 | 5 | 5 | 3 | Rebuild | High-value readiness domain requiring current tenant/product evidence. |
| 16 | Copilot Policy Writer VA | 5 | 5 | 5 | 2 | Merge | Merge into a draft-only Governance Policy Advisor with human approval. |
| 17 | Copilot Governance Strategist | 5 | 5 | 5 | 3 | Merge | Combine strategy, maturity, KPIs, and roadmap with Policy Writer in one advisory agent. |
| 18 | Copilot Integration Validator | 5 | 5 | 4 | 4 | Rebuild | Artifact-first assurance; live checks require isolated per-system read access. |
| 19 | Copilot Performance Assessor | 3 | 3 | 3 | 5 | Standalone | High employee-monitoring and telemetry risk; use only aggregate analytics. |
| 20 | Copilot Process Automation | 3 | 3 | 4 | 4 | Reuse Content Only | Governor may design and review workflows but should not deploy them. |
| 21 | Copilot Security & Compliance Audit | 5 | 5 | 4 | 5 | Rebuild | Core assurance function but requires separate security authorization and read-only evidence scopes. |
| 22 | Copilot Support Triage | 3 | 3 | 4 | 3 | Standalone | Keep support systems and operational escalation outside Governor. |
| 23 | Copilot Feature Governance | 5 | 5 | 5 | 3 | Merge | Strong fit for Copilot Readiness Advisor lifecycle, service-change, and rollout-gate topics. |
| 24 | Federal Copilot Academy | 3 | 3 | 5 | 3 | Standalone | Retain as a training destination; reuse governance modules. |
| 25 | FedOps Copilot Use Case Lab | 4 | 4 | 5 | 2 | Merge | Merge with #38 into low-privilege Governance Intake. |
| 26 | HHS IP Repo Librarian | 2 | 2 | 4 | 2 | Reuse Content Only | Reuse approved-source patterns; HHS repositories remain agency-specific. |
| 27 | HHS Mission Support Copilot | 3 | 2 | 3 | 4 | Standalone | Scope is too broad and sensitive for Governor. |
| 28 | Purview ITIL Advisor GAO | 5 | 5 | 4 | 4 | Rebuild | Valuable compliance/operations bridge under a distinct Purview/ITSM boundary. |
| 29 | NIH Copilot Prompt Library | 2 | 2 | 5 | 2 | Reuse Content Only | Reuse prompt structure; NIH-specific content remains separate. |
| 30 | Quick Reference Creator | 2 | 2 | 4 | 2 | Reuse Content Only | Output-formatting skill, not a governance domain agent. |
| 31 | Risky User Management Copilot | 4 | 4 | 3 | 5 | Standalone | SOC-only investigation data must not enter broadly accessible Governor context. |
| 32 | Document Sanitization & Reusability Agent | 3 | 3 | 4 | 3 | Rebuild | Useful governed-publication utility with ephemeral processing and human verification. |
| 33 | Script Modernization Manager | 1 | 1 | 3 | 4 | Standalone | Engineering lifecycle utility outside M365 governance. |
| 34 | SEC EnforceNet Timebound Copilot | 3 | 2 | 3 | 4 | Standalone | Case-level investigation and legal-hold authorization is agency-specific. |
| 35 | Skill MD Builder | 1 | 1 | 3 | 2 | Ignore | Retain only as developer tooling. |
| 36 | SOW Visual Designer | 2 | 1 | 4 | 3 | Standalone | Presentation utility outside Governor. |
| 37 | Tenant Sensitive Data Scout/Hound | 5 | 5 | 4 | 5 | Rebuild | Highest-value Copilot-readiness capability; must be read-only and separately scoped. |
| 38 | VA Copilot Use Case Builder | 4 | 4 | 5 | 2 | Merge | Merge with #25 into Governance Intake. |
| 39 | VA GCC Copilot Helpdesk | 3 | 3 | 4 | 3 | Standalone | Keep support separate and route to it when appropriate. |
| 40 | Word2Markdown Copilot | 1 | 1 | 4 | 2 | Ignore | Use as a build-time knowledge-ingestion utility, not a runtime agent. |

## Provisional link-only evaluation

No build specification is available for these agents. Scores and recommendations are title-based hypotheses and cannot authorize integration.

| Agent | BV | Rel | Reuse | Cx | Recommendation | Validation needed |
|---|---:|---:|---:|---:|---|---|
| ATO Boundary Architect | 5 | 5 | 3 | 4 | Rebuild | Obtain instructions, evidence model, control sources, and authorization design. |
| Copilot ACM Consult Assistant | 3 | 3 | 3 | 3 | Standalone | Confirm scope and whether it duplicates adoption/champion agents. |
| Champion Role Generator aliases | 2 | 2 | 3 | 2 | Reuse Content Only | Confirm output schema and approved role catalog. |
| Custom Role Creator | 4 | 4 | 2 | 4 | Standalone | Determine whether it writes roles; any write requires separate authorization. |
| Federal Narrative Builder | 2 | 2 | 3 | 2 | Standalone | Confirm sources, audience, and handling of agency-sensitive content. |
| Intune Operations Integrator - USPTO | 2 | 2 | 2 | 4 | Standalone | Obtain USPTO-specific scope and connector requirements. |
| SEC Copilot ACSM Advisor | 3 | 2 | 3 | 3 | Standalone | Confirm whether content is SEC-specific and current. |
| Security Operating Model Assistant | 4 | 4 | 3 | 3 | Reuse Content Only | Compare to Governance Strategist and Security Assurance before rebuilding. |
| SOW Creator Assistant | 2 | 1 | 3 | 2 | Standalone | Confirm approved templates and legal/procurement review. |
| VA FOIA vs Benefits Advisor | 2 | 1 | 2 | 3 | Standalone | Outside Governor scope. |
| Win365PC Deploy Advisor | 2 | 1 | 2 | 4 | Standalone | Outside Governor core; validate separately with endpoint teams. |

## Priority recommendation

The top five designs to rebuild or merge first are:

1. Tenant Sensitive Data Scout/Hound.
2. VA Copilot Data Guard.
3. Copilot Security & Compliance Audit.
4. RACI/RBAC Designer family.
5. Copilot GCC Implementation Advisor.

Governance Strategist and Policy Writer are also high priority, but should be merged into one new advisory boundary rather than rebuilt as separate agents.
