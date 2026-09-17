# M365 Governor Agent Inventory

## Scope and method

This inventory covers all artifacts under `Share-Your-Agents`:

- 44 published-agent shortcut files (`.url`) representing 42 unique published targets.
- 69 top-level build artifacts: 65 Word files, 2 PowerPoint files, 1 PNG, and 1 ZIP.
- 40 logical build-spec agents after normalizing duplicate, summary, full-spec, and saved-output variants.

The ZIP contains 16 Word files that duplicate top-level material and adds no unique textual content. A published shortcut proves only that a link was captured; it does not prove that the current user can access the agent or that its build specification matches the published version.

Most specifications do not contain a reliable formal owner field. The **Owner/context** column therefore records only the stated organization or audience and must not be treated as operational ownership.

## Logical build-spec agents

| # | Agent | Purpose | Files | Owner/context |
|---|---|---|---|---|
| 1 | ACSM IP Repo Librarian | Finds and adapts approved consulting IP for delivery and proposal teams. | `ACSM IP Repo Librarian v1.0.docx` | Microsoft internal / ACSM |
| 2 | Microsoft Cloud RACI & RBAC Designer | Designs RACI, RBAC, least privilege, separation of duties, and control mappings. | `Agent Build Instructions - RACI RBAC.docx` | Microsoft internal |
| 3 | Azure Lab Tenant Manager | Designs controlled Azure/M365 labs, baselines, scripts, and teardown plans. | `Azure Lab Tenant Manager build specs.docx` | Microsoft internal |
| 4 | VA RBAC Governance Designer | Designs VA/GCC RACI, RBAC, PIM, access certification, and privilege-risk controls. | `Copilot  RBAC & Access Governance (VA GCC Medium) – Full Build Specifications.docx`; `Copilot Agent Design – RBAC & Access Governance (VA GCC Medium) – Full Build Specifications.docx` | VA |
| 5 | Copilot Adoption ROI Analyst | Measures adoption, mission value, barriers, productivity, and ROI. | `Copilot Adoption & ROI Analyst M365 Copilot Agent - Full Build Specification.docx`; `Copilot Adoption & ROI Analyst M365 Copilot Agent.docx` | Federal / adoption teams |
| 6 | Copilot Champion Assistant | Coaches champions with role-based use cases, prompting, responsible AI, and campaigns. | `Copilot Agent Design – Adoption Champions’ Assistant (GCC Medium).docx` | Federal / adoption teams |
| 7 | VA Copilot Data Guard | Reviews classification, PII/PHI, privacy, grounding, DLP, records, and oversharing. | `Copilot Agent Design – Data Protection & Classification - Full Build Specifications.docx`; `Copilot Agent Design – Data Protection & Classification.docx` | VA |
| 8 | VA Copilot Incident & Change Agent | Classifies incidents, assesses changes, identifies trends, and prepares CAB/PIR artifacts. | `Copilot Agent Design – Incident & Change Management - Full Build Specification.docx`; `Copilot Agent Design – Incident & Change Management.docx` | VA |
| 9 | VA Copilot Knowledge Manager | Governs SOPs, runbooks, knowledge articles, training content, and lessons learned. | `Copilot Agent Design – Knowledge & Documentation - Full Build Specification.docx`; `Copilot Agent Design – Knowledge & Documentation.docx` | VA |
| 10 | VA Copilot Service Monitor | Assesses service health, SLA/SLO performance, telemetry, and user experience. | `Copilot Agent Design – Service Level & Performance Monitor - Full Build Specification.docx`; `Copilot Agent Design – Service Level & Performance Monitor.docx` | VA |
| 11 | Microsoft Internal Agent Evaluator | Evaluates grounding, retrieval, prompts, security trimming, usability, compliance, and readiness. | `Copilot Agent Evaluator.docx` | Microsoft internal |
| 12 | Copilot Agent/Prompt Roulette Trainer | Expands basic prompts or agent ideas into structured, governed versions. | `Copilot Agent Roulette Trainer.docx`; `M365 Copilot Agent design - Copilot Prompt Roulette Trainer.docx`; `Copilot Prompt Roulette Presentation.pptx` | Microsoft internal / training |
| 13 | Copilot End-User Trainer | Produces role-based training plans, proficiency assessments, job aids, and safe-use guidance. | `Copilot End-User Training M365 Copilot Agent - Full Build Specification.docx`; `Copilot End-User Training M365 Copilot Agent.docx` | Federal / adoption teams |
| 14 | Copilot Feedback Loop Agent | Correlates feedback, sentiment, service-desk trends, training, and adoption metrics. | `Copilot Feedback & Improvement Loop M365 Copilot Agent - Full Build Specification.docx`; `Copilot Feedback & Improvement Loop M365 Copilot Agent.docx` | Federal / adoption teams |
| 15 | Copilot GCC Implementation Advisor | Assesses GCC readiness and builds phased deployment, governance, security, and ATO plans. | `Copilot GCC Implementation Advisor.docx` | HHS / federal |
| 16 | Copilot Policy Writer VA | Drafts and maintains acceptable-use, privacy, data-protection, operational, and governance policies. | `Copilot Governance Policy Writer – Full Build Specification.docx` | VA |
| 17 | Copilot Governance Strategist | Designs maturity models, boards, policy frameworks, KPIs, risk models, and roadmaps. | `Copilot Governance Strategy Agent – Full Build Specification.docx` | Federal governance teams |
| 18 | Copilot Integration Validator | Validates connectors, APIs, identity flows, trust boundaries, data paths, and ATO dependencies. | `Copilot Integration Validator – M365 Copilot Agent - Full Build Specification.docx` | Federal technical governance |
| 19 | Copilot Performance Assessor | Measures performance gains using usage, time, quality, and impact indicators. | `Copilot Performance Assessor - Full Build Specifications.docx`; `Copilot Performance Assessor Agent.docx`; `Copilot Performance Assor Agent.docx` | Federal / performance teams |
| 20 | Copilot Process Automation | Designs governed Power Automate and M365 workflow automations. | `Copilot Process Automation – M365 Copilot Agent - Full Build Specification.docx` | Federal operations |
| 21 | Copilot Security & Compliance Audit | Performs control assessment, evidence mapping, ATO sustainment, risk scoring, and remediation advice. | `Copilot Security and Compliance Audit – Full Build Specification.docx` | Federal security/compliance |
| 22 | Copilot Support Triage | Handles support intake, severity, troubleshooting, known-issue matching, and escalation. | `Copilot Support Triage M365 Copilot Agent - Full Build Specification.docx`; `Copilot Support Triage M365 Copilot Agent.docx` | Federal support teams |
| 23 | Copilot Feature Governance | Assesses release risk, compliance, training readiness, rollout, approval, and lifecycle status. | `Copilot Version - Feature Governance M365 Copilot Agent - Full Build Specification.docx`; `Copilot Version - Feature Governance M365 Copilot Agent.docx` | Federal governance teams |
| 24 | Federal Copilot Academy | Builds federal curricula, labs, assessments, certifications, and executive education. | `Federal Copilot Academy – Microsoft 365 Copilot Agent.docx` | Federal training teams |
| 25 | FedOps Copilot Use Case Lab | Structures and validates federal IT-operations AI/automation use cases. | `FedOps Copilot Use Case Lab Agent Content.docx` | Federal operations |
| 26 | HHS IP Repo Librarian | Finds approved HHS reusable IP and identifies gaps and restrictions. | `HHS IP Repo Librarian v2.0.docx` | HHS |
| 27 | HHS Mission Support Copilot | Broad assistant for HHS mission, administrative, audit, program, and knowledge work. | `HHS Mission Support Copilot Agent - Full Build Spec.docx` | HHS |
| 28 | Purview ITIL Advisor GAO | Correlates Purview events and controls with incident, problem, change, and request processes. | `M365 Copilot Agent Specification.docx` | GAO |
| 29 | NIH Copilot Prompt Library | Creates and improves NIH role/workflow prompts across approved M365 workloads. | `NIH Copilot Prompt Library.docx` | NIH |
| 30 | Quick Reference Creator | Generates QRGs, job aids, SOP summaries, FAQs, and walkthroughs. | `Quick Reference Creator - build spec.docx` | General |
| 31 | Risky User Management Copilot | Correlates Entra, Defender, Sentinel, Purview, and Intune risky-user signals. | `Risky User Management Copilot.docx` | Security operations |
| 32 | Document Sanitization & Reusability Agent | Detects identifying content and creates sanitized reusable IP with a risk rating. | `Sanitizer Agent.docx` | Microsoft internal / federal |
| 33 | Script Modernization Manager | Modernizes scripts into governed repositories, RBAC models, and pipelines. | `Script Modernization Manager - Build Specs.docx` | Engineering |
| 34 | SEC EnforceNet Timebound Copilot | Supports investigation deadlines, legal holds, evidence, and audit preparation. | `SEC EnforceNet IP Repo Librarian.docx` (filename/content mismatch) | SEC |
| 35 | Skill MD Builder | Produces validated `SKILL.md` content from an elicited skill definition. | `Skill MD Builder.docx` | Agent developers |
| 36 | SOW Visual Designer | Converts approved project content into timelines, swimlanes, roadmaps, and visuals. | `SOW Visual Designer – Microsoft 365 Copilot Agent.docx` | Delivery teams |
| 37 | Tenant Sensitive Data Scout/Hound | Discovers unlabeled, overshared, or policy-uncovered sensitive M365 content. | `Tenant Sensitive Data Hound - full build specifications.docx`; `Tenant Sensitive Data Scout - full build specifications.docx` | Tenant data protection |
| 38 | VA Copilot Use Case Builder | Structures AI/automation use cases into value, data, risk, dependency, and governance artifacts. | `Use Case Builder detaild.docx` | VA |
| 39 | VA GCC Copilot Helpdesk | Provides GCC-grounded troubleshooting, ticket categorization, and escalation. | `VA-Helpdesk_Agent.docx` | VA |
| 40 | Word2Markdown Copilot | Converts Word structure into repository-ready Markdown. | `Word2Markdown Copilot.docx` | Agent developers / content teams |

