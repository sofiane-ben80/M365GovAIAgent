# 15 – Action Design & Implementation Plan

> **Legacy action design:** Preserve confirmation and approval behavior, but
> replace SharePoint-list writes with Dataverse request/event records and
> solution-aware Power Automate processing. See
> [12-PowerAutomate-Build-Guide.md](12-PowerAutomate-Build-Guide.md).

**Document:** Complete action design and implementation roadmap  
**Solution:** M365 Governance AI Agent  
**Version:** 1.0  
**Date:** 2026-07-26  
**Status:** Ready for Implementation  
**Author:** Implementation Team

---

## Executive Summary

The agent infrastructure is deployed and topics are triggered, but they currently only notify users that the action was selected without performing any actual operations. This document comprehensively analyzes all actions required for the Owner and Admin personas, designs the execution logic with data model updates, and provides a prioritized implementation roadmap.

**Key Findings:**
- 7 core owner actions require SharePoint list updates + audit logging
- 4 core admin actions require tenant-wide views + role validation
- All actions delegate execution to 4 Power Automate flows: ActionCallback, ActionStatus, OwnerNotification, AdminDigest
- Implementation can be done incrementally; owner actions are higher priority (Sprints A-B)
- Admin actions and proactive notifications are Phase 2 (Sprints C-D)

---

## 1. Action Analysis by Role & Topic

### 1.1 Site Owner Actions

#### 1.1.1 **MySites** Topic
**Current State:** Scaffold that notifies user with placeholder message  
**Purpose:** List all sites where caller is an owner

**Input Variables:**
- `Topic.CallerUPN` — Logged-in user's principal name (auto-set)

**Actions to Implement:**
1. **Query Contoso Sites list** (SharePoint connector)
   - Filter: `substringof('@{Topic.CallerUPN}', SiteOwners)`
   - Select fields: Title, SiteURL, ComplianceStatus, ComplianceAction, LastActivityDate, LastCertificationDate, SiteOwnersCount
   - Order by: ComplianceStatus DESC, then Title ASC
   - Pagination: Top 10 items per page (implement paging variable)

2. **Transform results** into Adaptive Card
   - Show site title, URL, compliance status (COMPLIANT/NON-COMPLIANT), last activity date
   - Add action button "View Details" → SiteDetail topic
   - Add action buttons: "Certify", "Archive", "More Info" for quick action

3. **Render card** to user with paging controls

**Data Updates:** None (read-only)

**Audit Trail:** None

**Success Metrics:**
- User sees all owned sites
- Status badges clearly indicate which need attention
- User can click to view details or take quick action

**Edge Cases:**
- User owns no sites → Show helpful message "You don't own any sites."
- Query returns >10 sites → Implement Next/Previous paging
- User owns site but is marked as archived → Show clearly with warning badge

**Flow Diagram:**
```
MySites topic triggered
    ↓
Set Topic.CallerUPN = System.User.PrincipalName
    ↓
Query Contoso Sites WHERE SiteOwners CONTAINS caller
    ↓
Transform to Adaptive Card with site list + action buttons
    ↓
Render card with "View Details", "Certify", "Archive" actions
    ↓
Listen for user selection
```

---

#### 1.1.2 **SitesNeedingAttention** Topic
**Current State:** Scaffold  
**Purpose:** Show only non-compliant sites owned by caller

**Input Variables:**
- `Topic.CallerUPN` — Logged-in user
- `Topic.FilterAction` (optional) — Filter by specific action type (CERTIFY, ARCHIVE, DELETE-REQUESTED, ASSIGN-OWNERS)

**Actions to Implement:**
1. **Query Contoso Sites list** with multi-condition filter
   - Filter: `substringof('@{Topic.CallerUPN}', SiteOwners) AND ComplianceStatus eq 'NON-COMPLIANT'`
   - If FilterAction is set: add `AND ComplianceAction eq '@{Topic.FilterAction}'`
   - Order by: ComplianceAction (CERTIFY first, then ARCHIVE, then DELETE, then ASSIGN-OWNERS), then LastActionDate DESC

2. **Categorize by recommended action:**
   - Section 1: CERTIFY NEEDED (overdue recertification) — "These sites need owner certification"
   - Section 2: ARCHIVE CANDIDATES (stale content) — "These sites might be ready to archive"
   - Section 3: DELETE REVIEW (very old) — "These sites may be candidates for deletion"
   - Section 4: OWNER ISSUES (no/missing owners) — "Ownership needs attention"

3. **Render categorized Adaptive Card**
   - Show count per category
   - List sites under each category with action buttons specific to the category

4. **Show filter options** — User can ask "show me only sites needing certification"

**Data Updates:** None (read-only)

**Audit Trail:** None

**Success Metrics:**
- User immediately sees only their at-risk sites
- Clear categorization by action type
- Understands why each site is flagged

**Flow Diagram:**
```
SitesNeedingAttention topic triggered
    ↓
Set Topic.CallerUPN = System.User.PrincipalName
    ↓
Query Contoso Sites WHERE SiteOwners CONTAINS caller AND ComplianceStatus = NON-COMPLIANT
    ↓
Transform to Adaptive Card categorized by ComplianceAction
    ↓
Render card with filtered list + filter dialog options
    ↓
Listen for action selection (Certify, Archive, Delete, AssignOwner)
```

---

#### 1.1.3 **SiteDetail** Topic
**Current State:** Scaffold with placeholder reasoning fields  
**Purpose:** Show full details of a selected site including triage explanation

**Input Variables:**
- `Topic.SelectedSiteUrl` — URL of the site to detail
- `Topic.SelectedSiteItemId` — SPO list item ID (from previous topic selection)
- `Topic.CallerUPN` — Logged-in user

**Actions to Implement:**
1. **Load full site record** from Contoso Sites
   - Use SelectedSiteItemId if available, else query by URL
   - Fetch all fields: Title, SiteURL, ComplianceStatus, ComplianceAction, LastActivityDate, LastCertificationDate, SiteOwnersCount, OwnersStr, Office, SubOffice, SiteType, AttestationStatus, AttestationExpiresAt, LastActionType, LastActionDate, LastActionBy

2. **Invoke Triage sub-agent** (or local logic) to generate explanation
   - Input: Site record
   - Output: Plain-language explanation of why this site is flagged (if non-compliant)
   - Example: "This site hasn't been certified in 18 months. Per policy, recertification is required annually. Click 'Certify' below to confirm this site is still needed."

3. **Render detailed Adaptive Card**
   - Header: Site title + status (COMPLIANT/NON-COMPLIANT)
   - Facts: URL, Last Activity, Certification Date, Owners, Site Type, Office
   - Triage Reasoning section (color-coded by action type)
   - Action buttons: "Certify", "Request Archive", "Flag for Deletion", "View Owner List" (owner context)
   - Admin-only buttons (if caller is admin): "Reassign Owners", "Mark Reviewed", "Force Archive"

4. **Listen for action selection** → Route to ActionCertify, ActionArchive, ActionDelete, etc.

**Data Updates:** None (read-only, but may update via action buttons)

**Audit Trail:** None (may be written by downstream actions)

**Success Metrics:**
- User sees full context for why site is flagged
- User understands recommended action
- Clear call-to-action buttons for next step

**Flow Diagram:**
```
SiteDetail topic triggered (from MySites or SitesNeedingAttention)
    ↓
Load full site record from Contoso Sites using SelectedSiteItemId
    ↓
Invoke Triage logic to generate plain-language explanation
    ↓
Render Adaptive Card with:
  - Site facts (Title, URL, Owners, Last Activity, etc.)
  - Triage reasoning (why it's flagged)
  - Action buttons (Certify, Archive, Delete, etc.)
    ↓
Listen for user action selection
```

---

#### 1.1.4 **CertifySite** Topic (Action)
**Current State:** Scaffold with setup but no execution  
**Purpose:** Confirm owner intent and execute site certification

**Input Variables:**
- `Topic.SelectedSiteUrl` — Full URL of site
- `Topic.SelectedSiteTitle` — Display name
- `Topic.SelectedSiteItemId` — List item ID
- `Topic.CallerUPN` — Site owner
- `Topic.SelectedSiteOwnersStr` (optional) — Current owners for display

**Actions to Implement:**

**Step 0 - Confirm Site URL** (if not provided)
```
IF Topic.SelectedSiteUrl is blank:
  → Ask user: "Which site would you like to certify? Please give me the site name or URL."
  → Store answer in Topic.SelectedSiteUrl
  → Continue to Step 1b (resolve item ID)
```

**Step 1a - Verify Ownership** (security check)
```
Query Contoso Sites:
  - Filter: SiteURL eq '@{Topic.SelectedSiteUrl}' AND 
            substringof('@{Topic.CallerUPN}', SiteOwners)
  - Top: 1

IF result.Count > 0:
  → Set Topic.SelectedSiteItemId = result[0].ID
  → Set Topic.SiteOwnersStr = result[0].OwnersStr
  → Continue to Step 2 (confirmation card)
ELSE:
  → Send message: "You are not listed as an owner of this site. 
    Only owners can certify. Please check the URL and try again."
  → End topic
```

**Step 1b - Resolve Item ID** (if URL was typed)
```
Query Contoso Sites:
  - Filter: SiteURL eq '@{Topic.SelectedSiteUrl}'
  - Top: 1

IF result.Count > 0:
  → Set Topic.SelectedSiteItemId = result[0].ID
  → Set Topic.SelectedSiteTitle = result[0].Title
  → Continue to Step 1a (ownership check)
ELSE:
  → Send message: "I couldn't find that site URL in the governance list.
    Please check the URL and try again, or select from 'My Sites'."
  → End topic
```

**Step 2 - Confirmation Adaptive Card**
```json
{
  "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
  "type": "AdaptiveCard",
  "version": "1.4",
  "body": [
    {
      "type": "Container",
      "style": "emphasis",
      "items": [
        {
          "type": "TextBlock",
          "text": "Confirm Site Certification",
          "weight": "Bolder",
          "size": "Large"
        }
      ]
    },
    {
      "type": "TextBlock",
      "text": "By certifying this site, you confirm that:",
      "wrap": true,
      "spacing": "Medium"
    },
    {
      "type": "BulletList",
      "items": [
        {
          "text": "The site is still needed and actively used"
        },
        {
          "text": "The ownership information is accurate"
        },
        {
          "text": "The content complies with information policies"
        }
      ]
    },
    {
      "type": "FactSet",
      "facts": [
        { "title": "Site", "value": "${Topic.SelectedSiteTitle}" },
        { "title": "URL", "value": "${Topic.SelectedSiteUrl}" },
        { "title": "Current Owners", "value": "${Topic.SiteOwnersStr}" },
        { "title": "Last Certification", "value": "${Topic.LastCertificationDate}" },
        { "title": "Certification Date", "value": "Today (${utcNow()})" }
      ]
    }
  ],
  "actions": [
    {
      "type": "Action.Submit",
      "title": "✓ Yes, Certify This Site",
      "style": "positive",
      "data": { "intent": "confirmCertify" }
    },
    {
      "type": "Action.Submit",
      "title": "✗ Cancel",
      "data": { "intent": "cancelCertify" }
    }
  ]
}
```

**IF user cancels:** Send "No problem — no changes were made." → End topic

**Step 3 - Execute Certification via ActionCallback Flow**
```powershell
Run flow: GovernanceAgent-ActionCallback
Inputs:
  - callerUPN = Topic.CallerUPN
  - actionType = "CERTIFY"
  - siteUrl = Topic.SelectedSiteUrl
  - siteTitle = Topic.SelectedSiteTitle
  - siteItemId = Topic.SelectedSiteItemId

Wait for outputs:
  - success (boolean)
  - actionStatus (COMPLETED | FAILED)
  - message (string)
```

**Step 4 - Handle Flow Response**
```
IF success == true AND actionStatus == "COMPLETED":
  → Send Adaptive Card (success):
    - ✓ Certification completed
    - Site: [Title]
    - Certified by: [UPN]
    - Certification date: [today]
    - Next review: 365 days from today
    - Status updated to: COMPLIANT
  → End topic

ELSE IF success == false OR actionStatus == "FAILED":
  → Send error message with details from flow output
  → End topic
```

**Data Updates by ActionCallback Flow:**
- Update Contoso Sites item:
  - `LastCertificationDate` = utcNow()
  - `ComplianceStatus` = "COMPLIANT"
  - `ComplianceAction` = "NONE"
  - `LastActionDate` = utcNow()
  - `LastActionType` = "CERTIFY"
  - `LastActionBy` = callerUPN
  - `AttestationStatus` = "ATTESTED"
  - `AttestedAt` = utcNow()
  - `AttestedBy` = callerUPN
  - `AttestationSource` = "AGENT"
  - `AttestationExpiresAt` = addDays(utcNow(), 365)

