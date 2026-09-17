# Governor365 release packages

## M365Governance 2.0.0.0 schema foundation

`M365Governance_2_0_0_0_managed.zip` is a managed Power Platform solution
exported from the development environment on 2026-09-17.

SHA-256:

```text
9E75CA2236E47B49A0F55F0473B6F7F75B843AA20CAF6A52949C58D54230BE15
```

The package contains all nine canonical `sb_` Dataverse tables, their columns,
local choices, lookups, and alternate keys:

1. Governance Site
2. Site Owner Assignment
3. Governance Action Request
4. Governance Action Event
5. Governance Policy Setting
6. Governance Scan Run
7. Scan Work Item
8. Notification Delivery
9. Evidence Snapshot

Validate it before import:

```powershell
.\scripts\Test-Governor365SolutionPackage.ps1 `
  -Path .\release\M365Governance_2_0_0_0_managed.zip `
  -ValidationProfile SchemaFoundation
```

This is a **schema-foundation package**, not the complete application package.
It intentionally does not claim to contain the replacement Power Automate
flows or reviewed Copilot Studio agents. Those components remain an open
functional-cutover gate. The validator's default `Complete` profile will reject
this package until those components are included.

Do not import the legacy `Governor365` 1.0, `M365GovMan` 1.0,
`M365Governance_1_0_0_1.zip`, or `SPAdminExport_1_0_0_1.zip` as the Dataverse
target release.
