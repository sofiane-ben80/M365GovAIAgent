param(
    [string]$EnvironmentId = $env:POWER_PLATFORM_ENVIRONMENT_ID,
    [string]$SolutionName = "Governor365",
    [switch]$Create,
    [switch]$Publish,
    [string[]]$AgentKey,
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($EnvironmentId)) {
    throw "Provide -EnvironmentId or set POWER_PLATFORM_ENVIRONMENT_ID."
}

$agentDefinitions = @(
    @{
        Key = "governance-policy-advisor"
        DisplayName = "Governance Policy Advisor"
        SchemaName = "copilots_gov_policy_01"
    },
    @{
        Key = "copilot-readiness-advisor"
        DisplayName = "Copilot Readiness Advisor"
        SchemaName = "copilots_copilot_readiness_01"
    },
    @{
        Key = "data-protection-advisor"
        DisplayName = "Data Protection Advisor"
        SchemaName = "copilots_data_protection_01"
    },
    @{
        Key = "identity-governance-advisor"
        DisplayName = "Identity Governance Advisor"
        SchemaName = "copilots_identity_governance_01"
    },
    @{
        Key = "security-compliance-assurance"
        DisplayName = "Security & Compliance Assurance"
        SchemaName = "copilots_security_assurance_01"
    }
)

function Invoke-Pac {
    param([string[]]$Arguments)

    $displayCommand = "pac " + ($Arguments -join " ")
    if ($DryRun) {
        Write-Host "[DryRun] $displayCommand"
        return @()
    }

    Write-Host "> $displayCommand"
    $output = & pac @Arguments 2>&1
    $output | Write-Host
    $outputText = $output -join [Environment]::NewLine
    if (
        $LASTEXITCODE -ne 0 -or
        $outputText -match "(?im)non-recoverable error|^Error:"
    ) {
        throw "Command failed: $displayCommand"
    }

    return @($output)
}

function Get-MarkdownSection {
    param(
        [string]$Content,
        [string]$Heading
    )

    $escapedHeading = [regex]::Escape($Heading)
    $match = [regex]::Match(
        $Content,
        "(?ms)^## $escapedHeading\s*\r?\n(?<body>.*?)(?=^## |\z)"
    )
    if (-not $match.Success) {
        throw "Required section not found: $Heading"
    }

    return $match.Groups["body"].Value.Trim()
}

function New-AgentTemplate {
    param(
        [hashtable]$Agent,
        [string]$SourcePath,
        [string]$OutputDirectory
    )

    $content = Get-Content -Path $SourcePath -Raw
    $description = Get-MarkdownSection -Content $content -Heading "Description"
    $instructions = Get-MarkdownSection -Content $content -Heading "Instructions"

    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

    $template = [ordered]@{
        version = "1.0.0"
        metadata = [ordered]@{
            templateName = "kickStartTemplate"
            templateVersion = "1.0.0"
            name = $Agent.DisplayName
            description = $description
            source = "CopilotStudio"
            quality = "PrivatePreview"
            iconBase64 = $null
            iconAltText = $null
            isGpt = $false
            documentationUri = $null
            supportedLanguages = @()
            industries = @()
            categories = @()
        }
        content = [ordered]@{
            displayName = $Agent.DisplayName
            description = $description
            instructions = $instructions
            conversationStarters = @()
        }
        customizations = [ordered]@{
            schema = [ordered]@{
                type = "object"
                properties = [ordered]@{}
            }
        }
        spec = [ordered]@{
            connectors = @()
        }
    }

    $jsonPath = Join-Path $OutputDirectory "kickStartTemplate-1.0.0.json"
    $template | ConvertTo-Json -Depth 20 |
        Set-Content -Path $jsonPath -Encoding UTF8

    $yaml = @"
kind: BotDefinition
entity:
  accessControlPolicy: GroupMembership
  authenticationMode: Integrated
  authenticationTrigger: Always
  configuration:
    settings:
      GenerativeActionsEnabled: true

  template: kickStartTemplate-1.0.0

components: []
"@
    $yamlPath = Join-Path $OutputDirectory "agent-template.yml"
    Set-Content -Path $yamlPath -Value $yaml -Encoding UTF8

    return $yamlPath
}

