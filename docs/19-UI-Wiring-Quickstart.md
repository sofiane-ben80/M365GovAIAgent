# Sprint A UI Wiring — Quickstart Guide

> **Legacy UI guide:** Bind topics and cards to Dataverse-backed Power Automate
> tools. Do not create direct governance SharePoint-list operations.

**Your Goal:** Convert topic YAML scaffolds into working Copilot Studio topics with SharePoint connectors and Adaptive Cards.

**Time:** ~2-4 hours to complete all 5 topics (MySites → SiteDetail → CertifySite → AdminDashboard → OrphanedSites)

---

## Quick Setup Checklist

Before you start:

- [ ] Open Copilot Studio: https://copilotstudio.microsoft.com/
- [ ] Navigate to your environment (9417045e-87bb-eac8-bda1-850674b11405)
- [ ] Open **Governance Owner Agent** bot
- [ ] Verify topics are visible: MySites, SiteDetail, CertifySite (should all exist)
- [ ] Have [16-Sprint-A-Implementation-Guide.md](16-Sprint-A-Implementation-Guide.md) open for detailed reference
- [ ] Have these GUIDs handy:
  - Contoso Sites list: `44dfbf52-8434-42d6-95c5-8ecf7614351d`
  - SharePoint site: `https://[tenant].sharepoint.com`

---

## Part 1: MySites Topic (Simplest — Start Here)

### Goal
User asks "show my sites" → Get all sites where caller is in SiteOwners field → Display Adaptive Card with site list + action buttons

### Steps

**1. Open MySites Topic**
- Copilot Studio → Governance Owner Agent → Topics → MySites
- Click "Edit" (or open in visual editor if in draft)
- You should see scaffold nodes with comments

**2. Keep existing nodes:**
- ✅ `setVariable_MySitesCallerUpn` (CallerUPN = System.User.PrincipalName)
- ✅ `setVariable_PageNumber` (PageNumber = 1)
- ✅ `setVariable_PageSize` (PageSize = 10)
- ✅ `setVariable_SitesJson` (SitesJson = "[]")
- ✅ `sendActivity_MySitesLoading` ("Loading your sites...")

**3. Replace the second sendActivity node**

Find: `sendActivity_MySitesList` (the one with long Adaptive Card description)

Delete it and add these nodes in sequence:

**Node A: Get items from Contoso Sites**
- **Type:** Action → Power Apps → SharePoint → Get items
- **Site:** `https://[tenant].sharepoint.com` (select your tenant)
- **List:** `Contoso Sites` (from dropdown, or paste GUID: 44dfbf52-8434-42d6-95c5-8ecf7614351d)
- **Filter query:**
  ```
  substringof('@{variables('Topic.CallerUPN')}',SiteOwners)
  ```
- **Sort by:** ComplianceStatus (or leave default)
- **Top Count:** 10
- **Select columns:** ID, Title, SiteURL, ComplianceStatus, ComplianceAction, LastActivityDate, LastCertificationDate, SiteOwnersCount
- **Store output in variable:** `Topic.SitesJson` (set to the results array from connector output)

**Node B: Show Adaptive Card with sites**
- **Type:** Adaptive Card
- **Card mode:** Select **Formula**, not JSON.
- **Card formula:** Paste the contents of `adaptive-cards/my-sites-card.powerfx`.
- The formula reads `Topic.SiteCount`, `Topic.PageSize`, and the `Topic.SitesJson`
  text returned by the flow. It uses `Table(ParseJSON(...))` and `ForAll(...)` to
  generate one ordinary Adaptive Card container per site.
- Do not add `$data`, `$when`, or `${...}` expressions. Copilot Studio does not
  run the Adaptive Cards templating engine before rendering the card.

**Node C: Listen for button clicks**
- **Type:** Question
- **Prompt:** "Select an action"
- **Variable:** `Topic.UserSelection`
- **Choices:**
  - View Details
  - Certify
  - Archive
  - Next Page

**Node D: Route to next topic**
- **Type:** If/Then (condition-based routing)
- **Condition 1:** `Topic.UserSelection = "Certify"`
  - **Action:** Go to topic → CertifySite
  - **Pass variables:** `Topic.SelectedSiteUrl`, `Topic.SelectedSiteItemId`, `Topic.SelectedSiteTitle`
- **Condition 2:** `Topic.UserSelection = "View Details"`
  - **Action:** Go to topic → SiteDetail
  - **Pass variables:** Same as above
