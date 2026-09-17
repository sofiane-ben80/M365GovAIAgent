<#
.SYNOPSIS
    Provisions the Governor365 Dataverse schema in an unmanaged solution.

.DESCRIPTION
    Creates the nine sb_ tables, their documented columns, local choices,
    lookups, and alternate keys. Existing components are inspected and
    preserved. A conflicting existing component causes an explicit failure.

    Every Dataverse request carries MSCRM.SolutionUniqueName so newly created
    components are added to the specified solution. No credentials or tokens
    are persisted.

.PARAMETER DataverseUrl
    Dataverse environment URL, for example https://contoso.crm.dynamics.com.

.PARAMETER SolutionUniqueName
    Unique name of an existing unmanaged solution.

.PARAMETER AccessToken
    Optional Dataverse bearer token as a SecureString. If omitted, Az.Accounts
    and then Azure CLI are tried.

.EXAMPLE
    .\Initialize-Governor365DataverseSchema.ps1 `
        -DataverseUrl https://contoso.crm.dynamics.com `
        -SolutionUniqueName M365Governance

.EXAMPLE
    .\Initialize-Governor365DataverseSchema.ps1 `
        -DataverseUrl https://contoso.crm.dynamics.com -WhatIf
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = "High")]
param(
    [Parameter(Mandatory)]
    [ValidateScript({
        $uri = $null
        [uri]::TryCreate([string]$_, [UriKind]::Absolute, [ref]$uri) -and
            $uri.Scheme -eq "https" -and
            [string]::IsNullOrEmpty($uri.Query) -and
            [string]::IsNullOrEmpty($uri.Fragment) -and
            ($uri.AbsolutePath -eq "/" -or [string]::IsNullOrEmpty($uri.AbsolutePath))
    })]
    [string] $DataverseUrl,

    [ValidatePattern('^[A-Za-z][A-Za-z0-9_]*$')]
    [string] $SolutionUniqueName = "M365Governance",

    [Alias("DataverseAccessToken")]
    [securestring] $AccessToken,

    [ValidateRange(1, 12)]
    [int] $MaximumRetryCount = 5
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$DataverseUrl = $DataverseUrl.TrimEnd("/")
$apiRoot = "$DataverseUrl/api/data/v9.2"
$script:bearerToken = $null
$script:created = [System.Collections.Generic.List[string]]::new()
$script:preserved = [System.Collections.Generic.List[string]]::new()
$script:planned = [System.Collections.Generic.List[string]]::new()

function New-Label {
    param([Parameter(Mandatory)][string] $Text)

    return @{
        "@odata.type" = "Microsoft.Dynamics.CRM.Label"
        LocalizedLabels = @(
            @{
                "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
                Label = $Text
                LanguageCode = 1033
            }
        )
    }
}

function ConvertFrom-SecureToken {
    param([Parameter(Mandatory)][securestring] $Token)

    $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Token)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)
    }
}

function Get-DataverseAccessToken {
    if ($null -ne $AccessToken) {
        return ConvertFrom-SecureToken -Token $AccessToken
    }

    $azAccounts = Get-Module -ListAvailable Az.Accounts |
        Sort-Object Version -Descending |
        Select-Object -First 1
    if ($null -ne $azAccounts) {
        Import-Module Az.Accounts -ErrorAction Stop
        try {
            $result = Get-AzAccessToken -ResourceUrl $DataverseUrl -ErrorAction Stop
            if ($result.Token -is [securestring]) {
                return ConvertFrom-SecureToken -Token $result.Token
            }
            if (-not [string]::IsNullOrWhiteSpace([string]$result.Token)) {
                return [string]$result.Token
            }
        }
        catch {
            Write-Verbose "Az.Accounts token acquisition failed: $($_.Exception.Message)"
        }
    }

    $az = Get-Command az -ErrorAction SilentlyContinue
    if ($null -ne $az) {
        $result = & $az.Source account get-access-token --resource $DataverseUrl --output json 2>&1
        if ($LASTEXITCODE -eq 0) {
            $tokenResult = $result | ConvertFrom-Json
            if (-not [string]::IsNullOrWhiteSpace([string]$tokenResult.accessToken)) {
                return [string]$tokenResult.accessToken
            }
        }
        Write-Verbose "Azure CLI token acquisition failed."
    }

    throw "Unable to acquire a Dataverse token. Supply -AccessToken, connect Az.Accounts, or run 'az login'."
}

function Invoke-DataverseRequest {
    param(
        [Parameter(Mandatory)]
        [ValidateSet("GET", "POST")]
        [string] $Method,

        [Parameter(Mandatory)]
        [string] $RelativeUrl,

        [AllowNull()]
        [hashtable] $Body
    )

    $headers = @{
        Authorization = "Bearer $script:bearerToken"
        Accept = "application/json"
        "Content-Type" = "application/json; charset=utf-8"
        "OData-MaxVersion" = "4.0"
        "OData-Version" = "4.0"
        "MSCRM.SolutionUniqueName" = $SolutionUniqueName
    }
    $parameters = @{
        Method = $Method
        Uri = "$apiRoot/$RelativeUrl"
        Headers = $headers
        ErrorAction = "Stop"
    }
    if ($null -ne $Body) {
        $parameters.Body = $Body | ConvertTo-Json -Depth 30 -Compress
    }

    for ($attempt = 1; $attempt -le $MaximumRetryCount; $attempt++) {
        try {
            return Invoke-RestMethod @parameters
        }
        catch {
            $errorRecord = $_
            $statusCode = 0
            $responseBody = ""
            $detail = $errorRecord.Exception.Message
            if ($null -ne $errorRecord.Exception.Response) {
                $statusCode = [int]$errorRecord.Exception.Response.StatusCode
                try {
                    if ($null -ne $errorRecord.Exception.Response.Content) {
                        $responseBody = $errorRecord.Exception.Response.Content.
                            ReadAsStringAsync().GetAwaiter().GetResult()
                    }
                }
                catch {
                    Write-Verbose "Could not read HttpResponseMessage.Content: $($_.Exception.Message)"
                }
            }

            # Invoke-RestMethod in PowerShell 7 commonly consumes HttpContent
            # before throwing and retains the response JSON in ErrorDetails.
            if ([string]::IsNullOrWhiteSpace($responseBody) -and
                -not [string]::IsNullOrWhiteSpace([string]$errorRecord.ErrorDetails.Message)) {
                $responseBody = [string]$errorRecord.ErrorDetails.Message
            }

            if (-not [string]::IsNullOrWhiteSpace($responseBody)) {
                $responseBody = $responseBody.Trim()
                try {
                    $webApiError = $responseBody | ConvertFrom-Json -ErrorAction Stop
                    if (-not [string]::IsNullOrWhiteSpace([string]$webApiError.error.message)) {
                        $code = [string]$webApiError.error.code
                        $message = [string]$webApiError.error.message
                        $detail = "Web API error"
                        if (-not [string]::IsNullOrWhiteSpace($code)) {
                            $detail += " $code"
                        }
                        $detail += ": $message. Response JSON: $responseBody"
                    }
                    else {
                        $detail = "Response body: $responseBody"
                    }
                }
                catch {
                    $detail = "Response body: $responseBody"
                }
            }

            $retryable = $statusCode -in 408, 429 -or ($statusCode -ge 500 -and $statusCode -le 599)
            if (-not $retryable -or $attempt -eq $MaximumRetryCount) {
                throw "Dataverse $Method '$RelativeUrl' failed (HTTP $statusCode): $detail"
            }

            $delay = [Math]::Min(60, [Math]::Pow(2, $attempt))
            Write-Warning "Dataverse returned HTTP $statusCode; retrying in $delay seconds."
            Start-Sleep -Seconds $delay
        }
    }
}

function Get-RequiredLevel {
    param([bool] $Required)

    return @{
        Value = $(if ($Required) { "ApplicationRequired" } else { "None" })
        CanBeChanged = $true
        ManagedPropertyLogicalName = "canmodifyrequirementlevelsettings"
    }
}

function New-ColumnPayload {
    param([Parameter(Mandatory)][hashtable] $Column)

    $payload = @{
        SchemaName = $Column.Name
        DisplayName = New-Label $Column.Display
        Description = New-Label $Column.Description
        RequiredLevel = Get-RequiredLevel ([bool]$Column.Required)
    }

    switch ($Column.Type) {
        "String" {
            $payload["@odata.type"] = "Microsoft.Dynamics.CRM.StringAttributeMetadata"
            $payload.MaxLength = $Column.Length
            $payload.FormatName = @{ Value = $(if ($Column.Format) { $Column.Format } else { "Text" }) }
        }
        "Memo" {
            $payload["@odata.type"] = "Microsoft.Dynamics.CRM.MemoAttributeMetadata"
            $payload.MaxLength = $(if ($Column.Length) { $Column.Length } else { 1048576 })
            $payload.Format = "TextArea"
        }
        "Integer" {
            $payload["@odata.type"] = "Microsoft.Dynamics.CRM.IntegerAttributeMetadata"
            $payload.MinValue = 0
            $payload.MaxValue = 2147483647
            $payload.Format = "None"
        }
        "Decimal" {
            $payload["@odata.type"] = "Microsoft.Dynamics.CRM.DecimalAttributeMetadata"
            $payload.MinValue = 0
            $payload.MaxValue = 100000000000
            $payload.Precision = 2
        }
        "DateTime" {
            $payload["@odata.type"] = "Microsoft.Dynamics.CRM.DateTimeAttributeMetadata"
            $payload.Format = "DateAndTime"
            $payload.DateTimeBehavior = @{ Value = "TimeZoneIndependent" }
        }
        "Boolean" {
            $payload["@odata.type"] = "Microsoft.Dynamics.CRM.BooleanAttributeMetadata"
            $payload.DefaultValue = $false
            $payload.OptionSet = @{
                "@odata.type" = "Microsoft.Dynamics.CRM.BooleanOptionSetMetadata"
                IsGlobal = $false
                TrueOption = @{
                    Value = 1
                    Label = New-Label "Yes"
                }
                FalseOption = @{
                    Value = 0
                    Label = New-Label "No"
                }
            }
        }
        "Choice" {
            $payload["@odata.type"] = "Microsoft.Dynamics.CRM.PicklistAttributeMetadata"
            $options = @()
            for ($index = 0; $index -lt $Column.Options.Count; $index++) {
                $options += @{
                    Value = 100000000 + $index
                    Label = New-Label $Column.Options[$index]
                }
            }
            $payload.OptionSet = @{
                "@odata.type" = "Microsoft.Dynamics.CRM.OptionSetMetadata"
                IsGlobal = $false
                OptionSetType = "Picklist"
                Options = $options
            }
        }
        default {
            throw "Unsupported column type '$($Column.Type)' for '$($Column.Name)'."
        }
    }

    return $payload
}

function New-Column {
    param(
        [Parameter(Mandatory)][string] $Name,
        [Parameter(Mandatory)][string] $Display,
        [Parameter(Mandatory)][ValidateSet("String", "Memo", "Integer", "Decimal", "DateTime", "Boolean", "Choice")]
        [string] $Type,
        [bool] $Required = $false,
        [int] $Length = 0,
        [string] $Format = "",
        [string[]] $Options = @(),
        [string] $Description = ""
    )

    return @{
        Name = $Name
        Display = $Display
        Type = $Type
        Required = $Required
        Length = $Length
        Format = $Format
        Options = $Options
        Description = $(if ($Description) { $Description } else { $Display })
    }
}

function New-Table {
    param(
        [string] $Name,
        [string] $Display,
        [string] $DisplayPlural,
        [string] $EntitySet,
        [ValidateSet("UserOwned", "OrganizationOwned")][string] $Ownership,
        [string] $PrimaryName,
        [int] $PrimaryNameLength,
        [array] $Columns,
        [string] $Description
    )

    return @{
        Name = $Name
        Display = $Display
        DisplayPlural = $DisplayPlural
        EntitySet = $EntitySet
        Ownership = $Ownership
        PrimaryName = $PrimaryName
        PrimaryNameLength = $PrimaryNameLength
        Columns = $Columns
        Description = $Description
    }
}

$tables = @(
    New-Table "sb_governancesite" "Governance Site" "Governance Sites" "sb_governancesites" "UserOwned" "sb_name" 300 @(
        New-Column "sb_tenantid" "Tenant ID" String $true 36
        New-Column "sb_m365siteid" "Microsoft 365 Site ID" String $true 200
        New-Column "sb_siteurl" "Site URL" String $true 400 "Url"
        New-Column "sb_webid" "Web ID" String $false 36
        New-Column "sb_groupid" "Group ID" String $false 36
        New-Column "sb_sitetype" "Site Type" Choice $true 0 "" @("Group", "Communication", "Classic", "Other")
        New-Column "sb_lifecyclestatus" "Lifecycle Status" Choice $true 0 "" @("Active", "ReadOnly", "Archived", "Deleted", "Unknown")
        New-Column "sb_lastactivityat" "Last Activity At" DateTime
        New-Column "sb_createdat" "Created At" DateTime
        New-Column "sb_storageusagemb" "Storage Usage MB" Decimal
        New-Column "sb_externalsharing" "External Sharing" Choice $false 0 "" @("Disabled", "ExistingGuests", "NewAndExistingGuests", "Anyone", "Unknown")
        New-Column "sb_office" "Office" String $false 200
        New-Column "sb_suboffice" "Suboffice" String $false 200
        New-Column "sb_directownercount" "Direct Owner Count" Integer $true
        New-Column "sb_groupownercount" "Group Owner Count" Integer $true
        New-Column "sb_effectiveownercount" "Effective Owner Count" Integer $true
        New-Column "sb_compliancestatus" "Compliance Status" Choice $true 0 "" @("Compliant", "NonCompliant", "Unknown")
        New-Column "sb_recommendedaction" "Recommended Action" Choice $true 0 "" @("None", "Certify", "Archive", "DeleteReview", "AssignOwners")
        New-Column "sb_triagereason" "Triage Reason" Memo
        New-Column "sb_lastcertifiedat" "Last Certified At" DateTime
        New-Column "sb_attestationstatus" "Attestation Status" Choice $true 0 "" @("NotAttested", "Attested", "Expired", "Exempt", "Unknown")
        New-Column "sb_attestationexpiresat" "Attestation Expires At" DateTime
        New-Column "sb_suppressnotificationsuntil" "Suppress Notifications Until" DateTime
        New-Column "sb_sourceetag" "Source ETag" String $false 200
        New-Column "sb_lastobservedat" "Last Observed At" DateTime $true
    ) "Current Microsoft 365 site inventory and compliance snapshot."

    New-Table "sb_siteownerassignment" "Site Owner Assignment" "Site Owner Assignments" "sb_siteownerassignments" "OrganizationOwned" "sb_principalupn" 320 @(
        New-Column "sb_principalobjectid" "Principal Object ID" String $false 36
        New-Column "sb_displayname" "Display Name" String $false 300
        New-Column "sb_ownershipsource" "Ownership Source" Choice $true 0 "" @("SharePoint", "M365Group", "ManualException")
        New-Column "sb_isactive" "Is Active" Boolean $true
        New-Column "sb_observedat" "Observed At" DateTime $true
    ) "Normalized owner-to-site relationship."

    New-Table "sb_governanceactionrequest" "Governance Action Request" "Governance Action Requests" "sb_governanceactionrequests" "OrganizationOwned" "sb_idempotencykey" 200 @(
        New-Column "sb_requesttype" "Request Type" Choice $true 0 "" @("Certify", "Archive", "DeleteReview", "AssignOwner", "Support")
        New-Column "sb_requeststatus" "Request Status" Choice $true 0 "" @("Pending", "AwaitingApproval", "Approved", "InProgress", "Completed", "Rejected", "Cancelled", "Failed")
        New-Column "sb_requestedbyobjectid" "Requested By Object ID" String $false 36
        New-Column "sb_requestedbyupn" "Requested By UPN" String $true 320
        New-Column "sb_requestedat" "Requested At" DateTime $true
        New-Column "sb_reason" "Reason" Memo
        New-Column "sb_targetownerupn" "Target Owner UPN" String $false 320
        New-Column "sb_confirmationmethod" "Confirmation Method" Choice $false 0 "" @("Button", "TypedConfirm", "AdminApproval")
        New-Column "sb_approvedbyupn" "Approved By UPN" String $false 320
        New-Column "sb_approvedat" "Approved At" DateTime
        New-Column "sb_completedat" "Completed At" DateTime
        New-Column "sb_externaloperationid" "External Operation ID" String $false 200
        New-Column "sb_failurecode" "Failure Code" String $false 100
        New-Column "sb_failuremessage" "Failure Message" Memo
    ) "Governed request and approval lifecycle."

    New-Table "sb_governanceactionevent" "Governance Action Event" "Governance Action Events" "sb_governanceactionevents" "OrganizationOwned" "sb_correlationid" 100 @(
        New-Column "sb_eventtype" "Event Type" Choice $true 0 "" @("Submitted", "Authorized", "ApprovalRequested", "Approved", "Rejected", "ExecutionStarted", "Completed", "Failed", "Notified")
        New-Column "sb_eventat" "Event At" DateTime $true
        New-Column "sb_actorupn" "Actor UPN" String $false 320
        New-Column "sb_message" "Message" Memo
        New-Column "sb_previousstate" "Previous State" String $false 100
        New-Column "sb_newstate" "New State" String $false 100
    ) "Append-only governance business event."

    New-Table "sb_governancepolicysetting" "Governance Policy Setting" "Governance Policy Settings" "sb_governancepolicysettings" "OrganizationOwned" "sb_key" 200 @(
        New-Column "sb_valuetype" "Value Type" Choice $true 0 "" @("Text", "WholeNumber", "Decimal", "Boolean", "DateTime")
        New-Column "sb_value" "Value" String $true 4000
        New-Column "sb_description" "Description" Memo
        New-Column "sb_isactive" "Is Active" Boolean $true
        New-Column "sb_effectivefrom" "Effective From" DateTime
        New-Column "sb_effectiveto" "Effective To" DateTime
    ) "Runtime governance policy setting."

    New-Table "sb_governancescanrun" "Governance Scan Run" "Governance Scan Runs" "sb_governancescanruns" "OrganizationOwned" "sb_name" 300 @(
        New-Column "sb_runid" "Run ID" String $true 36
        New-Column "sb_status" "Status" Choice $true 0 "" @("Running", "Completed", "CompletedWithErrors")
        New-Column "sb_startedat" "Started At" DateTime $true
        New-Column "sb_completedat" "Completed At" DateTime
        New-Column "sb_sourcewatermark" "Source Watermark" Memo
        New-Column "sb_sitesdiscovered" "Sites Discovered" Integer $true
        New-Column "sb_sitesprocessed" "Sites Processed" Integer $true
        New-Column "sb_recordsfailed" "Records Failed" Integer $true
        New-Column "sb_correlationid" "Correlation ID" String $true 36
    ) "Inventory scan control and summary."

    New-Table "sb_scanworkitem" "Scan Work Item" "Scan Work Items" "sb_scanworkitems" "OrganizationOwned" "sb_name" 300 @(
        New-Column "sb_idempotencykey" "Idempotency Key" String $true 200
        New-Column "sb_pagetoken" "Page Token" Memo
        New-Column "sb_status" "Status" Choice $true 0 "" @("Pending", "InProgress", "Completed", "Failed")
        New-Column "sb_attemptcount" "Attempt Count" Integer $true
        New-Column "sb_nextattemptat" "Next Attempt At" DateTime
        New-Column "sb_discoveredcount" "Discovered Count" Integer $true
        New-Column "sb_processedcount" "Processed Count" Integer $true
        New-Column "sb_errorcode" "Error Code" String $false 100
        New-Column "sb_errormessage" "Error Message" Memo
    ) "Bounded asynchronous inventory batch."

    New-Table "sb_notificationdelivery" "Notification Delivery" "Notification Deliveries" "sb_notificationdeliveries" "OrganizationOwned" "sb_idempotencykey" 200 @(
        New-Column "sb_recipientupn" "Recipient UPN" String $true 320
        New-Column "sb_notificationtype" "Notification Type" Choice $true 0 "" @("OwnerDigest", "CertificationReminder", "ActionUpdate")
        New-Column "sb_periodkey" "Period Key" String $true 100
        New-Column "sb_status" "Status" Choice $true 0 "" @("Pending", "Sent", "Responded", "Failed", "Suppressed")
        New-Column "sb_sentat" "Sent At" DateTime
        New-Column "sb_respondedat" "Responded At" DateTime
        New-Column "sb_teamsactivityid" "Teams Activity ID" String $false 200
        New-Column "sb_failuredetail" "Failure Detail" Memo
    ) "Digest and card delivery and response status."

    New-Table "sb_evidencesnapshot" "Evidence Snapshot" "Evidence Snapshots" "sb_evidencesnapshots" "OrganizationOwned" "sb_name" 300 @(
        New-Column "sb_evidencetype" "Evidence Type" Choice $true 0 "" @("Activity", "Ownership", "Sharing", "Storage", "Attestation", "Other")
        New-Column "sb_observedat" "Observed At" DateTime $true
        New-Column "sb_expiresat" "Expires At" DateTime
        New-Column "sb_source" "Source" String $true 200
        New-Column "sb_classification" "Classification" Choice $true 0 "" @("Public", "Internal", "Confidential", "Restricted")
        New-Column "sb_correlationid" "Correlation ID" String $true 100
        New-Column "sb_payload" "Minimized JSON Payload" Memo
    ) "Time-bound normalized governance evidence."
)

$lookups = @(
    @{ Table = "sb_siteownerassignment"; Name = "sb_site"; Display = "Site"; Target = "sb_governancesite"; Required = $true }
    @{ Table = "sb_siteownerassignment"; Name = "sb_lastscanrun"; Display = "Last Scan Run"; Target = "sb_governancescanrun"; Required = $false }
    @{ Table = "sb_governanceactionrequest"; Name = "sb_site"; Display = "Site"; Target = "sb_governancesite"; Required = $false }
    @{ Table = "sb_governanceactionevent"; Name = "sb_request"; Display = "Request"; Target = "sb_governanceactionrequest"; Required = $true }
    @{ Table = "sb_governancesite"; Name = "sb_lastscanrun"; Display = "Last Scan Run"; Target = "sb_governancescanrun"; Required = $false }
    @{ Table = "sb_scanworkitem"; Name = "sb_scanrun"; Display = "Scan Run"; Target = "sb_governancescanrun"; Required = $true }
    @{ Table = "sb_notificationdelivery"; Name = "sb_request"; Display = "Request"; Target = "sb_governanceactionrequest"; Required = $false }
    @{ Table = "sb_evidencesnapshot"; Name = "sb_site"; Display = "Resource"; Target = "sb_governancesite"; Required = $true }
)

$keys = @(
    @{ Table = "sb_governancesite"; Name = "sb_GovernanceSite_Tenant_Site"; Display = "Tenant and M365 Site"; Attributes = @("sb_tenantid", "sb_m365siteid") }
    @{ Table = "sb_governancesite"; Name = "sb_GovernanceSite_Tenant_Url"; Display = "Tenant and Site URL"; Attributes = @("sb_tenantid", "sb_siteurl") }
    @{ Table = "sb_siteownerassignment"; Name = "sb_SiteOwnerAssignment_Site_Upn_Source"; Display = "Site, UPN, and Source"; Attributes = @("sb_site", "sb_principalupn", "sb_ownershipsource") }
    @{ Table = "sb_governanceactionrequest"; Name = "sb_GovernanceActionRequest_Idempotency"; Display = "Request Idempotency Key"; Attributes = @("sb_idempotencykey") }
    @{ Table = "sb_governancepolicysetting"; Name = "sb_GovernancePolicySetting_Key"; Display = "Policy Key"; Attributes = @("sb_key") }
    @{ Table = "sb_governancescanrun"; Name = "sb_GovernanceScanRun_RunId"; Display = "Scan Run ID"; Attributes = @("sb_runid") }
    @{ Table = "sb_scanworkitem"; Name = "sb_ScanWorkItem_Run_Idempotency"; Display = "Scan Run and Idempotency Key"; Attributes = @("sb_scanrun", "sb_idempotencykey") }
    @{ Table = "sb_notificationdelivery"; Name = "sb_NotificationDelivery_Idempotency"; Display = "Notification Idempotency Key"; Attributes = @("sb_idempotencykey") }
)

function Get-Entity {
    param([Parameter(Mandatory)][string] $LogicalName)

    try {
        return Invoke-DataverseRequest GET "EntityDefinitions(LogicalName='$LogicalName')?`$select=LogicalName,SchemaName,OwnershipType,PrimaryNameAttribute,EntitySetName" $null
    }
    catch {
        if ($_.Exception.Message -match "HTTP 404") {
            return $null
        }
        throw
    }
}