- Write to Governance Action Log:
  - `Title` = "[Title] - Certified"
  - `SiteURL` = siteUrl
  - `SiteTitle` = siteTitle
  - `ActionType` = "CERTIFY"
  - `RequestedBy` = callerUPN
  - `RequestedAt` = utcNow()
  - `ActionStatus` = "COMPLETED"
  - `AdminApprover` = ""
  - `ApprovedAt` = ""
  - `Notes` = "Certified by owner via Copilot agent"

**Flow Diagram:**
```
CertifySite topic triggered
    ↓
[Step 0] Confirm URL (if needed)
    ↓
[Step 1a] Verify ownership + resolve Item ID
    ↓
[Step 2] Render confirmation card
    ↓
[Step 3] Call ActionCallback flow with CERTIFY action
    ↓
[Step 4] Display success/error card
    ↓
End topic
```

**Success Metrics:**
- List item updated with certification timestamp
- Compliance status changes to COMPLIANT
- Audit log entry written
- User sees confirmation with next review date

---

#### 1.1.5 **RequestArchival** Topic (Action)
**Current State:** Scaffold  
**Purpose:** Request site archival (owner-initiated, may require admin approval)

**Input Variables:**
- `Topic.SelectedSiteUrl` — Site URL
- `Topic.SelectedSiteTitle` — Site title
- `Topic.SelectedSiteItemId` — List item ID
- `Topic.CallerUPN` — Requesting owner
- `Topic.ArchivalReason` (optional) — Why owner wants to archive

**Actions to Implement:**

**Step 0 - Verify Ownership**
```
Query Contoso Sites:
  - Filter: SiteURL eq '@{Topic.SelectedSiteUrl}' AND 
            substringof('@{Topic.CallerUPN}', SiteOwners)

IF not found:
  → Send: "You are not an owner of this site. Only owners can request archival."
  → End topic
ELSE:
  → Continue to Step 1
```

**Step 1 - Get Archival Reason (optional)**
```
IF Topic.ArchivalReason is blank:
  Ask user: "Why would you like to archive this site? 
    (Optional: e.g., 'Project completed', 'Content moved', 'No longer needed')"
  Store in Topic.ArchivalReason
```

**Step 2 - Confirmation Card**
```json
{
  "type": "AdaptiveCard",
  "body": [
    {
      "type": "TextBlock",
      "text": "Request Archive",
      "weight": "Bolder",
      "size": "Large"
    },
    {
      "type": "TextBlock",
      "text": "You are requesting archival of this site. After archival:",
      "wrap": true
    },
    {
      "type": "BulletList",
      "items": [
        { "text": "The site will be moved to archive storage" },
        { "text": "Users will lose write access" },
        { "text": "Read access may still be available for compliance" },
        { "text": "Site retention policy applies" }
      ]
    },
    {
      "type": "FactSet",
      "facts": [
        { "title": "Site", "value": "${Topic.SelectedSiteTitle}" },
        { "title": "Reason", "value": "${Topic.ArchivalReason or '(not provided)'}" }
      ]
    }
  ],
  "actions": [
    {
      "type": "Action.Submit",
      "title": "✓ Request Archive",
      "style": "positive",
      "data": { "intent": "confirmArchive" }
    },
    {
      "type": "Action.Submit",
      "title": "✗ Cancel",
      "data": { "intent": "cancelArchive" }
    }
  ]
}
```

**Step 3 - Execute via ActionCallback**
```
Run flow: GovernanceAgent-ActionCallback
Inputs:
  - callerUPN = Topic.CallerUPN
  - actionType = "ARCHIVE"
  - siteUrl = Topic.SelectedSiteUrl
  - siteTitle = Topic.SelectedSiteTitle
  - siteItemId = Topic.SelectedSiteItemId
```

**Step 4 - Display Status**
```
IF success:
  → Send card: "✓ Archive request submitted"
    - Status: PENDING (awaiting admin review/execution)
    - Site: [Title]
    - Reason: [ArchivalReason]
    - Next: Admin will review and proceed with archival

ELSE:
  → Send error card
```

**Data Updates by ActionCallback:**
- Update Contoso Sites:
  - `ComplianceAction` = "ARCHIVE-INITIATED"
  - `LastActionDate` = utcNow()
  - `LastActionType` = "ARCHIVE"
  - `LastActionBy` = callerUPN

- Write Governance Action Log:
  - `ActionType` = "ARCHIVE-INITIATED"
  - `RequestedBy` = callerUPN
  - `RequestedAt` = utcNow()
  - `ActionStatus` = "PENDING"
  - `Notes` = Topic.ArchivalReason or "Archive requested by owner"

---

#### 1.1.6 **FlagForDeletion** Topic (Action)
**Current State:** Scaffold  
**Purpose:** Request site deletion review (high-risk action requiring explicit confirmation)

**Input Variables:**
- `Topic.SelectedSiteUrl`
- `Topic.SelectedSiteTitle`
- `Topic.SelectedSiteItemId`
- `Topic.CallerUPN`
- `Topic.ConfirmationToken` — Must be exact phrase "DELETE" to proceed

**Actions to Implement:**

**Step 0 - Ownership Check**
```
Query Contoso Sites with ownership filter
IF not found:
  → Send: "You are not an owner of this site."
  → End topic
```

**Step 1 - Warn User**
```
Send message with strong warning:
"⚠️ WARNING: You are about to request DELETION of this site.

This is a HIGH-RISK action. Once deleted:
- Content is PERMANENTLY REMOVED
- Users lose all access
- Data recovery may not be possible

To proceed, you must type exactly: DELETE

Please confirm by typing the word: DELETE"
```

**Step 2 - Get Confirmation Token**
```
Listen for user response
IF response != "DELETE":
  → Send: "Confirmation aborted. 
    Please type 'DELETE' exactly to confirm, or say 'cancel' to stop."
  → Listen again
```

