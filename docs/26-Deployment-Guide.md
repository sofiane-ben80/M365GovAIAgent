# 26 - Deployment Guide

This guide deploys Governor365 into a Power Platform environment and then
populates its Dataverse inventory from SharePoint Online. Complete the steps in
order. Do not substitute the legacy `M365Governance_1_0_0_1.zip`,
`SPAdminExport_1_0_0_1.zip`, `Governor365` 1.0, or `M365GovMan` 1.0 exports:
those packages contain SharePoint-backed proof-of-concept components and do
not implement the target architecture.

## 1. Choose the correct solution

Two similarly named solutions may appear in the development environment:

| Solution | Version | Prefix | Tables | Status |
|---|---:|---|---:|---|
| `Governor365` | 1.0.0.0 | `sof` | 1 legacy SharePoint Sites table | Legacy proof of concept |
| `M365Governance` | 2.0.0.0 | `sb` | 9 canonical governance tables | Current schema foundation |

If you see only one table, you are looking at the legacy `Governor365`
solution. Open or import `M365Governance` 2.0.0.0 instead. Its nine tables are
listed in the [canonical data model](04-DataModel.md).

## 2. Release contents

A deployable release consists of:

1. `Governor365_<version>_managed.zip`, exported from the development
   environment after all solution gates pass;
2. `scripts/Test-Governor365SolutionPackage.ps1`;
3. `scripts/Invoke-DataverseGovernanceScan.ps1`; and
4. the release notes and SHA-256 checksum for the managed ZIP.

The managed solution must contain:

- all nine Dataverse tables in the [canonical data model](04-DataModel.md);
- choices, relationships, alternate keys, forms, views, security roles, and
  access-team configuration;
- solution-aware Power Automate flows and child flows;
- Copilot Studio agents and their tool bindings;
- connection references and environment variable definitions; and
- any Power Apps and Adaptive Card assets included in the release.

The repository currently includes
`release/M365Governance_2_0_0_0_managed.zip`. This managed schema-foundation
package contains all nine tables, columns, choices, lookups, and alternate
keys. It does not contain the replacement flows or reviewed agents.

> **Current functional-release gate:** an end-to-end deployment must wait for
> the target flows and agents to be included and acceptance-tested. Do not
> rename the schema-only or a legacy ZIP and treat it as the complete package.

## 3. Prerequisites

The deployment operator needs:

- Power Platform System Administrator or Environment Maker plus the privileges
  required to import solutions and configure connections;
- SharePoint Administrator for tenant inventory;
- Power Platform CLI (`pac`) for command-line import, or access to the Power
  Apps maker portal;
- PowerShell 7;
- PnP.PowerShell;
- either Az.Accounts, Azure CLI, or a caller-supplied Dataverse access token;
- an Entra application registration for PnP interactive authentication; and
- approved Dataverse, Microsoft 365 Users, Approvals, Teams, Outlook, and
  governed Graph/SharePoint connector connections.

The PnP application must have the least privileges required to enumerate
tenant sites, read Microsoft 365 group owners, and read each site's associated
SharePoint Owners group. The deployment account must be allowed to consent to
those permissions.

## 4. Validate the release package

Validate the currently published schema foundation with:

```powershell
.\scripts\Test-Governor365SolutionPackage.ps1 `
  -Path .\release\M365Governance_2_0_0_0_managed.zip `
  -ValidationProfile SchemaFoundation
```

This must report `Managed = True`, `RequiredTables = 9`, and
`ValidationProfile = SchemaFoundation`.

For a future complete package, use the default strict validation:

From the repository root:

```powershell
.\scripts\Test-Governor365SolutionPackage.ps1 `
  -Path .\release\Governor365_2_0_0_0_managed.zip
```

The command must report `Managed = True`, nine required tables, at least one
cloud flow, at least one Copilot agent, and a SHA-256 hash. Compare the hash to
the release notes. Stop if validation fails.

## 5. Import the managed solution

### Power Apps maker portal

1. Open `https://make.powerapps.com`.
2. Select the target environment.
3. Open **Solutions**, select **Import solution**, and choose the validated
   `M365Governance_<version>_managed.zip`.
4. Select **Next** and review dependencies.
5. Map every connection reference to an approved connection.
6. Enter environment-variable values for the target tenant, SharePoint admin
   URL, Dataverse URL, governance administrator group, notification settings,
   and governed API endpoints.
7. Select **Import** and wait for a successful result.
8. Open the imported solution and confirm no component is missing.

