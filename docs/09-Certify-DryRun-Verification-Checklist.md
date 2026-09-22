# 09 - Certify Dry-Run Verification Checklist

> **Legacy checklist:** Adapt record identifiers and assertions to Dataverse
> Governance Site, Governance Action Request, and Governance Action Event.
> Target acceptance gates are in [01-Requirements.md](01-Requirements.md).

Document: Dry-run verification for owner certify flow (pre-pilot)  
Solution: M365 Governance AI Agent  
Date: 2026-07-04  
Status: Draft

---

## 1. Scope

Validate the Certify owner journey after Copilot Studio UI wiring and package re-export.

In scope:
1. Intent recognition and topic routing
2. Owner-only authorization behavior
3. Contoso Sites write updates (compliance + attestation)
4. Governance Action Log entry content
5. User-facing confirmation behavior

Out of scope:
1. SAM write-through (Phase 2+)
2. Admin Agent bulk operations
3. Proactive notification flows

---

## 2. Preconditions

1. Run schema/data scripts in dev tenant:
   - ../archive/legacy-2026-09-19/scripts/Initialize-GovernanceLists.ps1
   - ../archive/legacy-2026-09-19/scripts/Update-SampleData.ps1
2. Certify topic connector nodes are wired in Copilot Studio using:
   - docs/08-CopilotStudio-OwnerTopic-Wiring.md
   - copilot/flows/certify-site-topic-spec.txt
3. Test identities available:
   - Owner user with at least one owned site
   - Non-owner user
4. Copilot published to test environment and reachable in Teams test chat.

---

## 3. Test Cases

### TC-01 Recognize Certify Intent

Steps:
1. Sign in as owner test user.
2. Send: certify a site.

Expected:
1. Topic Certify Site starts.
2. Confirmation prompt appears before any write action.

Evidence to capture:
1. Chat screenshot of confirmation step.

---

### TC-02 Cancel Path Is Non-Destructive

Steps:
1. Start certify flow.
2. Answer No at confirmation.

Expected:
1. Agent returns no-change message.
2. No Contoso Sites update.
3. No Governance Action Log row created.

Evidence to capture:
1. Chat screenshot.
2. List query screenshot showing unchanged row.

---

### TC-03 Owner Certify Success Path

Steps:
1. Start certify flow as owner.
2. Confirm Yes.
3. Select a site owned by caller (from My Sites context or provided URL).

Expected Contoso Sites updates:
1. ComplianceStatus = COMPLIANT
2. ComplianceAction = NONE
3. LastActionType = CERTIFY
4. LastActionBy = caller UPN
5. LastCertificationDate set to current UTC time
6. AttestationStatus = ATTESTED
7. AttestedBy = caller UPN
8. AttestedAt set to current UTC time
9. AttestationSource = AGENT
10. AttestationExpiresAt set (current UTC + policy days)

Expected Action Log updates:
1. New row with ActionType = CERTIFY
2. ActionStatus = COMPLETED
3. RequestedBy = caller UPN
4. PreviousComplianceAction populated
5. PreviousComplianceStatus populated
6. ExternalAttestationWrite = SKIPPED
7. ReconciliationState = PENDING

Evidence to capture:
1. Chat screenshot of success response.
2. Contoso Sites row before/after.
3. Governance Action Log new row screenshot.

---

### TC-04 Non-Owner Authorization Guard

Steps:
1. Sign in as non-owner test user.
2. Attempt to certify a known site not owned by caller.

Expected:
1. Agent denies certification with owner-only guidance.
2. No write to Contoso Sites.
3. No Governance Action Log row for completion.

Evidence to capture:
1. Chat screenshot of deny response.
2. List evidence showing no update.

---

### TC-05 Data Freshness Spot Check

Steps:
1. Update one target site row manually in Contoso Sites (for test only).
2. Re-run Certify flow and verify current row state is used.

Expected:
1. Flow uses latest row values for previous status/action snapshot.
2. Logged previous values match immediately prior state.

Evidence to capture:
1. Before/after row snapshot.
2. Action log previous-value fields.

---

## 4. Exit Criteria

All must pass:
1. TC-01 through TC-05 pass.
2. No unauthorized writes observed.
3. Action log is complete and auditable.
4. No topic runtime errors in test chat.

---

## 6. Supplemental Deletion Guard Check

### TC-06 Deletion Request Confirmation Guard

Steps:
1. Start deletion request flow from site detail context.
2. Attempt continuation without explicit confirm text.

Expected:
1. Flow does not submit request.
2. User is informed that explicit confirmation is required.

Evidence to capture:
1. Chat screenshot showing guard behavior.

If any fail:
1. Keep P1-10 status as In Progress.
2. Record failing case, error text, and UPN used.
3. Re-test only failed cases after fix.

---

## 5. Result Record Template

Use this template per run:

- Date/Time (UTC):
- Environment:
- Build/Export Version:
- Tester:
- Cases Passed:
- Cases Failed:
- Notes:
- Follow-up Actions:
