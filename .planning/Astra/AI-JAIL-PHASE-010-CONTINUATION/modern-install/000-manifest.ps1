# Phase 000 - PLAN snapshot
# Windows PowerShell 5.1

function New-AijPlanSnapshot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Root
    )

    $resolved = @(Resolve-Path -LiteralPath $Root -ErrorAction Stop)

    if ($resolved.Count -ne 1) {
        throw 'Installer root is ambiguous.'
    }

    $rootPath = $resolved[0].ProviderPath

    if (-not [IO.Directory]::Exists($rootPath)) {
        throw 'Installer root is not a directory.'
    }

    $rootAttributes = [IO.File]::GetAttributes($rootPath)

    if (($rootAttributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw 'Installer root reparse point rejected.'
    }

    # Load validated local libraries

    foreach ($name in @(
        '000-config.ps1',
        '000-dependencies.ps1'
    )) {
        $path = Join-Path $rootPath $name

        if (-not [IO.File]::Exists($path)) {
            throw "Required file missing: $name."
        }

        $attributes = [IO.File]::GetAttributes($path)

        if (($attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Reparse-point file rejected: $name."
        }
    }

    . (Join-Path $rootPath '000-config.ps1')
    . (Join-Path $rootPath '000-dependencies.ps1')

    $configPath = Join-Path $rootPath 'config.env'
    $config = Read-AijConfig -Path $configPath

    if ($null -eq $config -or $config.Count -ne 13) {
        throw 'Configuration validation returned an unexpected result.'
    }

    $inventory = @(Get-AijPhaseInventory -Root $rootPath)

    # Phase 000 approval contract

    $requirementsPath = Join-Path $rootPath '000-requirements.json'

    Assert-AijOrdinaryFile -Path $requirementsPath

    $requirements = Get-Content -LiteralPath $requirementsPath -Raw |
        ConvertFrom-Json -ErrorAction Stop

    if ($requirements.schema -ne 1 -or
        $requirements.phase -cne '000' -or
        $requirements.approvals.production_apply_authorized -cne $false -or
        $requirements.approvals.explicit_installation_approval -cne $true -or
        $requirements.approvals.resolve_versions_before_installation -cne $true -or
        $requirements.approvals.display_installation_plan -cne $true) {
        throw 'Phase 000 planning policy mismatch.'
    }

    # Source identities

    $names = New-Object 'System.Collections.Generic.List[string]'

    foreach ($name in @(
        '000-run-all.bat',
        '000-engine.ps1',
        '000-review.ps1',
        '000-config.ps1',
        '000-dependencies.ps1',
        '000-manifest.ps1',
        '000-state.ps1',
        '000-state-store.ps1',
        '000-requirements.json',
        '_common.bat',
        'config.env'
    )) {
        $names.Add($name)
    }

    foreach ($phase in $inventory) {
        $names.Add([IO.Path]::GetFileName($phase.EntryPoint))
        $names.Add([IO.Path]::GetFileName($phase.Requirements))
    }

    $sourceFiles = New-Object 'System.Collections.Generic.List[object]'

    foreach ($name in @($names | Sort-Object -Unique)) {
        $path = Join-Path $rootPath $name

        Assert-AijOrdinaryFile -Path $path

        $sourceFiles.Add([pscustomobject][ordered]@{
            Name = $name
            Sha256 = (
                Get-FileHash `
                    -LiteralPath $path `
                    -Algorithm SHA256
            ).Hash
        })
    }

    # Dependency inventory

    $phaseRecords = New-Object 'System.Collections.Generic.List[object]'

    foreach ($phase in $inventory) {
        $dependencyRecords = New-Object 'System.Collections.Generic.List[object]'

        foreach ($dependency in $phase.Dependencies) {
            $dependencyRecords.Add([pscustomobject][ordered]@{
                Phase = $dependency.Phase
                RequiredState = $dependency.RequiredState
                Source = $dependency.Source
            })
        }

        $phaseRecords.Add([pscustomobject][ordered]@{
            Id = $phase.Id
            Name = $phase.Name
            DeclaredMode = $phase.DeclaredMode
            SecurityCritical = [bool]$phase.SecurityCritical
            EntryPointSha256 = $phase.EntryPointSha256
            RequirementsSha256 = $phase.RequirementsSha256
            Dependencies = @($dependencyRecords.ToArray())
            ExecutionAuthorized = $false
        })
    }

    # Outstanding planning work

    $outstanding = New-Object 'System.Collections.Generic.List[string]'

    $outstanding.Add(
        'Phase action handlers and selections are unresolved.'
    )

    $outstanding.Add(
        'Approved versions and artifact integrity lock are missing.'
    )

    $outstanding.Add(
        'Target identity and storage location are unverified.'
    )

    $outstanding.Add(
        'Runtime prerequisite evidence is missing.'
    )

    $outstanding.Add(
        'Human approval has not been recorded.'
    )

    if ($config['INSTALL_COMFYUI'] -ceq '1') {
        $outstanding.Add(
            'INSTALL_COMFYUI is requested but not implemented.'
        )
    }

    if ($config['INSTALL_VSCODE'] -ceq '1') {
        $outstanding.Add(
            'INSTALL_VSCODE is requested but outside current scope.'
        )
    }

    if ($config['ENABLE_NONO'] -ceq '1') {
        $outstanding.Add(
            'ENABLE_NONO is requested but outside current scope.'
        )
    }

    $features = [pscustomobject][ordered]@{
        INSTALL_COMFYUI = (
            $config['INSTALL_COMFYUI'] -ceq '1'
        )
        INSTALL_OPENCODE = (
            $config['INSTALL_OPENCODE'] -ceq '1'
        )
        INSTALL_VSCODE = (
            $config['INSTALL_VSCODE'] -ceq '1'
        )
        ENABLE_NONO = (
            $config['ENABLE_NONO'] -ceq '1'
        )
    }

    $manifest = [pscustomobject][ordered]@{
        Schema = 1
        Kind = 'PHASE_000_PLAN_SNAPSHOT'
        State = 'DRAFT_BLOCKED'
        Root = $rootPath

        ConfigurationSha256 = (
            Get-FileHash `
                -LiteralPath $configPath `
                -Algorithm SHA256
        ).Hash

        ProposedTarget = [pscustomobject][ordered]@{
            Drive = $config['TARGET_DRIVE']
            Distro = $config['DISTRO']
            StoragePathCandidate = (
                '{0}\{1}\wsl' -f
                $config['TARGET_DRIVE'],
                $config['DISTRO']
            )
            IdentityVerified = $false
            StoragePathVerified = $false
        }

        RequestedFeatures = $features
        PhaseCandidates = @($phaseRecords.ToArray())
        SourceFiles = @($sourceFiles.ToArray())
        SelectedActions = @()
        ArtifactLock = $null
        ReadyForApproval = $false
        ApprovalRecorded = $false
        ExecutionAuthorized = $false
        Outstanding = @($outstanding.ToArray())
    }

    # Stable snapshot identity, not proof of human approval

    $json = ConvertTo-Json `
        -InputObject $manifest `
        -Depth 20 `
        -Compress

    $sha = [Security.Cryptography.SHA256]::Create()

    try {
        $bytes = [Text.Encoding]::UTF8.GetBytes($json)
        $digest = $sha.ComputeHash($bytes)

        $fingerprint = [BitConverter]::ToString(
            $digest
        ).Replace('-', '')
    }
    finally {
        $sha.Dispose()
    }

    return [pscustomobject]@{
        Manifest = $manifest
        Json = $json
        Sha256 = $fingerprint
    }
}

function Format-AijPlanSnapshot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Snapshot
    )

    if ($null -eq $Snapshot.Manifest -or
        $Snapshot.Manifest.Kind -cne 'PHASE_000_PLAN_SNAPSHOT' -or
        $Snapshot.Manifest.State -cne 'DRAFT_BLOCKED') {
        throw 'Invalid PLAN snapshot.'
    }

    $m = $Snapshot.Manifest

    Write-Output 'PLAN SNAPSHOT: DRAFT_BLOCKED'
    Write-Output "Candidate phases: $(@($m.PhaseCandidates).Count)"
    Write-Output "Source files: $(@($m.SourceFiles).Count)"
    Write-Output "Snapshot SHA256: $($Snapshot.Sha256)"
    Write-Output 'Selected actions: NONE'
    Write-Output 'Artifact lock: MISSING'
    Write-Output 'Target identity: UNVERIFIED'
    Write-Output 'Approval: NOT RECORDED'
    Write-Output 'Execution: DISABLED'

    foreach ($reason in $m.Outstanding) {
        Write-Output "BLOCKER: $reason"
    }
}