### Power Platform CLI

```powershell
pac auth create `
  --environment "https://contoso.crm.dynamics.com"

pac solution import `
  --path .\release\M365Governance_2_0_0_0_managed.zip `
  --publish-changes
```

Use a deployment settings file for automated environments when connection
references or environment variables must be mapped non-interactively. Never
store connection secrets or access tokens in the repository.

## 6. Configure and activate components

1. Confirm that all nine tables exist and that their logical names, choices,
   lookups, and alternate keys match the data model.
2. Assign the Governor365 administrator and automation security roles.
3. Configure the Governance Site access-team template if owner-facing Power
   Apps read Dataverse directly.
4. Verify each connection reference and environment variable.
5. Turn on child flows first, then request/notification flows, and finally:
   - `Governor365 - Inventory - Process Work Item`;
   - `Governor365 - Inventory - Finalize Scan`; and
   - `Governor365 - Inventory - Start Scan`.
6. Keep scheduled inventory disabled until the bootstrap scan and acceptance
   tests succeed.
7. Open every imported Copilot Studio agent, resolve connection prompts, verify
   tool bindings, and publish only after authorization tests pass.

Do not continue to flow and agent activation after importing the current
schema-foundation package; those components are not included yet.

## 7. Run the backend inventory scanner

Install PnP.PowerShell if it is not already available:

```powershell
Install-Module PnP.PowerShell -Scope CurrentUser
```

Authenticate Az.Accounts or Azure CLI for Dataverse:

```powershell
Connect-AzAccount -Tenant "<tenant-guid>"
```

First perform a read-only discovery:

```powershell
.\scripts\Invoke-DataverseGovernanceScan.ps1 `
  -AdminUrl "https://contoso-admin.sharepoint.com" `
  -DataverseUrl "https://contoso.crm.dynamics.com" `
  -TenantId "<tenant-guid>" `
  -ClientId "<pnp-application-guid>" `
  -WhatIf
```

Then write a bounded development sample:

```powershell
.\scripts\Invoke-DataverseGovernanceScan.ps1 `
  -AdminUrl "https://contoso-admin.sharepoint.com" `
  -DataverseUrl "https://contoso.crm.dynamics.com" `
  -TenantId "<tenant-guid>" `
  -ClientId "<pnp-application-guid>" `
  -SiteLimit 5
```

Verify the scan run, five site records, normalized active owner assignments,
choice values, and owner counts. A bounded scan never changes lifecycle state
for sites it did not observe.

After the bounded test succeeds, run the complete inventory by omitting
`-SiteLimit`:

```powershell
.\scripts\Invoke-DataverseGovernanceScan.ps1 `
  -AdminUrl "https://contoso-admin.sharepoint.com" `
  -DataverseUrl "https://contoso.crm.dynamics.com" `
  -TenantId "<tenant-guid>" `
  -ClientId "<pnp-application-guid>"
```

Do not set `-IncludeSiteOwnerGroups:$false` for an authorization-ready
inventory. That switch omits SharePoint Owners-group members.

## 8. Validate the deployment

1. Confirm the full scan ends as `Completed`, not `CompletedWithErrors`.
2. Run the full scan a second time and confirm alternate keys prevent duplicate
   sites, assignments, and scan work.
3. Rename a test site and confirm its stable Microsoft 365 site ID retains the
   same Governance Site row.
4. Add and remove a test owner; confirm assignments are activated or
   deactivated only after authoritative owner discovery succeeds.
5. Confirm certification, suppression, and workflow-owned fields survive an
   inventory refresh.
6. Run every test in the
   [Power Automate acceptance suite](12-PowerAutomate-Build-Guide.md#10-acceptance-tests).
7. Confirm Owner A cannot retrieve Owner B's site.
8. Confirm a non-admin cannot retrieve the admin dashboard.
9. Confirm failed dependencies return explicit errors without legacy fallback.
10. Publish the agents and enable the recurring Start Scan flow only after all
    tests pass.

## 9. Rollback

Before importing an upgrade, retain the previously imported managed package
and record the active connection/environment configuration. If validation
fails:

1. disable recurring and request-processing flows;
2. unpublish or restore the previously verified agents;
3. import the prior managed solution version using the platform's supported
   upgrade path; and
4. preserve Dataverse inventory and audit rows unless the rollback plan
   explicitly requires data removal.

Never use the legacy SharePoint-list flows as an automatic fallback.
