---
name: admin-governance-review
description: Review tenant-wide SharePoint governance health, including dashboard counts, noncompliant sites, orphaned sites, missing or expired attestations, and one site's details. Use only for a user whose Governance Admin role is verified in the current conversation.
---

# Admin governance review

Activate `verify-governance-admin` before retrieving tenant-wide data.

## Required tools

- `GovernanceData-GetAdminDashboard`: return aggregate counts by compliance, recommended action, ownership, and attestation state.
- `GovernanceData-ListAdminSites`: return paged sites using approved filters.
- `GovernanceData-GetSite`: return one full site record in admin scope.

If a required tool is unavailable or fails, say that live governance data couldn't be loaded. Never render the hard-coded counts or sample records from legacy topics.

## Procedure

1. Map the request to dashboard, noncompliant, orphaned, not-attested/expired, or site detail.
2. Use only approved filter dimensions: compliance status/action, owner count, attestation status, office, suboffice, site type, or canonical site identity.
3. Return at most 10 site rows per page, prioritized by severity and oldest activity/certification.
4. Include title, canonical URL, status, recommended action, owner count, attestation status, and relevant dates.
5. Use `site-governance-assessment` when the user asks why a site is flagged.
6. Offer owner assignment only for ownership gaps, and disposition/certification only after loading the selected live record.

Lead with business impact and remediation. Do not expose connector configuration or unrestricted raw list payloads.