function Ensure-Table {
    param([Parameter(Mandatory)][hashtable] $Table)

    $existing = Get-Entity $Table.Name
    if ($null -ne $existing) {
        if ([string]$existing.OwnershipType -ne $Table.Ownership) {
            throw "Table '$($Table.Name)' exists with ownership '$($existing.OwnershipType)', expected '$($Table.Ownership)'."
        }
        if ([string]$existing.PrimaryNameAttribute -ne $Table.PrimaryName) {
            throw "Table '$($Table.Name)' has primary name '$($existing.PrimaryNameAttribute)', expected '$($Table.PrimaryName)'."
        }
        $script:preserved.Add("table $($Table.Name)")
        return $true
    }

    $body = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.EntityMetadata"
        SchemaName = $Table.Name
        DisplayName = New-Label $Table.Display
        DisplayCollectionName = New-Label $Table.DisplayPlural
        Description = New-Label $Table.Description
        OwnershipType = $Table.Ownership
        IsActivity = $false
        HasActivities = $false
        HasNotes = $false
        Attributes = @(
            @{
                "@odata.type" = "Microsoft.Dynamics.CRM.StringAttributeMetadata"
                AttributeType = "String"
                AttributeTypeName = @{ Value = "StringType" }
                SchemaName = $Table.PrimaryName
                DisplayName = New-Label $Table.Display
                Description = New-Label "Primary name for $($Table.Display)."
                IsPrimaryName = $true
                RequiredLevel = Get-RequiredLevel $true
                MaxLength = $Table.PrimaryNameLength
                FormatName = @{ Value = "Text" }
            }
        )
    }

    if ($PSCmdlet.ShouldProcess("$DataverseUrl table $($Table.Name)", "Create in solution $SolutionUniqueName")) {
        Invoke-DataverseRequest POST "EntityDefinitions" $body | Out-Null
        $script:created.Add("table $($Table.Name)")
        return $true
    }

    $script:planned.Add("table $($Table.Name)")
    return $false
}

