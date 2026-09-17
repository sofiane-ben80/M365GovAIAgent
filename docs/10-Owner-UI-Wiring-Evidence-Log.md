# 10 - Owner UI Wiring Evidence Log

> **Legacy evidence template:** Capture Dataverse table, flow run, solution
> import, and owner-isolation evidence for the target implementation. See
> [23-Power-Platform-Refactor.md](23-Power-Platform-Refactor.md).

Document: Execution log template for Copilot Studio owner-topic wiring  
Solution: M365 Governance AI Agent  
Date: 2026-07-04  
Status: Draft

---

## 1. Purpose

Use this log while performing the Copilot Studio UI wiring steps in `docs/08-CopilotStudio-OwnerTopic-Wiring.md`.

It captures:
1. What was wired
2. Which identities were used
3. Which test case/result was observed
4. What evidence artifact was saved

---

## 2. Run Metadata

- Run ID:
- Date/Time (UTC):
- Environment:
- Copilot Studio Environment Name:
- Agent Export Version (before):
- Agent Export Version (after):
- Operator:

---

## 3. Wiring Checklist Record

| Step ID | Topic | UI Node Added/Updated | Status (Pass/Fail/NA) | Notes |
|---|---|---|---|---|
| OW-01 | My Sites | Set Topic.CallerUPN from System.User.PrincipalName |  |  |
| OW-02 | My Sites | SharePoint Get items with owner filter |  |  |
| OW-03 | My Sites | Site-list adaptive card binding |  |  |
| OW-04 | Sites Needing Attention | SharePoint Get items with NON-COMPLIANT owner filter |  |  |
| OW-05 | Sites Needing Attention | Action-priority ordering in-topic |  |  |
| OW-06 | Site Detail | Selected site context resolution (URL/title/item ID) |  |  |
| OW-07 | Site Detail | Triage reasoning mapping |  |  |
| OW-08 | Certify Site | Ownership validation query |  |  |
| OW-09 | Certify Site | GovernanceAgent-ActionCallback invocation payload mapping |  |  |
| OW-10 | Certify Site | Action Callback outcome verification (site update + audit row) |  |  |
| OW-11 | Request Archival | Ownership validation + archive request action-log write |  |  |
| OW-12 | Flag for Deletion | Exact confirmation token guard (CONFIRM) |  |  |
| OW-13 | Flag for Deletion | Delete-request action-log write |  |  |

---

## 4. Test Result Mapping

Map execution outcomes to checklist and requirements.

| Case ID | Requirement ID | Topic | Result | Evidence Ref | Notes |
|---|---|---|---|---|---|
| TC-01 | FR-OWN-04 | Certify Site |  |  |  |
| TC-02 | FR-OWN-04 | Certify Site |  |  |  |
| TC-03 | FR-OWN-04 | Certify Site |  |  |  |
| TC-04 | FR-OWN-04 | Certify Site |  |  |  |
| TC-05 | FR-OWN-04 | Certify Site |  |  |  |
| TC-06 | FR-OWN-06 | Flag for Deletion |  |  |  |
| TC-07 | FR-OWN-05 | Request Archival |  |  |  |

---

## 5. Evidence Inventory

Store screenshots and export snapshots in a dated folder, then record paths below.

- Chat screenshots folder:
- SharePoint list evidence folder:
- Export package snapshot folder:
- Notes file:

Artifact list:
1. 
2. 
3. 

---

## 6. Issues and Follow-Ups

| Issue ID | Severity | Topic | Description | Owner | Status |
|---|---|---|---|---|---|
|  |  |  |  |  |  |

---

## 7. Sign-Off

- Owner journey wiring complete: Yes/No
- Certify dry-run ready for pilot: Yes/No
- Re-export completed: Yes/No
- Matrix/Roadmap updated: Yes/No
- Reviewed by:
- Review date/time (UTC):
