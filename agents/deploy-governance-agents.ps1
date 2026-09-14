param(
    [string]$EnvironmentId = $env:POWER_PLATFORM_ENVIRONMENT_ID,

    [string]$PrimaryBotId = $env:COPILOT_STUDIO_BOT_ID,

    [switch]$Publish,

    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptPath = Join-Path $PSScriptRoot "deploy-copilot-agent.ps1"

if (-not (Test-Path -Path $scriptPath -PathType Leaf)) {
    throw "Missing deployment helper: $scriptPath"
}

$projectDirs = @(
    ".\\M365 Governance Agent",
    ".\\Governance Admin Agent",
    ".\\Governance Owner Agent"
)

$params = @{
    ProjectDirs   = $projectDirs
    EnvironmentId = $EnvironmentId
    BotId         = $PrimaryBotId
    Publish       = $Publish
    DryRun        = $DryRun
}

& $scriptPath @params
