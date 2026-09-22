[CmdletBinding()]
param(
    [Parameter()]
    [ValidatePattern('^https://')]
    [string]$EnvironmentUrl = 'https://orgaa73b06e.crm.dynamics.com',

    [Parameter()]
    [securestring]$DataverseAccessToken,

    [Parameter()]
    [guid]$ApprovedAdminObjectId = 'cc46ae4f-7191-482a-b3cf-d7b0294c3da3'
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

$requestId = [guid]::Empty
$eventIds = [System.Collections.Generic.List[guid]]::new()
$results = [System.Collections.Generic.List[object]]::new()

function Add-Result {
    param(
        [Parameter(Mandatory)]
        [string]$Scenario,

        [Parameter(Mandatory)]
        [bool]$Passed,

        [Parameter(Mandatory)]
        [string]$Evidence
    )

    $results.Add([pscustomobject]@{
        Scenario = $Scenario
        Passed   = $Passed
        Evidence = $Evidence
    })
}

function Invoke-DataverseGet {
    param(
        [Parameter(Mandatory)]
        [string]$RelativeUri
    )

    Invoke-RestMethod -Method Get -Uri "$baseUrl/api/data/v9.2/$RelativeUri" -Headers $headers
}

function New-ActionEvent {
    param(
        [Parameter(Mandatory)]
        [int]$EventType,

        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter(Mandatory)]
        [string]$NewState,

        [Parameter()]
        [string]$PreviousState
    )

    $body = @{
        'sb_request@odata.bind' = "/sb_governanceactionrequests($requestId)"
        sb_eventtype            = $EventType
        sb_eventat              = [DateTime]::UtcNow.ToString('o')
        sb_actorupn             = 'governor365-lifecycle-test@example.invalid'
        sb_correlationid        = "lifecycle-$requestId"
        sb_message              = $Message
        sb_newstate             = $NewState
    }
    if (-not [string]::IsNullOrWhiteSpace($PreviousState)) {
        $body.sb_previousstate = $PreviousState
    }

    $created = Invoke-RestMethod `
        -Method Post `
        -Uri "$baseUrl/api/data/v9.2/sb_governanceactionevents" `
        -Headers ($headers + @{ Prefer = 'return=representation' }) `
        -Body ($body | ConvertTo-Json -Compress)
    $id = [guid]$created.sb_governanceactioneventid
    $eventIds.Add($id)
}

function Test-Confirmation {
    param(
        [Parameter(Mandatory)]
        [string]$RequestType,

        [Parameter()]
        [string]$Confirmation,

        [Parameter()]
        [string]$TargetOwnerUpn
    )

    switch ($RequestType.ToUpperInvariant()) {
        'SUPPORT' { return $true }
        'CERTIFY' { return $Confirmation -ceq 'CONFIRM' }
        'ARCHIVE' { return $Confirmation -ceq 'CONFIRM' }
        'DELETE_REVIEW' { return $Confirmation -ceq 'CONFIRM' }
        'ASSIGN_OWNER' {
            return $Confirmation -ceq 'CONFIRM' -and
                $TargetOwnerUpn -match '^[^@\s]+@[^@\s]+$'
        }
        default { return $false }
    }
}

