# 07 - SPO Connector and Attestation Integration Contract

> **Legacy implementation guide:** Replace governance-list storage with
> Dataverse and call SharePoint only as a governed source system through Power
> Automate. The approved target is documented in
> [23-Power-Platform-Refactor.md](23-Power-Platform-Refactor.md).

Document: Runtime Data and Attestation Contract  
Solution: M365 Governance AI Agent  
Version: 1.0  
Date: 2026-07-04  
Status: Draft

---

## 1. Purpose

This contract defines how the agent should:

1. Use Agent Knowledge versus live SharePoint data.
2. Query site state at runtime for current owner/admin responses.
3. Integrate attestation signals from SharePoint Advanced Management (SAM).
4. Resolve conflicts when values differ across systems.

This is the implementation reference for Step 1 and Step 2 connector work.

---

## 2. Architecture Decision

### 2.1 Source of Truth by Use Case

| Use Case | Primary Source | Why |
|---|---|---|
| Governance policy explanation, help text, FAQ | Agent Knowledge | Unstructured, explanatory content |
| Owner/admin site list, filtering, status cards | SharePoint connector to Contoso Sites list | Needs deterministic filters and row-level identity scope |
| Certify or other action writes | GovernanceAgent-ActionCallback flow writes to Contoso Sites and Governance Action Log | Transactional action path with audit |
| Cross-system attestation parity with SAM | Sync adapter flow/script | Reconciliation between governance list and SAM |

### 2.2 Knowledge Boundary Rule

Do not use Agent Knowledge as the execution data layer for site status or action decisions.
Knowledge can reference policy pages and documentation, but operational cards and actions must come from connector calls.

---

## 3. Runtime Query Contract (Live Freshness)

### 3.1 Fresh-Read Rule

Every user request for site state must execute a live SharePoint Get items call in that turn.
Do not answer owner/admin site-state questions from cached prior-turn payloads.

### 3.2 Owner Query Pattern

- Input identity: System.User.PrincipalName
- Filter base: substringof('<UPN>', SiteOwners) eq true
- Top count: 20 for owner list responses
- Select only required fields for card rendering

Required select set for owner list cards:
- Title
- SiteURL
- ComplianceStatus
- ComplianceAction
- LastActivityDate
- LastCertificationDate
- SiteOwnersCount
- LastActionDate
- LastActionType
- AttestationStatus
- AttestedAt
- AttestationSource

### 3.3 Admin Query Pattern

- No owner filter after admin role confirmation.
- Keep the same select minimization approach.
- Use explicit filters for dashboard slices (non-compliant, orphaned, by action).

### 3.4 Action Safety Rule

Before any write action:
1. Re-read the specific site row by SiteURL (Top 1).
2. Validate caller authorization (owner for owner actions, admin for admin actions).
3. Show confirmation card.
4. Apply update and write Governance Action Log.

---

## 4. Attestation Data Contract

### 4.1 New Columns in Contoso Sites

Add the following columns to support attestation integration:

| Internal Name | Type | Required | Description |
|---|---|---|---|
| AttestationStatus | Choice | No | Current attestation state |
| AttestedAt | DateTime | No | Last attestation timestamp |
| AttestedBy | Text | No | UPN for last attester |
| AttestationSource | Choice | No | Source system for current attestation |
| AttestationExpiresAt | DateTime | No | Optional expiry derived from policy |
| AttestationEvidenceId | Text | No | Optional external ID from SAM or workflow run |
| AttestationSyncAt | DateTime | No | Last successful sync from SAM |

Recommended choice sets:
- AttestationStatus: NOT-ATTESTED, ATTESTED, EXPIRED, EXEMPT, UNKNOWN
- AttestationSource: AGENT, SAM, IMPORT, MANUAL

### 4.2 Governance Action Log Extension

Add optional fields to Governance Action Log:

| Internal Name | Type | Description |
|---|---|---|
| ExternalAttestationWrite | Choice | YES, NO, SKIPPED |
| ExternalAttestationRef | Text | Reference ID if SAM update is supported |
| ReconciliationState | Choice | MATCHED, PENDING, CONFLICT |
| ReconciliationNotes | Note | Diagnostic detail for operations |

