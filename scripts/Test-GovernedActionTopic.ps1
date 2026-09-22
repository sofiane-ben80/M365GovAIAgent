param(
    [string]$SolutionPath = (Join-Path $PSScriptRoot "..\M365Governance_2_0_0_0"),
    [string]$SourcePath = (Join-Path $PSScriptRoot "..\agents\M365 Governance Agent\agents\Owner Operations\topics\SiteReview.mcs.yml")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$resolvedSolutionPath = (Resolve-Path -Path $SolutionPath).Path
$resolvedSourcePath = (Resolve-Path -Path $SourcePath).Path
$canonicalPath = Join-Path $resolvedSolutionPath "botcomponents\copilots_header_04c70.topic.OwnerSiteReview\data"
$relationshipsPath = Join-Path $resolvedSolutionPath "Assets\botcomponent_workflowset.xml"
$processorMetadataPath = Join-Path $resolvedSolutionPath (
    "Workflows\Governor365-Request-ProcessPending-" +
    "A14ED1E0-BBB3-F111-AAAC-000D3A367627.json.data.xml"
)

foreach ($requiredPath in @($canonicalPath, $relationshipsPath, $processorMetadataPath)) {
    if (-not (Test-Path -Path $requiredPath -PathType Leaf)) {
        throw "Required governed-action artifact was not found: $requiredPath"
    }
}

$source = Get-Content -Path $resolvedSourcePath -Raw
$canonical = Get-Content -Path $canonicalPath -Raw

if ($source -cne $canonical) {
    throw "The editable Site Review topic and canonical solution component are not synchronized."
}

$requiredPatterns = [ordered]@{
    "exact-site authorization" = "flowId:\s*4190243f-b9b3-f111-aaac-000d3a367627"
    "request submission" = "flowId:\s*7f675f00-bab3-f111-aaac-000d3a367627"
    "caller identity" = "text:\s*=System\.User\.PrincipalName"
    "certification action" = 'value:\s*="CERTIFY"'
    "archive action" = 'value:\s*="ARCHIVE"'
    "deletion-review action" = 'value:\s*="DELETE_REVIEW"'
    "owner-assignment action" = 'value:\s*="ASSIGN_OWNER"'
    "business reason" = "text_3:\s*=Topic\.ActionReason"
    "current-turn confirmation" = "text_4:\s*=Upper\(Trim\(Text\(Topic\.Confirmation\)\)\)"
    "idempotency key" = "text_5:\s*=Text\(GUID\(\)\)"
    "target owner" = "text_6:\s*=Topic\.TargetOwnerUPN"
    "typed deletion confirmation" = "Type CONFIRM to continue"
}

$errors = @()
foreach ($requirement in $requiredPatterns.GetEnumerator()) {
    if ($source -notmatch $requirement.Value) {
        $errors += "Missing $($requirement.Key) contract."
    }
}

if ($source -match "Mock response only") {
    $errors += "The governed-action branch still contains mock-only behavior."
}

[xml]$relationships = Get-Content -Path $relationshipsPath -Raw
$siteReviewFlowIds = @(
    $relationships.botcomponent_workflowset.botcomponent_workflow |
        Where-Object {
            [string]$_."botcomponentid.schemaname" -eq "copilots_header_04c70.topic.OwnerSiteReview"
        } |
        ForEach-Object {
            ([string]$_."workflowid.workflowid").ToLowerInvariant()
        }
)

foreach ($requiredFlowId in @(
    "4190243f-b9b3-f111-aaac-000d3a367627",
    "7f675f00-bab3-f111-aaac-000d3a367627"
)) {
    if ($requiredFlowId -notin $siteReviewFlowIds) {
        $errors += "The Site Review relationship for flow '$requiredFlowId' is missing."
    }
}

[xml]$processorMetadata = Get-Content -Path $processorMetadataPath -Raw
if (
    [string]$processorMetadata.Workflow.StateCode -ne "1" -or
    [string]$processorMetadata.Workflow.StatusCode -ne "2"
) {
    $errors += "The scheduled request processor is not active in canonical solution metadata."
}

if ($errors.Count -gt 0) {
    throw ("Governed-action topic validation failed:`n - " + ($errors -join "`n - "))
}

Write-Host (
    "Governed-action topic validation passed. Actions: 4; " +
    "authorization flows: exact-site read and request submission; mock behavior: 0."
) -ForegroundColor Green