**Step 3 - Final Confirmation Card (after user types DELETE)**
```json
{
  "type": "AdaptiveCard",
  "style": "emphasis",
  "body": [
    {
      "type": "TextBlock",
      "text": "⚠️ FINAL CONFIRMATION: Delete Site?",
      "weight": "Bolder",
      "size": "Large",
      "color": "warning"
    },
    {
      "type": "TextBlock",
      "text": "You have confirmed your intent to DELETE this site. This action:",
      "wrap": true,
      "spacing": "Medium"
    },
    {
      "type": "BulletList",
      "items": [
        { "text": "PERMANENTLY removes all content" },
        { "text": "CANNOT be undone" },
        { "text": "Requires admin approval before execution" },
        { "text": "Will be logged for audit purposes" }
      ]
    },
    {
      "type": "FactSet",
      "facts": [
        { "title": "Site", "value": "${Topic.SelectedSiteTitle}" },
        { "title": "URL", "value": "${Topic.SelectedSiteUrl}" },
        { "title": "Requested by", "value": "${Topic.CallerUPN}" },
        { "title": "Timestamp", "value": "${utcNow()}" }
      ]
    }
  ],
  "actions": [
    {
      "type": "Action.Submit",
      "title": "⚠️ Yes, Request Deletion",
      "style": "destructive",
      "data": { "intent": "confirmDelete" }
    },
    {
      "type": "Action.Submit",
      "title": "✗ Cancel",
      "data": { "intent": "cancelDelete" }
    }
  ]
}
```

**IF cancel:** End topic, no changes

**Step 4 - Execute via ActionCallback**
```
Run flow: GovernanceAgent-ActionCallback
Inputs:
  - callerUPN = Topic.CallerUPN
  - actionType = "DELETE-REQUESTED"
  - siteUrl = Topic.SelectedSiteUrl
  - siteTitle = Topic.SelectedSiteTitle
  - siteItemId = Topic.SelectedSiteItemId
  - confirmationText = "DELETE"
```

**Step 5 - Display Escalation Message**
```
Send card:
"✓ Deletion request submitted for admin review

Site: [Title]
Requested by: [UPN]
Status: PENDING - requires admin approval

An admin will review this request and execute deletion if approved.
You will be notified of the outcome."
```

**Data Updates by ActionCallback:**
- Update Contoso Sites:
  - `ComplianceAction` = "DELETE-REQUESTED"
  - `LastActionDate` = utcNow()
  - `LastActionType` = "DELETE"
  - `LastActionBy` = callerUPN

- Write Governance Action Log:
  - `ActionType` = "DELETE-REQUESTED"
  - `RequestedBy` = callerUPN
  - `RequestedAt` = utcNow()
  - `ActionStatus` = "PENDING"
  - `Notes` = "Deletion requested by owner, pending admin approval"

---

### 1.2 Admin Actions

#### 1.2.1 **AdminDashboard** Topic
**Current State:** Scaffold  
**Purpose:** Show tenant-wide governance summary for admins

**Input Variables:**
- `Topic.CallerUPN` — Admin user (pre-checked by CheckAdminRole flow)
- `Topic.FilterOffice` (optional) — Filter by office code

**Actions to Implement:**

**Step 1 - Verify Admin Role** (if not already checked by launcher)
```
Invoke CheckAdminRole flow
IF not admin:
  → Send: "Only tenant admins can access this view."
  → Route to Owner Agent
  → End topic
ELSE:
  → Continue
```

**Step 2 - Query Aggregate Counts**
```
Query Contoso Sites with grouping/counting:
  - Count by ComplianceStatus: { COMPLIANT, NON-COMPLIANT }
  - Count by ComplianceAction: { NONE, CERTIFY, ARCHIVE, DELETE-REQUESTED, ASSIGN-OWNERS }
  - Count of sites with orphaned owners (SiteOwners is empty)
  - Count of sites with not-attested status (AttestationStatus != ATTESTED)
```

**Step 3 - Render Dashboard Card**
```
Dashboard layout:
  
  SUMMARY SECTION:
  ┌─────────────────────────────┐
  │ Total Sites:          [count]│
  │ Compliant:            [count]│
  │ Non-Compliant:        [count]│
  │ Orphaned (no owners): [count]│
  │ Not Attested:         [count]│
  └─────────────────────────────┘

  BY ACTION NEEDED:
  ┌──────────────────────────────────┐
  │ Need Recertification:      [count]│
  │ Archive Candidates:        [count]│
  │ Delete Review:             [count]│
  │ Ownership Issues:          [count]│
  └──────────────────────────────────┘

  QUICK ACTIONS:
  [View Orphaned Sites] [View Non-Compliant] [View Attestation Status]
  [Generate Weekly Report] [Manual Rescan]
```

**Step 4 - Listen for Admin Action**
```
IF admin clicks "View Orphaned Sites":
  → Invoke OrphanedSites topic
ELSE IF admin clicks "View Non-Compliant":
  → Invoke NotAttestedSites topic
ELSE IF admin clicks "Generate Weekly Report":
  → Trigger Admin Digest flow
ELSE IF admin clicks "Manual Rescan":
  → Run Invoke-GovernanceScan.ps1 (if available)
```

**Data Updates:** None (read-only)

**Audit Trail:** None

---

#### 1.2.2 **OrphanedSites** Topic
**Current State:** Scaffold  
**Purpose:** Show sites with no owners for admin review

**Input Variables:**
- `Topic.CallerUPN` — Admin user
- `Topic.FilterOffice` (optional)

**Actions to Implement:**

**Step 1 - Admin Check** (as above)

**Step 2 - Query Orphaned Sites**
```
Query Contoso Sites:
  - Filter: SiteOwners IS EMPTY OR SiteOwnersCount <= 0
  - Filter: ComplianceStatus = 'NON-COMPLIANT' AND ComplianceAction = 'ASSIGN-OWNERS'
  - Order by: CreatedDate DESC (newest first, or LastActivityDate DESC)
  - Top: 20 (with pagination)
```

**Step 3 - Render Orphaned Sites Card**
```
Card shows:
  - Total orphaned count
  - List with fields: Title, SiteURL, Created Date, Last Activity, Site Type, Office
  - Action button per site: "Assign Owner", "Archive", "More Details"
```

**Step 4 - Listen for Admin Action**
- "Assign Owner" → ActionAssignOwners topic
- "Archive" → ActionArchive topic
- "More Details" → SiteDetail topic

---

#### 1.2.3 **NotAttestedSites** Topic
**Current State:** Scaffold  
**Purpose:** Show sites with missing or expired attestation

