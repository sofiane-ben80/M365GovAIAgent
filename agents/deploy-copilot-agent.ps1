param(
    [string]$ProjectDir = ".\M365 Governance Agent",

    [string[]]$ProjectDirs = @(),

    [string]$EnvironmentId = $env:POWER_PLATFORM_ENVIRONMENT_ID,

    [string]$BotId = $env:COPILOT_STUDIO_BOT_ID,

    [string]$PacPath,

    [switch]$Publish,

    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:PacErrorPatterns = @(
    "Error:",
    "is not understood in this context",
    "unknown argument",
    "required argument"
)

$script:PacExe = "pac"

function Write-Section {
    param([string]$Text)
    Write-Host ""
    Write-Host "=== $Text ===" -ForegroundColor Cyan
}

function Test-OutputHasPacError {
    param([string[]]$Lines)

    foreach ($line in $Lines) {
        foreach ($pattern in $script:PacErrorPatterns) {
            if ($line -match [regex]::Escape($pattern)) {
                return $true
            }
        }
    }

    return $false
}

function Invoke-CommandChecked {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [string[]]$Arguments = @(),

        [switch]$TreatPacOutputErrorsAsFailure
    )

    $display = if ($Arguments.Count -gt 0) {
        "$FilePath " + ($Arguments -join " ")
    }
    else {
        $FilePath
    }

    if ($DryRun) {
        Write-Host "[DryRun] $display"
        return
    }

    Write-Host "> $display" -ForegroundColor DarkGray
    $output = & $FilePath @Arguments 2>&1
    if ($output) {
        $output | ForEach-Object { Write-Host $_ }
    }

    if ($LASTEXITCODE -ne 0) {
        throw "Command failed (exit $LASTEXITCODE): $display"
    }

    if ($TreatPacOutputErrorsAsFailure -and (Test-OutputHasPacError -Lines @($output | ForEach-Object { $_.ToString() }))) {
        throw "PAC reported an error while running: $display"
    }
}

function Test-PacCopilotPushSupport {
    param([Parameter(Mandatory = $true)][string]$CandidatePath)

    $output = & $CandidatePath copilot 2>&1
    if ($LASTEXITCODE -ne 0) {
        # Some PAC builds return non-zero while still printing command usage.
        # Keep evaluating output text instead of failing here.
    }

    $text = ($output | ForEach-Object { $_.ToString() }) -join "`n"
    return ($text -match "\bpush\b")
}

function Resolve-PacExecutable {
    if ($PacPath) {
        if (-not (Test-Path -Path $PacPath -PathType Leaf)) {
            throw "The specified -PacPath was not found: $PacPath"
        }
        if (-not (Test-PacCopilotPushSupport -CandidatePath $PacPath)) {
            throw "The specified -PacPath does not support 'pac copilot push': $PacPath"
        }
        return (Resolve-Path -Path $PacPath).Path
    }

    $candidates = @(Get-Command pac -All -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -Unique)
    if (-not $candidates -or $candidates.Count -eq 0) {
        throw "Power Platform CLI (pac) is not installed or not available on PATH."
    }

    foreach ($candidate in $candidates) {
        if (Test-PacCopilotPushSupport -CandidatePath $candidate) {
            return $candidate
        }
    }

    $candidateList = ($candidates | ForEach-Object { "  - $_" }) -join "`n"
    throw @"
No PAC executable with 'copilot push' support was found.

Checked:
$candidateList

Use the Power Platform VS Code extension bundled PAC, or install/update PAC using an official installer, then rerun.
You can also pass an explicit path with -PacPath.
"@
}

$script:PacExe = Resolve-PacExecutable

if ([string]::IsNullOrWhiteSpace($EnvironmentId)) {
    throw "Provide -EnvironmentId or set POWER_PLATFORM_ENVIRONMENT_ID."
}

if ($Publish -and [string]::IsNullOrWhiteSpace($BotId)) {
    throw "-Publish requires -BotId or COPILOT_STUDIO_BOT_ID."
}

$effectiveProjectDirs = @()
if ($ProjectDirs -and $ProjectDirs.Count -gt 0) {
    $effectiveProjectDirs = $ProjectDirs
}
else {
    $effectiveProjectDirs = @($ProjectDir)
}

# Validate project folders
foreach ($dir in $effectiveProjectDirs) {
    if (-not (Test-Path -Path $dir -PathType Container)) {
        throw "Agent project folder not found: $dir"
    }
}

Write-Section "Auth Context"
Write-Host "Using PAC: $script:PacExe"
Invoke-CommandChecked -FilePath $script:PacExe -Arguments @("auth", "who") -TreatPacOutputErrorsAsFailure

Write-Section "Select Environment"
Invoke-CommandChecked -FilePath $script:PacExe -Arguments @("env", "select", "--environment", $EnvironmentId) -TreatPacOutputErrorsAsFailure

Write-Section "Push Agent(s) to Copilot Studio"
foreach ($dir in $effectiveProjectDirs) {
    Write-Host "Deploying project: $dir" -ForegroundColor Yellow
    Invoke-CommandChecked -FilePath $script:PacExe -Arguments @("copilot", "push", "--project-dir", $dir) -TreatPacOutputErrorsAsFailure
}

if ($Publish) {
    Write-Section "Publish Agent"
    Write-Host "Opening Copilot Studio for publish..."
    $studioUrl = "https://copilotstudio.microsoft.com/environments/$EnvironmentId/bots/$BotId/"
    Start-Process $studioUrl
    Write-Host "Complete publish manually in the browser, or use the Copilot Studio VS Code extension."
}

Write-Section "Done"
Write-Host "Agent deployment completed successfully." -ForegroundColor Green
Write-Host "Projects deployed: $($effectiveProjectDirs -join ', ')"
if (-not [string]::IsNullOrWhiteSpace($BotId)) {
    Write-Host "Studio URL: https://copilotstudio.microsoft.com/environments/$EnvironmentId/bots/$BotId/"
}
