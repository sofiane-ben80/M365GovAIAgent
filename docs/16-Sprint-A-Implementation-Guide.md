# Sprint A Implementation Guide: MySites, SiteDetail, CertifySite Topics

> **Legacy sprint guide:** Reuse conversational patterns only. Replace list item
> IDs and direct list actions with Dataverse GUIDs and the target Power Automate
> contracts.

**Document:** Detailed Copilot Studio UI wiring guide for Sprint A topics  
**Date:** 2026-07-26  
**Status:** Ready to implement  

---

## Overview

This guide shows how to implement the three core Sprint A topics in Copilot Studio's visual designer. Each topic has been scaffolded with the logic flow defined; this guide shows the UI wiring needed to connect SharePoint queries, conditions, and flow invocations.

**Topics to Wire:**
1. **MySites** (Governance Owner Agent)
2. **SiteDetail** (Governance Owner Agent)  
3. **CertifySite** (Governance Owner Agent)

**Key Resources Ready:**
- ✅ ActionCallback flow deployed and functional (all 4 action branches working)
- ✅ Topic YAML files updated with detailed logic
- ✅ SharePoint lists populated with real data (Contoso Sites, Governance Action Log)

---

## Part 1: MySites Topic Implementation

### 1.1 Topic Overview

**Trigger:** "show my sites", "my sites", "what sites do i own", etc.

**Flow:**
1. Get caller UPN
2. Query Contoso Sites WHERE SiteOwners CONTAINS caller UPN
3. Transform results to Adaptive Card
4. Render card with site list + action buttons
5. Listen for user selection (View Details, Certify, Archive)

### 1.2 Step-by-Step Copilot Studio UI Wiring

#### **Node 1: Trigger**
- Already set (OnRecognizedIntent with phrases)
- No action needed

#### **Node 2: Initialize Variables**
```
Variables to initialize (already in YAML):
- Topic.CallerUPN = System.User.PrincipalName
- Topic.PageNumber = "1"
- Topic.PageSize = "10"
- Topic.SitesJson = "[]"
```
Action: SendActivity("Loading your sites...")

#### **Node 3: Query Contoso Sites (NEW — requires UI wiring)**

**ACTION TYPE:** Power Apps connector → SharePoint → Get items

**Configuration:**
```
Site Address: https://mngenvmcap733570.sharepoint.com/sites/M365Governance
List: Contoso Sites (ID: 44dfbf52-8434-42d6-95c5-8ecf7614351d)

Filter Query (OData):
  substringof('@{Topic.CallerUPN}', SiteOwners)

Order By:
  ComplianceStatus desc, Title asc

Top Count: 10

Select Columns:
  - ID
  - Title
  - SiteURL
  - ComplianceStatus
  - ComplianceAction
  - LastActivityDate
  - LastCertificationDate
  - SiteOwnersCount
  - Office
  - OwnersStr
```

**Output Variable:** Topic.SitesJson = entire response

**Error Handling:** If query fails → SendActivity("Could not load your sites. Please try again.")

#### **Node 4: Check for Empty Results**

**CONDITION:** Check if Topic.SitesJson is empty or returns 0 items

```
IF count(Topic.SitesJson) = 0:
  → SendActivity("You don't own any sites.")
  → CancelAllDialogs
ELSE:
  → Continue to Node 5 (render card)
```

#### **Node 5: Render Adaptive Card (NEW — requires UI wiring)**

**ACTION TYPE:** Send an Adaptive Card