- **Condition 3:** `Topic.UserSelection = "Next Page"`
  - **Action:** Increment `Topic.PageNumber` → Re-query with new page
- **Else:** Cancel

**4. Test MySites**
- Click "Test" in top-right
- Say: "Show my sites"
- Verify: You should see your owned sites listed
- Verify: Status badges showing COMPLIANT/NON-COMPLIANT
- Verify: Action buttons clickable
- Response time should be <2 seconds

**✅ MySites Complete!**

---

## Part 2: SiteDetail Topic (Medium)

### Goal
Show full site details with triage explanation + action options

### Steps

**1. Open SiteDetail Topic**
- Topics → SiteDetail
- Edit in visual editor

**2. Keep existing nodes:**
- ✅ Variables initialized
- ✅ Guard check for `Topic.SelectedSiteUrl`

**3. Add SharePoint connector to load full site**

After guard check, add:

**Node A: Get full site item**
- **Type:** SharePoint → Get item
- **Site:** Same as before
- **List:** Contoso Sites
- **Item ID:** `Topic.SelectedSiteItemId` (or query by Title if ID not available)
- **Select:** All columns (Title, SiteURL, Owners, ComplianceStatus, ComplianceAction, LastCertificationDate, AttestationStatus, etc.)
- **Store in:** `Topic.SiteRecord`

**Node B: Calculate triage explanation**
- **Type:** Compose (or Set variable with formula)
- **Formula:** 
  ```
  IF ComplianceAction = 'CERTIFY' THEN
    "This site's certification expired on [date]. Please certify to bring it back to compliant status."
  ELSE IF ComplianceAction = 'ARCHIVE' THEN
    "This site has been inactive for 12+ months. Consider archiving to reduce storage and management overhead."
  ELSE IF ComplianceAction = 'DELETE-REQUESTED' THEN
    "This site is marked for deletion review due to governance violations. Contact administrators for details."
  ELSE IF ComplianceAction = 'ASSIGN-OWNERS' THEN
    "This site currently has no designated owners. Please assign an owner to restore governance."
  ELSE
    "This site is compliant and requires no immediate action."
  ```
- **Store in:** `Topic.TriageExplanation`

**Node C: Show detail card**
- **Type:** Adaptive Card

```json
{
  "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
  "type": "AdaptiveCard",
  "version": "1.4",
  "body": [
    {
      "type": "TextBlock",
      "text": "📌 Site Details",
      "weight": "bolder",
      "size": "large"
    },
    {
      "type": "FactSet",
      "facts": [
        {
          "name": "Title:",
          "value": "${Topic.SiteRecord.Title}"
        },
        {
          "name": "URL:",
          "value": "${Topic.SiteRecord.SiteURL}"
        },
        {
          "name": "Status:",
          "value": "${Topic.SiteRecord.ComplianceStatus}"
        },
        {
          "name": "Required Action:",
          "value": "${Topic.SiteRecord.ComplianceAction}"
        },
        {
          "name": "Last Certified:",
          "value": "${Topic.SiteRecord.LastCertificationDate}"
        },
        {
          "name": "Attestation Status:",
          "value": "${Topic.SiteRecord.AttestationStatus}"
        },
        {
          "name": "Owners:",
          "value": "${Topic.SiteRecord.SiteOwners}"
        }
      ]
    },
    {
      "type": "TextBlock",
      "text": "📋 Recommended Action",
      "weight": "bolder",
      "color": "${if(equals(Topic.SiteRecord.ComplianceStatus,'COMPLIANT'),'good','warning')}"
    },
    {
      "type": "TextBlock",
      "text": "${Topic.TriageExplanation}",
      "wrap": true
    }
  ],
  "actions": [
    {
      "type": "Action.Submit",
      "title": "Certify Site",
      "data": {
        "action": "certify",
        "siteUrl": "${Topic.SiteRecord.SiteURL}",
        "siteId": "${Topic.SiteRecord.ID}",
        "siteTitle": "${Topic.SiteRecord.Title}"
      }
    },
    {
      "type": "Action.Submit",
      "title": "Archive",
      "data": {
        "action": "archive"
      }
    },
    {
      "type": "Action.Submit",
      "title": "Back to My Sites",
      "data": {
        "action": "back"
      }
    }
  ]
}
```

**Node D: Route to actions**
- **Type:** If/Then
- **Condition 1:** `Topic.UserSelection = "Certify"`
  → Go to CertifySite topic (pass site context)
- **Condition 2:** `Topic.UserSelection = "Back"`
  → Go to MySites topic