function Get-Attributes {
    param([Parameter(Mandatory)][string] $TableName)

    $response = Invoke-DataverseRequest GET "EntityDefinitions(LogicalName='$TableName')/Attributes?`$select=LogicalName,AttributeType,RequiredLevel" $null
    $attributes = @{}
    foreach ($attribute in $response.value) {
        $attributes[[string]$attribute.LogicalName] = $attribute
    }
    return $attributes
}

function Ensure-ChoiceOptions {
    param(
        [Parameter(Mandatory)][string] $TableName,
        [Parameter(Mandatory)][hashtable] $Column
    )

    $url = "EntityDefinitions(LogicalName='$TableName')/Attributes(LogicalName='$($Column.Name)')" +
        "/Microsoft.Dynamics.CRM.PicklistAttributeMetadata?`$select=LogicalName&" +
        "`$expand=OptionSet(`$select=Options)"
    $metadata = Invoke-DataverseRequest GET $url $null
    $labels = @{}
    $values = @{}
    foreach ($option in $metadata.OptionSet.Options) {
        $label = @($option.Label.LocalizedLabels | Where-Object LanguageCode -eq 1033 | Select-Object -First 1).Label
        if (-not [string]::IsNullOrWhiteSpace([string]$label)) {
            $labels[[string]$label] = [int]$option.Value
            $values[[int]$option.Value] = [string]$label
        }
    }

    for ($index = 0; $index -lt $Column.Options.Count; $index++) {
        $label = $Column.Options[$index]
        if ($labels.ContainsKey($label)) {
            continue
        }
        $value = 100000000 + $index
        if ($values.ContainsKey($value)) {
            throw "Choice '$TableName.$($Column.Name)' needs '$label', but value $value is already used by '$($values[$value])'."
        }
        $body = @{
            EntityLogicalName = $TableName
            AttributeLogicalName = $Column.Name
            Value = $value
            Label = New-Label $label
            SolutionUniqueName = $SolutionUniqueName
        }
        if ($PSCmdlet.ShouldProcess("$TableName.$($Column.Name) option '$label'", "Insert Dataverse choice option")) {
            Invoke-DataverseRequest POST "InsertOptionValue" $body | Out-Null
            $script:created.Add("choice option $TableName.$($Column.Name):$label")
        }
        else {
            $script:planned.Add("choice option $TableName.$($Column.Name):$label")
        }
    }
}

