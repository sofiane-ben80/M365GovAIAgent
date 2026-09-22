param(
    [string]$SolutionPath = (Join-Path $PSScriptRoot "..\M365Governance_2_0_0_0"),
    [string]$SolutionZipPath = (Join-Path $PSScriptRoot "..\M365Governance_2_0_0_0.zip"),
    [ValidateSet("Any", "Unmanaged", "Managed")]
    [string]$ExpectedPackageType = "Unmanaged"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$resolvedSolutionPath = (Resolve-Path -Path $SolutionPath).Path
$solutionManifestPath = Join-Path $resolvedSolutionPath "Other\Solution.xml"
$customizationsPath = Join-Path $resolvedSolutionPath "Other\Customizations.xml"
$componentRelationshipsPath = Join-Path $resolvedSolutionPath "Assets\botcomponent_workflowset.xml"
$botComponentsPath = Join-Path $resolvedSolutionPath "botcomponents"
$workflowsPath = Join-Path $resolvedSolutionPath "Workflows"

foreach ($requiredPath in @(
    $solutionManifestPath,
    $customizationsPath,
    $componentRelationshipsPath,
    $botComponentsPath,
    $workflowsPath
)) {
    if (-not (Test-Path -Path $requiredPath)) {
        throw "Required solution artifact was not found: $requiredPath"
    }
}

[xml]$solutionManifest = Get-Content -Path $solutionManifestPath -Raw
$missingDependencies = @(
    $solutionManifest.SelectNodes(
        "/ImportExportXml/SolutionManifest/MissingDependencies/MissingDependency"
    )
)

if ($missingDependencies.Count -gt 0) {
    $dependencyDescriptions = @(
        foreach ($dependency in $missingDependencies) {
            $required = $dependency.Required
            "'$($required.displayName)' (type $($required.type), id $($required.id))"
        }
    )

    throw (
        "The solution declares missing dependencies: " +
        ($dependencyDescriptions -join ", ") +
        ". Remove stale component relationships or add the required components before packaging."
    )
}

$rootComponents = @($solutionManifest.SelectNodes(
    "/ImportExportXml/SolutionManifest/RootComponents/RootComponent"
))
$entityRootNames = @(
    $rootComponents |
        Where-Object { [string]$_.type -eq "1" } |
        ForEach-Object { ([string]$_.schemaName).ToLowerInvariant() } |
        Sort-Object -Unique
)
$entityFolderNames = @(
    Get-ChildItem -Path (Join-Path $resolvedSolutionPath "Entities") -Directory |
        ForEach-Object { $_.Name.ToLowerInvariant() } |
        Sort-Object -Unique
)
if (Compare-Object $entityRootNames $entityFolderNames) {
    throw "Dataverse table root components do not match the unpacked Entities folders."
}

$workflowMetadataFiles = @(Get-ChildItem -Path $workflowsPath -Filter "*.json.data.xml" -File)
$workflowDefinitionFiles = @(Get-ChildItem -Path $workflowsPath -Filter "*.json" -File)
if ($workflowMetadataFiles.Count -ne $workflowDefinitionFiles.Count) {
    throw (
        "Workflow file mismatch: found $($workflowMetadataFiles.Count) metadata files and " +
        "$($workflowDefinitionFiles.Count) JSON definitions."
    )
}

$workflowIds = @(
    foreach ($metadataFile in $workflowMetadataFiles) {
        [xml]$workflowMetadata = Get-Content -Path $metadataFile.FullName -Raw
        ([string]$workflowMetadata.Workflow.WorkflowId).Trim("{}").ToLowerInvariant()
    }
)
$duplicateWorkflowIds = @(
    $workflowIds |
        Group-Object |
        Where-Object { $_.Count -gt 1 } |
        ForEach-Object { $_.Name }
)
if ($duplicateWorkflowIds.Count -gt 0) {
    throw "Duplicate workflow IDs were found: $($duplicateWorkflowIds -join ', ')."
}

$workflowRootIds = @(
    $rootComponents |
        Where-Object { [string]$_.type -eq "29" } |
        ForEach-Object { ([string]$_.id).Trim("{}").ToLowerInvariant() } |
        Sort-Object -Unique
)
if (Compare-Object ($workflowIds | Sort-Object -Unique) $workflowRootIds) {
    throw "Workflow root components do not match the unpacked workflow metadata."
}

[xml]$customizations = Get-Content -Path $customizationsPath -Raw
$declaredConnectionReferences = @(
    $customizations.ImportExportXml.connectionreferences.connectionreference |
        ForEach-Object {
            ([string]$_.connectionreferencelogicalname).ToLowerInvariant()
        } |
        Sort-Object -Unique
)
$usedConnectionReferences = @(
    Get-ChildItem -Path $workflowsPath -Filter "*.json" -File |
        Select-String -Pattern '"connectionReferenceLogicalName"\s*:\s*"(?<name>[^"]+)"' |
        ForEach-Object {
            $_.Matches[0].Groups["name"].Value.ToLowerInvariant()
        } |
        Sort-Object -Unique
)
$undeclaredConnectionReferences = @(
    $usedConnectionReferences |
        Where-Object { $_ -notin $declaredConnectionReferences }
)
if ($undeclaredConnectionReferences.Count -gt 0) {
    throw (
        "Workflows use undeclared connection references: " +
        ($undeclaredConnectionReferences -join ", ") +
        "."
    )
}

$canvasRootCount = @($rootComponents | Where-Object { [string]$_.type -eq "300" }).Count
$canvasFileCount = @(
    Get-ChildItem -Path (Join-Path $resolvedSolutionPath "CanvasApps") -Filter "*.meta.xml" -File
).Count
if ($canvasRootCount -ne $canvasFileCount -or $canvasRootCount -lt 1) {
    throw "Canvas app root components and unpacked metadata files do not match."
}

$controlRootCount = @($rootComponents | Where-Object { [string]$_.type -eq "66" }).Count
$controlFileCount = @(
    Get-ChildItem -Path (Join-Path $resolvedSolutionPath "Controls") -Filter "ControlManifest.xml" -File -Recurse
).Count
if ($controlRootCount -ne $controlFileCount -or $controlRootCount -lt 1) {
    throw "Code component root components and control manifests do not match."
}

$roleRootCount = @($rootComponents | Where-Object { [string]$_.type -eq "20" }).Count
$roleFileCount = @(
    Get-ChildItem -Path (Join-Path $resolvedSolutionPath "Roles") -Filter "*.xml" -File
).Count
if ($roleRootCount -ne $roleFileCount -or $roleRootCount -lt 1) {
    throw "Security role root components and unpacked role files do not match."
}

$botCount = @(
    Get-ChildItem -Path (Join-Path $resolvedSolutionPath "bots") -Filter "bot.xml" -File -Recurse
).Count
$botComponentCount = @(
    Get-ChildItem -Path $botComponentsPath -Filter "botcomponent.xml" -File -Recurse
).Count
$environmentVariableCount = @(
    Get-ChildItem -Path (
        Join-Path $resolvedSolutionPath "environmentvariabledefinitions"
    ) -Filter "environmentvariabledefinition.xml" -File -Recurse
).Count
if ($botCount -lt 1 -or $botComponentCount -lt 1 -or $environmentVariableCount -lt 1) {
    throw "Bots, bot components, and environment variables must all be present."
}

[xml]$componentRelationships = Get-Content -Path $componentRelationshipsPath -Raw
$declaredFlowIdsByComponent = @{}

Get-ChildItem -Path $botComponentsPath -Directory | ForEach-Object {
    $dataPath = Join-Path $_.FullName "data"
    if (-not (Test-Path -Path $dataPath -PathType Leaf)) {
        return
    }

    $flowIds = @(
        Select-String -Path $dataPath -Pattern "^\s*flowId:\s*(?<id>[0-9a-fA-F-]{36})\s*$" |
            ForEach-Object { $_.Matches[0].Groups["id"].Value.ToLowerInvariant() } |
            Sort-Object -Unique
    )

    if ($flowIds.Count -gt 0) {
        $declaredFlowIdsByComponent[$_.Name] = $flowIds
    }
}

$relationshipErrors = @()
foreach ($relationship in @($componentRelationships.botcomponent_workflowset.botcomponent_workflow)) {
    $componentSchemaName = [string]$relationship."botcomponentid.schemaname"
    $workflowId = ([string]$relationship."workflowid.workflowid").ToLowerInvariant()

    if (-not $declaredFlowIdsByComponent.ContainsKey($componentSchemaName)) {
        $relationshipErrors += (
            "Relationship '$componentSchemaName' -> '$workflowId' has no active flowId in the component definition."
        )
        continue
    }

    if ($workflowId -notin $declaredFlowIdsByComponent[$componentSchemaName]) {
        $relationshipErrors += (
            "Relationship '$componentSchemaName' -> '$workflowId' is stale. " +
            "Active flowIds: $($declaredFlowIdsByComponent[$componentSchemaName] -join ', ')."
        )
    }
}

foreach ($componentSchemaName in $declaredFlowIdsByComponent.Keys) {
    $relatedFlowIds = @(
        $componentRelationships.botcomponent_workflowset.botcomponent_workflow |
            Where-Object {
                [string]$_."botcomponentid.schemaname" -eq $componentSchemaName
            } |
            ForEach-Object {
                ([string]$_."workflowid.workflowid").ToLowerInvariant()
            }
    )

    foreach ($flowId in $declaredFlowIdsByComponent[$componentSchemaName]) {
        if ($flowId -notin $relatedFlowIds) {
            $relationshipErrors += (
                "Component '$componentSchemaName' declares flowId '$flowId' but the solution relationship is missing."
            )
        }
    }
}

if ($relationshipErrors.Count -gt 0) {
    throw (
        "Bot component workflow validation failed:`n - " +
        ($relationshipErrors -join "`n - ")
    )
}

$flowBindingCount = @(
    $componentRelationships.botcomponent_workflowset.botcomponent_workflow
).Count

$resolvedSolutionZipPath = (Resolve-Path -Path $SolutionZipPath).Path
Add-Type -AssemblyName System.IO.Compression.FileSystem
$solutionArchive = [System.IO.Compression.ZipFile]::OpenRead($resolvedSolutionZipPath)
try {
    $packageEntries = @($solutionArchive.Entries)
    $packageSolutionEntry = $solutionArchive.GetEntry("solution.xml")
    if ($null -eq $packageSolutionEntry) {
        throw "The solution ZIP does not contain solution.xml at its root."
    }

    $solutionReader = [System.IO.StreamReader]::new($packageSolutionEntry.Open())
    try {
        [xml]$packageSolutionManifest = $solutionReader.ReadToEnd()
    }
    finally {
        $solutionReader.Dispose()
    }

    $packageManagedValue = [string]$packageSolutionManifest.ImportExportXml.SolutionManifest.Managed
    $expectedManagedValue = switch ($ExpectedPackageType) {
        "Managed" { "1" }
        "Unmanaged" { "0" }
        default { $packageManagedValue }
    }
    if ($packageManagedValue -ne $expectedManagedValue) {
        throw (
            "Expected a $ExpectedPackageType package but solution.xml has Managed=" +
            "'$packageManagedValue'."
        )
    }

    $packageWorkflowCount = @(
        $packageEntries | Where-Object { $_.FullName -like "Workflows/*.json" }
    ).Count
    $packageCanvasCount = @(
        $packageEntries | Where-Object { $_.FullName -like "CanvasApps/*.msapp" }
    ).Count
    $packageBotCount = @(
        $packageEntries | Where-Object { $_.FullName -like "bots/*/bot.xml" }
    ).Count
    $packageBotComponentCount = @(
        $packageEntries |
            Where-Object { $_.FullName -like "botcomponents/*/botcomponent.xml" }
    ).Count
    $packageEnvironmentVariableCount = @(
        $packageEntries |
            Where-Object {
                $_.FullName -like (
                    "environmentvariabledefinitions/*/environmentvariabledefinition.xml"
                )
            }
    ).Count
    $packageControlCount = @(
        $packageEntries |
            Where-Object { $_.FullName -like "Controls/*/ControlManifest.xml" }
    ).Count

    $packageComparisons = @{
        "workflows" = @($packageWorkflowCount, $workflowDefinitionFiles.Count)
        "Canvas apps" = @($packageCanvasCount, $canvasFileCount)
        "bots" = @($packageBotCount, $botCount)
        "bot components" = @($packageBotComponentCount, $botComponentCount)
        "environment variables" = @($packageEnvironmentVariableCount, $environmentVariableCount)
        "code components" = @($packageControlCount, $controlFileCount)
    }
    $packageErrors = @(
        foreach ($componentType in $packageComparisons.Keys) {
            $counts = $packageComparisons[$componentType]
            if ($counts[0] -ne $counts[1]) {
                "$componentType (ZIP $($counts[0]), source $($counts[1]))"
            }
        }
    )
    if ($packageErrors.Count -gt 0) {
        throw "Solution ZIP/source component mismatch: $($packageErrors -join '; ')."
    }
}
finally {
    $solutionArchive.Dispose()
}

Write-Host (
    "Solution package integrity validation passed. Tables: $($entityRootNames.Count); " +
    "security roles: $roleFileCount; distinct workflows: $($workflowIds.Count); " +
    "flow-bound agent components: $($declaredFlowIdsByComponent.Count); " +
    "topic-to-flow relationships: $flowBindingCount; Canvas apps: $canvasFileCount; " +
    "bots: $botCount; bot components: $botComponentCount; " +
    "environment variables: $environmentVariableCount; connection references: " +
    "$($declaredConnectionReferences.Count); code components: $controlFileCount; " +
    "missing dependencies: 0; package type: $ExpectedPackageType."
) -ForegroundColor Green
