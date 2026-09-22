# 03 – Agent Design

**Document:** Per-Agent Design Specification  
**Solution:** M365 Governance AI Agent  
**Version:** 2.0 target  
**Date:** 2026-09-17  
**Status:** Approved target

---

## 1. Agent Map

```
M365 Governance Agent (Orchestrator)
├── Owner Operations (local child)
│   └── My Sites topic
├── Admin Operations (local child)
│   └── Admin Dashboard topic
├── Governance Policy Advisor (local child)
├── Copilot Readiness Advisor (local child)
├── Data Protection Advisor (local child)
├── Identity Governance Advisor (local child)
└── Security & Compliance Assurance (local child)
```

The User/Owner and Admin agents have separate security and tool boundaries.
The optional orchestrator is a thin Teams-connected launcher and does not gain
privilege from routing. Domain subagents are invoked within the destination
agent's bounded context.

Implementation update (2026-09-21):
- Governor M365 uses manual Entra authentication for the embedded Canvas PCF
  channel and has zero active `InvokeConnectedAgentTaskAction` components.
- Seven local child agents are enabled beneath Governor M365. They share the
  parent's manual authentication, conversation, and publication lifecycle.
- Owner portfolio and administrator dashboard capabilities are implemented as
  child-owned topics so the manually authenticated Canvas identity is not lost
  across an unsupported connected-agent authentication boundary.
- The five specialist advisor records and the Owner/Admin agents remain
  separately published for reuse, but Governor does not invoke those records
  as connected agents.
- Every operational flow continues to authorize the caller independently.
- See [22-Agent-Orchestration-Architecture.md](22-Agent-Orchestration-Architecture.md)
  and [29-Agent-Architecture-Review.md](29-Agent-Architecture-Review.md) for
  the decision rationale and current-state assessment.

---

## 2. Orchestrator Agent

### 2.1 Identity & Purpose
| Field | Value |
|-------|-------|
| **Name** | M365 Governance Agent |
| **Role** | Handoff-only supervisor and Canvas-facing entry point |
| **Copilot Studio Type** | Top-level parent agent with seven local children |
| **Solution Name** | M365Governance |
| **Prefix** | `sb` |

### 2.2 Responsibilities
- Greet the user and establish context
- Route to the correct local child based on user intent
- Preserve signed-in system context during delegation; do not accept caller
  identity from prose
- Offer the Admin destination only from a minimized, server-validated
  capability result, while still requiring the Admin Agent to reverify access
- Handle fallback / out-of-scope utterances gracefully

### 2.3 Topics

| Topic | Trigger Phrases | Behavior |
|-------|----------------|---------|
| **Greeting / Start** | Conversation start | Greet user by name and present launcher menu (Owner Agent / Admin Agent) |
| **Owner Route** | "show my sites", "what sites do I own", "my sharepoint sites" | Handoff → Owner Operations child |
| **Admin Route** | "admin view", "show all sites", "orphaned sites", "not attested", "tenant overview" | Handoff → Admin Operations child |
| **Help** | "help", "what can you do", "menu" | Show capabilities card |
| **Fallback** | Any unmatched input | Clarify intent; offer menu |

### 2.4 System Prompt (Instructions)
```
You are the M365 Governance Agent for [Organization Name]. You help SharePoint site owners 
and tenant administrators manage site compliance, including recertification, archival, and deletion.

You are a handoff-only supervisor for seven local child agents:
- Owner Operations
- Admin Operations
- Governance Policy Advisor
- Copilot Readiness Advisor
- Data Protection Advisor
- Identity Governance Advisor
- Security & Compliance Assurance

Do not execute domain work directly. Route quickly. Children and tools derive
caller identity from System.User.PrincipalName.
```

### 2.5 Connections / Actions
| Connection | Purpose |
|------------|---------|
| Copilot Studio child-agent handoffs | Route conversation to the matching local child |

---

## 3. Governance User & Owner Agent

### 3.1 Identity & Purpose
| Field | Value |
|-------|-------|
| **Name** | Governance User & Owner Agent |
| **Role** | General governance help plus view, understand, and act on sites owned by the signed-in user |
| **Copilot Studio Type** | Published entry agent |
| **Invoked By** | Teams user directly, or Orchestrator launcher |

### 3.2 Responsibilities
- Call the owner-scoped Power Automate tool backed by Dataverse
- Provide general guidance and support request entry when the caller owns no
  governed site
