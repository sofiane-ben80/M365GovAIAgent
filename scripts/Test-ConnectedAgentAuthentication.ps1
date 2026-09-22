param(
    [string]$SolutionPath = (Join-Path $PSScriptRoot "..\M365Governance_2_0_0_0")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-BotAuthentication {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BotPath
    )

    if (-not (Test-Path -Path $BotPath -PathType Leaf)) {
        throw "Connected-agent bot definition was not found: $BotPath"
    }

    [xml]$botDocument = Get-Content -Path $BotPath -Raw
    $bot = $botDocument.bot
    [pscustomobject]@{
        Mode    = [string]$bot.authenticationmode
        Trigger = [string]$bot.authenticationtrigger
    }
}

$resolvedSolutionPath = (Resolve-Path -Path $SolutionPath).Path
$botsPath = Join-Path $resolvedSolutionPath "bots"
$componentsPath = Join-Path $resolvedSolutionPath "botcomponents"

if (-not (Test-Path -Path $botsPath -PathType Container)) {
    throw "Solution bots folder was not found: $botsPath"
}

if (-not (Test-Path -Path $componentsPath -PathType Container)) {
    throw "Solution botcomponents folder was not found: $componentsPath"
}

$connectedComponents = @(
    Get-ChildItem -Path $componentsPath -Directory |
        Where-Object {
            $_.Name -like "*.InvokeConnectedAgentTaskAction.*" -and
            (Test-Path -Path (Join-Path $_.FullName "botcomponent.xml") -PathType Leaf) -and
            (Test-Path -Path (Join-Path $_.FullName "data") -PathType Leaf)
        }
)

$validatedConnections = 0
foreach ($component in $connectedComponents) {
    $parentSchemaName = $component.Name.Split(".")[0]
    $componentDataPath = Join-Path $component.FullName "data"

    $schemaMatches = @(
        Select-String -Path $componentDataPath -Pattern "^\s*botSchemaName:\s*(?<schema>[A-Za-z0-9_]+)\s*$"
    )

    if ($schemaMatches.Count -ne 1) {
        throw "Expected exactly one botSchemaName in $componentDataPath; found $($schemaMatches.Count)."
    }

    $childSchemaName = $schemaMatches[0].Matches[0].Groups["schema"].Value
    $parentAuthentication = Get-BotAuthentication -BotPath (
        Join-Path $botsPath "$parentSchemaName\bot.xml"
    )

    if ($parentAuthentication.Mode -ne "2") {
        throw (
            "Unsupported connected-agent authentication: parent '$parentSchemaName' " +
            "uses authentication mode '$($parentAuthentication.Mode)' while component " +
            "'$($component.Name)' invokes another Copilot Studio agent. Copilot chat " +
            "supports connected-agent publication only with Integrated authentication. " +
            "Keep manual-authentication launchers free of InvokeConnectedAgentTaskAction components."
        )
    }

    $childAuthentication = Get-BotAuthentication -BotPath (
        Join-Path $botsPath "$childSchemaName\bot.xml"
    )

    $mismatchedFields = @()
    foreach ($field in @("Mode", "Trigger")) {
        if ($parentAuthentication.$field -cne $childAuthentication.$field) {
            $mismatchedFields += $field
        }
    }

    if ($mismatchedFields.Count -gt 0) {
        throw (
            "Connected agent authentication mismatch: parent '$parentSchemaName', " +
            "child '$childSchemaName', component '$($component.Name)'. " +
            "Mismatched fields: $($mismatchedFields -join ', '). " +
            "Connected agents must preserve the launcher's authentication mode and trigger."
        )
    }

    $validatedConnections++
}

Write-Host (
    "Connected-agent compatibility validation passed. Active connections: " +
    "$validatedConnections."
) -ForegroundColor Green