function Ensure-Columns {
    param([Parameter(Mandatory)][hashtable] $Table)

    $attributes = Get-Attributes $Table.Name
    foreach ($column in $Table.Columns) {
        if ($attributes.ContainsKey($column.Name)) {
            $actualType = [string]$attributes[$column.Name].AttributeType
            $expectedType = $(if ($column.Type -eq "Choice") { "Picklist" } else { $column.Type })
            if ($actualType -ne $expectedType) {
                throw "Column '$($Table.Name).$($column.Name)' has type '$actualType', expected '$($column.Type)'."
            }
            $actualRequired = [string]$attributes[$column.Name].RequiredLevel.Value
            if ($column.Required -and $actualRequired -notin "ApplicationRequired", "SystemRequired") {
                throw "Column '$($Table.Name).$($column.Name)' is optional but the documented schema requires it."
            }
            if ($column.Type -eq "String") {
                $stringUrl = "EntityDefinitions(LogicalName='$($Table.Name)')/Attributes(LogicalName='$($column.Name)')" +
                    "/Microsoft.Dynamics.CRM.StringAttributeMetadata?`$select=MaxLength"
                $stringMetadata = Invoke-DataverseRequest GET $stringUrl $null
                if ([int]$stringMetadata.MaxLength -lt $column.Length) {
                    throw "Column '$($Table.Name).$($column.Name)' is shorter than the required $($column.Length) characters."
                }
            }
            if ($column.Type -eq "Choice") {
                Ensure-ChoiceOptions $Table.Name $column
            }
            $script:preserved.Add("column $($Table.Name).$($column.Name)")
            continue
        }

        $body = New-ColumnPayload $column
        if ($PSCmdlet.ShouldProcess("$($Table.Name).$($column.Name)", "Create Dataverse column")) {
            Invoke-DataverseRequest POST "EntityDefinitions(LogicalName='$($Table.Name)')/Attributes" $body | Out-Null
            $script:created.Add("column $($Table.Name).$($column.Name)")
        }
        else {
            $script:planned.Add("column $($Table.Name).$($column.Name)")
        }
    }
}

