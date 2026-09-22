[CmdletBinding()]
param(
    [Parameter()]
    [ValidatePattern('^https://')]
    [string]$EnvironmentUrl = 'https://orgaa73b06e.crm.dynamics.com',

    [Parameter()]
    [securestring]$DataverseAccessToken
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

$roleValue = 126390000
$migrationSourceValue = 126390002
$temporaryIds = [System.Collections.Generic.List[guid]]::new()
$results = [System.Collections.Generic.List[object]]::new()

function Invoke-RoleQuery {
    param(
        [Parameter(Mandatory)]
        [guid]$PrincipalObjectId
    )

    $now = [DateTime]::UtcNow.ToString('o')
    $filter = "sb_principalobjectid eq '$PrincipalObjectId' and " +
        "sb_role eq $roleValue and sb_isactive eq true and " +
        "(sb_validfrom eq null or sb_validfrom le $now) and " +
        "(sb_validuntil eq null or sb_validuntil gt $now)"
    $encodedFilter = [Uri]::EscapeDataString($filter)
    $uri = "$baseUrl/api/data/v9.2/sb_governanceroleassignments?" +
        "`$select=sb_governanceroleassignmentid&`$filter=$encodedFilter&`$top=2"

    @((Invoke-RestMethod -Method Get -Uri $uri -Headers $headers).value)
}

function Add-TestAssignment {
    param(
        [Parameter(Mandatory)]
        [guid]$PrincipalObjectId,

        [Parameter(Mandatory)]
        [string]$Scenario,

        [Parameter(Mandatory)]
        [bool]$IsActive,

        [Parameter()]
        [datetime]$ValidFrom,

        [Parameter()]
        [datetime]$ValidUntil
    )

    $body = @{
        sb_name             = "Authorization test - $Scenario"
        sb_principalobjectid = $PrincipalObjectId.ToString()
        sb_principalupn     = "governor365-test-$Scenario@example.invalid"
        sb_displayname      = "Governor365 test $Scenario"
        sb_role             = $roleValue
        sb_isactive         = $IsActive
        sb_assignmentsource = $migrationSourceValue
        sb_grantedat        = [DateTime]::UtcNow.ToString('o')
        sb_reason           = 'Temporary automated authorization test fixture.'
    }
    if ($PSBoundParameters.ContainsKey('ValidFrom')) {
        $body.sb_validfrom = $ValidFrom.ToUniversalTime().ToString('o')
    }
    if ($PSBoundParameters.ContainsKey('ValidUntil')) {
        $body.sb_validuntil = $ValidUntil.ToUniversalTime().ToString('o')
    }

    $created = Invoke-RestMethod `
        -Method Post `
        -Uri "$baseUrl/api/data/v9.2/sb_governanceroleassignments" `
        -Headers ($headers + @{ Prefer = 'return=representation' }) `
        -Body ($body | ConvertTo-Json -Compress)
    $id = [guid]$created.sb_governanceroleassignmentid
    $temporaryIds.Add($id)
    $id
}

function Add-Result {
    param(
        [Parameter(Mandatory)]
        [string]$Scenario,

        [Parameter(Mandatory)]
        [int]$ExpectedCount,

        [Parameter(Mandatory)]
        [int]$ActualCount
    )

    $passed = $ExpectedCount -eq $ActualCount
    $results.Add([pscustomobject]@{
        Scenario = $Scenario
        Expected = $ExpectedCount
        Actual   = $ActualCount
        Passed   = $passed
    })
}

try {
    $approvedAdmin = 'cc46ae4f-7191-482a-b3cf-d7b0294c3da3'
    Add-Result -Scenario 'approved-active-admin' -ExpectedCount 1 `
        -ActualCount (Invoke-RoleQuery -PrincipalObjectId $approvedAdmin).Count

    Add-Result -Scenario 'missing-assignment' -ExpectedCount 0 `
        -ActualCount (Invoke-RoleQuery -PrincipalObjectId ([guid]::NewGuid())).Count

    $inactive = [guid]::NewGuid()
    Add-TestAssignment -PrincipalObjectId $inactive -Scenario 'inactive' `
        -IsActive $false | Out-Null
    Add-Result -Scenario 'inactive-assignment' -ExpectedCount 0 `
        -ActualCount (Invoke-RoleQuery -PrincipalObjectId $inactive).Count

    $expired = [guid]::NewGuid()
    Add-TestAssignment -PrincipalObjectId $expired -Scenario 'expired' `
        -IsActive $true `
        -ValidFrom ([DateTime]::UtcNow.AddDays(-10)) `
        -ValidUntil ([DateTime]::UtcNow.AddDays(-1)) | Out-Null
    Add-Result -Scenario 'expired-assignment' -ExpectedCount 0 `
        -ActualCount (Invoke-RoleQuery -PrincipalObjectId $expired).Count

    $future = [guid]::NewGuid()
    Add-TestAssignment -PrincipalObjectId $future -Scenario 'future' `
        -IsActive $true `
        -ValidFrom ([DateTime]::UtcNow.AddDays(1)) | Out-Null
    Add-Result -Scenario 'future-assignment' -ExpectedCount 0 `
        -ActualCount (Invoke-RoleQuery -PrincipalObjectId $future).Count

    $duplicatePrincipal = [guid]::NewGuid()
    Add-TestAssignment -PrincipalObjectId $duplicatePrincipal `
        -Scenario 'unique-key-first' -IsActive $true | Out-Null
    $duplicateRejected = $false
    try {
        Add-TestAssignment -PrincipalObjectId $duplicatePrincipal `
            -Scenario 'unique-key-second' -IsActive $true | Out-Null
    }
    catch {
        $duplicateRejected = $true
    }
    $duplicateCount = (Invoke-RoleQuery -PrincipalObjectId $duplicatePrincipal).Count
    Add-Result -Scenario 'duplicate-role-rejected' -ExpectedCount 1 `
        -ActualCount ([int]($duplicateRejected -and $duplicateCount -eq 1))
}
finally {
    foreach ($id in $temporaryIds) {
        try {
            Invoke-RestMethod `
                -Method Delete `
                -Uri "$baseUrl/api/data/v9.2/sb_governanceroleassignments($id)" `
                -Headers $headers
        }
        catch {
            Write-Warning "Could not delete temporary assignment $id`: $($_.Exception.Message)"
        }
    }
}

$results | Format-Table -AutoSize
$failed = @($results | Where-Object { -not $_.Passed })
if ($failed.Count -gt 0) {
    throw "$($failed.Count) governance role authorization test(s) failed."
}

Write-Output "All $($results.Count) governance role authorization tests passed."
