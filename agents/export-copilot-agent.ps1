param(
    [string]$ProjectDir = ".\M365 Governance Agent",
    [string]$PublisherPrefix = "new",
    [string]$OutputDir = ".\exports",
    [string]$SolutionName,
    [string]$BotId,
    [string]$Environment,
    [switch]$IncludeTemplate,
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Section {
    param([string]$Text)
    Write-Host ""
    Write-Host "=== $Text ===" -ForegroundColor Cyan
}

function Run-Or-Show {
    param([string]$Command)

    if ($DryRun) {
        Write-Host "[DryRun] $Command"
        return
    }

    Write-Host "> $Command"
    Invoke-Expression $Command
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed: $Command"
    }
}

# Validate PAC CLI availability
try {
    $null = Get-Command pac -ErrorAction Stop
}
catch {
    throw "Power Platform CLI (pac) is not installed or not available on PATH."
}

# Validate project folder
if (-not (Test-Path -Path $ProjectDir -PathType Container)) {
    throw "Project folder not found: $ProjectDir"
}

# Ensure output folder
if (-not (Test-Path -Path $OutputDir -PathType Container)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$zipOutputPath = Resolve-Path -Path $OutputDir

Write-Section "Auth Context"
Run-Or-Show "pac auth who"

Write-Section "Step 1: Pull Latest Agent Changes"
$pullCmd = "pac copilot pull --project-dir `"$ProjectDir`""
Run-Or-Show $pullCmd

Write-Section "Step 2: Package Agent Workspace"
$packParts = @(
    "pac copilot pack",
    "--publisher-prefix `"$PublisherPrefix`"",
    "--project-dir `"$ProjectDir`"",
    "--output-path `"$($zipOutputPath.Path)`""
)

if (-not [string]::IsNullOrWhiteSpace($SolutionName)) {
    $packParts += "--solution-name `"$SolutionName`""
}

Run-Or-Show ($packParts -join " ")

Write-Section "Optional Step: Extract Template YAML"
if ($IncludeTemplate) {
    if ([string]::IsNullOrWhiteSpace($BotId)) {
        throw "-IncludeTemplate requires -BotId."
    }

    $templateFile = Join-Path $zipOutputPath.Path ("copilot-template-{0}.yml" -f $timestamp)
    $extractParts = @(
        "pac copilot extract-template",
        "--bot `"$BotId`"",
        "--templateFileName `"$templateFile`"",
        "--overwrite"
    )

    if (-not [string]::IsNullOrWhiteSpace($Environment)) {
        $extractParts += "--environment `"$Environment`""
    }

    Run-Or-Show ($extractParts -join " ")
    Write-Host "Template file: $templateFile"
}
else {
    Write-Host "Skipped. Use -IncludeTemplate -BotId <id> if you need a template YAML export."
}

Write-Section "Completed"
Write-Host "Export complete. Check output folder: $($zipOutputPath.Path)"
Write-Host "If pac pack generated multiple files, use the newest .zip for manual import."