function Ensure-Lookup {
    param([Parameter(Mandatory)][hashtable] $Lookup)

    $attributes = Get-Attributes $Lookup.Table
    if ($attributes.ContainsKey($Lookup.Name)) {
        if ([string]$attributes[$Lookup.Name].AttributeType -ne "Lookup") {
            throw "Column '$($Lookup.Table).$($Lookup.Name)' exists but is not a lookup."
        }
        $url = "EntityDefinitions(LogicalName='$($Lookup.Table)')/Attributes(LogicalName='$($Lookup.Name)')" +
            "/Microsoft.Dynamics.CRM.LookupAttributeMetadata?`$select=LogicalName,Targets"
        $metadata = Invoke-DataverseRequest GET $url $null
        if ($Lookup.Target -notin @($metadata.Targets)) {
            throw "Lookup '$($Lookup.Table).$($Lookup.Name)' does not target '$($Lookup.Target)'."
        }
        $script:preserved.Add("lookup $($Lookup.Table).$($Lookup.Name)")
        return
    }

    $relationshipName = "sb_$($Lookup.Table.Substring(3))_$($Lookup.Name.Substring(3))"
    $body = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.OneToManyRelationshipMetadata"
        SchemaName = $relationshipName
        ReferencedEntity = $Lookup.Target
        ReferencingEntity = $Lookup.Table
        Lookup = @{
            SchemaName = $Lookup.Name
            DisplayName = New-Label $Lookup.Display
            Description = New-Label "$($Lookup.Display) lookup."
            RequiredLevel = Get-RequiredLevel ([bool]$Lookup.Required)
        }
        CascadeConfiguration = @{
            Assign = "NoCascade"
            Delete = "Restrict"
            Merge = "NoCascade"
            Reparent = "NoCascade"
            Share = "NoCascade"
            Unshare = "NoCascade"
        }
    }
    if ($PSCmdlet.ShouldProcess("$($Lookup.Table).$($Lookup.Name)", "Create Dataverse lookup to $($Lookup.Target)")) {
        Invoke-DataverseRequest POST "RelationshipDefinitions" $body | Out-Null
        $script:created.Add("lookup $($Lookup.Table).$($Lookup.Name)")
    }
    else {
        $script:planned.Add("lookup $($Lookup.Table).$($Lookup.Name)")
    }
}