- Present results as a card or table in Teams
- Support filtering: show all / show only non-compliant / show by action type
- Invoke Triage Agent to explain why a specific site is flagged
- Allow the user to select a site and take an action
- Handoff to Action Agent for certify / archive / delete requests in

### 3.3 Topics

| Topic | Trigger | Behavior |
|-------|---------|---------|
| **My All Sites** | "show all my sites", "list my sites" | Call `Governor365 - Agent - List Owner Sites`; return a paginated card |
| **My At-Risk Sites** | "show my at-risk sites", "which of my sites need attention" | Call the same tool with `ComplianceStatus = NonCompliant` |
| **Site Detail** | User selects a site from list | Show full detail card; invoke Triage Agent for recommendation |
| **Filter by Action** | "show sites I need to certify", "show sites to archive" | Filter by `ComplianceAction` field |
| **Certify Site** | "certify [site name]", user taps certify button | Confirm intent → handoff to Action Agent |
| **Archive Site** | "archive [site name]", user taps archive button | Confirm intent → handoff to Action Agent |
| **Delete Site** | "delete [site name]", user taps delete button | Show warning, require explicit confirmation → handoff to Action Agent |
| **Back / Exit** | "go back", "cancel" | End or return to launcher menu |

### 3.4 Site List Card (Adaptive Card Schema)
Each site entry in the response presents:
- Site Title + URL (hyperlink)
- Last Activity Date
- Last Certification Date
- Compliance Status badge (green = COMPLIANT, red = NON-COMPLIANT)
- Recommended Action badge (CERTIFY / ARCHIVE / DELETE / ASSIGN-OWNERS / NONE)
- [Details] button → triggers site detail topic
- [Quick Certify] button (if action = CERTIFY) → quick action

### 3.5 Connections / Actions
| Connection | Purpose |
|------------|---------|
| Power Automate tool | Read Governance Site through exact active Site Owner Assignment |
| Triage Sub-Agent | Invoked for per-site triage explanation |
| Action Sub-Agent | Invoked when user confirms an action |

---

## 4. Governance Admin Agent

### 4.1 Identity & Purpose
| Field | Value |
|-------|-------|
| **Name** | Admin Agent |
| **Role** | Tenant-wide governance view, attestation oversight, and management |
| **Copilot Studio Type** | Published entry agent |
| **Invoked By** | Teams user directly, or Orchestrator launcher |

### 4.2 Responsibilities
- Call the admin-scoped Power Automate tool for tenant-wide Governance Site data
- Present aggregate compliance summary (counts by status + action type)
- Highlight orphaned sites (no owners) as highest priority
- Highlight sites that are not attested, expired, or attestation-missing
- Support filtering by Office, SubOffice, ComplianceAction, and AttestationStatus
- Allow admin to assign an owner to an orphaned site
- Allow admin to trigger action on any site (not restricted to ownership)
- Help admins decide whether a missing-owner or not-attested site should be assigned, certified, archived, or deleted

### 4.3 Topics

| Topic | Trigger | Behavior |
|-------|---------|---------|
| **Dashboard Summary** | "admin dashboard", "summary", "overview" | Query all sites, return count card: total / compliant / non-compliant / by action type |
| **All At-Risk Sites** | "show all non-compliant sites", "all at-risk sites" | Return paginated list, sorted by severity (no owners first, then archive, certify) |
| **Orphaned Sites** | "show orphaned sites", "sites with no owners" | Filter `SiteOwners IS EMPTY` |
| **Not Attested Sites** | "not attested", "attestation overdue", "sites not attested" | Filter `AttestationStatus <> ATTESTED` or `AttestationExpiresAt <= Today` |
| **Filter by Office** | "show sites from [Office]" | Filter by `Office` field |
| **Filter by Action** | "show all sites needing certification" | Filter by `ComplianceAction` |
| **Site Detail** | Admin selects a site | Full detail + triage reasoning |
| **Assign Owner** | "assign owner to [site]" | Prompt for owner UPN, handoff to Action Agent |
| **Certify / Archive / Delete** | Admin selects action on any site | Handoff to Action Agent |
| **Export Report** | "export report", "give me a CSV" | Generate an approved Power Automate export or link to the admin Power App view |

