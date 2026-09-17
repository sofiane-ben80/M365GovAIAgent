# M365 Governor Knowledge Asset Catalog

## Reusable corpus assets

| Asset | Source agent/file | Purpose | Reuse? | Conditions |
|---|---|---|---|---|
| Enterprise phased rollout model | `Enterprise_AI_Phased_Rollout_Plan.docx`; `CAIO_Executive_Brief - Enterprise Copilot Strategy.docx` | WHO/ROLE/RBAC/WHERE/ACTION/dependency/governance gates | Yes - High | Validate product, tenant, and schedule assumptions. |
| Governance delivery operating model | `Full  WHO -> GOVERNANCE chain.docx`; `HHS Governance Delivery Workflow template.png` | Responsibility split, phases, and deliverables | Yes - High | Generalize agency names and confirm accountable owners. |
| GCC governance availability framework | `MCS Governance in GCC - FieldDays 3-25-26.pptx` | Zoned governance and feature-availability planning | Yes - High | Treat as dated; verify every availability claim. |
| Agent licensing/access test matrix | `M365-Copilot-Agents-Test Matrix-SEC.docx` | Creation, sharing, installation, access, licensing, and role tests | Yes - High | Rerun in each tenant/cloud. |
| Agent evaluation framework | `Copilot Agent Evaluator.docx` | Preproduction and recurring assurance gates | Yes - Very High | Convert to automated and manual acceptance tests. |
| Federal policy/control pattern | Policy Writer, Strategist, Security Audit, GCC Advisor, RBAC specs | NIST/FedRAMP/Zero Trust/ATO mappings and artifact shapes | Yes - Very High | Bind to approved baseline revisions; not legal advice or authorization. |
| Sensitive-data assessment pattern | Data Guard and Scout/Hound specs | DLP, labels, permissions, exposure, and remediation scoring | Yes - Very High | Implement against read-only, scoped evidence adapters. |
| Prompt libraries | `NIH Copilot Prompt Library.docx`; Roulette files | Prompt structures and training starters | Yes - High | Reuse structure; separate agency-specific content. |
| Agent authoring templates | `Agent content Template.docx`; `Microsoft 365 Copilot Agent Design Template v2.0.docx`; build instructions | Standard design and publishing checklist | Yes - High | Add explicit authorization, data classification, evaluation, and retirement fields. |
| Reality Filter | `REALITY FILTER.docx` | Grounding, uncertainty labeling, and correction behavior | Yes - High | Adapt principles; do not copy rigidly where they harm usability. |
| Sanitization pattern | `Sanitizer Agent.docx` | Remove organization/person identifiers before reuse | Yes - Medium/High | Use ephemeral processing and human verification. |
| Word-to-Markdown pattern | `Word2Markdown Copilot.docx` | Normalize content for governed repositories | Yes - Medium/High | Preserve source, classification, version, and owner metadata. |
| Performance formulas/examples | Performance Assessor files | KPI schema, confidence/method fields, DAX examples | Limited | Do not ground production answers on person-specific modeled examples. |
| Workflow transformation prompt | Single-page workflow prompt files | Convert SOW content to delivery workflow | Limited | Sanitize customer references and verify generated milestones. |

## Required production knowledge classes

| Knowledge class | Example content | Required metadata/control |
|---|---|---|
| Approved agency policy | Copilot acceptable use, privacy, records, data handling | Owner, approver, version, effective date, classification, superseded-by |
| Federal control baselines | NIST 800-53, FedRAMP baselines, inheritance, Zero Trust | Revision, applicability profile, control owner, interpretation authority |
| Microsoft authoritative sources | Microsoft Learn, Service Trust Portal, Product Terms, Message Center, roadmap | Cloud applicability, retrieved date, expiration/revalidation date |
| Purview configuration | Labels, DLP, retention, records, eDiscovery, audit | Tenant, environment, reader scope, snapshot time, evidence lineage |
| Identity governance | Entra roles, PIM, access reviews, Conditional Access | Tenant, authorized audience, collection time, sensitivity |
| M365 permissions | SharePoint, OneDrive, Teams, Exchange sharing and guests | Resource, caller scope, link/group expansion, collection time |
| Agent inventory | Owner, Agent ID, environment, connectors, knowledge, sharing, lifecycle | Accountable owner, risk tier, review date, status, retirement date |
| Operations evidence | Incidents, changes, service health, runbooks, PIRs | System of record, ticket access, retention, redaction |
| Adoption evidence | Aggregated usage, training, support, satisfaction | Purpose limitation, privacy approval, aggregation threshold, retention |
| Agency profiles | DOI, IRS, Census, Federal Reserve, VA, HHS, GAO, NIH, SEC | Strict profile separation, policy owner, cloud, approved source set |

## Source-governance requirements

1. Do not hard-code cross-tenant SharePoint URLs, connector IDs, role IDs, or environment IDs.
2. Every source has an accountable owner, classification, version, effective date, and review date.
3. Expired or superseded sources are excluded from normal grounding.
4. Official Microsoft availability and licensing claims have a short revalidation interval.
5. Search results preserve security trimming; indexing does not broaden access.
6. Findings retain lineage to source record and collection timestamp.
7. Raw CUI, PII, PHI, investigation, or personnel data is not copied into a general Governor knowledge base.
8. Agency profiles are separate collections with explicit audience controls.
9. Sanitized reusable IP retains a placeholder legend and human approval record.
10. The knowledge pipeline is tested for prompt injection and poisoned documents.

## Assets not suitable for production grounding

- Person-specific Performance Assessor examples.
- Customer-specific workflow examples before sanitization.
- Dated feature/pricing claims without current official confirmation.
- Duplicate ZIP contents.
- Tenant-specific URLs, connection references, identities, and role assignments.
- Agent outputs that lack source lineage and approval status.