function Ensure-Key {
    param([Parameter(Mandatory)][hashtable] $Key)

    $response = Invoke-DataverseRequest GET "EntityDefinitions(LogicalName='$($Key.Table)')/Keys?`$select=SchemaName,LogicalName,KeyAttributes" $null
    $expected = @($Key.Attributes | Sort-Object)
    foreach ($existing in $response.value) {
        $actual = @($existing.KeyAttributes | Sort-Object)
        if ([string]$existing.SchemaName -eq $Key.Name) {
            if (($actual -join "|") -ne ($expected -join "|")) {
                throw "Alternate key '$($Key.Name)' exists with different attributes."
            }
            $script:preserved.Add("alternate key $($Key.Table).$($Key.Name)")
            return
        }
        if (($actual -join "|") -eq ($expected -join "|")) {
            $script:preserved.Add("alternate key $($Key.Table).$([string]$existing.SchemaName)")
            return
        }
    }

    $body = @{
        "@odata.type" = "Microsoft.Dynamics.CRM.EntityKeyMetadata"
        SchemaName = $Key.Name
        DisplayName = New-Label $Key.Display
        KeyAttributes = $Key.Attributes
    }
    if ($PSCmdlet.ShouldProcess("$($Key.Table).$($Key.Name)", "Create Dataverse alternate key")) {
        Invoke-DataverseRequest POST "EntityDefinitions(LogicalName='$($Key.Table)')/Keys" $body | Out-Null
        $script:created.Add("alternate key $($Key.Table).$($Key.Name)")
    }
    else {
        $script:planned.Add("alternate key $($Key.Table).$($Key.Name)")
    }
}