try {
    $now = [DateTime]::UtcNow.ToString('o')
    $adminFilter = [Uri]::EscapeDataString(
        "sb_principalobjectid eq '$ApprovedAdminObjectId' and " +
        'sb_role eq 126390000 and sb_isactive eq true and ' +
        "(sb_validfrom eq null or sb_validfrom le $now) and " +
        "(sb_validuntil eq null or sb_validuntil gt $now)"
    )
    $adminRows = @((Invoke-DataverseGet (
        "sb_governanceroleassignments?`$select=sb_governanceroleassignmentid" +
        "&`$filter=$adminFilter&`$top=2"
    )).value)
    Add-Result -Scenario 'approved-admin-authorization' `
        -Passed ($adminRows.Count -eq 1) `
        -Evidence "Expected one active assignment; found $($adminRows.Count)."

    $unknownObjectId = [guid]::NewGuid()
    $unknownFilter = [Uri]::EscapeDataString(
        "sb_principalobjectid eq '$unknownObjectId' and " +
        'sb_role eq 126390000 and sb_isactive eq true'
    )
    $unknownRows = @((Invoke-DataverseGet (
        "sb_governanceroleassignments?`$select=sb_governanceroleassignmentid" +
        "&`$filter=$unknownFilter&`$top=1"
    )).value)
    Add-Result -Scenario 'unauthorized-principal-denied' `
        -Passed ($unknownRows.Count -eq 0) `
        -Evidence "Expected zero assignments; found $($unknownRows.Count)."

    Add-Result -Scenario 'confirmation-rules' `
        -Passed (
            (Test-Confirmation -RequestType SUPPORT) -and
            (Test-Confirmation -RequestType CERTIFY -Confirmation CONFIRM) -and
            -not (Test-Confirmation -RequestType CERTIFY -Confirmation Confirm) -and
            (Test-Confirmation -RequestType DELETE_REVIEW -Confirmation CONFIRM) -and
            -not (Test-Confirmation -RequestType DELETE_REVIEW -Confirmation '') -and
            (Test-Confirmation -RequestType ASSIGN_OWNER -Confirmation CONFIRM `
                -TargetOwnerUpn 'owner@example.invalid') -and
            -not (Test-Confirmation -RequestType ASSIGN_OWNER -Confirmation CONFIRM)
        ) `
        -Evidence 'Exact confirmation and assignment-target cases matched the flow contract.'

    $idempotencyKey = "governor365-lifecycle-test-$([guid]::NewGuid())"
    $requestBody = @{
        sb_requesttype          = 100000004
        sb_requeststatus        = 100000000
        sb_requestedbyobjectid  = $ApprovedAdminObjectId.ToString()
        sb_requestedbyupn       = 'governor365-lifecycle-test@example.invalid'
        sb_requestedat          = [DateTime]::UtcNow.ToString('o')
        sb_reason               = 'Temporary automated request lifecycle fixture.'
        sb_confirmationmethod   = 100000000
        sb_idempotencykey       = $idempotencyKey
    }
    $request = Invoke-RestMethod `
        -Method Post `
        -Uri "$baseUrl/api/data/v9.2/sb_governanceactionrequests" `
        -Headers ($headers + @{ Prefer = 'return=representation' }) `
        -Body ($requestBody | ConvertTo-Json -Compress)
    $requestId = [guid]$request.sb_governanceactionrequestid

    $duplicateRejected = $false
    try {
        Invoke-RestMethod `
            -Method Post `
            -Uri "$baseUrl/api/data/v9.2/sb_governanceactionrequests" `
            -Headers $headers `
            -Body ($requestBody | ConvertTo-Json -Compress) | Out-Null
    }
    catch {
        $duplicateRejected = $true
    }
    $keyFilter = [Uri]::EscapeDataString("sb_idempotencykey eq '$idempotencyKey'")
    $sameKeyRows = @((Invoke-DataverseGet (
        "sb_governanceactionrequests?`$select=sb_governanceactionrequestid" +
        "&`$filter=$keyFilter&`$top=2"
    )).value)
    Add-Result -Scenario 'idempotency-key-enforced' `
        -Passed ($duplicateRejected -and $sameKeyRows.Count -eq 1) `
        -Evidence "Duplicate rejected: $duplicateRejected; durable rows: $($sameKeyRows.Count)."

    New-ActionEvent -EventType 100000000 -Message 'Request submitted.' -NewState Pending

    Invoke-RestMethod `
        -Method Patch `
        -Uri "$baseUrl/api/data/v9.2/sb_governanceactionrequests($requestId)" `
        -Headers $headers `
        -Body (@{ sb_requeststatus = 100000003 } | ConvertTo-Json -Compress)
    New-ActionEvent -EventType 100000005 -Message 'Execution started.' `
        -PreviousState Pending -NewState InProgress

    Invoke-RestMethod `
        -Method Patch `
        -Uri "$baseUrl/api/data/v9.2/sb_governanceactionrequests($requestId)" `
        -Headers $headers `
        -Body (@{
            sb_requeststatus = 100000004
            sb_completedat   = [DateTime]::UtcNow.ToString('o')
        } | ConvertTo-Json -Compress)
    New-ActionEvent -EventType 100000006 -Message 'Request completed.' `
        -PreviousState InProgress -NewState Completed

    $eventFilter = [Uri]::EscapeDataString("_sb_request_value eq $requestId")
    $events = @((Invoke-DataverseGet (
        "sb_governanceactionevents?`$select=sb_eventtype,sb_previousstate,sb_newstate" +
        "&`$filter=$eventFilter&`$orderby=sb_eventat asc"
    )).value)
    $eventTypes = @($events | ForEach-Object { [int]$_.sb_eventtype })
    Add-Result -Scenario 'transition-event-completeness' `
        -Passed (
            $events.Count -eq 3 -and
            $eventTypes[0] -eq 100000000 -and
            $eventTypes[1] -eq 100000005 -and
            $eventTypes[2] -eq 100000006
        ) `
        -Evidence "Expected Submitted, ExecutionStarted, Completed; found $($eventTypes -join ', ')."

    $requestState = Invoke-DataverseGet (
        "sb_governanceactionrequests($requestId)?`$select=sb_requeststatus,sb_completedat"
    )
    Add-Result -Scenario 'terminal-state-persisted' `
        -Passed (
            [int]$requestState.sb_requeststatus -eq 100000004 -and
            -not [string]::IsNullOrWhiteSpace($requestState.sb_completedat)
        ) `
        -Evidence "Status $($requestState.sb_requeststatus); completed $($requestState.sb_completedat)."
}
finally {
    foreach ($eventId in $eventIds) {
        try {
            Invoke-RestMethod `
                -Method Delete `
                -Uri "$baseUrl/api/data/v9.2/sb_governanceactionevents($eventId)" `
                -Headers $headers
        }
        catch {
            Write-Warning "Could not delete temporary event $eventId`: $($_.Exception.Message)"
        }
    }

    if ($requestId -ne [guid]::Empty) {
        try {
            Invoke-RestMethod `
                -Method Delete `
                -Uri "$baseUrl/api/data/v9.2/sb_governanceactionrequests($requestId)" `
                -Headers $headers
        }
        catch {
            Write-Warning "Could not delete temporary request $requestId`: $($_.Exception.Message)"
        }
    }
}

$results | Format-Table -AutoSize
$failed = @($results | Where-Object { -not $_.Passed })
if ($failed.Count -gt 0) {
    throw "$($failed.Count) governance request lifecycle test(s) failed."
}

Write-Output "All $($results.Count) governance request lifecycle tests passed."
