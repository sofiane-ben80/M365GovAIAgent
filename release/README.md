# Governor365 release packages

## M365Governance 2.0.0.0 integrated release

`M365Governance_2_0_0_0_managed.zip` is a managed Power Platform solution
exported from the published development environment on 2026-09-22.

SHA-256:

```text
41B18FAFE3A6576E1C89F3611FA1154CD7B3239D5F6692E33E852402700C731E
```

The package contains:

- 10 Dataverse tables;
- five security roles;
- 11 distinct Power Automate cloud flows;
- one Canvas app;
- eight Copilot Studio agents and 105 bot components;
- 11 environment variables and six connection references;
- one Governance Site owner access-team template; and
- the `Governor365.AgentChat` PCF control.

The package has 22 unique flow-bound agent components and 23 topic-to-flow
relationships. These references reuse the 11 cloud flows and must not be
reported as additional flows.

Validate it before import:

```powershell
.\scripts\Test-Governor365SolutionPackage.ps1 `
  -Path .\release\M365Governance_2_0_0_0_managed.zip
```

Power Apps Solution Checker reports zero critical findings, zero high findings,
and one medium aggregate finding for five Canvas formula warnings. Review
those warnings in Power Apps Studio after import.

Five target-catalog flows remain design-only: Inventory Process Work Item,
Inventory Finalize Scan, Owner Digest, Admin Summary, and Card Response.
`Governor365 - Inventory - Start Scan` intentionally remains off until its
worker and finalizer are implemented and tested.

Do not import the legacy `Governor365` 1.0, `M365GovMan` 1.0,
`M365Governance_1_0_0_1.zip`, or `SPAdminExport_1_0_0_1.zip` as the Dataverse
target release.
