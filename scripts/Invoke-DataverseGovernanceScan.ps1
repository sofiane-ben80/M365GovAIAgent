<#
.SYNOPSIS
    Scans SharePoint Online and reconciles the Governor365 Dataverse inventory.

.DESCRIPTION
    Discovers tenant sites with PnP.PowerShell and writes site snapshots and
    normalized owner assignments to Dataverse. The script:

      - creates and completes a Governance Scan Run;
      - upserts Governance Site by the tenant/site alternate key;
      - upserts Site Owner Assignment rows;
      - deactivates assignments only after owner discovery succeeds;
      - marks unobserved sites Unknown only after a fully successful scan; and
      - preserves certification and notification fields owned by other flows.

    This is the supported bootstrap and migration scanner. The production target
    remains the solution-aware Power Automate inventory pipeline documented in
    docs/12-PowerAutomate-Build-Guide.md.

.PARAMETER AdminUrl
    SharePoint Online administration center URL.

.PARAMETER DataverseUrl
    Dataverse environment URL, without an API path.

.PARAMETER TenantId
    Entra tenant GUID written to the Governance Site alternate key.

.PARAMETER ClientId
    Entra application ID used by PnP.PowerShell interactive authentication.

.PARAMETER DataverseAccessToken
    Optional Dataverse OAuth bearer token. When omitted, the script obtains a
    token from Az.Accounts or Azure CLI. The token is never written to disk.

.PARAMETER IncludeSiteOwnerGroups
    Connect to each site and include members of its associated SharePoint
    Owners group. Disable only for a faster, deliberately incomplete bootstrap
    scan that captures M365 group owners but is not authorization-complete.

.PARAMETER WhatIf
    Performs bounded tenant site discovery without writing Dataverse.

.EXAMPLE
    .\Invoke-DataverseGovernanceScan.ps1 `
      -AdminUrl "https://contoso-admin.sharepoint.com" `
      -DataverseUrl "https://contoso.crm.dynamics.com" `
      -TenantId "00000000-0000-0000-0000-000000000000" `
      -ClientId "00000000-0000-0000-0000-000000000000"

.EXAMPLE
    .\Invoke-DataverseGovernanceScan.ps1 `
      -AdminUrl "https://contoso-admin.sharepoint.com" `
      -DataverseUrl "https://contoso.crm.dynamics.com" `
      -TenantId "00000000-0000-0000-0000-000000000000" `
      -ClientId "00000000-0000-0000-0000-000000000000" `
      -IncludeSiteOwnerGroups:$false -WhatIf
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^https://[^/]+-admin\.sharepoint\.com/?$')]
    [string] $AdminUrl,

    [Parameter(Mandatory)]
    [ValidatePattern('^https://[^/]+\.crm\d*\.dynamics\.com/?$')]
    [string] $DataverseUrl,

    [Parameter(Mandatory)]
    [ValidateScript({
        $parsedGuid = [guid]::Empty
        [guid]::TryParse([string]$_, [ref]$parsedGuid)
    })]
    [string] $TenantId,

    [Parameter(Mandatory)]
    [ValidateScript({
        $parsedGuid = [guid]::Empty
        [guid]::TryParse([string]$_, [ref]$parsedGuid)
    })]
    [string] $ClientId,

    [securestring] $DataverseAccessToken,

    [bool] $IncludeSiteOwnerGroups = $true,

    [ValidateRange(1, 20)]
    [int] $MaximumRetryCount = 6,

    [ValidateRange(0, 10000)]
    [int] $SiteLimit,

    [string] $GovernanceSiteEntitySet = "sb_governancesites",
    [string] $OwnerAssignmentEntitySet = "sb_siteownerassignments",
    [string] $ScanRunEntitySet = "sb_governancescanruns"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$DataverseUrl = $DataverseUrl.TrimEnd("/")
$AdminUrl = $AdminUrl.TrimEnd("/")
$apiRoot = "$DataverseUrl/api/data/v9.2"
$observedAt = [datetime]::UtcNow
$scanRunId = [guid]::NewGuid()
$correlationId = [guid]::NewGuid()
$choiceCache = @{}

function ConvertTo-PlainText {
    param([Parameter(Mandatory)] $Value)

    if ($Value -is [securestring]) {
        $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Value)
        try {
            return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
        }
        finally {
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)
        }
    }

    return [string]$Value
}

function Get-DataverseToken {
    if ($null -ne $DataverseAccessToken) {
        return ConvertTo-PlainText -Value $DataverseAccessToken
    }

    $azAccounts = Get-Module -ListAvailable -Name Az.Accounts |
        Sort-Object Version -Descending |
        Select-Object -First 1
    if ($null -ne $azAccounts) {
        Import-Module Az.Accounts -ErrorAction Stop
        $token = Get-AzAccessToken -ResourceUrl $DataverseUrl -TenantId $TenantId
        return ConvertTo-PlainText -Value $token.Token
    }

    $azCommand = Get-Command az -ErrorAction SilentlyContinue
    if ($null -ne $azCommand) {
        $tokenResult = & $azCommand.Source account get-access-token `
            --resource $DataverseUrl `
            --tenant $TenantId `
            --output json |
            ConvertFrom-Json
        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($tokenResult.accessToken)) {
            throw "Azure CLI could not acquire a Dataverse access token."
        }
        return [string]$tokenResult.accessToken
    }

    throw "Provide -DataverseAccessToken, install Az.Accounts, or sign in with Azure CLI."
}

function Invoke-DataverseRequest {
    param(
        [Parameter(Mandatory)]
        [ValidateSet("GET", "POST", "PATCH")]
        [string] $Method,

        [Parameter(Mandatory)]
        [string] $RelativeUrl,

        [hashtable] $Body
    )

    $headers = @{
        Authorization      = "Bearer $script:accessToken"
        Accept             = "application/json"
        "OData-MaxVersion" = "4.0"
        "OData-Version"    = "4.0"
    }

    $invokeParameters = @{
        Method      = $Method
        Uri         = "$apiRoot/$RelativeUrl"
        Headers     = $headers
        ErrorAction = "Stop"
    }
    if ($null -ne $Body) {
        $headers["Content-Type"] = "application/json; charset=utf-8"
        $invokeParameters.Body = $Body | ConvertTo-Json -Depth 10 -Compress
    }

    for ($attempt = 1; $attempt -le $MaximumRetryCount; $attempt++) {
        try {
            return Invoke-RestMethod @invokeParameters
        }
        catch {
            $statusCode = $null
            if ($null -ne $_.Exception.Response) {
                $statusCode = [int]$_.Exception.Response.StatusCode
            }

            $retryable = $statusCode -eq 429 -or $statusCode -eq 408 -or
                ($statusCode -ge 500 -and $statusCode -le 599)
            if (-not $retryable -or $attempt -eq $MaximumRetryCount) {
                throw
            }

            $delaySeconds = [Math]::Min(60, [Math]::Pow(2, $attempt))
            Write-Warning "Dataverse returned HTTP $statusCode. Retrying in $delaySeconds seconds."
            Start-Sleep -Seconds $delaySeconds
        }
    }
}

function Escape-ODataString {
    param([AllowEmptyString()][string] $Value)
    return $Value.Replace("'", "''")
}

function ConvertTo-DataverseDate {
    param($Value)
    if ($null -eq $Value) {
        return $null
    }
    $date = [datetime]$Value
    if ($date -eq [datetime]::MinValue) {
        return $null
    }
    return $date.ToUniversalTime().ToString("o")
}

function Get-ChoiceValue {
    param(
        [Parameter(Mandatory)][string] $TableLogicalName,
        [Parameter(Mandatory)][string] $ColumnLogicalName,
        [Parameter(Mandatory)][string] $Label
    )

    $cacheKey = "$TableLogicalName|$ColumnLogicalName|$Label"
    if ($choiceCache.ContainsKey($cacheKey)) {
        return $choiceCache[$cacheKey]
    }

    $metadataUrl = "EntityDefinitions(LogicalName='$TableLogicalName')" +
        "/Attributes(LogicalName='$ColumnLogicalName')" +
        "/Microsoft.Dynamics.CRM.PicklistAttributeMetadata?" +
        "`$select=LogicalName&`$expand=OptionSet(`$select=Options)"
    $metadata = Invoke-DataverseRequest -Method GET -RelativeUrl $metadataUrl

    $matchingOptions = @($metadata.OptionSet.Options | Where-Object {
        $localizedLabels = @($_.Label.LocalizedLabels | ForEach-Object { $_.Label })
        $localizedLabels -contains $Label -or $_.Label.UserLocalizedLabel.Label -eq $Label
    })
    if ($matchingOptions.Count -ne 1) {
        throw "Choice '$TableLogicalName.$ColumnLogicalName' has $($matchingOptions.Count) options labelled '$Label'."
    }

    $choiceCache[$cacheKey] = [int]$matchingOptions[0].Value
    return $choiceCache[$cacheKey]
}

function Get-PnPPropertyValue {
    param(
        [Parameter(Mandatory)] $InputObject,
        [Parameter(Mandatory)][string[]] $Names
    )
    foreach ($name in $Names) {
        $property = $InputObject.PSObject.Properties[$name]
        if ($null -ne $property -and $null -ne $property.Value) {
            return $property.Value
        }
    }
    return $null
}

function Get-NormalizedOwner {
    param(
        [Parameter(Mandatory)] $Principal,
        [Parameter(Mandatory)][ValidateSet("SharePoint", "M365Group")] [string] $Source
    )

    $upn = Get-PnPPropertyValue -InputObject $Principal -Names @(
        "UserPrincipalName", "Email", "Mail", "LoginName"
    )
    if ([string]::IsNullOrWhiteSpace([string]$upn)) {
        return $null
    }

    $upn = [string]$upn
    if ($upn.Contains("|")) {
        $upn = $upn.Split("|")[-1]
    }
    $upn = $upn.Trim().ToLowerInvariant()
    if ($upn -notmatch '^[^@\s]+@[^@\s]+\.[^@\s]+$') {
        return $null
    }

    $objectId = Get-PnPPropertyValue -InputObject $Principal -Names @("Id", "UserId")
    $parsedObjectId = [guid]::Empty
    if ($null -eq $objectId -or
        -not [guid]::TryParse([string]$objectId, [ref]$parsedObjectId)) {
        $objectId = $null
    }
    $displayName = Get-PnPPropertyValue -InputObject $Principal -Names @(
        "DisplayName", "Title"
    )

    return [pscustomobject]@{
        UPN        = $upn
        ObjectId   = if ($null -ne $objectId) { [string]$objectId } else { $null }
        DisplayName = if ($null -ne $displayName) { [string]$displayName } else { $null }
        Source     = $Source
    }
}