### 4.4 Summary Card Schema
```
┌────────────────────────────────────────────────────────┐
│  M365 Governance Summary — [Date]                     │
├──────────────┬──────────────┬──────────────┬──────────┤
│ Total Sites  │ Compliant    │ Non-Compliant│ Orphaned │
│   [N]        │   [N] ✅     │   [N] ⚠️     │  [N] 🔴  │
├──────────────┴──────────────┴──────────────┴──────────┤
│  BY ACTION REQUIRED                                    │
│  • CERTIFY:        [N] sites                          │
│  • ARCHIVE:        [N] sites                          │
│  • ASSIGN-OWNERS:  [N] sites                          │
│  • NOT ATTESTED:   [N] sites                          │
└────────────────────────────────────────────────────────┘
  [View Orphaned Sites]  [View Not Attested]  [View All At-Risk]  [Filter ▼]
```

### 4.5 Connections / Actions
| Connection | Purpose |
|------------|---------|
| Power Automate admin tool | Read Dataverse only after current-turn admin verification |
| Triage Sub-Agent | Per-site explanation |
| Action Sub-Agent | Execute admin-initiated actions |

---

## 5. Triage Sub-Agent

### 5.1 Identity & Purpose
| Field | Value |
|-------|-------|
| **Name** | Triage Agent |
| **Role** | Recommendation engine — explain why a site is flagged and what action is appropriate |
| **Copilot Studio Type** | Sub-agent (invoked programmatically, not directly by user) |
| **Invoked By** | Site Owner Agent, Admin Agent (when user requests site detail) |

### 5.2 Responsibilities
- Receive site data (from the calling agent's context)
- Evaluate against triage rules from Governance Policy Setting in Dataverse
- Generate a plain-language explanation of the issue
- Return a structured recommendation: action, severity, and reasoning
- In Phase 2: factor in user activity counts from M365 Usage Reports

### 5.3 Triage Logic

#### Phase 1 Rules (matching archived
`../archive/legacy-2026-09-19/fixInput.ps1` logic)

```
RULE 1 — ASSIGN-OWNERS (highest priority)
  IF SiteOwners IS EMPTY OR SiteOwners count < MinOwnerThreshold
  THEN action = ASSIGN-OWNERS, severity = CRITICAL
  reasoning = "This site has no registered owners. It cannot be managed or certified 
               without an assigned owner."

RULE 2 — ARCHIVE (stale content, no recent activity)
  IF LastActivityDate ≤ TODAY - StalenessThresholdDays (default: 1024)
  AND SiteOwners IS NOT EMPTY
  THEN action = ARCHIVE (candidate), severity = HIGH
  reasoning = "This site hasn't had any activity in over [X] days. It may contain 
               valuable historical content but is no longer being actively used."
  Note: In Phase 1, all stale sites default to ARCHIVE. In Phase 2, low-activity 
        sites are promoted to DELETE after usage analysis.

RULE 3 — CERTIFY (overdue recertification)
  IF LastCertificationDate ≤ TODAY - CertificationThresholdDays (default: 365)
  AND LastActivityDate > TODAY - StalenessThresholdDays
  AND SiteOwners IS NOT EMPTY
  THEN action = CERTIFY, severity = MEDIUM
  reasoning = "This site's annual recertification is overdue. Please confirm the 
               site is still needed and that the ownership is up to date."

RULE 4 — COMPLIANT
  IF SiteOwners IS NOT EMPTY
  AND LastCertificationDate > TODAY - CertificationThresholdDays
  AND LastActivityDate > TODAY - StalenessThresholdDays
  THEN action = NONE, severity = INFO
  reasoning = "This site is compliant. No action required."
```

#### Phase 2 Enhancements (planned)
```
RULE 2a — DELETE (stale AND low usage)
  IF LastActivityDate ≤ TODAY - StalenessThresholdDays
  AND UniqueUsersLast90Days < LowUsageThreshold (default: 5)
  THEN upgrade ARCHIVE → DELETE, severity = HIGH
  reasoning = "This site has had no activity in [X] days and fewer than [N] unique 
               users in the past 90 days. Deletion is recommended unless the content 
               has retention requirements."

RULE 5 — TOO MANY OWNERS
  IF SiteOwners count > MaxOwnerThreshold (default: 10)
  THEN action = REVIEW-OWNERS, severity = LOW
  reasoning = "This site has [N] owners, which exceeds the recommended maximum of 
               [MaxOwnerThreshold]. Consider reducing the owner list."
```