**4. Test SiteDetail**
- From MySites, click "View Details"
- Verify: Full site record displayed
- Verify: Triage explanation shows correctly
- Verify: Action buttons work

**✅ SiteDetail Complete!**

---

## Part 3: CertifySite Topic (Most Complex — Highest Priority)

### Goal
End-to-end certification flow with ownership verification + ActionCallback invocation

### Steps

**1. Open CertifySite Topic**

**2. Keep existing nodes:**
- ✅ CallerUPN variable
- ✅ ActionType = "CERTIFY"
- ✅ Site URL input guard

**3. After URL guard, add:**

**Node A: Resolve item ID**
- **Type:** SharePoint → Get items
- **Filter:** `SiteURL eq '${Topic.SelectedSiteUrl}'`
- **Top:** 1
- **Store:** `Topic.SelectedSiteItemId` (from result.ID)

**Node B: Verify ownership (SECURITY CHECK)**
- **Type:** SharePoint → Get items
- **Filter:** `SiteURL eq '${Topic.SelectedSiteUrl}' and substringof('${Topic.CallerUPN}',SiteOwners)`
- **Top:** 1
- **Condition check:** IF result count = 0 → Show error, cancel
- **Else:** Continue
- **Store result:** `Topic.SiteOwnersStr` (from SiteOwners field)

**Node C: Show confirmation card**
- **Type:** Adaptive Card

```json
{
  "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
  "type": "AdaptiveCard",
  "version": "1.4",
  "body": [
    {
      "type": "TextBlock",
      "text": "✅ Confirm Certification",
      "weight": "bolder",
      "size": "large",
      "color": "good"
    },
    {
      "type": "TextBlock",
      "text": "By certifying this site, you confirm that:\n✓ The site is still needed and actively used\n✓ The ownership information is accurate\n✓ The content complies with information policies",
      "wrap": true
    },
    {
      "type": "FactSet",
      "facts": [
        {
          "name": "Site:",
          "value": "${Topic.SelectedSiteTitle}"
        },
        {
          "name": "URL:",
          "value": "${Topic.SelectedSiteUrl}"
        },
        {
          "name": "Owners:",
          "value": "${Topic.SiteOwnersStr}"
        },
        {
          "name": "Certification Date:",
          "value": "${System.DateTime.UtcNow}"
        },
        {
          "name": "Next Review:",
          "value": "365 days from today"
        }
      ]
    }
  ],
  "actions": [
    {
      "type": "Action.Submit",
      "title": "✅ Confirm Certification",
      "data": {
        "action": "confirm"
      }
    },
    {
      "type": "Action.Submit",
      "title": "❌ Cancel",
      "data": {
        "action": "cancel"
      }
    }
  ]
}
```

**Node D: Check confirmation**
- **Type:** Question
- **Prompt:** "Proceed with certification?"
- **Variable:** `Topic.CertifyConfirmation`
- **Choices:** Yes, No
- **If No:** Show "Canceled" message → Cancel dialog

**Node E: Invoke ActionCallback flow**
- **Type:** Action → Power Automate → [Select flow] → GovernanceAgent-ActionCallback
- **Flow inputs:**
  - `callerUPN`: Topic.CallerUPN
  - `actionType`: "CERTIFY"
  - `siteUrl`: Topic.SelectedSiteUrl
  - `siteTitle`: Topic.SelectedSiteTitle
  - `siteItemId`: Topic.SelectedSiteItemId
- **Capture outputs:**
  - `Topic.ActionSuccess` (success boolean)
  - `Topic.ActionStatus` (COMPLETED/FAILED)
  - `Topic.ActionMessage` (response message)

**Node F: Show success card**
- **Type:** Adaptive Card

```json
{
  "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
  "type": "AdaptiveCard",
  "version": "1.4",
  "body": [
    {
      "type": "TextBlock",
      "text": "🎉 Certification Complete!",
      "weight": "bolder",
      "size": "large",
      "color": "good"
    },
    {
      "type": "TextBlock",
      "text": "Your site has been successfully certified.",
      "wrap": true
    },
    {
      "type": "FactSet",
      "facts": [
        {
          "name": "Site:",
          "value": "${Topic.SelectedSiteTitle}"
        },
        {
          "name": "Certified By:",
          "value": "${Topic.CallerUPN}"
        },
        {
          "name": "Certification Date:",
          "value": "${System.DateTime.UtcNow}"
        },
        {
          "name": "Status:",
          "value": "✅ COMPLIANT"
        },
        {
          "name": "Next Review:",
          "value": "365 days"
        }
      ]
    }
  ],
  "actions": [
    {
      "type": "Action.Submit",
      "title": "Back to My Sites",
      "data": {
        "action": "back"
      }
    },
    {
      "type": "Action.Submit",
      "title": "Certify Another",
      "data": {
        "action": "certify_another"
      }
    }
  ]
}
```

