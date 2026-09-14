param(
    [string]$StartPath = ".",
    [string]$AgentPath = ".\\M365 Governance Agent",
    [switch]$AllowDirty,
    [switch]$AllowMain,
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$script:HasGit = $true

function Write-Section {
    param([string]$Text)
    Write-Host ""
    Write-Host "=== $Text ===" -ForegroundColor Cyan
}

function Find-GitRoot {
    param([string]$Path)

    $resolved = Resolve-Path -Path $Path
    $current = [System.IO.DirectoryInfo]::new($resolved.Path)

    while ($null -ne $current) {
        $gitDir = Join-Path $current.FullName ".git"
        if (Test-Path $gitDir) {
            return $current.FullName
        }

        $current = $current.Parent
    }

    return $null
}

function Prompt-Continue {
    param([string]$Message)

    if ($DryRun) {
        Write-Host "[DryRun] $Message"
        return
    }

    Write-Host ""
    Read-Host $Message | Out-Null
}

function Prompt-YesNo {
    param([string]$Question)

    if ($DryRun) {
        Write-Host "[DryRun] $Question -> yes"
        return $true
    }

    while ($true) {
        $answer = (Read-Host "$Question [y/n]").Trim().ToLowerInvariant()
        if ($answer -in @("y", "yes")) { return $true }
        if ($answer -in @("n", "no")) { return $false }
    }
}

function Get-DirtyCount {
    if (-not $script:HasGit) {
        return 0
    }

    (git status --porcelain | Measure-Object).Count
}

function Commit-IfWanted {
    param([string]$DefaultMessage)

    if (-not $script:HasGit) {
        Write-Host "Skipping commit: no git repository detected."
        return
    }

    if ((Get-DirtyCount) -eq 0) {
        Write-Host "No file changes to commit."
        return
    }

    git status --short

    if (-not (Prompt-YesNo "Create a commit now?")) {
        return
    }

    $message = $DefaultMessage
    if (-not $DryRun) {
        $typed = Read-Host "Commit message (Enter for default)"
        if (-not [string]::IsNullOrWhiteSpace($typed)) {
            $message = $typed
        }
    }
    else {
        Write-Host "[DryRun] Commit message: $DefaultMessage"
    }

    git add -A
    git commit -m $message
}

$gitRoot = Find-GitRoot -Path $StartPath
if (-not $gitRoot) {
    $script:HasGit = $false
    $resolvedStart = Resolve-Path -Path $StartPath
    $gitRoot = $resolvedStart.Path
}

Push-Location $gitRoot
try {
    Write-Section "Sync Cycle"
    Write-Host "Repository: $gitRoot"

    if ($script:HasGit) {
        $branch = (git branch --show-current).Trim()
        Write-Host "Current branch: $branch"

        if (-not $AllowMain -and $branch -in @("main", "master", "dev")) {
            throw "Current branch is '$branch'. Switch to a feature branch or rerun with -AllowMain."
        }

        if (-not $AllowDirty -and (Get-DirtyCount) -gt 0) {
            throw "Working tree is dirty. Commit or stash first, or rerun with -AllowDirty."
        }
    }
    else {
        Write-Warning "No git repository detected. Running checklist-only mode (no branch/commit automation)."
    }

    $agentFullPath = Join-Path $gitRoot $AgentPath
    if (Test-Path $agentFullPath) {
        Write-Host "Agent folder: $agentFullPath"
    }
    else {
        Write-Warning "Agent folder not found at: $agentFullPath"
    }

    Write-Section "Step 1: Pull From Copilot Studio"
    Write-Host "In VS Code Copilot Studio tools, run Pull/Download latest agent." 
    Prompt-Continue "Press Enter when pull is complete"

    Write-Section "Step 1a: Commit Pulled Changes"
    Commit-IfWanted -DefaultMessage "chore(sync): pull updates from Copilot Studio"

    Write-Section "Step 2: Publish Local Changes"
    Write-Host "In VS Code Copilot Studio tools, run Publish/Push agent."
    Prompt-Continue "Press Enter when publish is complete"

    Write-Section "Step 3: Pull Once More"
    Write-Host "Run Pull/Download again to capture server-side metadata updates."
    Prompt-Continue "Press Enter when post-publish pull is complete"

    Write-Section "Step 3a: Commit Post-Publish Changes"
    Commit-IfWanted -DefaultMessage "chore(sync): post-publish metadata sync"

    Write-Section "Done"
    if ($script:HasGit) {
        git status --short
    }
    else {
        Write-Host "No git status available in checklist-only mode."
    }
    Write-Host "Full sync cycle completed."
}
finally {
    Pop-Location
}
