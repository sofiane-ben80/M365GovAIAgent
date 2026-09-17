# 25 - Deployment Status and Runbook

**Release date:** 2026-09-17  
**Target environment:** Sofiane Benabderrahmane's Environment  
**Environment ID:** `9417045e-87bb-eac8-bda1-850674b11405`

## Release objective

Publish the latest Power Platform-first design without representing
design-only Dataverse or Power Automate components as deployed capability, and
publish the matching source and documentation to GitHub.

## Release result

- GitHub `main` was updated on 2026-09-17 with the reviewed agent source,
  Dataverse flow contracts, architecture media, canonical documentation, and
  hackathon materials.
- The Owner and Admin deployable source instructions were aligned and validated
  locally.
- Live Owner/Admin publication was intentionally deferred. The target
  Dataverse schema and replacement Power Automate tools are not provisioned,
  while deterministic legacy topics and embedded workflows still exist in the
  current packages. Publishing instructions alone would not constitute a safe
  functional cutover.
- The installed PAC CLI can list, publish, and extract templates but does not
  provide the guarded `copilot pull`/`push` commands used by the repository
  deployment helper. A push-capable Copilot Studio source workflow must be
  restored before the reviewed package can be released.

## Verified tenant inventory

| Component | ID | Verified state |
|---|---|---|
| Governor M365 | `d610fa66-3e1e-f111-8341-6045bd088c4f` | Published, active, provisioned |
| Governance Owner Agent | `18c2cb08-2014-47a3-8c0c-5baeecf4f5e3` | Published, active, provisioned |
| Governance Admin Agent | `c7eea6a2-3fc0-4e3a-8ebb-56ff7a390033` | Published, active, provisioned |
| Governance Policy Advisor | `0af1ffd3-d69a-4313-9bcb-05c91c19ffd6` | Published shell; production tools disabled |
| Copilot Readiness Advisor | `a303e7c0-110d-4f10-9736-53dd7c51b040` | Published shell; production tools disabled |
| Data Protection Advisor | `7f9c6873-cf91-455e-95f7-86321e2f84a3` | Published shell; production tools disabled |
| Identity Governance Advisor | `7f385fc4-d4a2-42f0-b9e7-0890096b6fed` | Published shell; production tools disabled |
| Security & Compliance Assurance | `ad57f320-41aa-4e1b-8b85-e432ba139ebc` | Published shell; production tools disabled |

## Source release

The Owner and Admin deployable instruction files now:

- use Dataverse-backed, solution-aware Power Automate tools as the only target
  data and request path;
- derive identity from `System.User.PrincipalName`;
- fail closed when authorization or a required tool is unavailable;
- prohibit fallback to Azure SQL and governance SharePoint lists;
- restore owner certification as a governed request after a fresh owner check
  and explicit confirmation;
- require typed `CONFIRM` for deletion review; and
- prohibit fabricated records, request IDs, and successful outcomes.

Flow contracts in `copilot/flows` are implementation specifications. They are
not evidence that corresponding flows are active in the target environment.

## Current cutover boundary

This release is an instruction and documentation alignment, not the Dataverse
functional cutover. The following gates remain open:

1. create the Dataverse tables, choices, keys, relationships, roles, and
   access-team template;
2. build and activate the solution-aware owner/admin read and request flows;
3. bind Copilot Studio tools and connection references;
4. run owner-isolation, unauthorized-admin, confirmation, idempotency, error,
   and audit-event tests;
5. export and unpack a verified Power Platform solution; and
6. import the managed solution into test before production promotion.

Until those gates pass, an unavailable target tool must produce an explicit
service-unavailable response. It must not invoke a legacy data path.

## Safe deployment sequence

1. Export or pull each live agent into an ignored comparison folder.
2. Compare generated topics, connected-agent declarations, settings,
   workflows, and connection references with source control.
3. Push only the reviewed Owner/Admin instruction alignment.
4. Publish the changed agents.
5. Poll each deployment until it reports provisioned.
6. Extract each live template again and verify the released instructions.
7. Run failure-path smoke tests before enabling any new tool.
8. Commit the post-publish source and this release record to GitHub.

## Functional cutover validation

| Test | Required result |
|---|---|
| Owner A lists sites | Only active exact assignments for Owner A are returned |
| Owner A requests Owner B site | Request is denied and no other-owner data is returned |
| Non-admin requests dashboard | Admin verification fails closed and returns no tenant data |
| Tool dependency unavailable | Explicit error; no fabricated data or success |
| Duplicate request | Existing request ID is returned using the idempotency key |
| Certification | Fresh owner read, explicit confirmation, `PENDING` request |
| Deletion review | Typed `CONFIRM`, human approval path, no direct deletion |
| Audit | Request creation and every transition append action events |

## Rollback

Retain pre-release live template exports. If routing, authorization, or tool
availability regresses, restore the previously verified agent definition,
publish it, and keep Dataverse-bound tools disabled until the failed gate is
corrected and retested.