**Card Template:**
```json
{
  "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
  "type": "AdaptiveCard",
  "version": "1.4",
  "body": [
    {
      "type": "TextBlock",
      "text": "Your SharePoint Sites",
      "weight": "Bolder",
      "size": "Large"
    },
    {
      "type": "TextBlock",
      "text": "You own @{length(Topic.SitesJson)} site(s)",
      "spacing": "Small"
    }
  ],
  "body": [
    {
      "type": "Container",
      "items": [
        {
          "type": "ColumnSet",
          "columns": [
            {
              "width": "stretch",
              "items": [
                {
                  "type": "TextBlock",
                  "text": "**@{item().Title}**",
                  "wrap": true,
                  "weight": "Bolder"
                },
                {
                  "type": "TextBlock",
                  "text": "@{item().SiteURL}",
                  "size": "Small",
                  "spacing": "Small"
                },
                {
                  "type": "TextBlock",
                  "text": "Status: @{if(equals(item().ComplianceStatus, 'COMPLIANT'), '✅ Compliant', '⚠️ Needs Attention')}",
                  "size": "Small",
                  "spacing": "Small"
                },
                {
                  "type": "TextBlock",
                  "text": "Action: @{item().ComplianceAction}",
                  "size": "Small"
                }
              ]
            }
          ]
        }
      ]
    }
  ],
  "actions": [
    {
      "type": "Action.Submit",
      "title": "View Details",
      "data": {
        "intent": "siteDetail",
        "siteUrl": "@{item().SiteURL}",
        "siteItemId": "@{item().ID}",
        "siteTitle": "@{item().Title}"
      }
    },
    {
      "type": "Action.Submit",
      "title": "Certify",
      "data": {
        "intent": "certifySite",
        "siteUrl": "@{item().SiteURL}",
        "siteItemId": "@{item().ID}",
        "siteTitle": "@{item().Title}"
      }
    },
    {
      "type": "Action.Submit",
      "title": "Archive",
      "data": {
        "intent": "archiveSite",
        "siteUrl": "@{item().SiteURL}",
        "siteItemId": "@{item().ID}",
        "siteTitle": "@{item().Title}"
      }
    }
  ]
}
```

**Data Binding:** Loop over Topic.SitesJson results to generate card per site (or use repeating container)

#### **Node 6: Listen for User Selection**

**ACTION TYPE:** Wait for response from Adaptive Card

```
IF response.intent = "siteDetail":
  → Set Topic.SelectedSiteUrl = response.siteUrl
  → Set Topic.SelectedSiteItemId = response.siteItemId
  → Set Topic.SelectedSiteTitle = response.siteTitle
  → Redirect to SiteDetail topic

ELSE IF response.intent = "certifySite":
  → Set Topic.SelectedSiteUrl = response.siteUrl
  → Set Topic.SelectedSiteItemId = response.siteItemId
  → Set Topic.SelectedSiteTitle = response.siteTitle
  → Redirect to CertifySite topic

ELSE IF response.intent = "archiveSite":
  → Set Topic.SelectedSiteUrl = response.siteUrl
  → Set Topic.SelectedSiteItemId = response.siteItemId
  → Set Topic.SelectedSiteTitle = response.siteTitle
  → Redirect to RequestArchival topic
```

---

## Part 2: SiteDetail Topic Implementation

### 2.1 Topic Overview

**Trigger:** "site details", "show site details", "tell me about this site", "explain this site", etc.

**Input Context:** 
- Topic.SelectedSiteUrl (from MySites card or user input)
- Topic.SelectedSiteItemId (optional, from card)

**Flow:**
1. Get caller UPN
2. Check if we have site URL (if not, ask)
3. Load full site record from Contoso Sites
4. Generate triage explanation
5. Render detail card with all fields + action buttons
6. Listen for action selection

### 2.2 Copilot Studio UI Wiring

#### **Node 1-2: Trigger + Initialize Variables**
Already set in YAML.

#### **Node 3: Guard Check**

**CONDITION:** Is Topic.SelectedSiteUrl blank?

```
IF blank:
  → SendActivity: "Which site would you like more information about? 
    You can say the site name or URL, or go back to [My Sites] to select one."
  → Ask question: "Enter site URL or name:"
  → Store in Topic.SelectedSiteUrl
ELSE:
  → Continue
```

#### **Node 4: Load Full Site Record (NEW — requires UI wiring)**

**ACTION TYPE:** SharePoint → Get item

**Configuration:**
```
Site Address: https://mngenvmcap733570.sharepoint.com/sites/M365Governance
List: Contoso Sites
Item ID: Topic.SelectedSiteItemId (if set) OR
Filter Query: SiteURL eq '@{Topic.SelectedSiteUrl}'

Select all columns:
  - Title
  - SiteURL
  - ComplianceStatus
  - ComplianceAction
  - LastActivityDate
  - LastCertificationDate
  - SiteOwnersCount
  - OwnersStr
  - Office
  - SubOffice
  - SiteType
  - CreatedDate
  - SiteStorageUsageMB
  - AttestationStatus
  - AttestedAt
  - AttestationExpiresAt
  - LastActionType
  - LastActionDate
  - LastActionBy
```

