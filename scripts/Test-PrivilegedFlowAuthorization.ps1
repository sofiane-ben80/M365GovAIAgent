param(
    [string]$SolutionPath = (Join-Path $PSScriptRoot "..\M365Governance_2_0_0_0")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$resolvedSolutionPath = (Resolve-Path -Path $SolutionPath).Path
$workflowsPath = Join-Path $resolvedSolutionPath "Workflows"

if (-not (Test-Path -Path $workflowsPath -PathType Container)) {
    throw "Solution workflows directory was not found: $workflowsPath"
}

$errors = @()
$privilegedFlowCount = 0

function Get-RoleAssignmentQueries {
    param(
        [Parameter()]
        [AllowNull()]
        [object]$Node
    )

    if ($null -eq $Node) {
        return
    }

    if ($Node -is [System.Collections.IEnumerable] -and $Node -isnot [string]) {
        foreach ($item in $Node) {
            Get-RoleAssignmentQueries -Node $item
        }
        return
    }

    if ($Node -isnot [pscustomobject]) {
        return
    }

    $inputs = $null
    $parameters = $null
    $entityName = $null
    $inputsProperty = $Node.PSObject.Properties["inputs"]
    if ($null -ne $inputsProperty) {
        $inputs = $inputsProperty.Value
    }
    $parametersProperty = if ($null -ne $inputs) {
        $inputs.PSObject.Properties["parameters"]
    }
    if ($null -ne $parametersProperty) {
        $parameters = $parametersProperty.Value
    }
    $entityNameProperty = if ($null -ne $parameters) {
        $parameters.PSObject.Properties["entityName"]
    }
    if ($null -ne $entityNameProperty) {
        $entityName = $entityNameProperty.Value
    }
    if ([string]$entityName -eq "sb_governanceroleassignments") {
        $parameters
    }

    foreach ($property in $Node.PSObject.Properties) {
        Get-RoleAssignmentQueries -Node $property.Value
    }
}

Get-ChildItem -Path $workflowsPath -Filter "*.json" -File | ForEach-Object {
    $content = Get-Content -Path $_.FullName -Raw
    $workflow = $content | ConvertFrom-Json
    $roleAssignmentQueries = @(Get-RoleAssignmentQueries -Node $workflow)
    $isAdminAuthorizationFlow =
        $roleAssignmentQueries.Count -gt 0 -or
        $_.BaseName -match "CheckAdminRole|VerifyAdmin"

    if (-not $isAdminAuthorizationFlow) {
        return
    }

    $privilegedFlowCount++

    if ($roleAssignmentQueries.Count -eq 0) {
        $errors += "$($_.Name) does not query Governance Role Assignment."
        return
    }

    $authorizationFilters = @(
        $roleAssignmentQueries |
            ForEach-Object { [string]$_.PSObject.Properties['$filter'].Value }
    )

    if ($authorizationFilters -notmatch "sb_principalobjectid eq") {
        $errors += "$($_.Name) does not authorize by immutable Entra object ID."
    }

    if ($authorizationFilters -match "sb_principalupn eq") {
        $errors += "$($_.Name) authorizes by mutable UPN."
    }

    if ($authorizationFilters -notmatch "sb_role eq 126390000") {
        $errors += "$($_.Name) does not require the GovernanceAdmin role."
    }

    if ($authorizationFilters -notmatch "sb_isactive eq true") {
        $errors += "$($_.Name) does not require an active role assignment."
    }

    if (
        $authorizationFilters -notmatch "sb_validfrom eq null or sb_validfrom le" -or
        $authorizationFilters -notmatch "sb_validuntil eq null or sb_validuntil gt"
    ) {
        $errors += "$($_.Name) does not enforce the assignment validity window."
    }

    if (@($roleAssignmentQueries | Where-Object { $_.'$top' -eq 2 }).Count -ne $roleAssignmentQueries.Count) {
        $errors += "$($_.Name) does not retrieve up to two assignments for duplicate detection."
    }

    $officeUsersReference =
        $workflow.properties.connectionReferences.PSObject.Properties["shared_office365users"]
    if (
        $null -ne $officeUsersReference -and
        $officeUsersReference.Value.runtimeSource -ne "embedded"
    ) {
        $errors += "$($_.Name) requires per-user Office 365 connector consent."
    }
}

if ($privilegedFlowCount -eq 0) {
    throw "No Governance Role Assignment authorization flows were found."
}

if ($errors.Count -gt 0) {
    throw (
        "Privileged flow authorization validation failed:`n - " +
        ($errors -join "`n - ")
    )
}

Write-Host (
    "Privileged flow authorization validation passed. " +
    "Validated flows: $privilegedFlowCount; authority: Governance Role Assignment; key: Entra object ID."
) -ForegroundColor Green