**Input Variables:**
- `Topic.CallerUPN` — Admin user
- `Topic.FilterStatus` (optional) — Filter by AttestationStatus (NOT-ATTESTED, EXPIRED, UNKNOWN)

**Actions to Implement:**

**Step 1 - Admin Check**

**Step 2 - Query Not-Attested Sites**
```
Query Contoso Sites:
  - Filter: AttestationStatus IN ('NOT-ATTESTED', 'EXPIRED', 'UNKNOWN')
  - Order by: AttestationExpiresAt ASC (soonest expiry first)
  - Top: 20 (with pagination)
```

**Step 3 - Render Card**
```
Card shows:
  - Total not-attested count by status
  - List with fields: Title, Status, Attested At, Expires At, Attested By
  - Action button per site: "Review", "Mark Compliant", "Certify", "Archive"
```

---

#### 1.2.4 **ActionAssignOwners** Topic (Admin)
**Current State:** Scaffold  
**Purpose:** Assign owner to orphaned or under-owned sites

**Input Variables:**
- `Topic.SelectedSiteUrl`
- `Topic.SelectedSiteTitle`
- `Topic.SelectedSiteItemId`
- `Topic.CallerUPN` — Admin performing action
- `Topic.TargetOwnerUPN` — UPN of new owner to assign

**Actions to Implement:**

**Step 1 - Verify Admin Role**
```
Invoke CheckAdminRole flow
IF not admin:
  → End topic with "Admin role required"
```

**Step 2 - Get Target Owner UPN** (if not provided)
```
IF Topic.TargetOwnerUPN is blank:
  Ask: "What is the UPN of the user to assign as owner? 
         (e.g., user@contoso.com)"
  Store answer in Topic.TargetOwnerUPN
```

**Step 3 - Verify Target User Exists** (optional Graph call or manual verification)
```
(Use Microsoft Graph to verify user exists)
IF user not found:
  → Send: "User not found. Please check the UPN and try again."
  → Loop back to Step 2
```

**Step 4 - Confirmation Card**
```json
{
  "type": "AdaptiveCard",
  "body": [
    {
      "type": "TextBlock",
      "text": "Assign Owner to Site",
      "weight": "Bolder"
    },
    {
      "type": "TextBlock",
      "text": "You are assigning a new owner to this site:",
      "wrap": true
    },
    {
      "type": "FactSet",
      "facts": [
        { "title": "Site", "value": "${Topic.SelectedSiteTitle}" },
        { "title": "New Owner", "value": "${Topic.TargetOwnerUPN}" },
        { "title": "Admin", "value": "${Topic.CallerUPN}" }
      ]
    }
  ],
  "actions": [
    {
      "type": "Action.Submit",
      "title": "✓ Assign",
      "style": "positive",
      "data": { "intent": "confirmAssign" }
    },
    {
      "type": "Action.Submit",
      "title": "✗ Cancel",
      "data": { "intent": "cancelAssign" }
    }
  ]
}
```

**Step 5 - Execute via ActionCallback**
```
Run flow: GovernanceAgent-ActionCallback
Inputs:
  - callerUPN = Topic.CallerUPN
  - actionType = "ASSIGN-OWNERS"
  - siteUrl = Topic.SelectedSiteUrl
  - siteTitle = Topic.SelectedSiteTitle
  - siteItemId = Topic.SelectedSiteItemId
  - targetOwnerUPN = Topic.TargetOwnerUPN
```

**Step 6 - Display Success**
```
Send card:
"✓ Owner assigned successfully

Site: [Title]
New Owner: [TargetOwnerUPN]
Assigned by: [Admin UPN]
Timestamp: [utcNow()]"
```

**Data Updates by ActionCallback:**
- Update Contoso Sites:
  - `SiteOwners` = append targetOwnerUPN (or replace if was empty)
  - `SiteOwnersCount` = recalculate
  - `ComplianceAction` = "NONE" (if ownership was the issue)
  - `ComplianceStatus` = "COMPLIANT" (if this resolves the issue)
  - `LastActionDate` = utcNow()
  - `LastActionType` = "ASSIGN-OWNERS"
  - `LastActionBy` = callerUPN

- Write Governance Action Log:
  - `ActionType` = "ASSIGN-OWNERS"
  - `RequestedBy` = callerUPN
  - `RequestedAt` = utcNow()
  - `ActionStatus` = "COMPLETED"
  - `Notes` = "Owner assigned: [TargetOwnerUPN]"

---

### 1.3 Shared Action Topics (Used by both Owner and Admin)

#### 1.3.1 **ActionStatus** Topic
**Current State:** Scaffold  
**Purpose:** Show status of pending actions (archive requests, deletion requests, etc.)

**Input Variables:**
- `Topic.CallerUPN` — Caller (used for filtering if owner, not if admin)
- `Topic.IsAdmin` — Boolean, true if caller is admin

**Actions to Implement:**

**Step 1 - Query Governance Action Log**
```
Query Governance Action Log:
  IF IsAdmin == true:
    Filter: None (show all pending actions)
    Order by: RequestedAt DESC
  ELSE (owner context):
    Filter: RequestedBy eq '@{Topic.CallerUPN}'
    Order by: RequestedAt DESC

  Where: ActionStatus IN ('PENDING', 'IN-PROGRESS')
  Top: 10 (with pagination)
```

**Step 2 - Render Status Card**
```
Card shows:
  - Table of pending actions
  - Columns: Site, Action Type, Requested On, Status, Admin Notes
  - If admin: Show "Approve", "Reject", "Mark Complete" buttons
  - If owner: Show "View Details", "Cancel Request" (if appropriate)
```

**Step 3 - Listen for Action**
- Admin clicks "Approve" → Update action log, trigger execution
- Admin clicks "Reject" → Update action log, notify requester
- Owner clicks "Cancel Request" → Ask confirmation, mark cancelled

---

## 2. Implementation Approach

### 2.1 Topic Implementation Strategy

Each topic follows this pattern:

1. **Query Phase** — Use SharePoint connector to get data
2. **Transform Phase** — Convert raw data to Adaptive Cards
3. **Interaction Phase** — Listen for user button clicks / voice input
4. **Action Phase** — Execute action (either call flow or route to next topic)
5. **Confirmation Phase** — Show result/error card

