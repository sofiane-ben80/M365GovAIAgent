param(
    [string]$EnvironmentId = $env:POWER_PLATFORM_ENVIRONMENT_ID,

    [string]$PrimaryBotId = $env:COPILOT_STUDIO_BOT_ID,

    [switch]$Publish,

    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptPath = Join-Path $PSScriptRoot "deploy-copilot-agent.ps1"
$repositoryRoot = (Resolve-Path -Path (Join-Path $PSScriptRoot "..\..")).Path
$authenticationTestPath = Join-Path $repositoryRoot "scripts\Test-ConnectedAgentAuthentication.ps1"

if (-not (Test-Path -Path $scriptPath -PathType Leaf)) {
    throw "Missing deployment helper: $scriptPath"
}

if (-not (Test-Path -Path $authenticationTestPath -PathType Leaf)) {
    throw "Missing connected-agent authentication test: $authenticationTestPath"
}

& $authenticationTestPath -SolutionPath (
    Join-Path $repositoryRoot "M365Governance_2_0_0_0"
)

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
