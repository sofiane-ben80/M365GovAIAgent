[CmdletBinding()]
param(
    [Parameter()]
    [ValidatePattern('^https://')]
    [string]$EnvironmentUrl = 'https://orgaa73b06e.crm.dynamics.com',

    [Parameter()]
    [securestring]$DataverseAccessToken,

    [Parameter()]
    [string]$TeamTemplateName = 'Governor365 Site Owner Read',

    [Parameter()]
    [switch]$FailOnUnmappedPrincipal
)

$ErrorActionPreference = 'Stop'
$baseUrl = $EnvironmentUrl.TrimEnd('/')

if ($DataverseAccessToken) {
    $token = [System.Net.NetworkCredential]::new('', $DataverseAccessToken).Password
}
else {
    $token = az account get-access-token `
        --resource "$baseUrl/" `
        --query accessToken `
        --output tsv
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($token)) {
        throw 'Azure CLI did not return a Dataverse access token.'
    }
}

$headers = @{
    Authorization      = "Bearer $token"
    Accept             = 'application/json'
    'Content-Type'     = 'application/json'
    'OData-MaxVersion' = '4.0'
    'OData-Version'    = '4.0'
}

function Invoke-DataverseGet {
    param(
        [Parameter(Mandatory)]
        [string]$RelativeUri
    )

    Invoke-RestMethod -Method Get -Uri "$baseUrl/api/data/v9.2/$RelativeUri" -Headers $headers
}

function Invoke-RecordTeamAction {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('AddUserToRecordTeam', 'RemoveUserFromRecordTeam')]
        [string]$Action,

        [Parameter(Mandatory)]
        [guid]$SystemUserId,

        [Parameter(Mandatory)]
        [guid]$SiteId,

        [Parameter(Mandatory)]
        [guid]$TeamTemplateId
    )

    $body = @{
        Record = @{
            '@odata.type'         = 'Microsoft.Dynamics.CRM.sb_governancesite'
            sb_governancesiteid   = $SiteId
        }
        TeamTemplate = @{
            '@odata.type' = 'Microsoft.Dynamics.CRM.teamtemplate'
            teamtemplateid = $TeamTemplateId
        }
    }
    Invoke-RestMethod `
        -Method Post `
        -Uri "$baseUrl/api/data/v9.2/systemusers($SystemUserId)/Microsoft.Dynamics.CRM.$Action" `
        -Headers $headers `
        -Body ($body | ConvertTo-Json -Depth 5 -Compress) | Out-Null
}

$escapedTemplateName = $TeamTemplateName.Replace("'", "''")
$templates = @((Invoke-DataverseGet (
    "teamtemplates?`$select=teamtemplateid,teamtemplatename,objecttypecode" +
    "&`$filter=teamtemplatename eq '$escapedTemplateName'"
)).value)
if ($templates.Count -ne 1) {
    throw "Expected one '$TeamTemplateName' template; found $($templates.Count)."
}
$templateId = [guid]$templates[0].teamtemplateid

$assignments = @((Invoke-DataverseGet (
    'sb_siteownerassignments?' +
    '$select=sb_siteownerassignmentid,sb_principalobjectid,sb_principalupn,_sb_site_value' +
    '&$filter=sb_isactive eq true&$top=5000'
)).value)

$desiredBySite = @{}
$unmapped = [System.Collections.Generic.List[object]]::new()
foreach ($assignment in $assignments) {
    if ([string]::IsNullOrWhiteSpace($assignment.sb_principalobjectid)) {
        $unmapped.Add($assignment)
        continue
    }

    $objectId = [guid]$assignment.sb_principalobjectid
    $users = @((Invoke-DataverseGet (
        "systemusers?`$select=systemuserid&" +
        "`$filter=azureactivedirectoryobjectid eq $objectId"
    )).value)
    if ($users.Count -ne 1) {
        $unmapped.Add($assignment)
        continue
    }

    $siteId = [guid]$assignment._sb_site_value
    if (-not $desiredBySite.ContainsKey($siteId)) {
        $desiredBySite[$siteId] = [System.Collections.Generic.HashSet[guid]]::new()
    }
    [void]$desiredBySite[$siteId].Add([guid]$users[0].systemuserid)
}

$teams = @((Invoke-DataverseGet (
    "teams?`$select=teamid,_regardingobjectid_value&" +
    "`$filter=_teamtemplateid_value eq $templateId&`$top=5000"
)).value)
$teamBySite = @{}
foreach ($team in $teams) {
    $teamBySite[[guid]$team._regardingobjectid_value] = [guid]$team.teamid
}

$added = 0
$removed = 0
$allSiteIds = [System.Collections.Generic.HashSet[guid]]::new()
foreach ($siteId in $desiredBySite.Keys) {
    [void]$allSiteIds.Add($siteId)
}
foreach ($siteId in $teamBySite.Keys) {
    [void]$allSiteIds.Add($siteId)
}

foreach ($siteId in $allSiteIds) {
    $desired = [System.Collections.Generic.HashSet[guid]]::new()
    if ($desiredBySite.ContainsKey($siteId)) {
        $desired = $desiredBySite[$siteId]
    }

    $current = [System.Collections.Generic.HashSet[guid]]::new()
    if ($teamBySite.ContainsKey($siteId)) {
        $teamId = $teamBySite[$siteId]
        $members = @((Invoke-DataverseGet (
            "teams($teamId)/teammembership_association?`$select=systemuserid"
        )).value)
        foreach ($member in $members) {
            [void]$current.Add([guid]$member.systemuserid)
        }
    }

    foreach ($systemUserId in $desired) {
        if (-not $current.Contains($systemUserId)) {
            Invoke-RecordTeamAction `
                -Action AddUserToRecordTeam `
                -SystemUserId $systemUserId `
                -SiteId $siteId `
                -TeamTemplateId $templateId
            $added++
        }
    }

    foreach ($systemUserId in $current) {
        if (-not $desired.Contains($systemUserId)) {
            Invoke-RecordTeamAction `
                -Action RemoveUserFromRecordTeam `
                -SystemUserId $systemUserId `
                -SiteId $siteId `
                -TeamTemplateId $templateId
            $removed++
        }
    }
}

[pscustomobject]@{
    ActiveAssignments  = $assignments.Count
    DesiredMemberships = ($desiredBySite.Values | ForEach-Object Count | Measure-Object -Sum).Sum
    AccessTeams        = $teams.Count
    Added              = $added
    Removed            = $removed
    UnmappedPrincipals = $unmapped.Count
} | Format-List

if ($unmapped.Count -gt 0) {
    $unmapped |
        Select-Object sb_principalupn, sb_principalobjectid, _sb_site_value |
        Sort-Object sb_principalupn |
        Format-Table -AutoSize

    if ($FailOnUnmappedPrincipal) {
        throw "$($unmapped.Count) active assignment principal(s) have no unique Dataverse user."
    }
}