**Estimated Effort per Topic:**
- Read-only query topics (MySites, SitesNeedingAttention, AdminDashboard): 4-6 hours each (query + card design + paging)
- Action topics with confirmation (CertifySite, RequestArchival): 6-8 hours each (ownership check + confirmation card + flow invocation + error handling)
- High-risk action topics (FlagForDeletion): 8-10 hours (confirmation flow + token verification)

---

### 2.2 Data Model Updates Required

All updates are handled by the ActionCallback flow, which must be fully implemented in Power Automate:

**Contoso Sites list updates:**
- LastCertificationDate (CERTIFY)
- ComplianceStatus (all actions)
- ComplianceAction (all actions)
- LastActionDate (all actions)
- LastActionType (all actions)
- LastActionBy (all actions)
- AttestationStatus (all actions)
- AttestedAt (CERTIFY)
- AttestedBy (CERTIFY)
- AttestationSource (CERTIFY)
- AttestationExpiresAt (CERTIFY)
- SiteOwners / SiteOwnersCount (ASSIGN-OWNERS)

**Governance Action Log writes:**
- All actions must write an audit entry
- Required fields: SiteURL, SiteTitle, ActionType, RequestedBy, RequestedAt, ActionStatus, Notes
- Optional fields: AdminApprover, ApprovedAt, PreviousComplianceStatus, PreviousComplianceAction

---

### 2.3 Flow Implementation Requirements

**Flows that are complete but need wiring:**
1. **GovernanceAgent-ActionCallback** — Already deployed, needs flow logic completion
   - Implement CERTIFY, ARCHIVE, DELETE-REQUESTED, ASSIGN-OWNERS branching
   - Implement SharePoint Update/Create actions
   - Error handling and validation

**Flows that need to be built:**
1. **GovernanceAgent-OwnerNotification** — Weekly owner digest
2. **GovernanceAgent-AdminDigest** — Weekly admin summary
3. **GovernanceAgent-AdaptiveCardResponse** — Handle inline card actions

---

## 3. Implementation Roadmap

### **Sprint A: Owner Core Journey (Weeks 1-2)**

**Goal:** Enable owners to view sites and certify

**Tasks:**
1. Implement MySites topic
   - SharePoint query by SiteOwners filter
   - Adaptive Card rendering
   - Paging controls
2. Implement SiteDetail topic
   - Load full site record
   - Show compliance status and triage reasoning
   - Add action buttons (Certify, Archive, Delete)
3. Implement CertifySite topic
   - Ownership verification
   - Confirmation card
   - ActionCallback invocation
   - Success/error handling
4. Complete ActionCallback flow in Power Automate
   - CERTIFY branch logic
   - SharePoint Update + Governance Action Log Create
   - Error handling

**Deliverables:**
- Owner can ask "show my sites"
- Owner can click "Certify"
- Certification updates list and shows success card
- Audit log entry created

**Success Metrics:**
- Sites returned in <2 seconds
- Certification updates propagate within 30 seconds
- No errors or missing list updates

---

### **Sprint B: Archive & Delete (Weeks 3-4)**

**Goal:** Enable owners to request archival and deletion

**Tasks:**
1. Implement SitesNeedingAttention topic
   - Filter by ComplianceStatus = NON-COMPLIANT
   - Categorize by recommended action
   - Show count per category
2. Implement RequestArchival topic
   - Ownership check
   - Archival reason capture
   - ActionCallback invocation (ARCHIVE)
3. Implement FlagForDeletion topic
   - Strong warnings
   - Confirmation token (must type "DELETE")
   - Final confirmation card
   - ActionCallback invocation (DELETE-REQUESTED)
4. Complete ActionCallback flow
   - ARCHIVE branch logic
   - DELETE-REQUESTED branch logic

**Deliverables:**
- Owner sees only their at-risk sites
- Owner can request archival
- Owner can request deletion with confirmation
- Action log tracks all requests

---

### **Sprint C: Admin Dashboard (Weeks 5-6)**

**Goal:** Enable admins to see tenant-wide view and manage at-risk sites

**Tasks:**
1. Implement AdminDashboard topic
   - Aggregate counts by status
   - Quick link cards to views
2. Implement OrphanedSites topic
   - Query sites with no owners
   - Assign Owner action link
3. Implement NotAttestedSites topic
   - Query by AttestationStatus
   - Filter options
4. Implement ActionAssignOwners topic
   - Target owner UPN capture
   - Confirmation
   - ActionCallback invocation (ASSIGN-OWNERS)
5. Complete ActionCallback flow
   - ASSIGN-OWNERS branch logic
   - Owner count recalculation

**Deliverables:**
- Admin can ask "admin dashboard"
- Admin sees all sites needing attention
- Admin can assign owner to orphaned sites
- All admin actions logged

---

### **Sprint D: Proactive Notifications (Weeks 7-8)**

**Goal:** Automated weekly notifications for owners and admins

**Tasks:**
1. Implement OwnerNotification flow
   - Weekly scheduled trigger
   - Query sites needing attention per owner
   - Personalized Teams message with Adaptive Card
   - Action buttons (Certify, Archive, Dismiss)
2. Implement AdminDigest flow
   - Weekly scheduled trigger
   - Aggregate counts and summaries
   - Orphaned sites list
   - Action buttons
3. Implement AdaptiveCardResponse flow
   - Handle button clicks from proactive messages
   - Update DisableNotifyUntil if "Dismiss" clicked
   - Log response action
4. Configure schedules in Power Automate
   - Owner notification: Weekly on Monday 9 AM
   - Admin digest: Weekly on Monday 8 AM

**Deliverables:**
- Owners receive weekly personalized summary
- Admins receive weekly tenant summary
- Card action buttons trigger flows
- Responses logged and tracked

---

## 4. Power Automate Flow Specifications

### 4.1 ActionCallback Flow (Core Execution Engine)

**Status:** Deployed, needs internal logic completion

**Trigger:** HTTP request from Copilot Studio topics

**Input Schema:**
```json
{
  "callerUPN": "string",
  "actionType": "string (CERTIFY|ARCHIVE|DELETE-REQUESTED|ASSIGN-OWNERS)",
  "siteUrl": "string",
  "siteTitle": "string",
  "siteItemId": "integer",
  "targetOwnerUPN": "string (required for ASSIGN-OWNERS)",
  "confirmationText": "string (required for DELETE-REQUESTED, value must be 'DELETE')"
}
```

