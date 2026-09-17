# M365 Governor Implementation Guide

## Delivery state

The repository contains an operational three-agent governance foundation and a
defined five-advisor expansion. Documentation distinguishes deployed source,
migration definitions, and planned components so that design intent is not
reported as live capability.

| Capability | State | Source of record |
| --- | --- | --- |
| Governor M365 launcher | Implemented in exported Copilot Studio source | `agents/M365 Governance Agent` |
| Governance Owner Agent | Implemented classic package | `agents/Governance Owner Agent` |
| Governance Admin Agent | Implemented classic package | `agents/Governance Admin Agent` |
| Owner and Admin skills migration | Defined; acceptance and cutover remain | `new-agents` and `skills` |
| Five connected domain advisors | Published shells verified; audiences and production tools remain disabled | `new-agents/advisor-manifest.yml` and `docs/live-baseline-2026-09-16.md` |
| Shared evidence and tool broker | Contract and data model defined; implementation remains | `docs/08-Advisor-Agent-Integration-Architecture.md` |

## Runtime path

```text
Signed-in user
  -> Governor M365
  -> one connected Owner, Admin, or domain advisor
  -> that agent's topic, child, prompt, or authorized tool
  -> bounded result to the destination agent
  -> one user-facing response
```

The launcher does not query data. Owner and Admin tools enforce their own
authorization. Advisor tools enforce identity, audience, purpose, scope,
freshness, and response minimization through the evidence broker.

## Implementation layers

| Layer | Components | Implementation rule |
| --- | --- | --- |
| Experience | Governor, Owner, Admin, and five domain advisors | One direct launcher handoff; one response owner |
| Domain orchestration | Child agents, topics, prompts, and deterministic workflows | Remain inside the parent domain and maximum orchestration depth |
| Tool and authorization | Power Automate flows and managed APIs | Typed inputs and bounded versioned outputs; fail closed |
| Evidence | Resource, snapshot, fact, relationship, finding, assessment, control, policy, capability, and request records | Store minimized facts and lineage; keep restricted artifacts in approved sources |
| Collection | Scheduled collectors and direct source adapters | Scheduled baselines plus fresh scoped validation for consequential claims and writes |
| Operations | Agent registry, capability registry, evaluation harness, telemetry, and ALM | Correlate launcher, agent, tool, collection, and request events |

## Source ownership

| Path | Ownership |
| --- | --- |
| `agents/*/*.mcs.yml` | Deployable classic Copilot Studio packages |
| `agents/*/agents/*.mcs.yml` | Generated connected-agent declarations |
| `agents/*/topics/*.mcs.yml` | Routing and deterministic conversation topics |
| `agents/*/workflows` | Workflows embedded in agent packages |
| `agents/*-instructions.txt` | Authoring instructions for current agents |
| `new-agents/*.md` | Skills-based target agent instructions |
| `new-agents/advisor-manifest.yml` | Advisor route, release, deployment, and audience inventory |
| `skills/*/SKILL.md` | Reusable task procedures and safety rules |
| `flows/*.txt` | Workflow contracts and implementation notes |
| `docs/architecture.md` | Canonical runtime and security architecture |

## Release sequence

1. **Foundation:** validate launcher, Owner, and Admin routing, authorization,
   confirmation, failure handling, and audit behavior.
2. **Skills migration:** validate the Owner and Admin skills-based definitions
   against the classic package before cutover.
3. **Shared platform:** implement registries, broker authorization envelope,
   normalized evidence contracts, telemetry, and evaluation harness.
4. **Advisor shells:** create and publish the five definitions without
   production connectors, record deployment identifiers and audiences in the
   manifest, and connect routes only after ambiguity and handoff tests pass.
5. **Wave 1:** release Governance Policy and Copilot Readiness with approved
   knowledge and read-only assessment tools.
6. **Wave 2:** release Data Protection with isolated evidence collection and
   deterministic exposure scoring.
7. **Wave 3:** release Identity Governance with restricted person-level access
   and direct validation of current assignments.
8. **Wave 4:** release Security & Compliance Assurance over audience-trimmed
   normalized findings and approved control baselines.

Each wave must pass target-cloud capability validation, positive and negative
authorization tests, routing tests, evidence-freshness checks,
duplicate-response checks, and rollback verification before publication.

## Change and deployment workflow

1. Create a feature branch and pull the latest live package before editing
   generated source.
2. Review changes to agent declarations, topics, settings, workflows, and
   connection references.
3. Validate source syntax and focused persona scenarios.
4. Push with the deployment helper and publish deliberately in Copilot Studio.
5. Pull again to capture server-generated metadata and reconcile the diff.
6. Commit and push the final source and documentation together.

Detailed work packages, dependencies, acceptance criteria, and rollout gates
are maintained in the
[Advisor Implementation Roadmap](09-Advisor-Implementation-Roadmap.md).