function Write-AgentGptComponent {
    param(
        [hashtable]$Agent,
        [string]$SourcePath,
        [string]$SolutionDirectory
    )

    $content = Get-Content -Path $SourcePath -Raw
    $description = Get-MarkdownSection -Content $content -Heading "Description"
    $instructions = Get-MarkdownSection -Content $content -Heading "Instructions"
    $componentSchemaName = "$($Agent.SchemaName).gpt.default"
    $componentDirectory = Join-Path `
        $SolutionDirectory `
        "botcomponents\$componentSchemaName"
    New-Item -ItemType Directory -Path $componentDirectory -Force | Out-Null

    $escapedDescription = [Security.SecurityElement]::Escape($description)
    $escapedDisplayName = [Security.SecurityElement]::Escape($Agent.DisplayName)
    $componentXml = @(
        "<botcomponent schemaname=`"$componentSchemaName`">",
        "  <componenttype>15</componenttype>",
        "  <description>$escapedDescription</description>",
        "  <iscustomizable>0</iscustomizable>",
        "  <name>$escapedDisplayName</name>",
        "  <parentbotid>",
        "    <schemaname>$($Agent.SchemaName)</schemaname>",
        "  </parentbotid>",
        "  <statecode>0</statecode>",
        "  <statuscode>1</statuscode>",
        "</botcomponent>"
    ) -join [Environment]::NewLine
    Set-Content `
        -Path (Join-Path $componentDirectory "botcomponent.xml") `
        -Value $componentXml `
        -Encoding UTF8

    $indentedInstructions = ($instructions -split "\r?\n" |
        ForEach-Object { "  $_" }) -join [Environment]::NewLine
    $componentData = @(
        "kind: GptComponentMetadata",
        "displayName: $($Agent.DisplayName)",
        "instructions: |",
        $indentedInstructions,
        "responseInstructions:",
        "gptCapabilities:",
        "  webBrowsing: false",
        "  codeInterpreter: false",
        "",
        "aISettings:",
        "  model: {}"
    ) -join [Environment]::NewLine
    Set-Content `
        -Path (Join-Path $componentDirectory "data") `
        -Value $componentData `
        -Encoding UTF8
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$newAgentsRoot = Join-Path $repoRoot "new-agents"
$outputRoot = Join-Path $PSScriptRoot "exports\advisor-publish"

$selectedAgentKeys = @($AgentKey | Where-Object {
    -not [string]::IsNullOrWhiteSpace($_)
})
if ($selectedAgentKeys.Count -gt 0) {
    $unknownKeys = @($selectedAgentKeys | Where-Object {
        $_ -notin $agentDefinitions.Key
    })
    if ($unknownKeys.Count -gt 0) {
        throw "Unknown agent key(s): $($unknownKeys -join ', ')"
    }
    $agentDefinitions = @($agentDefinitions | Where-Object {
        $_.Key -in $selectedAgentKeys
    })
}

$inventoryOutput = Invoke-Pac -Arguments @(
    "copilot", "list",
    "--environment", $EnvironmentId
)
$inventoryText = $inventoryOutput -join [Environment]::NewLine

foreach ($agent in $agentDefinitions) {
    $sourcePath = Join-Path $newAgentsRoot "$($agent.Key).md"
    if (-not (Test-Path -Path $sourcePath -PathType Leaf)) {
        throw "Agent source not found: $sourcePath"
    }

    $existingMatch = [regex]::Match(
        $inventoryText,
        "(?m)^$([regex]::Escape($agent.DisplayName))\s+(?<id>[0-9a-fA-F-]{36})\s+(?<componentState>\S+)\s+"
    )

    if ($existingMatch.Success) {
        $botId = $existingMatch.Groups["id"].Value
        $componentState = $existingMatch.Groups["componentState"].Value
        Write-Host "$($agent.DisplayName) already exists: $botId"
    }
    elseif ($Create) {
        $agentOutputDirectory = Join-Path $outputRoot $agent.Key
        $templatePath = New-AgentTemplate `
            -Agent $agent `
            -SourcePath $sourcePath `
            -OutputDirectory $agentOutputDirectory

        Push-Location $agentOutputDirectory
        try {
            Invoke-Pac -Arguments @(
                "copilot", "create",
                "--environment", $EnvironmentId,
                "--schemaName", $agent.SchemaName,
                "--templateFileName", $templatePath,
                "--displayName", $agent.DisplayName,
                "--solution", $SolutionName
            ) | Out-Null
        }
        finally {
            Pop-Location
        }

        if ($DryRun) {
            if ($Publish) {
                Write-Host "[DryRun] Publish will run after the created bot ID is resolved."
            }
            continue
        }

        $refreshedOutput = Invoke-Pac -Arguments @(
            "copilot", "list",
            "--environment", $EnvironmentId
        )
        $refreshedText = $refreshedOutput -join [Environment]::NewLine
        $createdMatch = [regex]::Match(
            $refreshedText,
            "(?m)^$([regex]::Escape($agent.DisplayName))\s+(?<id>[0-9a-fA-F-]{36})\s+(?<componentState>\S+)\s+"
        )
        if (-not $createdMatch.Success) {
            throw "Created agent was not found in live inventory: $($agent.DisplayName)"
        }
        $botId = $createdMatch.Groups["id"].Value
        $componentState = $createdMatch.Groups["componentState"].Value
        $inventoryText = $refreshedText
        Write-Host "Created $($agent.DisplayName): $botId"
    }
    else {
        if ($DryRun) {
            Write-Host "[DryRun] Deployment state was not queried for $($agent.DisplayName)."
        }
        else {
            Write-Host "$($agent.DisplayName) is not deployed. Use -Create to create it."
        }
        continue
    }

    if ($Publish -and $componentState -ne "Published") {
        Invoke-Pac -Arguments @(
            "copilot", "publish",
            "--environment", $EnvironmentId,
            "--bot", $botId
        ) | Out-Null
    }
    elseif ($Publish) {
        Write-Host "$($agent.DisplayName) already reports Published; skipping redundant publish."
    }

    if ($Publish) {
        Invoke-Pac -Arguments @(
            "copilot", "status",
            "--environment", $EnvironmentId,
            "--bot-id", $botId
        ) | Out-Null
    }
}