**Output Variables:**
- Topic.SiteRecord = response (store entire item)
- Topic.SelectedSiteTitle = response.Title
- Topic.SiteOwnersStr = response.OwnersStr

**Error Handling:** If not found → SendActivity("Site not found") → CancelAllDialogs

#### **Node 5: Generate Triage Explanation (NEW)**

**ACTION TYPE:** Calculate or invoke triage logic

```
Triage rules (hardcoded or from Governance Config):

IF ComplianceStatus = "COMPLIANT":
  Topic.TriageExplanation = "✅ This site is compliant. Certification is current and expires on [date]."

ELSE IF ComplianceAction = "CERTIFY":
  Topic.TriageExplanation = "⚠️ This site is overdue for recertification. 
    Last certified @{Topic.SiteRecord.LastCertificationDate}. 
    Recertification required annually per policy. 
    Click [Certify] to confirm this site is still needed."

ELSE IF ComplianceAction = "ARCHIVE":
  Topic.TriageExplanation = "🗂️ This site may be ready to archive. 
    Last activity was @{Topic.SiteRecord.LastActivityDate}. 
    Content is stale (>12 months old). Consider archiving if no longer needed."

ELSE IF ComplianceAction = "DELETE":
  Topic.TriageExplanation = "🗑️ This site is a candidate for deletion. 
    Very old content with minimal recent activity. 
    Verify no retained data before deleting."

ELSE IF ComplianceAction = "ASSIGN-OWNERS":
  Topic.TriageExplanation = "👤 This site has no owners. 
    Owner assignment is required to maintain governance. 
    Contact your admin to assign an owner."
```

#### **Node 6: Render Detail Card**

**ACTION TYPE:** Send an Adaptive Card with full details

**Card Template:**
```json
{
  "type": "AdaptiveCard",
  "version": "1.4",
  "body": [
    {
      "type": "TextBlock",
      "text": "@{Topic.SiteRecord.Title}",
      "weight": "Bolder",
      "size": "Large"
    },
    {
      "type": "TextBlock",
      "text": "@{if(equals(Topic.SiteRecord.ComplianceStatus, 'COMPLIANT'), '✅ COMPLIANT', '⚠️ NON-COMPLIANT')}",
      "color": "@{if(equals(Topic.SiteRecord.ComplianceStatus, 'COMPLIANT'), 'good', 'warning')}",
      "weight": "Bolder",
      "spacing": "Small"
    },
    {
      "type": "TextBlock",
      "text": "Site Information",
      "weight": "Bolder",
      "spacing": "Medium"
    },
    {
      "type": "FactSet",
      "facts": [
        { "title": "URL", "value": "@{Topic.SiteRecord.SiteURL}" },
        { "title": "Type", "value": "@{Topic.SiteRecord.SiteType}" },
        { "title": "Office", "value": "@{Topic.SiteRecord.Office}" },
        { "title": "Created", "value": "@{Topic.SiteRecord.CreatedDate}" },
        { "title": "Storage", "value": "@{Topic.SiteRecord.SiteStorageUsageMB} MB" }
      ]
    },
    {
      "type": "TextBlock",
      "text": "Ownership",
      "weight": "Bolder",
      "spacing": "Medium"
    },
    {
      "type": "FactSet",
      "facts": [
        { "title": "Owners", "value": "@{Topic.SiteRecord.OwnersStr}" },
        { "title": "Count", "value": "@{Topic.SiteRecord.SiteOwnersCount}" },
        { "title": "Last Activity", "value": "@{Topic.SiteRecord.LastActivityDate}" }
      ]
    },
    {
      "type": "TextBlock",
      "text": "Compliance",
      "weight": "Bolder",
      "spacing": "Medium"
    },
    {
      "type": "FactSet",
      "facts": [
        { "title": "Status", "value": "@{Topic.SiteRecord.ComplianceStatus}" },
        { "title": "Recommended Action", "value": "@{Topic.SiteRecord.ComplianceAction}" },
        { "title": "Last Certified", "value": "@{Topic.SiteRecord.LastCertificationDate}" },
        { "title": "Attestation", "value": "@{Topic.SiteRecord.AttestationStatus}" },
        { "title": "Expires", "value": "@{Topic.SiteRecord.AttestationExpiresAt}" }
      ]
    },
    {
      "type": "TextBlock",
      "text": "Triage Explanation",
      "weight": "Bolder",
      "spacing": "Medium"
    },
    {
      "type": "TextBlock",
      "text": "@{Topic.TriageExplanation}",
      "wrap": true,
      "spacing": "Small"
    }
  ],
  "actions": [
    {
      "type": "Action.Submit",
      "title": "Certify This Site",
      "style": "positive",
      "data": { "intent": "certify" }
    },
    {
      "type": "Action.Submit",
      "title": "Request Archive",
      "data": { "intent": "archive" }
    },
    {
      "type": "Action.Submit",
      "title": "Flag for Deletion",
      "style": "destructive",
      "data": { "intent": "delete" }
    },
    {
      "type": "Action.Submit",
      "title": "Back to My Sites",
      "data": { "intent": "back" }
    }
  ]
}
```