### 5.4 Output Schema (returned to calling agent)
```json
{
  "siteUrl": "https://...",
  "siteTitle": "Site Name",
  "complianceStatus": "NON-COMPLIANT",
  "recommendedAction": "CERTIFY",
  "severity": "MEDIUM",
  "reasoning": "This site's annual recertification is overdue by 187 days. ...",
  "details": {
    "lastActivityDate": "2024-09-10",
    "lastCertificationDate": "2024-06-01",
    "daysSinceActivity": 183,
    "daysSinceCertification": 285,
    "ownerCount": 2,
    "minOwnerThreshold": 1,
    "maxOwnerThreshold": 10
  }
}
```

### 5.5 Topics

| Topic | Invoked By | Behavior |
|-------|------------|---------|
| **Evaluate Site** | Owner Agent / Admin Agent | Receives site data in context; returns recommendation object |
| **Explain Recommendation** | Owner Agent / Admin Agent (user asks "why?") | Returns plain-language reasoning for the current site |

### 5.6 Connections / Actions
| Connection | Purpose |
|------------|---------|
| Power Automate evidence tool | Read active Dataverse policy and site evidence |
| *(Phase 2)* Microsoft Graph | `GET /reports/getSharePointSiteUsageDetail` — usage counts |

---

## 6. Action Sub-Agent

### 6.1 Identity & Purpose
| Field | Value |
|-------|-------|
| **Name** | Action Agent |
| **Role** | Execute governance actions and write audit log |
| **Copilot Studio Type** | Sub-agent (invoked after user confirmation) |
| **Invoked By** | Site Owner Agent, Admin Agent |

### 6.2 Responsibilities
- Receive the action request (certify / archive / delete / assign-owners) and target site URL
- Present a confirmation step before executing (especially for destructive actions)
- Call the appropriate Power Automate flow to execute the action
- Create or update the governed Dataverse request and site snapshot through Power Automate
- Append a Dataverse Governance Action Event for every state transition
- Return success/failure confirmation to the calling agent

### 6.3 Actions Supported

| Action | Trigger | Confirmation Required | What Changes |
|--------|---------|----------------------|--------------|
| **CERTIFY** | User confirms recertification | Yes (single confirm) | `LastCertificationDate` = today; `ComplianceAction` = NONE; `ComplianceStatus` = COMPLIANT (if no other issues) |
| **ARCHIVE** | User requests archival | Yes (single confirm) | Create pending request and action event; execute only after required approval |
| **DELETE** | User requests deletion review | Yes (typed confirm + approval) | Create deletion-review request; never silently delete |
| **ASSIGN-OWNERS** | Admin assigns owner to orphaned site | Yes | Create admin-authorized request; update source and Dataverse assignment only after success |

### 6.4 Confirmation Flow

```
Action Agent receives: {action: "DELETE", siteUrl: "...", siteTitle: "..."}
         │
         ▼
Present warning card:
  "⚠️ You are about to request DELETION of: [Site Title]
   URL: [URL]
   This action will be logged and sent to the admin for approval.
   Are you sure?"
   [Yes, request deletion]  [Cancel]
         │
    [Yes]▼
Present second confirmation:
  "This is irreversible once an admin approves. Type the site name to confirm: ____"
         │
    [Confirmed]▼
Call Power Automate "Action Callback Flow"
Append Governance Action Event
Return: "Your deletion request for [Site Title] has been submitted. 
         An admin will review and approve. You'll be notified when complete."
```

### 6.5 Action Event Schema
Each request state transition creates an append-only `Governance Action Event`:
```
SiteURL           : https://...
SiteTitle         : Site Name
ActionType        : CERTIFY | ARCHIVE | DELETE | ASSIGN-OWNERS
RequestedBy       : user@tenant.com
RequestedAt       : 2026-03-12T14:30:00Z
Status            : PENDING | COMPLETED | REJECTED
AdminApprover     : (admin UPN if applicable)
Notes             : free text
```

### 6.6 Power Automate Flows Called

| Flow | Action Type | What It Does |
|------|-------------|-------------|
| Action Callback Flow | CERTIFY | Completes request, updates Dataverse site snapshot, appends event |
| Action Callback Flow | ARCHIVE | Creates/advances an approval-backed Dataverse request |
| Action Callback Flow | DELETE | Sets `ComplianceAction = DELETE-REQUESTED`; creates admin approval task |
| Action Callback Flow | ASSIGN-OWNERS | Executes approved source update, then reconciles Dataverse assignment |

