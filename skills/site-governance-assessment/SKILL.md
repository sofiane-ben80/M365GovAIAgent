---
name: site-governance-assessment
description: Explain a SharePoint site's compliance state, severity, and recommended governance action from a live site record and policy thresholds. Use when a user asks why a site is flagged, what action is recommended, or whether a site is compliant.
---

# Site governance assessment

Assess only data returned by an authorized governance data tool. Do not retrieve a broader record or change authorization scope.

## Inputs

Use the live site record and policy values from `GovernanceData-GetGovernanceConfig`. Defaults may be used only when the tool confirms a setting is absent:

- `CertificationThresholdDays`: 365
- `StalenessThresholdDays`: 1024
- `MinOwnerCount`: 1

Compute `effectiveOwnerCount` as the greater of direct SharePoint owners and M365 Group owners when both values are available.

## Rules

Apply the first matching rule:

1. **CRITICAL / ASSIGN-OWNERS** when `effectiveOwnerCount < MinOwnerCount`.
2. **HIGH / ARCHIVE** when inactivity exceeds `StalenessThresholdDays` and the site has enough owners.
3. **MEDIUM / CERTIFY** when certification is missing or older than `CertificationThresholdDays`, after the earlier rules are excluded.
4. **INFO / NONE** otherwise.

## Response

Return a concise explanation containing:

- compliance status and severity;
- the live facts that triggered the rule;
- the threshold used;
- the recommended next action;
- relevant M365 Group, Teams, or Planner dependencies when present.

Distinguish missing data from zero. If required dates or counts are unavailable, state that the assessment is incomplete and do not infer compliance. Never claim that an action was executed.