## Supporting assets that are not separate agents

| Asset group | Files |
|---|---|
| Agent authoring templates | `Agent content Template.docx`; `Microsoft 365 Copilot Agent Design Template v2.0.docx`; `M365 Copilot Agent Build Instructions.docx`; `Creating An Agent Copilot M365.docx` |
| Governance delivery model | `Enterprise_AI_Phased_Rollout_Plan.docx`; `CAIO_Executive_Brief - Enterprise Copilot Strategy.docx`; `Full  WHO → GOVERNANCE chain.docx`; `HHS Governance Delivery Workflow template.png` |
| Workflow-generation examples | `Prompt for creating the single page delivery workflow.docx`; `Prompt for creating the single page delivery workflow for Charlie.docx` |
| Governance and test references | `M365-Copilot-Agents-Test Matrix-SEC.docx`; `MCS Governance in GCC • FieldDays 3-25-26.pptx`; `REALITY FILTER.docx` |
| Duplicate archive | `Copilot Governance Policy Writer – Full Build Specification.zip` |

## Published-link reconciliation

The following shortcuts map with high or probable confidence to the logical agents above:

| Published shortcut(s) | Logical agent |
|---|---|
| `ACSM IP Repo Librarian V2.url`; `ACSM IP Repo Librarian.url`; `M365 Copilot Agent - ACSM Repo Librarian.url` | #1 ACSM IP Repo Librarian; the last two share one target |
| `Azure Lab Tenant Manager.url` | #3 Azure Lab Tenant Manager |
| `Copilot Adoption ROI Analyst.url` | #5 Copilot Adoption ROI Analyst |
| `Copilot Champion Assistant.url` | #6 Copilot Champion Assistant |
| `Copilot Agent Roulette.url`; `Copilot Prompt Roulette.url` | #12 Agent/Prompt Roulette family |
| `Copilot GCC Implementation Advisor.url` | #15 GCC Implementation Advisor |
| `Copilot Governance Strategist.url` | #17 Governance Strategist |
| `Connect Performance Evaluation Assistant.url`; `Copilot Connect Performance Advisor.url` | #19 Performance Assessor (probable) |
| `Data Sensitivity Hound v3.url`; `Tenant Sensitive Data Scout.url` | #37 Sensitive Data Scout/Hound |
| `Documentation Sanitization & Reuse Assistant.url` | #32 Sanitization Agent |
| `Fed Data Governance Copilot Advisor.url` | #7 Data Guard or #17 Strategist (ambiguous) |
| `FedGov Copilot Risk Assessor.url` | #21 Security & Compliance Audit (probable) |
| `Federal Copilot Academy.url` | #24 Federal Copilot Academy |
| `FedOps Copilot Use Case Lab.url` | #25 FedOps Use Case Lab |
| `HHS Missions Support Copilot.url` | #27 HHS Mission Support |
| `M365 Ops Monitor GAO.url` | #10 Service Monitor (probable agency variant) |
| `Microsoft Agent Evaluator.url` | #11 Agent Evaluator |
| `Ops Workflow RACI & RBAC.url`; `RACI & RBAC Designer Agent.url` | #2 or #4 RACI/RBAC family |
| `Purview ITIL Advisor GAO.url` | #28 Purview ITIL Advisor |
| `Quick Reference Creator.url` | #30 Quick Reference Creator |
| `Risky User Management Assistant.url` | #31 Risky User Management |
| `Script Modernization Manager.url` | #33 Script Modernization |
| `Skill MD Builder.url` | #35 Skill MD Builder |
| `SOW Visual Designer.url` | #36 SOW Visual Designer |
| `VA Copilot Use Case Builder.url` | #38 VA Use Case Builder |
| `Word to Markdown format Converter.url` | #40 Word2Markdown |