**Node G: Route next action**
- **Type:** If/Then
- **Condition 1:** User selects "Back to My Sites" → Go to MySites
- **Condition 2:** User selects "Certify Another" → Reset variables, ask for new site URL

**4. Test CertifySite (CRITICAL)**
- From MySites, click "Certify"
- Verify: Ownership check works (try with non-owner account)
- Verify: Confirmation card displays
- Verify: After confirmation, ActionCallback flow invokes
- Verify: SharePoint list updates with new certification date
- Verify: Audit log entry created
- Verify: Success card shows

**✅ CertifySite Complete! (Highest Priority)**

---

## Part 4: AdminDashboard Topic (4 steps)

### Goal
Show tenant-wide summary + admin verification

### Steps

**1. Open AdminDashboard Topic**

**2. Keep existing:**
- ✅ CallerUPN variable

**3. Add nodes:**

**Node A: Invoke CheckAdminRole flow**
- **Type:** Action → Power Automate → GovernanceAgent-CheckAdminRole
- **Input:** `callerUPN` = Topic.CallerUPN
- **Output:** `Topic.IsAdmin` (boolean)
- **If False:** Show "Admin role required" → Cancel

**Node B: Get aggregate counts**
- **Type:** SharePoint → Get items (x5 separate queries)**
  
  Query 1 (Compliant count):
  - Filter: `ComplianceStatus eq 'COMPLIANT'`
  - Store: `Topic.CompliantCount`
  
  Query 2 (Non-Compliant count):
  - Filter: `ComplianceStatus ne 'COMPLIANT'`
  - Store: `Topic.NonCompliantCount`
  
  Query 3 (Orphaned count):
  - Filter: `SiteOwnersCount eq 0`
  - Store: `Topic.OrphanedCount`
  
  Query 4 (Not Attested count):
  - Filter: `AttestationStatus ne 'ATTESTED'`
  - Store: `Topic.NotAttestedCount`
  
  Query 5 (Needing recert count):
  - Filter: `ComplianceAction eq 'CERTIFY'`
  - Store: `Topic.CertifyNeededCount`

**Node C: Show dashboard card**
- **Type:** Adaptive Card

```json
{
  "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
  "type": "AdaptiveCard",
  "version": "1.4",
  "body": [
    {
      "type": "TextBlock",
      "text": "📊 M365 Governance Dashboard",
      "weight": "bolder",
      "size": "large"
    },
    {
      "type": "TextBlock",
      "text": "Compliance Summary",
      "weight": "bolder",
      "size": "medium"
    },
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
                  "text": "✅ Compliant"
                },
                {
                  "type": "TextBlock",
                  "text": "${Topic.CompliantCount}",
                  "weight": "bolder",
                  "size": "large",
                  "color": "good"
                }
              ]
            },
            {
              "width": "stretch",
              "items": [
                {
                  "type": "TextBlock",
                  "text": "⚠️ Non-Compliant"
                },
                {
                  "type": "TextBlock",
                  "text": "${Topic.NonCompliantCount}",
                  "weight": "bolder",
                  "size": "large",
                  "color": "warning"
                }
              ]
            },
            {
              "width": "stretch",
              "items": [
                {
                  "type": "TextBlock",
                  "text": "👥 Orphaned"
                },
                {
                  "type": "TextBlock",
                  "text": "${Topic.OrphanedCount}",
                  "weight": "bolder",
                  "size": "large"
                }
              ]
            }
          ]
        }
      ]
    },
    {
      "type": "TextBlock",
      "text": "Action Items",
      "weight": "bolder",
      "size": "medium"
    },
    {
      "type": "ColumnSet",
      "columns": [
        {
          "width": "stretch",
          "items": [
            {
              "type": "TextBlock",
              "text": "📋 Need Recertification: ${Topic.CertifyNeededCount}"
            }
          ]
        },
        {
          "width": "stretch",
          "items": [
            {
              "type": "TextBlock",
              "text": "🔍 Not Attested: ${Topic.NotAttestedCount}"
            }
          ]
        }
      ]
    }
  ],
  "actions": [
    {
      "type": "Action.Submit",
      "title": "View Orphaned Sites",
      "data": {
        "action": "orphaned"
      }
    }
  ]
}
```