#### **Node 7: Listen for Action Selection**

```
IF response.intent = "certify":
  → Set Topic.SelectedSiteUrl = Topic.SiteRecord.SiteURL
  → Set Topic.SelectedSiteItemId = Topic.SiteRecord.ID
  → Set Topic.SelectedSiteTitle = Topic.SiteRecord.Title
  → Redirect to CertifySite topic

ELSE IF response.intent = "archive":
  → Set Topic.SelectedSiteUrl = Topic.SiteRecord.SiteURL
  → Set Topic.SelectedSiteItemId = Topic.SiteRecord.ID
  → Set Topic.SelectedSiteTitle = Topic.SiteRecord.Title
  → Redirect to RequestArchival topic

ELSE IF response.intent = "delete":
  → Set Topic.SelectedSiteUrl = Topic.SiteRecord.SiteURL
  → Set Topic.SelectedSiteItemId = Topic.SiteRecord.ID
  → Set Topic.SelectedSiteTitle = Topic.SiteRecord.Title
  → Redirect to FlagForDeletion topic

ELSE IF response.intent = "back":
  → Redirect to MySites topic
```

---

## Part 3: CertifySite Topic Implementation

### 3.1 Topic Overview

**Trigger:** "certify", "certify site", "certify a site", "certify my site"

**Flow:**
1. Get caller UPN
2. Ask for site URL (if not provided from card)
3. Resolve site item ID (if only URL provided)
4. Verify caller is owner (security check)
5. Show confirmation card
6. Wait for confirmation
7. Invoke ActionCallback flow with CERTIFY action
8. Show success card with next review date

### 3.2 Copilot Studio UI Wiring

#### **Node 1-2: Trigger + Initialize Variables**
Already set in YAML.

#### **Node 3: Guard Check**

**CONDITION:** Is Topic.SelectedSiteUrl empty?

```
IF empty:
  → SendActivity: "Which site would you like to certify? 
    Please provide the site name or full URL."
  → Question: "Enter site URL or name:"
  → Set Topic.SelectedSiteUrl = response
  → Continue to Node 4
ELSE:
  → Continue to Node 4 (skip this)
```

#### **Node 4: Resolve Item ID (if needed)**

**CONDITION:** Is Topic.SelectedSiteItemId empty?

```
IF empty:
  → SendActivity: "Looking up site in governance list..."
  → SharePoint: Get items WHERE SiteURL eq '@{Topic.SelectedSiteUrl}'
  → IF found:
      Set Topic.SelectedSiteItemId = result.ID
      Set Topic.SelectedSiteTitle = result.Title
      Continue
    ELSE:
      SendActivity: "Site not found. Please check URL and try again."
      CancelAllDialogs
```

#### **Node 5: Verify Ownership (Security Check)**

**ACTION TYPE:** SharePoint → Get items (with ownership filter)

```
Site Address: https://mngenvmcap733570.sharepoint.com/sites/M365Governance
List: Contoso Sites
Filter Query:
  SiteURL eq '@{Topic.SelectedSiteUrl}' 
  AND substringof('@{Topic.CallerUPN}', SiteOwners)

Top Count: 1
```

**CONDITION:** Is result count > 0?

```
IF count > 0:
  → Set Topic.SiteOwnersStr = result.OwnersStr
  → SendActivity: "✓ Ownership verified. You are listed as an owner."
  → Continue to Node 6

ELSE:
  → SendActivity: "You are not listed as an owner of this site. 
    Only owners can certify. Please contact your admin if this is an error."
  → CancelAllDialogs
```