**Output Schema:**
```json
{
  "success": "boolean",
  "actionStatus": "string (COMPLETED|PENDING|REJECTED|FAILED)",
  "actionType": "string",
  "siteUrl": "string",
  "message": "string"
}
```

**Steps to Implement:**

1. **Validate Input**
   - Confirm siteUrl and actionType present
   - For ASSIGN-OWNERS: require targetOwnerUPN
   - For DELETE-REQUESTED: require confirmationText = "DELETE"
   - If validation fails: return FAILED

2. **Get Current Item**
   - SharePoint: Get item from Contoso Sites using siteItemId
   - Preserve current values for audit reconciliation
   - If not found: return FAILED

3. **Branch by actionType**

   **CASE CERTIFY:**
   - Update Contoso Sites:
     ```
     LastCertificationDate: now()
     ComplianceStatus: "COMPLIANT"
     ComplianceAction: "NONE"
     LastActionDate: now()
     LastActionType: "CERTIFY"
     LastActionBy: callerUPN
     AttestationStatus: "ATTESTED"
     AttestedAt: now()
     AttestedBy: callerUPN
     AttestationSource: "AGENT"
     AttestationExpiresAt: addDays(now(), 365)
     ```
   - Create Governance Action Log:
     ```
     Title: "[SiteTitle] - Certified"
     SiteURL: siteUrl
     SiteTitle: siteTitle
     ActionType: "CERTIFY"
     RequestedBy: callerUPN
     RequestedAt: now()
     ActionStatus: "COMPLETED"
     Notes: "Certified by owner via Copilot agent"
     ```
   - Return: { success: true, actionStatus: "COMPLETED", message: "Site certification complete" }

   **CASE ARCHIVE:**
   - Update Contoso Sites:
     ```
     ComplianceAction: "ARCHIVE-INITIATED"
     LastActionDate: now()
     LastActionType: "ARCHIVE"
     LastActionBy: callerUPN
     ```
   - Create Governance Action Log:
     ```
     ActionType: "ARCHIVE-INITIATED"
     ActionStatus: "PENDING"
     Notes: "Archive request submitted by owner"
     ```
   - Return: { success: true, actionStatus: "PENDING", message: "Archive request submitted" }

   **CASE DELETE-REQUESTED:**
   - Validate: confirmationText = "DELETE"
   - Update Contoso Sites:
     ```
     ComplianceAction: "DELETE-REQUESTED"
     LastActionDate: now()
     LastActionType: "DELETE"
     LastActionBy: callerUPN
     ```
   - Create Governance Action Log:
     ```
     ActionType: "DELETE-REQUESTED"
     ActionStatus: "PENDING"
     Notes: "Deletion request submitted by owner, requires admin approval"
     ```
   - Return: { success: true, actionStatus: "PENDING", message: "Deletion request submitted for admin review" }

   **CASE ASSIGN-OWNERS:**
   - Update Contoso Sites:
     ```
     SiteOwners: append targetOwnerUPN (with semicolon separator)
     SiteOwnersCount: count items after append
     ComplianceAction: (depends on policy - could be "NONE" if min threshold met)
     ComplianceStatus: (recalculate based on other factors)
     LastActionDate: now()
     LastActionType: "ASSIGN-OWNERS"
     LastActionBy: callerUPN
     ```
   - Create Governance Action Log:
     ```
     ActionType: "ASSIGN-OWNERS"
     ActionStatus: "COMPLETED"
     Notes: "Owner assigned: [targetOwnerUPN]"
     ```
   - Return: { success: true, actionStatus: "COMPLETED", message: "Owner assigned successfully" }

4. **Error Handling**
   - Catch SharePoint errors → return FAILED with error message
   - Catch validation errors → return FAILED with specific message
   - Log all errors to flow run history

---

### 4.2 OwnerNotification Flow (Weekly Digest)

**Trigger:** Scheduled cloud flow (weekly, e.g., Monday 9 AM)

**Steps:**
1. Get all sites where ComplianceStatus = NON-COMPLIANT
2. Group by SiteOwners (split semicolon-separated list)
3. For each owner with at-risk sites:
   a. Filter their sites
   b. Categorize by recommended action
   c. Create personalized Adaptive Card
   d. Send Teams message to owner UPN
   e. Log notification sent
4. Track DisableNotifyUntil (skip if set and not expired)

**Card Actions:**
- "Certify This Site" → invoke CertifySite topic (pass context)
- "Request Archive" → invoke RequestArchival topic
- "Dismiss for 30 days" → update DisableNotifyUntil in list

---

### 4.3 AdminDigest Flow (Weekly Summary)

**Trigger:** Scheduled cloud flow (weekly, e.g., Monday 8 AM)

**Steps:**
1. Query aggregate counts:
   - Total sites / compliant / non-compliant
   - By action type (CERTIFY, ARCHIVE, DELETE-REQUESTED, ASSIGN-OWNERS)
   - Orphaned count
   - Not-attested count
2. Get top 10 orphaned sites for display
3. Create summary Adaptive Card
4. Send to Admin group via Teams

**Card Sections:**
- Summary tiles (total, compliant, non-compliant)
- Breakdown by action type
- Quick action links (View Orphaned, View Not-Attested)
- List of top orphaned sites with "Assign Owner" button

---

### 4.4 AdaptiveCardResponse Flow

**Trigger:** HTTP request from card action buttons (from proactive messages)

**Input:**
```json
{
  "ownerUPN": "string",
  "actionType": "string (DISMISS|CERTIFY|ARCHIVE)",
  "siteUrl": "string (if action is CERTIFY or ARCHIVE)"
}
```

**Steps:**
1. If actionType = "DISMISS":
   - Update Contoso Sites: DisableNotifyUntil = addDays(now(), 30)
   - Log action
   - Return success
2. If actionType = "CERTIFY" or "ARCHIVE":
   - Look up site item ID
   - Invoke ActionCallback with appropriate actionType
   - Log response action
   - Return result

---

## 5. Testing Strategy

### 5.1 Functional Testing (Per Sprint)

**Owner Actions Sprint A:**
- [ ] MySites returns correct sites for owner
- [ ] SiteDetail shows full record and triage reasoning
- [ ] CertifySite verifies ownership before updating
- [ ] Certification updates list (LastCertificationDate, ComplianceStatus, AttestationStatus)
- [ ] Audit log entry written with correct values

