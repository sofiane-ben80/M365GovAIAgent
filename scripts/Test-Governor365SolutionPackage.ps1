<#
.SYNOPSIS
    Verifies that a Governor365 managed solution contains the required components.

.DESCRIPTION
    Reads a Power Platform solution ZIP without extracting it and fails when
    the package is unmanaged or does not contain the documented Dataverse
    tables, Power Automate workflows, and Copilot Studio agents.

.PARAMETER Path
    Path to the managed Governor365 solution ZIP.

.EXAMPLE
    .\Test-Governor365SolutionPackage.ps1 `
      -Path .\release\Governor365_2_0_0_0_managed.zip
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$requiredTables = @(
    "sb_governancesite",
    "sb_siteownerassignment",
    "sb_governanceactionrequest",
    "sb_governanceactionevent",
    "sb_governancepolicysetting",
    "sb_governancescanrun",
    "sb_scanworkitem",
    "sb_notificationdelivery",
    "sb_evidencesnapshot"
)

Add-Type -AssemblyName System.IO.Compression.FileSystem
$resolvedPath = (Resolve-Path -LiteralPath $Path).Path
$archive = [System.IO.Compression.ZipFile]::OpenRead($resolvedPath)

try {
    $entryNames = @($archive.Entries | ForEach-Object FullName)
    $solutionEntry = $archive.GetEntry("solution.xml")
    $customizationsEntry = $archive.GetEntry("customizations.xml")
    $errors = [System.Collections.Generic.List[string]]::new()

    if ($null -eq $solutionEntry) {
        $errors.Add("solution.xml is missing.")
    }

    if ($null -eq $customizationsEntry) {
        $errors.Add("customizations.xml is missing.")
    }

    $solutionXml = ""
    if ($null -ne $solutionEntry) {
        $reader = [System.IO.StreamReader]::new($solutionEntry.Open())
        try {
            $solutionXml = $reader.ReadToEnd()
        }
        finally {
            $reader.Dispose()
        }
    }

    $customizationsXml = ""
    if ($null -ne $customizationsEntry) {
        $reader = [System.IO.StreamReader]::new($customizationsEntry.Open())
        try {
            $customizationsXml = $reader.ReadToEnd()
        }
        finally {
            $reader.Dispose()
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($solutionXml)) {
        [xml] $manifest = $solutionXml
        $solution = $manifest.ImportExportXml.SolutionManifest

        if ([string]$solution.Managed -ne "1") {
            $errors.Add("The package is not managed.")
        }

        if ([string]::IsNullOrWhiteSpace([string]$solution.UniqueName)) {
            $errors.Add("The solution unique name is missing.")
        }
    }

    $packageXml = "$solutionXml`n$customizationsXml"
    $missingTables = @(
        $requiredTables |
            Where-Object {
                $packageXml.IndexOf($_, [StringComparison]::OrdinalIgnoreCase) -lt 0
            }
    )
    if ($missingTables.Count -gt 0) {
        $errors.Add("Missing Dataverse tables: $($missingTables -join ', ').")
    }

    $workflowEntries = @(
        $entryNames |
            Where-Object { $_ -match '^Workflows/.+\.json$' }
    )
    if ($workflowEntries.Count -eq 0) {
        $errors.Add("No Power Automate cloud flows were found.")
    }

    $botEntries = @(
        $entryNames |
            Where-Object { $_ -match '^bots/[^/]+/bot\.xml$' }
    )
    if ($botEntries.Count -eq 0) {
        $errors.Add("No Copilot Studio agents were found.")
    }

    if ($errors.Count -gt 0) {
        throw "Solution package validation failed:`n - $($errors -join "`n - ")"
    }

    [pscustomobject]@{
        Path             = $resolvedPath
        UniqueName       = [string]$solution.UniqueName
        Version          = [string]$solution.Version
        Managed          = $true
        RequiredTables   = $requiredTables.Count
        CloudFlows       = $workflowEntries.Count
        CopilotAgents    = $botEntries.Count
        Sha256           = (Get-FileHash -LiteralPath $resolvedPath -Algorithm SHA256).Hash
    }
}
finally {
    $archive.Dispose()
}