#### **Node 6: Show Confirmation Card**

**ACTION TYPE:** Send an Adaptive Card

```json
{
  "type": "AdaptiveCard",
  "version": "1.4",
  "body": [
    {
      "type": "Container",
      "style": "emphasis",
      "items": [
        {
          "type": "TextBlock",
          "text": "Confirm Certification",
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
        { "text": "The site is still needed and actively used" },
        { "text": "The ownership information is accurate" },
        { "text": "The content complies with information policies" }
      ]
    },
    {
      "type": "FactSet",
      "facts": [
        { "title": "Site", "value": "@{Topic.SelectedSiteTitle}" },
        { "title": "URL", "value": "@{Topic.SelectedSiteUrl}" },
        { "title": "Owners", "value": "@{Topic.SiteOwnersStr}" },
        { "title": "Certification Date", "value": "@{System.DateTime.UtcNow}" },
        { "title": "Next Review", "value": "@{addDays(System.DateTime.UtcNow, 365)}" }
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

#### **Node 7: Check Confirmation Response**

```
IF response.intent = "cancelCertify":
  → SendActivity: "No problem — no changes were made."
  → CancelAllDialogs

ELSE IF response.intent = "confirmCertify":
  → Continue to Node 8 (invoke flow)
```

#### **Node 8: Invoke ActionCallback Flow (NEW)**

**ACTION TYPE:** Power Apps connector → Run a flow

**Configuration:**
```
Flow: GovernanceAgent-ActionCallback

Inputs:
  - callerUPN: Topic.CallerUPN
  - actionType: "CERTIFY"
  - siteUrl: Topic.SelectedSiteUrl
  - siteTitle: Topic.SelectedSiteTitle
  - siteItemId: Topic.SelectedSiteItemId
  - previousComplianceStatus: "" (can be empty)
  - previousComplianceAction: "" (can be empty)

Outputs captured:
  - Topic.ActionSuccess = outputs('success')
  - Topic.ActionStatus = outputs('actionStatus')
  - Topic.ActionMessage = outputs('message')
```

**Error Handling:** If flow fails → SendActivity("Error: {error details}") → CancelAllDialogs

#### **Node 9: Show Success Card**

**CONDITION:** Is Topic.ActionSuccess = true?

```
IF true:
  → SendActivity: Display success card (see below)
  → CancelAllDialogs

ELSE:
  → SendActivity: Display error card
  → CancelAllDialogs
```

**Success Card Template:**
```json
{
  "type": "AdaptiveCard",
  "version": "1.4",
  "body": [
    {
      "type": "Container",
      "style": "emphasis",
      "items": [
        {
          "type": "TextBlock",
          "text": "✅ Certification Complete!",
          "weight": "Bolder",
          "size": "Large"
        }
      ]
    },
    {
      "type": "FactSet",
      "facts": [
        { "title": "Site", "value": "@{Topic.SelectedSiteTitle}" },
        { "title": "Certified by", "value": "@{Topic.CallerUPN}" },
        { "title": "Certification Date", "value": "@{System.DateTime.UtcNow}" },
        { "title": "Next Review", "value": "@{addDays(System.DateTime.UtcNow, 365)}" }
      ]
    },
    {
      "type": "TextBlock",
      "text": "Status updated to: **COMPLIANT**",
      "wrap": true,
      "spacing": "Medium"
    },
    {
      "type": "TextBlock",
      "text": "Attestation status: **ATTESTED**",
      "wrap": true
    },
    {
      "type": "TextBlock",
      "text": "You'll receive a reminder when certification renewal is needed.",
      "wrap": true,
      "spacing": "Medium",
      "color": "good"
    }
  ],
  "actions": [
    {
      "type": "Action.Submit",
      "title": "Show My Sites",
      "data": { "intent": "showMySites" }
    },
    {
      "type": "Action.Submit",
      "title": "Certify Another Site",
      "data": { "intent": "certifyAnother" }
    }
  ]
}
```

#### **Node 10: Listen for Next Action**

```
IF response.intent = "showMySites":
  → Redirect to MySites topic

ELSE IF response.intent = "certifyAnother":
  → Reset Topic.SelectedSiteUrl = ""
  → Restart CertifySite topic