**Owner Actions Sprint B:**
- [ ] SitesNeedingAttention filters non-compliant only
- [ ] Sites categorized by action type
- [ ] Archive request updates ComplianceAction = ARCHIVE-INITIATED
- [ ] Delete request requires "DELETE" token
- [ ] Deletion request status = PENDING
- [ ] Audit log written with correct notes

**Admin Actions Sprint C:**
- [ ] AdminDashboard shows correct aggregate counts
- [ ] OrphanedSites returns sites with empty SiteOwners
- [ ] NotAttestedSites returns correct statuses
- [ ] Assign Owner updates SiteOwners field
- [ ] Owner count recalculated correctly

**Notifications Sprint D:**
- [ ] OwnerNotification sent to owners with at-risk sites
- [ ] AdminDigest sent to admin group
- [ ] Card action buttons invoke correct flows
- [ ] DisableNotifyUntil set and honored

### 5.2 Data Integrity Testing

- [ ] List item updates are atomic (all-or-nothing)
- [ ] Audit log entries complete and correctly formatted
- [ ] Timestamps accurate (using utcNow())
- [ ] No orphaned log entries (every update has corresponding log)
- [ ] No duplicate log entries

### 5.3 Security Testing

- [ ] Owners can only update their own sites
- [ ] Admins can see all sites
- [ ] Admin-only actions reject non-admin users
- [ ] Delete action requires explicit confirmation token
- [ ] All actions logged with requester identity

---

## 6. Success Criteria

### Owner Journey Success
- Owner asks "show my sites" → receives list in <2 seconds
- Owner clicks "Certify" → completes with updated status card in <5 seconds
- Owner can request archive and deletion with clear confirmations
- Audit log shows every action taken

### Admin Journey Success
- Admin asks "admin dashboard" → receives summary in <2 seconds
- Admin can see and manage orphaned sites
- Admin can assign owners to sites
- All admin actions logged with admin identity

### System Success
- All topics functioning without errors
- SharePoint list updates propagate within 30 seconds
- No data loss or corruption
- Weekly notifications delivered on schedule
- Response times <3 seconds for all queries
- Zero unhandled exceptions

---

## 7. Rollout Plan

### Phase 1: Internal Testing (Week 9)
- Deploy to test environment
- Run through all manual test cases
- Have stakeholders validate workflows

### Phase 2: Pilot Rollout (Week 10)
- Deploy to production
- Limited to internal pilot users (e.g., IT team + 10 site owners)
- Monitor error logs and user feedback
- Make adjustments as needed

### Phase 3: Full Rollout (Week 11)
- Announce to all site owners via email
- Provide training documentation
- Monitor adoption and adjust as needed

---

## Appendix A: Topic Status Summary

| Topic | Owner | Admin | Status | Sprint |
|-------|-------|-------|--------|--------|
| **Query Topics** | | | | |
| MySites | ✓ | | Scaffold → Sprint A | A |
| SitesNeedingAttention | ✓ | | Scaffold → Sprint A | A |
| AdminDashboard | | ✓ | Scaffold → Sprint C | C |
| OrphanedSites | | ✓ | Scaffold → Sprint C | C |
| NotAttestedSites | | ✓ | Scaffold → Sprint C | C |
| SiteDetail | ✓ | ✓ | Scaffold → Sprint A | A |
| **Action Topics** | | | | |
| CertifySite | ✓ | | Scaffold → Sprint A | A |
| RequestArchival | ✓ | | Scaffold → Sprint B | B |
| FlagForDeletion | ✓ | | Scaffold → Sprint B | B |
| ActionAssignOwners | | ✓ | Scaffold → Sprint C | C |
| ActionStatus | ✓ | ✓ | Scaffold → Sprint B | B |
| **Flows** | | | | |
| CheckAdminRole | ✓ | ✓ | **Complete** | Deploy |
| ActionCallback | ✓ | ✓ | Deployed, logic needed | A, B, C |
| OwnerNotification | ✓ | | Stub → Sprint D | D |
| AdminDigest | | ✓ | Stub → Sprint D | D |
| AdaptiveCardResponse | ✓ | ✓ | Stub → Sprint D | D |

---

## Appendix B: List Field Reference

**Contoso Sites - Fields Updated by Actions:**

| Field | CERTIFY | ARCHIVE | DELETE | ASSIGN-OWNERS |
|-------|---------|---------|--------|---------------|
| LastCertificationDate | ✓ | | | |
| ComplianceStatus | ✓ | | | ✓ |
| ComplianceAction | ✓ | ✓ | ✓ | ✓ |
| LastActionDate | ✓ | ✓ | ✓ | ✓ |
| LastActionType | ✓ | ✓ | ✓ | ✓ |
| LastActionBy | ✓ | ✓ | ✓ | ✓ |
| AttestationStatus | ✓ | | | |
| AttestedAt | ✓ | | | |
| AttestedBy | ✓ | | | |
| AttestationExpiresAt | ✓ | | | |
| SiteOwners | | | | ✓ |
| SiteOwnersCount | | | | ✓ |

**Governance Action Log - Always Written:**
- Title, SiteURL, SiteTitle, ActionType, RequestedBy, RequestedAt, ActionStatus, Notes

---

## Appendix C: Adaptive Card Templates

*(Full JSON definitions provided above in each topic section)*

Key reusable components:
- Success card (green checkmark, completed message)
- Error card (red X, error message with details)
- Confirmation card (facts + Action.Submit buttons)
- Warning card (yellow/orange, strong language)
- List card (table of items with action buttons)
- Summary card (counts/facts + quick action links)

---

## Next Steps

1. **Immediately (This Week):**
   - Review this plan with stakeholders
   - Identify any missing requirements or design changes
   - Confirm prioritization (Sprints A-D)

2. **Week 1 - Sprint A Kickoff:**
   - Create detailed Copilot Studio UI specifications for each topic
   - Wire MySites, SiteDetail, CertifySite topics
   - Complete ActionCallback flow logic for CERTIFY
   - Deploy and test

3. **Ongoing:**
   - Follow sprint roadmap
   - Test thoroughly before each sprint release
   - Gather user feedback and iterate

---

**Document Owner:** Implementation Team  
**Last Updated:** 2026-07-26  
**Status:** Ready for Execution