function Get-SiteOwners {
    param(
        [Parameter(Mandatory)] $TenantSite,
        [Parameter(Mandatory)] $AdminConnection
    )

    $owners = [System.Collections.Generic.List[object]]::new()
    $groupId = Get-PnPPropertyValue -InputObject $TenantSite -Names @("GroupId")

    if ($null -ne $groupId -and [guid]$groupId -ne [guid]::Empty) {
        $groupOwners = @(Get-PnPMicrosoft365GroupOwner `
            -Identity ([string]$groupId) `
            -Connection $AdminConnection `
            -ErrorAction Stop)
        foreach ($groupOwner in $groupOwners) {
            $owner = Get-NormalizedOwner -Principal $groupOwner -Source "M365Group"
            if ($null -ne $owner) {
                $owners.Add($owner)
            }
        }
    }

    if ($IncludeSiteOwnerGroups) {
        $siteConnection = Connect-PnPOnline `
            -Url ([string]$TenantSite.Url) `
            -ClientId $ClientId `
            -Tenant $TenantId `
            -Interactive `
            -PersistLogin `
            -ReturnConnection

        $ownerGroup = Get-PnPGroup -AssociatedOwnerGroup -Connection $siteConnection
        if ($null -ne $ownerGroup) {
            $groupMembers = @(Get-PnPGroupMember `
                -Group $ownerGroup `
                -Connection $siteConnection)
            foreach ($member in $groupMembers) {
                $owner = Get-NormalizedOwner -Principal $member -Source "SharePoint"
                if ($null -ne $owner) {
                    $owners.Add($owner)
                }
            }
        }

    }

    return @($owners |
        Group-Object { "$($_.Source)|$($_.UPN)" } |
        ForEach-Object { $_.Group[0] })
}

function Get-SiteType {
    param($TenantSite)

    $groupId = Get-PnPPropertyValue -InputObject $TenantSite -Names @("GroupId")
    if ($null -ne $groupId -and [guid]$groupId -ne [guid]::Empty) {
        return "Group"
    }

    $template = [string](Get-PnPPropertyValue -InputObject $TenantSite -Names @("Template"))
    if ($template -like "SITEPAGEPUBLISHING*") {
        return "Communication"
    }
    if ($template -match '^(STS|WIKI|BLOG|PUBLISHING)') {
        return "Classic"
    }
    return "Other"
}

function Get-ExternalSharingLabel {
    param($TenantSite)

    $sharing = [string](Get-PnPPropertyValue `
        -InputObject $TenantSite `
        -Names @("SharingCapability"))
    switch ($sharing) {
        "Disabled" { return "Disabled" }
        "ExternalUserSharingOnly" { return "NewAndExistingGuests" }
        "ExternalUserAndGuestSharing" { return "Anyone" }
        "ExistingExternalUserSharingOnly" { return "ExistingGuests" }
        default { return "Unknown" }
    }
}

function Get-GovernanceRecommendation {
    param(
        [int] $OwnerCount,
        [nullable[datetime]] $LastActivityAt,
        [nullable[datetime]] $LastCertifiedAt
    )

    if ($OwnerCount -lt 1) {
        return @{
            Compliance = "NonCompliant"
            Action     = "AssignOwners"
            Reason     = "No active owner assignment was discovered."
        }
    }
    if ($null -ne $LastActivityAt -and $LastActivityAt -le [datetime]::UtcNow.AddMonths(-36)) {
        return @{
            Compliance = "NonCompliant"
            Action     = "Archive"
            Reason     = "No authoritative activity was observed within 36 months."
        }
    }
    if ($null -eq $LastCertifiedAt -or $LastCertifiedAt -le [datetime]::UtcNow.AddMonths(-12)) {
        return @{
            Compliance = "NonCompliant"
            Action     = "Certify"
            Reason     = "Certification is missing or older than 12 months."
        }
    }
    return @{
        Compliance = "Compliant"
        Action     = "None"
        Reason     = "Owner, activity, and certification checks passed."
    }
}

function Get-ExistingSite {
    param(
        [Parameter(Mandatory)][string] $M365SiteId
    )

    $tenant = Escape-ODataString $TenantId
    $siteId = Escape-ODataString $M365SiteId
    $query = "${GovernanceSiteEntitySet}?" +
        "`$select=sb_governancesiteid,sb_lastcertifiedat" +
        "&`$filter=sb_tenantid eq '$tenant' and sb_m365siteid eq '$siteId'"
    $response = Invoke-DataverseRequest -Method GET -RelativeUrl $query
    $matches = @($response.value)
    if ($matches.Count -gt 1) {
        throw "Duplicate Governance Site rows exist for tenant '$TenantId' and site '$M365SiteId'."
    }
    if ($matches.Count -eq 1) {
        return $matches[0]
    }
    return $null
}

function Set-OwnerAssignments {
    param(
        [Parameter(Mandatory)][guid] $GovernanceSiteId,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]] $Owners
    )

    $sourceValues = @{
        SharePoint = Get-ChoiceValue `
            -TableLogicalName "sb_siteownerassignment" `
            -ColumnLogicalName "sb_ownershipsource" `
            -Label "SharePoint"
        M365Group = Get-ChoiceValue `
            -TableLogicalName "sb_siteownerassignment" `
            -ColumnLogicalName "sb_ownershipsource" `
            -Label "M365Group"
    }
    $observedKeys = @{}

    foreach ($owner in $Owners) {
        $sourceValue = $sourceValues[$owner.Source]
        $ownerKey = "$sourceValue|$($owner.UPN)"
        $observedKeys[$ownerKey] = $true
        $escapedUpn = Escape-ODataString $owner.UPN
        $query = "${OwnerAssignmentEntitySet}?" +
            "`$select=sb_siteownerassignmentid" +
            "&`$filter=_sb_site_value eq $GovernanceSiteId" +
            " and sb_principalupn eq '$escapedUpn'" +
            " and sb_ownershipsource eq $sourceValue"
        $existing = @((
            Invoke-DataverseRequest -Method GET -RelativeUrl $query
        ).value)

        $body = @{
            "sb_site@odata.bind" = "/$GovernanceSiteEntitySet($GovernanceSiteId)"
            sb_principalupn      = $owner.UPN
            sb_ownershipsource  = $sourceValue
            sb_isactive         = $true
            sb_observedat       = ConvertTo-DataverseDate $observedAt
            "sb_lastscanrun@odata.bind" = "/$ScanRunEntitySet($scanRunId)"
        }
        if (-not [string]::IsNullOrWhiteSpace($owner.ObjectId)) {
            $body.sb_principalobjectid = $owner.ObjectId
        }
        if (-not [string]::IsNullOrWhiteSpace($owner.DisplayName)) {
            $body.sb_displayname = $owner.DisplayName
        }

        if ($existing.Count -gt 1) {
            throw "Duplicate owner assignments exist for '$($owner.UPN)' on site '$GovernanceSiteId'."
        }
        if ($existing.Count -eq 1) {
            Invoke-DataverseRequest `
                -Method PATCH `
                -RelativeUrl "$OwnerAssignmentEntitySet($($existing[0].sb_siteownerassignmentid))" `
                -Body $body |
                Out-Null
        }
        else {
            Invoke-DataverseRequest `
                -Method POST `
                -RelativeUrl $OwnerAssignmentEntitySet `
                -Body $body |
                Out-Null
        }
    }

    $activeQuery = "${OwnerAssignmentEntitySet}?" +
        "`$select=sb_siteownerassignmentid,sb_principalupn,sb_ownershipsource" +
        "&`$filter=_sb_site_value eq $GovernanceSiteId and sb_isactive eq true"
    $activeAssignments = @((
        Invoke-DataverseRequest -Method GET -RelativeUrl $activeQuery
    ).value)
    foreach ($assignment in $activeAssignments) {
        $key = "$($assignment.sb_ownershipsource)|$($assignment.sb_principalupn)"
        if (-not $observedKeys.ContainsKey($key)) {
            Invoke-DataverseRequest `
                -Method PATCH `
                -RelativeUrl "$OwnerAssignmentEntitySet($($assignment.sb_siteownerassignmentid))" `
                -Body @{
                    sb_isactive = $false
                    sb_observedat = ConvertTo-DataverseDate $observedAt
                    "sb_lastscanrun@odata.bind" = "/$ScanRunEntitySet($scanRunId)"
                } |
                Out-Null
        }
    }
}

function Set-UnobservedSitesUnknown {
    $unknownValue = Get-ChoiceValue `
        -TableLogicalName "sb_governancesite" `
        -ColumnLogicalName "sb_lifecyclestatus" `
        -Label "Unknown"
    $tenant = Escape-ODataString $TenantId
    $relativeUrl = "${GovernanceSiteEntitySet}?" +
        "`$select=sb_governancesiteid" +
        "&`$filter=sb_tenantid eq '$tenant'" +
        " and (_sb_lastscanrun_value ne $scanRunId or _sb_lastscanrun_value eq null)"

    while (-not [string]::IsNullOrWhiteSpace($relativeUrl)) {
        $response = Invoke-DataverseRequest -Method GET -RelativeUrl $relativeUrl
        foreach ($site in @($response.value)) {
            Invoke-DataverseRequest `
                -Method PATCH `
                -RelativeUrl "$GovernanceSiteEntitySet($($site.sb_governancesiteid))" `
                -Body @{ sb_lifecyclestatus = $unknownValue } |
                Out-Null
        }

        $relativeUrl = $null
        $nextLinkProperty = $response.PSObject.Properties['@odata.nextLink']
        if ($null -ne $nextLinkProperty) {
            $relativeUrl = ([string]$nextLinkProperty.Value).Replace("$apiRoot/", "")
        }
    }
}

if ($null -eq (Get-Module -ListAvailable -Name PnP.PowerShell)) {
    throw "PnP.PowerShell is required. Install it with Install-Module PnP.PowerShell -Scope CurrentUser."
}
Import-Module PnP.PowerShell -ErrorAction Stop

$adminConnection = Connect-PnPOnline `
    -Url $AdminUrl `
    -ClientId $ClientId `
    -Tenant $TenantId `
    -Interactive `
    -PersistLogin `
    -ReturnConnection

$sites = @(Get-PnPTenantSite `
    -IncludeOneDriveSites:$false `
    -Detailed `
    -Connection $adminConnection |
    Where-Object {
        -not [string]::IsNullOrWhiteSpace([string]$_.Url) -and
        $_.Url -notmatch '-my\.sharepoint\.com(?:/|$)'
    })
if ($SiteLimit -gt 0) {
    $sites = @($sites | Select-Object -First $SiteLimit)
}
if ($sites.Count -eq 0) {
    throw "Tenant discovery returned no SharePoint sites; Dataverse was not changed."
}

if (-not $PSCmdlet.ShouldProcess(
        "$DataverseUrl tenant $TenantId",
        "reconcile $($sites.Count) discovered SharePoint sites"
    )) {
    Write-Host "Discovered $($sites.Count) sites. Dataverse was not changed."
    return
}

$script:accessToken = Get-DataverseToken
$runStatusRunning = Get-ChoiceValue `
    -TableLogicalName "sb_governancescanrun" `
    -ColumnLogicalName "sb_status" `
    -Label "Running"
$runStatusCompleted = Get-ChoiceValue `
    -TableLogicalName "sb_governancescanrun" `
    -ColumnLogicalName "sb_status" `
    -Label "Completed"
$runStatusErrors = Get-ChoiceValue `
    -TableLogicalName "sb_governancescanrun" `
    -ColumnLogicalName "sb_status" `
    -Label "CompletedWithErrors"

$scanRunBody = @{
    sb_governancescanrunid = $scanRunId
    sb_name                = "SharePoint inventory $($observedAt.ToString('yyyy-MM-dd HH:mm:ss')) UTC"
    sb_runid               = [string]$scanRunId
    sb_status              = $runStatusRunning
    sb_startedat           = ConvertTo-DataverseDate $observedAt
    sb_sitesdiscovered     = $sites.Count
    sb_sitesprocessed      = 0
    sb_recordsfailed       = 0
    sb_correlationid       = [string]$correlationId
}
Invoke-DataverseRequest -Method POST -RelativeUrl $ScanRunEntitySet -Body $scanRunBody | Out-Null

$processed = 0
$failed = 0
$fatalFailure = $null
try {
    $siteTypeValues = @{}
    foreach ($label in @("Group", "Communication", "Classic", "Other")) {
        $siteTypeValues[$label] = Get-ChoiceValue `
            -TableLogicalName "sb_governancesite" `
            -ColumnLogicalName "sb_sitetype" `
            -Label $label
    }
    $activeLifecycleValue = Get-ChoiceValue `
        -TableLogicalName "sb_governancesite" `
        -ColumnLogicalName "sb_lifecyclestatus" `
        -Label "Active"

    foreach ($site in $sites) {
        try {
            $siteUrl = [string]$site.Url
            $siteIdValue = Get-PnPPropertyValue -InputObject $site -Names @("SiteId", "Id")
            if ($null -eq $siteIdValue -or [guid]$siteIdValue -eq [guid]::Empty) {
                throw "SharePoint did not return a stable site collection ID."
            }
            $m365SiteId = [string]$siteIdValue
            $owners = @(Get-SiteOwners `
                -TenantSite $site `
                -AdminConnection $adminConnection)

            $existingSite = Get-ExistingSite -M365SiteId $m365SiteId
            $lastCertifiedAt = $null
            if ($null -ne $existingSite -and $null -ne $existingSite.sb_lastcertifiedat) {
                $lastCertifiedAt = [datetime]$existingSite.sb_lastcertifiedat
            }

            $lastActivityAt = Get-PnPPropertyValue `
                -InputObject $site `
                -Names @("LastContentModifiedDate", "LastContentModifiedDateTime")
            $effectiveOwnerCount = @(
                $owners |
                    ForEach-Object { $_.UPN } |
                    Sort-Object -Unique
            ).Count
            $recommendation = Get-GovernanceRecommendation `
                -OwnerCount $effectiveOwnerCount `
                -LastActivityAt $lastActivityAt `
                -LastCertifiedAt $lastCertifiedAt
            $siteType = Get-SiteType -TenantSite $site
            $externalSharing = Get-ExternalSharingLabel -TenantSite $site
            $groupId = Get-PnPPropertyValue -InputObject $site -Names @("GroupId")
            $directOwnerCount = @($owners | Where-Object Source -eq "SharePoint").Count
            $groupOwnerCount = @($owners | Where-Object Source -eq "M365Group").Count

            $body = @{
                sb_tenantid            = $TenantId
                sb_m365siteid          = $m365SiteId
                sb_name                = [string]$site.Title
                sb_siteurl             = $siteUrl
                sb_sitetype            = $siteTypeValues[$siteType]
                sb_lifecyclestatus     = $activeLifecycleValue
                sb_directownercount    = $directOwnerCount
                sb_groupownercount     = $groupOwnerCount
                sb_effectiveownercount = $effectiveOwnerCount
                sb_compliancestatus    = Get-ChoiceValue `
                    -TableLogicalName "sb_governancesite" `
                    -ColumnLogicalName "sb_compliancestatus" `
                    -Label $recommendation.Compliance
                sb_recommendedaction   = Get-ChoiceValue `
                    -TableLogicalName "sb_governancesite" `
                    -ColumnLogicalName "sb_recommendedaction" `
                    -Label $recommendation.Action
                sb_triagereason        = $recommendation.Reason
                sb_externalsharing     = Get-ChoiceValue `
                    -TableLogicalName "sb_governancesite" `
                    -ColumnLogicalName "sb_externalsharing" `
                    -Label $externalSharing
                sb_lastobservedat      = ConvertTo-DataverseDate $observedAt
                "sb_lastscanrun@odata.bind" = "/$ScanRunEntitySet($scanRunId)"
            }

            $createdAt = Get-PnPPropertyValue `
                -InputObject $site `
                -Names @("TimeCreated", "Created")
            $storageMb = Get-PnPPropertyValue `
                -InputObject $site `
                -Names @("StorageUsageCurrent")
            if ($null -ne $lastActivityAt) {
                $body.sb_lastactivityat = ConvertTo-DataverseDate $lastActivityAt
            }
            if ($null -ne $createdAt) {
                $body.sb_createdat = ConvertTo-DataverseDate $createdAt
            }
            if ($null -ne $storageMb) {
                $body.sb_storageusagemb = [decimal]$storageMb
            }
            if ($null -ne $groupId -and [guid]$groupId -ne [guid]::Empty) {
                $body.sb_groupid = [string]$groupId
            }

            if ($null -eq $existingSite) {
                $body.sb_attestationstatus = Get-ChoiceValue `
                    -TableLogicalName "sb_governancesite" `
                    -ColumnLogicalName "sb_attestationstatus" `
                    -Label "NotAttested"
                Invoke-DataverseRequest `
                    -Method POST `
                    -RelativeUrl $GovernanceSiteEntitySet `
                    -Body $body |
                    Out-Null
                $existingSite = Get-ExistingSite -M365SiteId $m365SiteId
            }
            else {
                Invoke-DataverseRequest `
                    -Method PATCH `
                    -RelativeUrl "$GovernanceSiteEntitySet($($existingSite.sb_governancesiteid))" `
                    -Body $body |
                    Out-Null
            }

            Set-OwnerAssignments `
                -GovernanceSiteId ([guid]$existingSite.sb_governancesiteid) `
                -Owners $owners
            $processed++
            Write-Host "[$processed/$($sites.Count)] Reconciled $siteUrl"
        }
        catch {
            $failed++
            Write-Error "Failed to reconcile '$($site.Url)': $($_.Exception.Message)" -ErrorAction Continue
        }
    }

    if ($failed -eq 0 -and $SiteLimit -eq 0) {
        Set-UnobservedSitesUnknown
    }
}
catch {
    $failed = [Math]::Max(1, $failed)
    $fatalFailure = $_
}
finally {
    $completedAt = [datetime]::UtcNow
    $status = if ($failed -eq 0) { $runStatusCompleted } else { $runStatusErrors }
    Invoke-DataverseRequest `
        -Method PATCH `
        -RelativeUrl "$ScanRunEntitySet($scanRunId)" `
        -Body @{
            sb_status          = $status
            sb_completedat     = ConvertTo-DataverseDate $completedAt
            sb_sitesprocessed  = $processed
            sb_recordsfailed   = $failed
        } |
        Out-Null
}

Write-Host ""
Write-Host "Scan run: $scanRunId"
Write-Host "Discovered: $($sites.Count); processed: $processed; failed: $failed"
if ($SiteLimit -gt 0) {
    Write-Host "Bounded scan: unobserved site lifecycle state was not changed."
}
if ($null -ne $fatalFailure) {
    throw $fatalFailure
}
if ($failed -gt 0) {
    throw "The scan completed with $failed failed site(s). Unobserved sites were not changed."
}