### 6.7 Topics

| Topic | Triggered By | Behavior |
|-------|-------------|---------|
| **Execute Certify** | Owner/Admin Agent | Single confirm → update SPO → log → confirm user |
| **Execute Archive** | Owner/Admin Agent | Single confirm → call PA flow → log → confirm user |
| **Execute Delete** | Owner/Admin Agent | Double confirm → call PA flow → log → notify admin |
| **Execute Assign Owners** | Admin Agent | Prompt for UPN → confirm → update SPO → log |
| **Action Status** | User asks "did my archive go through?" | Query caller-authorized Dataverse requests and events |

### 6.8 Connections / Actions
| Connection | Purpose |
|------------|---------|
| Power Automate request tools | Authorize and update Dataverse requests, events, and site state |
| Power Automate (HTTP action) | Trigger Action Callback Flow |

---

## 7. Notification Design (Power Automate + Adaptive Cards)

### 7.1 Owner Weekly Notification Card

```json
AdaptiveCard {
  body: [
    TextBlock: "📋 M365 Governance Alert — Sites Needing Your Attention",
    TextBlock: "Hi [Owner Name], the following sites you own require action:",
    Container (for each site):
      ColumnSet:
        Column: Site Title (link), Last Activity, Last Certified
        Column: Action Badge (CERTIFY / ARCHIVE / DELETE)
      ActionSet:
        Action.Submit: "Certify"  → sends {action: CERTIFY, siteUrl: ...}
        Action.Submit: "Archive"  → sends {action: ARCHIVE, siteUrl: ...}
        Action.Submit: "Dismiss"  → suppresses notification for this site for 30 days
  ]
}
```

### 7.2 Admin Weekly Digest Card

```json
AdaptiveCard {
  body: [
    TextBlock: "🛡️ M365 Governance Weekly Summary — [Date Range]",
    FactSet:
      Total Sites Evaluated: [N]
      Compliant: [N]
      Non-Compliant: [N]
      Orphaned (No Owners): [N]
      Certify Required: [N]
      Archive Candidates: [N]
      Delete Candidates: [N]
    TextBlock: "🔴 Orphaned Sites (require immediate attention):",
    Table (first 5 orphaned sites)
    Action.OpenUrl: "View Full Report in SharePoint"
    Action.Submit: "Start Governance Session" → opens Teams chat with agent
  ]
}
```

---

## 8. Conversation Examples

### 8.1 Owner Query Example

```
User:    "Show me my sites that need attention"

Agent:   "Hi Alex! I found 3 sites you own that need attention:
         
         1. 📁 Project Phoenix
            Last Activity: 18 months ago | Overdue certification
            Recommendation: CERTIFY — This site's certification is 400 days overdue.
            [Certify Now]  [More Details]  [Archive]
         
         2. 📁 Q3 Budget Planning
            Last Activity: 3 years ago | No recent activity
            Recommendation: ARCHIVE — This site hasn't had activity in 1,100 days.
            [Archive]  [More Details]  [Mark as Active]
         
         3. 📁 HR Onboarding 2021
            Last Activity: 4 years ago | Stale
            Recommendation: Consider DELETION — Very old and no recent users.
            [Request Deletion]  [Archive Instead]  [More Details]"

User:    "Why is Project Phoenix flagged?"

Agent:   "Project Phoenix was last certified on February 5, 2025 — that was 400 days 
          ago. Our policy requires recertification every 365 days. The site itself is 
          active (last used 18 months ago), so it just needs a quick recertification 
          to confirm it's still needed and ownership is current.
          
          Would you like to certify it now? [Certify Now]"
```

### 8.2 Admin Query Example

```
User:    "Show me the governance summary"

Agent:   "🛡️ M365 Governance Summary — March 12, 2026

          Total Sites: 8,432
          ✅ Compliant: 5,218 (61.9%)
          ⚠️ Non-Compliant: 3,214 (38.1%)
          🔴 Orphaned (No Owners): 47
          🟠 Not Attested: 312

          By required action:
          • CERTIFY: 2,841 sites
          • ARCHIVE: 326 sites  
          • ASSIGN-OWNERS: 47 sites
          • NOT ATTESTED: 312 sites

          Your highest priority: 47 orphaned sites need owners assigned, and 312 sites
          need attestation review.
          
          [View Orphaned Sites]  [View Not Attested]  [View All Non-Compliant]  [Filter by Office ▼]"
```