---

## 5. SAM Integration Model

### 5.1 Integration Modes

Use two integration modes so deployment does not block on uncertain API capability:

1. Read-sync mode (mandatory first):
   - Scheduled flow/script pulls attestation status from SAM (or export source).
   - Upserts attestation fields into Contoso Sites.
   - Sets AttestationSource = SAM when SAM is newer.

2. Write-through mode (optional when supported):
   - On certify action, after local write, call SAM update endpoint/connector.
   - Store result in ExternalAttestationWrite and ExternalAttestationRef.

If write-through is unavailable, keep local governance update authoritative for chat UX and mark reconciliation as PENDING.

### 5.2 Sync Cadence

- Owner/admin conversational reads: always live from Contoso Sites.
- SAM reconciliation job:
  - Default: every 6 hours.
  - Minimum: once daily.
- Trigger immediate sync for a site after a successful certify action when possible.

---

## 6. Conflict Resolution Rules

When local and SAM attestation values differ:

1. Determine recency by timestamp (AttestedAt from each source).
2. If SAM timestamp is newer by at least 5 minutes, SAM wins for read display.
3. If local timestamp is newer by at least 5 minutes, local wins and queue SAM write/sync.
4. If timestamps are equal but status differs, set ReconciliationState = CONFLICT and surface admin warning in dashboard.
5. Never block user confirmation response on external sync failure; return success for local transaction and report external sync state separately.

Display rule in owner cards:
- Show a small note when ReconciliationState is PENDING or CONFLICT.

---

## 7. Topic-Level Behavior Contract

### 7.1 My Sites

- Execute live owner filter query.
- Render list card from current rows.
- Include attestation badge from AttestationStatus.

### 7.2 Sites Needing Attention

- Execute live owner filter with ComplianceStatus = NON-COMPLIANT.
- Sort by action priority (ASSIGN-OWNERS, ARCHIVE, CERTIFY).
- Include attestation age hint if AttestedAt is stale.

### 7.3 Certify Site

On confirm:
1. Update LastCertificationDate, ComplianceStatus, ComplianceAction, LastAction fields.
2. Update attestation fields:
   - AttestationStatus = ATTESTED
   - AttestedAt = now UTC
   - AttestedBy = caller UPN
   - AttestationSource = AGENT
3. Write Governance Action Log entry.
4. Attempt SAM write-through if available.
5. Set reconciliation fields according to outcome.

---

## 8. Security and Permissions Contract

1. Owner scope: caller must be present in SiteOwners for owner actions.
2. Admin scope: only confirmed admin can run tenant-wide queries.
3. Connector permissions:
   - Read: Sites.Read.All (delegated/app per architecture)
   - Write: Sites.ReadWrite.All where write actions are enabled
4. No silent elevation: if the caller lacks rights, return a clear denial message.

---

## 9. Non-Functional Requirements

1. Freshness: conversational state responses reflect latest Contoso Sites row values at query time.
2. Determinism: all operational queries use explicit OData filters.
3. Auditability: all write actions append Governance Action Log.
4. Resilience: external attestation failure does not lose local action record.
5. Observability: reconciliation states must be queryable in admin views.

---

## 10. Implementation Order

1. Add attestation columns to Contoso Sites and log extensions.
2. Implement live connector reads in My Sites and Sites Needing Attention.
3. Extend GovernanceAgent-ActionCallback CERTIFY path to include attestation fields and keep topic wiring as invocation-only.
4. Add SAM read-sync job (scheduled).
5. Add optional SAM write-through path.
6. Add admin reconciliation dashboard slice.

---

## 11. Open Verification Items

1. Confirm SAM data access path available in this tenant (API, connector, export, or report feed).
2. Confirm whether SAM supports direct write/update for site attestations.
3. Confirm required role assignments for service principal or delegated connector identity.
4. Confirm attestation expiry policy (fixed days versus policy-driven per site type).

Until item 2 is verified, implement read-sync first and keep write-through as optional capability flag.
