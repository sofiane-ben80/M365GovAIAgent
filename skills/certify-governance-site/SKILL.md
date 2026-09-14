---
name: certify-governance-site
description: Certify a governed SharePoint site after resolving the site, verifying the caller is authorized, showing the current live record, and obtaining explicit confirmation. Use when an owner or governance admin asks to certify or recertify a site.
---

# Certify a governance site

## Required tools

- `GovernanceData-GetSite`: resolve the site and return its item ID, canonical URL, title, owners, and current compliance values.
- `GovernanceAgent-ActionCallback`: execute and audit the certification.

## Procedure

1. Resolve the requested site from its item ID, canonical URL, or an unambiguous title.
2. Verify authorization against the live record. Owners must be listed as an owner. Admins must have a successful `GovernanceAgent-CheckAdminRole` result from the current conversation.
3. Show the site title, canonical URL, current owners, last certification date, and current recommended action.
4. Ask: "Certify this site now?" Treat only an explicit affirmative answer in the current turn as confirmation.
5. Call `GovernanceAgent-ActionCallback` with:
   - `callerUPN`, `actionType: CERTIFY`, `siteUrl`, `siteTitle`, `siteItemId`;
   - `previousComplianceStatus` and `previousComplianceAction` from the live record;
   - blank `targetOwnerUPN` and `confirmationText`.
6. Report success only when `success` is true. Preserve the returned distinction between `COMPLETED`, `PENDING`, `REJECTED`, and `FAILED`.

Never certify from a typed title alone, skip the authorization check, reuse confirmation from an earlier request, or write directly to SharePoint.