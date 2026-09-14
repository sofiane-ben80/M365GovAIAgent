param(
    [ValidateSet("status", "pull", "publish")]
    [string]$Mode = "status",

    [string]$AgentPath = ".\M365 Governance Agent",

    [switch]$AllowDirty,

    [switch]$AllowMain
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Section {
    param([string]$Text)
    Write-Host ""
    Write-Host "=== $Text ===" -ForegroundColor Cyan
}

function Test-GitRepo {
    $null = git rev-parse --show-toplevel 2>$null
    return ($LASTEXITCODE -eq 0)
}

function Get-CurrentBranch {
    if (-not (Test-GitRepo)) {
        return "(no-git)"
    }
    (git branch --show-current).Trim()
}

function Get-DirtyCount {
    if (-not (Test-GitRepo)) {
        return 0
    }
    (git status --porcelain | Measure-Object).Count
}

function Assert-CleanWorktree {
    if ($AllowDirty) {
        return
    }

    $dirtyCount = Get-DirtyCount
    if ($dirtyCount -gt 0) {
        throw "Working tree is dirty ($dirtyCount changed items). Commit or stash first, or use -AllowDirty."
    }
}

function Show-Status {
    Write-Section "Repository"
    if (-not (Test-GitRepo)) {
        Write-Warning "Current folder is not a git repository. Git sync details are unavailable."
        Write-Section "Agent Folder Check"
        if (Test-Path $AgentPath) {
            Write-Host "Agent folder found: $AgentPath"
        }
        else {
            Write-Warning "Agent folder not found: $AgentPath"
        }
        return
    }

    $branch = Get-CurrentBranch
    Write-Host "Branch: $branch"

    $upstream = (git rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2>$null).Trim()
    if ($LASTEXITCODE -eq 0 -and $upstream) {
        $counts = (git rev-list --left-right --count "$upstream...HEAD").Trim().Split(" ")
        if ($counts.Count -eq 2) {
            Write-Host "Behind/Ahead vs ${upstream}: $($counts[0])/$($counts[1])"
        }
    }
    else {
        Write-Host "No upstream tracking branch configured."
    }

    Write-Section "Working Tree"
    git status --short

    Write-Section "Recent Commits"
    git log --oneline -n 5

    Write-Section "Agent Folder Check"
    if (Test-Path $AgentPath) {
        Write-Host "Agent folder found: $AgentPath"
    }
    else {
        Write-Warning "Agent folder not found: $AgentPath"
    }
}

function Prompt-Continue {
    param([string]$Message)
    Write-Host ""
    Read-Host $Message | Out-Null
}

function Prompt-YesNo {
    param([string]$Question)
    while ($true) {
        $answer = (Read-Host "$Question [y/n]").Trim().ToLowerInvariant()
        if ($answer -in @("y", "yes")) { return $true }
        if ($answer -in @("n", "no")) { return $false }
    }
}

function Commit-IfWanted {
    if (-not (Test-GitRepo)) {
        Write-Host "Skipping commit: not a git repository."
        return
    }

    if ((Get-DirtyCount) -eq 0) {
        Write-Host "No file changes to commit."
        return
    }

    if (-not (Prompt-YesNo "Create a commit for these sync changes now?")) {
        return
    }

    $defaultMessage = "chore(sync): update local copy from Copilot Studio"
    $message = Read-Host "Commit message (Enter for default)"
    if ([string]::IsNullOrWhiteSpace($message)) {
        $message = $defaultMessage
    }

    git add -A
    git commit -m $message
}

function Run-PullWorkflow {
    Assert-CleanWorktree
    Show-Status

    Write-Section "Pull From Copilot Studio"
    Write-Host "1) In VS Code Copilot Studio panel, run Pull/Download latest agent."
    Write-Host "2) Return here after pull completes."
    Prompt-Continue "Press Enter after Copilot Studio pull is complete"

    Write-Section "Post-Pull Changes"
    if (Test-GitRepo) {
        git status --short
    }
    else {
        Write-Host "No git status available in this folder."
    }
    Commit-IfWanted

    Write-Host ""
    Write-Host "Pull sync helper complete."
}

function Run-PublishWorkflow {
    $branch = Get-CurrentBranch
    if (-not $AllowMain -and $branch -in @("main", "master", "dev")) {
        throw "Current branch is '$branch'. Switch to a feature branch, or use -AllowMain to override."
    }

    Write-Section "Pre-Publish Status"
    Show-Status

    if ((Get-DirtyCount) -gt 0) {
        Write-Warning "You have uncommitted local changes."
        if (-not $AllowDirty) {
            throw "Commit local changes before publish, or re-run with -AllowDirty."
        }
    }

    Write-Section "Publish To Copilot Studio"
    Write-Host "1) In VS Code Copilot Studio panel, run Publish/Push for the agent."
    Write-Host "2) After publishing, pull once to capture server-side metadata updates."
    Prompt-Continue "Press Enter after publish + post-publish pull are complete"

    Write-Section "Post-Publish Changes"
    if (Test-GitRepo) {
        git status --short
    }
    else {
        Write-Host "No git status available in this folder."
    }
    Commit-IfWanted

    Write-Host ""
    Write-Host "Publish sync helper complete."
}

switch ($Mode) {
    "status"  { Show-Status }
    "pull"    { Run-PullWorkflow }
    "publish" { Run-PublishWorkflow }
}
