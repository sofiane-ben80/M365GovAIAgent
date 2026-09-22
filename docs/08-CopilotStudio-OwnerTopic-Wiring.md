# 08 - Copilot Studio Owner Topic Wiring

> **Legacy implementation guide:** Reuse the topic/card patterns, but bind them
> to the Dataverse Power Automate contracts in
> [12-PowerAutomate-Build-Guide.md](12-PowerAutomate-Build-Guide.md). Do not add
> direct governance SharePoint-list actions.

Document: Owner Topic Connector Wiring Runbook  
Solution: M365 Governance AI Agent  
Date: 2026-07-04  
Status: Draft

---

## 1. Goal

Wire the owner journey topics to live SharePoint list reads and writes in Copilot Studio UI:

1. My Sites
2. Sites Needing Attention
3. Certify Site
4. Site Detail
5. Flag for Deletion
6. Request Archival

Admin persona wiring is defined separately, but it follows the same pattern: read the full Contoso Sites list, surface orphaned and not-attested sites, then hand off to action topics only after confirmation.

This runbook assumes list schema is already initialized by scripts.

---

## 2. Prerequisites

1. Run scripts in dev tenant:
   - ../archive/legacy-2026-09-19/scripts/Initialize-GovernanceLists.ps1
   - ../archive/legacy-2026-09-19/scripts/Update-SampleData.ps1
2. Confirm SharePoint connection exists in Copilot Studio for:
   - https://mngenvmcap733570.sharepoint.com/sites/M365Governance
3. Confirm user can pass owner authorization checks and that flow/connector identities have required SharePoint write permissions.

---

## 3. Global Topic Variables

Use these topic variables across owner topics:

- Topic.CallerUPN (string)
- Topic.SelectedSiteUrl (string)
- Topic.SelectedSiteTitle (string)
- Topic.SelectedSiteItemId (string/number, normalize in UI)
- Topic.PreviousComplianceStatus (string)
- Topic.PreviousComplianceAction (string)
- Topic.ActionCompleted (boolean)
- Topic.ActionType (string)
- Topic.ActionStatus (string)
- Topic.RequiredConfirmationText (string; default: CONFIRM)

Set Topic.CallerUPN from:
- System.User.PrincipalName

Output contract after owner action topics complete:
- Topic.ActionCompleted = true|false
- Topic.ActionType = CERTIFY | ARCHIVE-REQUESTED | DELETE-REQUESTED
- Topic.ActionStatus = COMPLETED | CANCELLED | FAILED
- Topic.SelectedSiteUrl and Topic.SelectedSiteTitle remain populated for summary cards

---

## 4. My Sites Topic Wiring

Target topic file in export:
- copilot/agents/M365 Governance Agent/topics/MySites.mcs.yml

In Copilot Studio UI topic editor:

1. Add Set variable node:
   - Topic.CallerUPN = System.User.PrincipalName

2. Add an action node that calls `GovernanceAgent-GetMySites`:
   - UserUPN: Topic.CallerUPN
   - Save `success` as Topic.GetMySitesSuccess.
   - Save `siteCount` as Topic.SiteCount.
   - Save `sitesJson` as Topic.SitesJson.
   - Save `message` as Topic.GetMySitesMessage.

3. Add response conditions before rendering:
   - If Topic.GetMySitesSuccess is false, show Topic.GetMySitesMessage and stop.
   - If Topic.SiteCount is 0, show Topic.GetMySitesMessage and stop.

4. Parse Topic.SitesJson and add an adaptive card response node using the My Sites card template.
   - Map itemId, title, siteUrl, siteType, complianceStatus, complianceAction,
     attestationStatus, lastCertificationDate, lastActivityDate, siteOwners, and
     siteOwnersCount from each returned row.
   - Preserve itemId, title, and siteUrl in each card action payload.

5. Use `copilot/flows/get-my-sites-flow.txt` as the flow's build and response contract.

---

## 5. Sites Needing Attention Topic Wiring

Target topic file in export:
- copilot/agents/M365 Governance Agent/topics/SitesNeedingAttention.mcs.yml

In Copilot Studio UI topic editor:

1. Set Topic.CallerUPN = System.User.PrincipalName.

2. Add SharePoint Get items node:
   - Filter Query:
     substringof('@{Topic.CallerUPN}', SiteOwners) eq true and ComplianceStatus eq 'NON-COMPLIANT'
   - Order By: ComplianceAction asc
   - Top Count: 20
   - Select Query:
     Title,SiteURL,ComplianceStatus,ComplianceAction,LastActivityDate,LastCertificationDate,EffectiveOwnerCount,AttestationStatus,AttestedAt,AttestationSource

3. Sort to action priority in-topic if needed:
   - ASSIGN-OWNERS first
   - ARCHIVE second
   - CERTIFY third

4. Render adaptive card list and include quick actions.

---

## 6. Certify Topic Wiring

Refine exported certify topic scaffold:
- copilot/agents/M365 Governance Agent/topics/CertifySite.mcs.yml
- copilot/flows/certify-site-topic-spec.txt

Required write behavior after confirmation:

1. Run flow: GovernanceAgent-ActionCallback.
   Required inputs:
   - callerUPN = Topic.CallerUPN
   - actionType = CERTIFY
   - siteUrl = Topic.SelectedSiteUrl
   - siteTitle = Topic.SelectedSiteTitle
   - siteItemId = Topic.SelectedSiteItemId
   - previousComplianceStatus = Topic.PreviousComplianceStatus
   - previousComplianceAction = Topic.PreviousComplianceAction

2. Validate flow response and branch:
   - success = true and actionStatus = COMPLETED -> render success card and set Topic.ActionCompleted = true
   - otherwise -> show safe failure message with returned message text

3. Do not perform direct SharePoint Update item / Create item writes in this topic.
   - Contoso Sites updates and Governance Action Log writes are centralized in GovernanceAgent-ActionCallback.

---

## 7. Validation Checklist

1. Owner can query only owned sites.
2. Non-owner cannot certify a site.
3. Certify updates both compliance and attestation fields.
4. Action log row includes reconciliation fields.
5. Empty-state responses are user-friendly.

---

## 8. Site Detail Topic Wiring

Target topic file in export:
- copilot/agents/M365 Governance Agent/topics/SiteDetail.mcs.yml

In Copilot Studio UI topic editor:

1. Resolve selected site context from list/detail action submit payload:
   - Topic.SelectedSiteUrl
   - Topic.SelectedSiteTitle

2. Add SharePoint Get items node for selected site:
   - Filter Query: SiteURL eq '@{Topic.SelectedSiteUrl}'
   - Top Count: 1

3. Invoke triage logic (sub-agent or equivalent) and map:
   - Topic.TriageReasoning
   - Topic.TriageSeverity

4. Render adaptive card template:
   - adaptive-cards/site-detail-card.json

---

## 9. Flag for Deletion Wiring

Target topic file in export:
- copilot/agents/M365 Governance Agent/topics/FlagForDeletion.mcs.yml

In Copilot Studio UI topic editor:

1. Add ownership check (same pattern as Certify).
2. Require explicit confirmation text exactly equal to CONFIRM.
3. Invoke GovernanceAgent-ActionCallback with `actionType = DELETE-REQUESTED` and selected site context.
4. Handle callback response and render requested/rejected/failure messaging.

---

## 10. Notes

---

1. The exported .mcs.yml does not always round-trip all UI-authored connector node details in a maintainable way.
2. Treat this runbook as the source for UI wiring, then re-export the solution package.
3. After wiring and export, update roadmap/matrix statuses accordingly.
4. Normalize SelectedSiteItemId as numeric before passing it to Action Callback flow inputs.

---

## 11. Admin Persona Wiring (Planned)

Target outcomes for the Admin sub-agent:

1. Dashboard summary with counts for compliant, non-compliant, orphaned, and not-attested sites.
2. Orphaned sites list that lets an admin decide whether to assign an owner or archive/delete.
3. Not attested list that filters on `AttestationStatus` and `AttestationExpiresAt`.
4. Site detail view that shows the same triage reasoning used for owners, but without the owner-only filter.
5. Action handoff paths that preserve the caller's UPN and write a full action log entry.