try {
    $script:bearerToken = Get-DataverseAccessToken

    $escapedSolutionName = $SolutionUniqueName.Replace("'", "''")
    $solutionResponse = Invoke-DataverseRequest GET "solutions?`$select=uniquename,ismanaged&`$expand=publisherid(`$select=customizationprefix)&`$filter=uniquename eq '$escapedSolutionName'" $null
    $solutions = @($solutionResponse.value)
    if ($solutions.Count -ne 1) {
        throw "Unmanaged solution '$SolutionUniqueName' was not found uniquely in $DataverseUrl."
    }
    if ([bool]$solutions[0].ismanaged) {
        throw "Solution '$SolutionUniqueName' is managed. Schema provisioning requires an unmanaged solution."
    }
    if ([string]$solutions[0].publisherid.customizationprefix -ne "sb") {
        throw "Solution '$SolutionUniqueName' uses publisher prefix '$($solutions[0].publisherid.customizationprefix)'; the documented schema requires 'sb'."
    }

    $availableTables = @{}
    foreach ($table in $tables) {
        $availableTables[$table.Name] = Ensure-Table $table
    }
    foreach ($table in $tables) {
        if ($availableTables[$table.Name]) {
            Ensure-Columns $table
        }
    }
    foreach ($lookup in $lookups) {
        if ($availableTables[$lookup.Table] -and $availableTables[$lookup.Target]) {
            Ensure-Lookup $lookup
        }
        else {
            $script:planned.Add("lookup $($lookup.Table).$($lookup.Name)")
        }
    }
    foreach ($key in $keys) {
        if ($availableTables[$key.Table]) {
            Ensure-Key $key
        }
        else {
            $script:planned.Add("alternate key $($key.Table).$($key.Name)")
        }
    }

    [pscustomobject]@{
        DataverseUrl = $DataverseUrl
        SolutionUniqueName = $SolutionUniqueName
        Tables = $tables.Count
        Created = $script:created.Count
        Preserved = $script:preserved.Count
        Planned = $script:planned.Count
        CreatedComponents = @($script:created)
        PlannedComponents = @($script:planned)
    }
}
finally {
    $script:bearerToken = $null
}