```

---

## Testing Checklist

### MySites Topic
- [ ] User can ask "show my sites"
- [ ] List returns only sites where user is in SiteOwners field
- [ ] Compliance status (✅ Compliant / ⚠️ Non-Compliant) displays correctly
- [ ] "View Details" button passes site context correctly
- [ ] "Certify" button routes to CertifySite with site data
- [ ] "Archive" button routes to RequestArchival with site data
- [ ] Empty state handled (no sites returns helpful message)
- [ ] Response time < 2 seconds

### SiteDetail Topic
- [ ] Topic can be triggered by name ("site details") or by card selection
- [ ] Asks for site name if not provided
- [ ] Loads full site record with all fields
- [ ] Displays correct compliance status and triage reasoning
- [ ] Triage explanation accurately reflects ComplianceAction
- [ ] "Certify" button routes correctly
- [ ] "Archive" button routes correctly
- [ ] "Delete" button routes correctly
- [ ] "Back" returns to MySites
- [ ] Response time < 2 seconds

### CertifySite Topic
- [ ] Topic triggered by "certify" or card selection
- [ ] Asks for site URL if not provided
- [ ] Resolves site item ID correctly
- [ ] Ownership verification prevents non-owners from certifying
- [ ] Confirmation card displays all relevant information
- [ ] Cancel button stops without making changes
- [ ] ActionCallback flow is invoked with correct inputs
- [ ] Site list is updated with new certification date
- [ ] ComplianceStatus changes to COMPLIANT
- [ ] AttestationStatus changes to ATTESTED
- [ ] Audit log entry is written
- [ ] Success card shows correct dates
- [ ] User can quickly certify another site
- [ ] Response time < 5 seconds (including flow execution)

---

## Deployment Steps

1. **Update Topic YAML Files**
   - ✅ Already updated (MySites.mcs.yml, SiteDetail.mcs.yml, CertifySite.mcs.yml)

2. **Deploy to Copilot Studio**
   ```powershell
   cd c:\source\M365GovAIAgent\copilot\agents
   .\deploy-governance-agents.ps1
   ```
   This will push updated topics to both agents.

3. **Wire Topics in Copilot Studio UI**
   - Open Governance Owner Agent in Copilot Studio
   - Go to Topics → MySites
   - Use "Visual editor" or "Code editor" to add:
     - SharePoint Get items connector (as shown in Node 3 above)
     - Adaptive Card rendering (as shown in Node 5)
     - Condition checks
     - Topic redirects
   - Repeat for SiteDetail and CertifySite

4. **Test Each Topic**
   - Use Copilot Studio's Test button
   - Try various user inputs and verify flow

5. **Verify ActionCallback Flow**
   - Open Power Automate
   - Navigate to "Flows" → "Cloud Flows"
   - Find "GovernanceAgent-ActionCallback"
   - Verify CERTIFY branch is correctly configured
   - Test with a real site ID

6. **Publish Agents**
   - In Copilot Studio, click "Publish" on Owner Agent
   - Test in Teams

---

## Next: Wiring Instructions for Copilot Studio

For each node that requires SharePoint connectors or other actions:

1. Click the **+** button to add an action
2. Select **Power Apps connectors** → **SharePoint**
3. Choose the appropriate action (Get items, Get item)
4. Fill in the fields as specified above
5. For conditions, use **Condition** node and specify the logic
6. For topic redirects, use **Route** or **Redirect** action (depends on Copilot Studio version)

---

## Summary

**Sprint A Completion Targets:**

| Task | Status | Effort | Owner |
|------|--------|--------|-------|
| Update MySites YAML | ✅ Done | 1h | - |
| Update SiteDetail YAML | ✅ Done | 1h | - |
| Update CertifySite YAML | ✅ Done | 1.5h | - |
| Wire MySites in UI | ⏳ Todo | 3-4h | Dev |
| Wire SiteDetail in UI | ⏳ Todo | 3-4h | Dev |
| Wire CertifySite in UI | ⏳ Todo | 4-5h | Dev |
| Test all three topics | ⏳ Todo | 3-4h | QA |
| Verify ActionCallback | ⏳ Todo | 1h | Dev |
| Deploy & publish | ⏳ Todo | 0.5h | Dev |

**Total Remaining Effort:** ~20-22 hours

**Timeline:** 2-3 days with dedicated developer

---

**Document Prepared By:** AI Implementation Team  
**Ready for Handoff:** Yes — all YAML prepared, ready for UI implementation  
