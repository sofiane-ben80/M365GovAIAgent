# SQL and Canvas Design Audit

Audit date: 2026-08-26

> **Historical proof-of-concept audit:** The approved target now uses Dataverse
> and Power Automate. Keep this document as migration evidence only. Do not use
> its SQL recommendations for new production implementation. See
> [23-Power-Platform-Refactor.md](23-Power-Platform-Refactor.md).

## Decision

The current requirement is valid: ownership is an application filter, not a SQL authorization boundary. Users may query either their directly owned sites or the full inventory. The application remains read-only.

For a large inventory, keep the normalized `[ECS_M365].[DOI-SP-SiteOwners]` table and `[ECS_M365].[DOI-SP-AccessibleSites]` view. They are scale-oriented query structures, not security structures. Do not filter the semicolon-delimited `Owners` value in a Canvas collection.

## Live SQL Findings

Before remediation, the database contained 86 site rows and 96 normalized owner rows. The owner mapping exactly matched the parsed `Owners` values: zero missing, stale, duplicate, malformed, or orphaned mappings.

The live database had drifted from the filter-only design:

- Enabled `[ECS_M365].[SiteOwnerAccessPolicy]` RLS limited the app user to 49 base-table rows.
- The app user had `SELECT` on the base table but not on the accessible view, which prevented the view from appearing as a usable Power Apps data source.
- The owner table primary key was `(GovernID, OwnerUpn)` and its secondary index used the same order. There was no owner-leading access path.
- Bureau activity and creation browse indexes were absent, and the bureau title index did not have the intended key order.

`canvas-app/sql/004-align-filter-only-access.sql` was applied successfully. After remediation:

- No site RLS policy, predicate function, or user-bureau mapping table remains.
- The app user can read 86 all-site rows and 49 directly owned rows through the view.
- The app user cannot query the owner mapping table directly.
- The owner primary key is `(OwnerUpn, GovernID)` and the reverse index is `(GovernID, OwnerUpn)`.
- Bureau title, activity, and creation indexes exist and are enabled.

The SQL server currently has public network access enabled, TLS 1.2 minimum, and an approved private endpoint. Public access is unrelated to the filter-only authorization decision and should be disabled again after interactive Studio/database work is complete.

## Canvas Package Findings

The newest repository artifacts by timestamp are `canvas-app/dist/MySitesDashboard-filtered.*` and `canvas-app/dist/MySitesDashboard-owner-filter-v3.*`; each pair is byte-identical.

These artifacts are not valid large-inventory builds. Their executable `Src/Screen1.fx.yaml` and connection metadata still reference `[ECS_M365].[DOI-SP-Sites]`, collect owner rows locally, and scan `Owners`. The embedded preview `.pa.yaml` references the accessible view, but that does not change the executable app. At a large site count, the app can omit owned sites beyond the Canvas row limit.

`canvas-app/Pack-OwnerGovernanceApp.ps1` now rejects an output unless both the executable formulas and connection metadata use `ECS_M365.DOI-SP-AccessibleSites` and no inventory collection/base-table owner filter remains.

## Remaining Package Action

1. Open the current app in Power Apps Studio using the same Entra SQL connection.
2. Add `[ECS_M365].[DOI-SP-AccessibleSites]`, which is now granted and discoverable.
3. Apply the formulas from `canvas-app/src/Src/Screen1.pa.yaml` in Studio.
4. Save, publish, and export the app.
5. Unpack the Studio export into `canvas-app/src`, then run `canvas-app/Pack-OwnerGovernanceApp.ps1`.
6. Validate with the Canvas data row limit set to 1 before replacing the deployed app.

Do not revoke the existing base-table `SELECT` grant until the deployed app has been replaced and the view-based smoke test passes. After that cutover, revoking direct base-table access is recommended to prevent regression to client-side inventory scans.