---
name: owner-site-portfolio
description: Review SharePoint sites owned by the signed-in user, including all owned sites, sites needing attention, and details for one owned site. Use for requests such as my sites, what do I own, sites needing attention, or details about my site.
---

# Owner site portfolio

Use the signed-in user's verified principal name as `callerUPN`. Never accept a user-supplied UPN as the owner scope.

## Required tools

- `GovernanceData-ListOwnerSites`: list Dataverse Governance Site rows related
  to an active exact Site Owner Assignment for `callerUPN`; accepts paging.
- `GovernanceData-GetSite`: load one site by item ID or canonical URL and enforce owner scope.

If a required tool is unavailable or fails, say that live governance data couldn't be loaded. Never substitute sample sites or invented values.

## Procedure

1. Determine whether the user wants all owned sites, only sites needing attention, or one site's details.
2. Call the appropriate tool with `callerUPN` on every request.
3. For lists, return at most 10 items at a time. Include title, URL, inventory status, site type, last activity date, office, and owner count.
4. For details, resolve ambiguity before loading the record. Do not disclose a record unless the owner-scoped tool confirms access.
5. Offer request archive, request deletion review, contact support, or check request status. Never offer attestation or certification.

## Edge cases

- No sites: state that no governed sites list the caller as an owner.
- Multiple title matches: show the matching titles and canonical URLs and ask the user to choose.
- More results: preserve the current filters and request the next page from the tool.
- Admin-only request: direct the user to the Governance Admin Agent without exposing tenant-wide data.

Use plain business language. Do not expose internal SharePoint field names unless the user asks for technical detail.