## Link-only agents

These links have no clearly matching local build specification. Purpose is inferred from title only and must be validated with the agent owner before any integration decision.

| Agent | Provisional purpose | Confidence |
|---|---|---|
| `ATO Boundary Architect.url` | Define authorization boundaries and ATO dependencies. | Low |
| `Copilot ACM Consult Assistant.url` | Adoption and change-management consulting. | Low |
| `Copilot Champion Role Generator.url`; `Copilot Role Generator.url` | Generate champion-role definitions; both links share one target. | Low |
| `Custom Role Creator.url` | Create organizational or access-role definitions. | Low |
| `Federal Narrative Builder.url` | Produce federal executive/program narratives. | Low |
| `Intune Operations Integrator - USPTO.url` | Integrate Intune operational processes for USPTO. | Low |
| `SEC Copilot ACSM Advisor.url` | SEC adoption/change/service-management advice. | Low |
| `Security Operating Model (SOM) Assistant.url` | Design security operating models. | Low |
| `SOW Creator Assistant.url` | Draft Statements of Work. | Low |
| `VA FOIA vs Benefits Advisor.url` | Distinguish FOIA and VA-benefits workflows. | Low |
| `Win365PC Deploy Advisor.url` | Plan Windows 365 deployments. | Low |

## Duplication and quality findings

- Ten agent families have exact duplicate full/summary text.
- The two VA RBAC files are near duplicates.
- Sensitive Data Hound and Scout are the same specification with different names.
- The Roulette family contains two related modes, not separate governance products.
- Two Performance Assessor files are identical person-specific sample outputs, not additional specifications.
- `SEC EnforceNet IP Repo Librarian.docx` contains a timebound-investigation agent rather than a librarian.
- Static product availability, pricing, and GCC statements are snapshots and require current official validation.