if ($Publish -and $DryRun) {
    Write-Host "[DryRun] Export $SolutionName, add GPT metadata components, pack the solution, and import with published customizations."
    return
}

if ($Publish) {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $solutionZip = Join-Path $outputRoot "$SolutionName-$timestamp.zip"
    $solutionDirectory = Join-Path $outputRoot "$SolutionName-$timestamp"
    $patchedZip = Join-Path $outputRoot "$SolutionName-advisors-$timestamp.zip"

    Invoke-Pac -Arguments @(
        "solution", "export",
        "--environment", $EnvironmentId,
        "--name", $SolutionName,
        "--path", $solutionZip,
        "--overwrite",
        "--managed", "false"
    ) | Out-Null

    Invoke-Pac -Arguments @(
        "solution", "unpack",
        "--zipfile", $solutionZip,
        "--folder", $solutionDirectory,
        "--packagetype", "Unmanaged",
        "--allowWrite",
        "--clobber"
    ) | Out-Null

    foreach ($agent in $agentDefinitions) {
        $sourcePath = Join-Path $newAgentsRoot "$($agent.Key).md"
        Write-AgentGptComponent `
            -Agent $agent `
            -SourcePath $sourcePath `
            -SolutionDirectory $solutionDirectory
    }

    Invoke-Pac -Arguments @(
        "solution", "pack",
        "--zipfile", $patchedZip,
        "--folder", $solutionDirectory,
        "--packagetype", "Unmanaged"
    ) | Out-Null

    Invoke-Pac -Arguments @(
        "solution", "import",
        "--environment", $EnvironmentId,
        "--path", $patchedZip,
        "--publish-changes"
    ) | Out-Null
}
