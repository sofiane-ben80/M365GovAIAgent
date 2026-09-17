# Advisor Deployment and Component Backlog

> **Architecture update (2026-09-17):** Re-map storage to Dataverse and runtime
> orchestration to Power Automate. Azure SQL and Azure-hosted API backlog items
> below are retained as historical analysis and are not the approved target.
> See `../../docs/23-Power-Platform-Refactor.md`.

## Live advisor shells

All five shells were created in environment
`9417045e-87bb-eac8-bda1-850674b11405` on September 16, 2026. Their
source-controlled descriptions and instructions were round-trip verified after
solution import.

| Agent | Bot ID | Schema name | Live state |
| --- | --- | --- | --- |
| Governance Policy Advisor | `0af1ffd3-d69a-4313-9bcb-05c91c19ffd6` | `copilots_gov_policy_01` | Published, active, provisioned |
| Copilot Readiness Advisor | `a303e7c0-110d-4f10-9736-53dd7c51b040` | `copilots_copilot_readiness_01` | Published, active, provisioned |
| Data Protection Advisor | `7f9c6873-cf91-455e-95f7-86321e2f84a3` | `copilots_data_protection_01` | Published, active, provisioned |
| Identity Governance Advisor | `7f385fc4-d4a2-42f0-b9e7-0890096b6fed` | `copilots_identity_governance_01` | Published, active, provisioned |
| Security & Compliance Assurance | `ad57f320-41aa-4e1b-8b85-e432ba139ebc` | `copilots_security_assurance_01` | Published, active, provisioned |

These are safe shells, not production-ready advisors. They have no production
tools or knowledge and are not connected to Governor M365.

## Components to build

| Component | Initial implementation | Status | Dependency |
| --- | --- | --- | --- |
| Advisor agent shells | Five Copilot Studio agents | Complete | None |
| Repeatable shell publishing | PAC create plus solution-based GPT component sync | Complete | PAC authentication |
| Agent and capability registry | Azure SQL tables and admin workflow | Not started | Approved schema and owners |
| Evidence and finding store | Azure SQL logical schemas | Not started | Classification and retention decisions |
| Evidence/tool broker | Managed API with Entra OAuth | Contract started | App registration, hosting, SQL access |
| Policy connector operations | Five broker operations | Contract started | Approved policy repository |
| Readiness connector operations | Five broker operations | Contract started | Profile, capability, and change sources |
| Data Protection operations | Five broker operations | Planned | Purview/Graph/SAM source decisions |
| Identity operations | Five broker operations | Planned | Entra reader consent and person-data controls |
| Assurance operations | Five broker operations | Planned | Control baseline and isolated security sources |
| Scheduled collectors | Jobs/functions/automation | Not started | Source identities and refresh SLAs |
| Deterministic assessment engine | Versioned rubric executor | Not started | Approved maturity/readiness rubrics |
| Restricted artifact store | Approved SharePoint library or object store | Not started | Records and classification decision |
| Policy/control knowledge | Security-trimmed approved repository | Not started | Source owners and lifecycle metadata |
| Telemetry correlation | Application Insights or approved equivalent | Not started | Broker runtime and privacy review |
| Evaluation harness | Routing, authorization, failure, and groundedness cases | Not started | Test identities and fixtures |
| Governor connected-agent routes | Seven connected-agent declarations | Blocked intentionally | Audience groups and shell mismatch tests |

## Connector implementation started

The first Swagger contract is
`connectors/governor-advisor-broker/apiDefinition.swagger.json`. It defines all
ten Policy and Readiness operations with:

- OAuth 2.0 and no model-supplied caller identity;
- typed and bounded request inputs;
- correlation IDs;
- freshness, partial-result, classification, and source metadata;
- deterministic rubric version fields;
- explicit fail-closed error codes;
- draft-only policy artifact status.

Before deployment, the broker host and Entra application scope placeholders
must be replaced through environment configuration. No secret belongs in the
Swagger file.

## Next implementation slice

1. Create the broker Entra app registration and `Governor.Access` delegated
   scope.
2. Select the managed API runtime and managed identity.
3. Add SQL registries for agents, capabilities, sources, profiles, rubrics,
   assessments, findings, and evidence references.
4. Implement `GetReadinessBaseline` and `GetCapabilityClaim` first because they
   are read-only and have clear freshness contracts.
5. Implement `SearchApprovedPolicy` only after approved-source lifecycle and
   security trimming are available.
6. Add broker denial, stale, partial, malformed-input, timeout, and paging
   tests before binding the connector to either live advisor.
7. Configure audience groups and test mismatch prompts before adding the five
   connected-agent routes to Governor M365.