**Node D: Route actions**
- If user selects "View Orphaned Sites" → Go to OrphanedSites topic

**✅ AdminDashboard Complete!**

---

## Part 5: OrphanedSites Topic (Similar to MySites)

### Goal
Show sites with no owners + admin actions

### Steps

**1. Open OrphanedSites Topic**

**2. Add nodes:**

**Node A: Get orphaned sites**
- **Type:** SharePoint → Get items
- **Filter:** `SiteOwnersCount eq 0 and ComplianceAction eq 'ASSIGN-OWNERS'`
- **Top:** 10
- **Store:** `Topic.OrphanedSitesJson`

**Node B: Show list card**
- **Type:** Adaptive Card (similar structure to MySites but with admin-specific buttons)

```json
{
  "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
  "type": "AdaptiveCard",
  "version": "1.4",
  "body": [
    {
      "type": "TextBlock",
      "text": "👥 Orphaned Sites (No Owners)",
      "weight": "bolder",
      "size": "large"
    },
    {
      "type": "Container",
      "items": [
        {
          "type": "TextBlock",
          "text": "${Title}"
        },
        {
          "type": "TextBlock",
          "text": "${SiteURL}",
          "size": "small",
          "color": "accent"
        }
      ],
      "$data": "${Topic.OrphanedSitesJson}"
    }
  ],
  "actions": [
    {
      "type": "Action.Submit",
      "title": "Assign Owner",
      "data": {
        "action": "assign_owner"
      }
    },
    {
      "type": "Action.Submit",
      "title": "Archive",
      "data": {
        "action": "archive"
      }
    }
  ]
}
```

**Node C: Route admin actions**
- Assign Owner → Topic: ActionAssignOwners (Sprint B)
- Archive → Topic: RequestArchival (Sprint B)

**✅ OrphanedSites Complete!**

---

## Testing Checklist

After wiring all topics, run through this:

### MySites
- [ ] Say "show my sites"
- [ ] Verify you see your owned sites in <2 sec
- [ ] Verify status badges correct
- [ ] Click "Certify" → routes to CertifySite ✅
- [ ] Click "View Details" → routes to SiteDetail ✅

### SiteDetail
- [ ] Full site record displays
- [ ] Triage explanation shows (based on action type)
- [ ] Buttons clickable
- [ ] "Back to My Sites" works ✅

### CertifySite (CRITICAL TEST)
- [ ] Ownership verification works (test with non-owner = error)
- [ ] Confirmation card shows
- [ ] After yes: Flow invokes
- [ ] SharePoint list updates:
  - [ ] LastCertificationDate = today
  - [ ] ComplianceStatus = COMPLIANT
  - [ ] AttestationStatus = ATTESTED
  - [ ] AttestationExpiresAt = today + 365 days
- [ ] Audit log entry created with ActionType=CERTIFY
- [ ] Success card displays

### AdminDashboard
- [ ] Admin role check works (test with non-admin = error)
- [ ] Counts display correctly
- [ ] Orphaned Sites link works ✅

### OrphanedSites
- [ ] Shows sites with no owners
- [ ] Admin actions available

---

## Common Issues & Fixes

| Issue | Solution |
|-------|----------|
| SharePoint connector not showing lists | Ensure you've selected the correct SharePoint site (your tenant) |
| OData filter syntax error | Use exact format: `SiteURL eq 'value' and ComplianceStatus ne 'other'` |
| Variables not available in card | Wrap in `${}`: `${Topic.SelectedSiteTitle}` |
| Button clicks not routing | Verify topic redirect is configured with "Send variables" checked |
| Flow not invoking | Check flow exists and is enabled in Power Automate |
| Response times slow (>5 sec) | Check SharePoint site performance, reduce filter complexity |

---

## Next Steps

**After testing all topics:**

1. ✅ Export bot to repo (auto-sync should already done)
2. ✅ Document any deviations from YAML scaffolds
3. ✅ Prepare UAT sign-off
4. ✅ Schedule Sprint B kick-off

**Sprint B topics (2-3 weeks):**
- RequestArchival (owner can request archive)
- FlagForDeletion (owner can flag for deletion)
- ActionStatus (check status of pending actions)

---

**Ready to start wiring?**

> **Shortcut:** Start with MySites (15 min), then SiteDetail (15 min), then CertifySite (30 min). These three are the core user journey. AdminDashboard & OrphanedSites are supporting topics you can do later.

**Report back when you hit any snags!**
