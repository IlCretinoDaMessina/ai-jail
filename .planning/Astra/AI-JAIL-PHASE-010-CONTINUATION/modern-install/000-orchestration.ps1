# Phase 000 - Mock orchestration
# Windows PowerShell 5.1

$authorizationPath = Join-Path $PSScriptRoot '000-authorization.ps1'
$dependencyPath = Join-Path $PSScriptRoot '000-dependencies.ps1'

if (-not (
    Get-Command New-AijD2Document `
        -CommandType Function `
        -ErrorAction SilentlyContinue
)) {
    if (-not [IO.File]::Exists($authorizationPath)) {
        throw 'Required file missing: 000-authorization.ps1.'
    }

    $attributes = [IO.File]::GetAttributes($authorizationPath)

    if (($attributes -band
        [IO.FileAttributes]::ReparsePoint) -ne 0) {

        throw 'Authorization library reparse point rejected.'
    }

    . $authorizationPath
}

if (-not (
    Get-Command Get-AijPhaseInventory `
        -CommandType Function `
        -ErrorAction SilentlyContinue
)) {
    if (-not [IO.File]::Exists($dependencyPath)) {
        throw 'Required file missing: 000-dependencies.ps1.'
    }

    $attributes = [IO.File]::GetAttributes($dependencyPath)

    if (($attributes -band
        [IO.FileAttributes]::ReparsePoint) -ne 0) {

        throw 'Dependency library reparse point rejected.'
    }

    . $dependencyPath
}

foreach ($functionName in @(
    'New-AijD2Document',
    'Assert-AijD2Document',
    'Assert-AijD2Path',
    'Read-AijD2Document',
    'Save-AijD2Document',
    'Write-AijD2NewFile',
    'Get-AijD2SourceLock',
    'New-AijMockWorkspace',
    'Get-AijMockTargetIdentity',
    'Enter-AijMockLock',
    'Exit-AijMockLock',
    'New-AijPlanSnapshot',
    'Get-AijPhaseInventory',
    'New-AijStateDraft',
    'Copy-AijStateRecord',
    'New-AijStateWrapperFromRecord',
    'Read-AijStateFile',
    'Write-AijStateDraftFile',
    'Write-AijStateFile',
    'Apply-AijPhaseResultTransition',
    'Get-AijResumeDirective',
    'Get-AijExitDisposition'
)) {
    if (-not (
        Get-Command $functionName `
            -CommandType Function `
            -ErrorAction SilentlyContinue
    )) {
        throw "Required function missing: $functionName."
    }
}

$script:AijD3Root = $PSScriptRoot

function Get-AijD3PlanPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Workspace
    )

    Join-Path $Workspace 'orchestration-plan.json'
}

function Get-AijD3AuditPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Workspace
    )

    Join-Path $Workspace 'orchestration-audit.jsonl'
}

function Get-AijD3PendingPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Workspace
    )

    Join-Path $Workspace 'orchestration-pending.json'
}

function Get-AijD3ApprovalDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Workspace
    )

    Join-Path $Workspace 'orchestration-approvals'
}

function Get-AijD3SourceLock {
    param(
        [Parameter(Mandatory = $true)]
        $Snapshot
    )

    $items = New-Object 'System.Collections.Generic.List[object]'
    $seen = @{}

    foreach ($source in @(Get-AijD2SourceLock $Snapshot)) {
        if ($seen.ContainsKey($source.Name)) {
            throw 'D3_SOURCE_LOCK_INVALID'
        }

        $seen[$source.Name] = $true

        $items.Add([pscustomobject][ordered]@{
            Name = $source.Name
            Sha256 = $source.Sha256
        })
    }

    foreach ($name in @(
        '000-orchestration.ps1'
    )) {
        if ($seen.ContainsKey($name)) {
            continue
        }

        $path = Join-Path $script:AijD3Root $name
        Assert-AijD2Path $path

        if (-not [IO.File]::Exists($path)) {
            throw 'D3_SOURCE_MISSING'
        }

        $items.Add([pscustomobject][ordered]@{
            Name = $name
            Sha256 = (
                Get-FileHash `
                    -LiteralPath $path `
                    -Algorithm SHA256
            ).Hash
        })

        $seen[$name] = $true
    }

    return @(
        $items.ToArray() |
            Sort-Object Name
    )
}

function Get-AijD3PhasePlans {
    param(
        [Parameter(Mandatory = $true)]
        $Inventory,

        [hashtable]$ExitCodeOverrides = @{},

        [string[]]$VerifyFailurePhases = @()
    )

    $validPhases = @{}

    foreach ($phase in @($Inventory)) {
        $validPhases[$phase.Id] = $true
    }

    foreach ($key in @($ExitCodeOverrides.Keys)) {
        $id = [string]$key

        if (-not $validPhases.ContainsKey($id)) {
            throw 'D3_RESULT_SEQUENCE_INVALID'
        }
    }

    $verifyFailures = @{}

    foreach ($id in @($VerifyFailurePhases)) {
        if (-not $validPhases.ContainsKey($id) -or
            $verifyFailures.ContainsKey($id)) {

            throw 'D3_VERIFY_SEQUENCE_INVALID'
        }

        $verifyFailures[$id] = $true
    }

    $plans = New-Object 'System.Collections.Generic.List[object]'

    foreach ($phase in @($Inventory)) {
        $id = $phase.Id
        $codes = @(0)

        if ($ExitCodeOverrides.ContainsKey($id)) {
            $codes = @($ExitCodeOverrides[$id])
        }

        if ($codes.Count -lt 1 -or $codes.Count -gt 8) {
            throw 'D3_RESULT_SEQUENCE_INVALID'
        }

        for ($i = 0; $i -lt $codes.Count; $i++) {
            if ($codes[$i] -isnot [int] -and
                $codes[$i] -isnot [long]) {

                throw 'D3_RESULT_SEQUENCE_INVALID'
            }

            if ($codes[$i] -lt [int]::MinValue -or
                $codes[$i] -gt [int]::MaxValue) {

                throw 'D3_RESULT_SEQUENCE_INVALID'
            }

            if ($i -lt ($codes.Count - 1) -and
                $codes[$i] -ne 3010) {

                throw 'D3_RESULT_SEQUENCE_INVALID'
            }
        }

        $dependencies =
            New-Object 'System.Collections.Generic.List[object]'

        foreach ($dependency in @($phase.Dependencies)) {
            $dependencies.Add([pscustomobject][ordered]@{
                Phase = $dependency.Phase
                RequiredState = $dependency.RequiredState
                Source = $dependency.Source
            })
        }

        $plans.Add([pscustomobject][ordered]@{
            Phase = $id
            Dependencies = @($dependencies.ToArray())
            ExitCodes = @(
                $codes |
                    ForEach-Object {
                        [int]$_
                    }
            )
            VerifyPass = (-not $verifyFailures.ContainsKey($id))
        })
    }

    return $plans.ToArray()
}

function New-AijD3Plan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Workspace,

        [hashtable]$ExitCodeOverrides = @{},

        [string[]]$VerifyFailurePhases = @()
    )

    $snapshot = New-AijPlanSnapshot -Root $script:AijD3Root

    $inventory = @(
        Get-AijPhaseInventory -Root $script:AijD3Root
    )

    $target = Get-AijMockTargetIdentity $Workspace

    $sources = @(
        Get-AijD3SourceLock -Snapshot $snapshot
    )

    $artifactLock = [pscustomobject][ordered]@{
        Schema = 1
        Kind = 'MOCK_ORCHESTRATION_ARTIFACT_LOCK'
        Artifacts = @()
        NetworkAcquisitionAllowed = $false
        DownloadedCodeExecutionAllowed = $false
        ExecutorVersion = 1
    }

    $phasePlans = @(
        Get-AijD3PhasePlans `
            -Inventory $inventory `
            -ExitCodeOverrides $ExitCodeOverrides `
            -VerifyFailurePhases $VerifyFailurePhases
    )

    $record = [pscustomobject][ordered]@{
        Schema = 1
        Kind = 'MOCK_ORCHESTRATION_PLAN'
        Scope = 'MOCK_ONLY'
        BaseSnapshotSha256 = $snapshot.Sha256
        ConfigurationSha256 =
            $snapshot.Manifest.ConfigurationSha256
        SourceFiles = $sources
        SourceLockSha256 =
            (New-AijD2Document $sources).Sha256
        ArtifactLock = $artifactLock
        ArtifactLockSha256 =
            (New-AijD2Document $artifactLock).Sha256
        Target = $target
        TargetSha256 =
            (New-AijD2Document $target).Sha256
        PhasePlans = $phasePlans
        ProductionExecutionAuthorized = $false
    }

    return New-AijD2Document $record
}

function Get-AijD3PhasePlan {
    param(
        [Parameter(Mandatory = $true)]
        $Plan,

        [Parameter(Mandatory = $true)]
        [string]$Phase
    )

    $items = @(
        $Plan.Record.PhasePlans |
            Where-Object {
                $_.Phase -ceq $Phase
            }
    )

    if ($items.Count -ne 1) {
        throw 'D3_PHASE_PLAN_INVALID'
    }

    return $items[0]
}

function Assert-AijD3Plan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Plan,

        [Parameter(Mandatory = $true)]
        [string]$Workspace
    )

    Assert-AijD2Document $Plan

    $record = $Plan.Record

    if ($record.Schema -ne 1 -or
        $record.Kind -cne 'MOCK_ORCHESTRATION_PLAN' -or
        $record.Scope -cne 'MOCK_ONLY' -or
        $record.ProductionExecutionAuthorized -isnot [bool] -or
        $record.ProductionExecutionAuthorized -ne $false) {

        throw 'D3_PRODUCTION_BLOCKED'
    }

    if ($null -eq $record.ArtifactLock -or
        $record.ArtifactLock.Schema -ne 1 -or
        $record.ArtifactLock.Kind -cne
            'MOCK_ORCHESTRATION_ARTIFACT_LOCK' -or
        @($record.ArtifactLock.Artifacts).Count -ne 0 -or
        $record.ArtifactLock.NetworkAcquisitionAllowed -ne $false -or
        $record.ArtifactLock.DownloadedCodeExecutionAllowed -ne $false) {

        throw 'D3_ARTIFACT_LOCK_INVALID'
    }

    if ((New-AijD2Document $record.ArtifactLock).Sha256 -cne
        $record.ArtifactLockSha256) {

        throw 'D3_ARTIFACT_LOCK_CHANGED'
    }

    $targetIdentity =
        Get-AijMockTargetIdentity $Workspace

    if ((New-AijD2Document $targetIdentity).Sha256 -cne
        $record.TargetSha256) {

        throw 'D3_TARGET_CHANGED'
    }

    $configPath = Join-Path $script:AijD3Root 'config.env'
    Assert-AijD2Path $configPath

    if ((Get-FileHash `
        -LiteralPath $configPath `
        -Algorithm SHA256
    ).Hash -cne $record.ConfigurationSha256) {

        throw 'D3_CONFIG_CHANGED'
    }

    $names = @{}

    foreach ($source in @($record.SourceFiles)) {
        if ($source.Name -isnot [string] -or
            $source.Name -cnotmatch
                '^[A-Za-z0-9_][A-Za-z0-9_.-]*$' -or
            $source.Name.Contains('..') -or
            $source.Sha256 -isnot [string] -or
            $source.Sha256 -cnotmatch '^[A-F0-9]{64}$' -or
            $names.ContainsKey($source.Name)) {

            throw 'D3_SOURCE_LOCK_INVALID'
        }

        $names[$source.Name] = $true

        $path = Join-Path $script:AijD3Root $source.Name
        Assert-AijD2Path $path

        if (-not [IO.File]::Exists($path) -or
            (Get-FileHash `
                -LiteralPath $path `
                -Algorithm SHA256
            ).Hash -cne $source.Sha256) {

            throw 'D3_SOURCE_CHANGED'
        }
    }

    foreach ($required in @(
        '000-config.ps1',
        '000-dependencies.ps1',
        '000-state.ps1',
        '000-state-store.ps1',
        '000-manifest.ps1',
        '000-authorization.ps1',
        '000-config-export.ps1',
        '000-mock-control.ps1',
        '000-orchestration.ps1',
        '_common.bat',
        'config.env'
    )) {
        if (-not $names.ContainsKey($required)) {
            throw 'D3_SOURCE_LOCK_INVALID'
        }
    }

    if ((New-AijD2Document @($record.SourceFiles)).Sha256 -cne
        $record.SourceLockSha256) {

        throw 'D3_SOURCE_LOCK_INVALID'
    }

    $snapshot = New-AijPlanSnapshot -Root $script:AijD3Root

    if ($snapshot.Sha256 -cne $record.BaseSnapshotSha256) {
        throw 'D3_BASE_PLAN_CHANGED'
    }

    $inventory = @(
        Get-AijPhaseInventory -Root $script:AijD3Root
    )

    $phasePlans = @($record.PhasePlans)

    if ($phasePlans.Count -ne $inventory.Count) {
        throw 'D3_PHASE_PLAN_INVALID'
    }

    for ($i = 0; $i -lt $inventory.Count; $i++) {
        $current = $inventory[$i]
        $planned = $phasePlans[$i]

        if ($planned.Phase -cne $current.Id -or
            $planned.VerifyPass -isnot [bool]) {

            throw 'D3_PHASE_PLAN_INVALID'
        }

        $currentDependencies = @(
            $current.Dependencies |
                ForEach-Object {
                    [pscustomobject][ordered]@{
                        Phase = $_.Phase
                        RequiredState = $_.RequiredState
                        Source = $_.Source
                    }
                }
        )

        if ((New-AijD2Document $currentDependencies).Sha256 -cne
            (New-AijD2Document @($planned.Dependencies)).Sha256) {

            throw 'D3_DEPENDENCY_PLAN_CHANGED'
        }

        $codes = @($planned.ExitCodes)

        if ($codes.Count -lt 1 -or $codes.Count -gt 8) {
            throw 'D3_RESULT_SEQUENCE_INVALID'
        }

        for ($j = 0; $j -lt $codes.Count; $j++) {
            if ($codes[$j] -isnot [int] -and
                $codes[$j] -isnot [long]) {

                throw 'D3_RESULT_SEQUENCE_INVALID'
            }

            if ($j -lt ($codes.Count - 1) -and
                $codes[$j] -ne 3010) {

                throw 'D3_RESULT_SEQUENCE_INVALID'
            }
        }
    }
}

function Assert-AijD3AuditEntry {
    param(
        [Parameter(Mandatory = $true)]
        $Entry
    )

    Assert-AijD2Document $Entry

    $record = $Entry.Record

    $expectedProperties = @(
        'Schema',
        'Kind',
        'Sequence',
        'PreviousSha256',
        'Utc',
        'Event',
        'Phase',
        'PlanSha256',
        'StateSha256',
        'ApprovalSha256',
        'PhaseEvidenceSha256',
        'EvidenceSha256',
        'ExitCode'
    )

    $properties = @($record.PSObject.Properties.Name)

    if ($properties.Count -ne $expectedProperties.Count) {
        throw 'D3_AUDIT_SCHEMA_INVALID'
    }

    foreach ($name in $expectedProperties) {
        if ($properties -cnotcontains $name) {
            throw 'D3_AUDIT_SCHEMA_INVALID'
        }
    }

    if ($record.Schema -ne 1 -or
        $record.Kind -cne 'MOCK_ORCHESTRATION_AUDIT' -or
        ($record.Sequence -isnot [int] -and
            $record.Sequence -isnot [long]) -or
        $record.Sequence -lt 1 -or
        $record.PreviousSha256 -isnot [string] -or
        $record.PreviousSha256 -cnotmatch '^[A-F0-9]{64}$' -or
        $record.Utc -isnot [string] -or
        $record.Utc -notmatch '^\d{4}-\d{2}-\d{2}T' -or
        $record.Phase -isnot [string] -or
        $record.Phase -cnotmatch '^[0-9]{3}$' -or
        $record.Phase -in @('000', '999')) {

        throw 'D3_AUDIT_SCHEMA_INVALID'
    }

    if ($record.Event -cnotin @(
        'ORCHESTRATION_INITIALIZED',
        'APPROVAL_RECORDED',
        'PHASE_STARTED',
        'PHASE_RESULT',
        'STATE_COMMITTED',
        'VERIFY_PASS',
        'VERIFY_FAIL',
        'EXECUTION_DENIED'
    )) {
        throw 'D3_AUDIT_SCHEMA_INVALID'
    }

    foreach ($name in @(
        'PlanSha256',
        'StateSha256',
        'ApprovalSha256',
        'PhaseEvidenceSha256',
        'EvidenceSha256'
    )) {
        if ($record.$name -isnot [string] -or
            $record.$name -cnotmatch '^[A-F0-9]{64}$') {

            throw 'D3_AUDIT_SCHEMA_INVALID'
        }
    }

    if ($null -ne $record.ExitCode -and
        $record.ExitCode -isnot [int] -and
        $record.ExitCode -isnot [long]) {

        throw 'D3_AUDIT_SCHEMA_INVALID'
    }
}

function Get-AijD3AuditTail {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Workspace
    )

    $path = Get-AijD3AuditPath -Workspace $Workspace
    Assert-AijD2Path $path

    $previous = '0' * 64
    $sequence = 0
    $committedState = $null

    $approvals =
        New-Object 'System.Collections.Generic.List[string]'

    $verified = @{}
    $verificationFailure = $null

    if ([IO.File]::Exists($path)) {
        $bytes = [IO.File]::ReadAllBytes($path)

        if ($bytes.Length -eq 0) {
            throw 'D3_AUDIT_EMPTY'
        }

        if ($bytes.Length -ge 3 -and
            $bytes[0] -eq 0xEF -and
            $bytes[1] -eq 0xBB -and
            $bytes[2] -eq 0xBF) {

            throw 'D3_AUDIT_BOM_REJECTED'
        }

        $encoding = New-Object Text.UTF8Encoding(
            $false,
            $true
        )

        try {
            $text = $encoding.GetString($bytes)
        }
        catch {
            throw 'D3_AUDIT_UTF8_INVALID'
        }

        if (-not $text.EndsWith(
            "`n",
            [StringComparison]::Ordinal
        )) {
            throw 'D3_AUDIT_TRUNCATED'
        }

        foreach ($line in $text.Split([char]10)) {
            if ($line.Length -eq 0) {
                continue
            }

            try {
                $entry = ConvertFrom-Json `
                    -InputObject $line `
                    -ErrorAction Stop
            }
            catch {
                throw 'D3_AUDIT_JSON_INVALID'
            }

            Assert-AijD3AuditEntry -Entry $entry

            if ($entry.Record.Sequence -ne ($sequence + 1) -or
                $entry.Record.PreviousSha256 -cne $previous) {

                throw 'D3_AUDIT_CHAIN_INVALID'
            }

            $sequence++
            $previous = $entry.Sha256

            switch ($entry.Record.Event) {
                'ORCHESTRATION_INITIALIZED' {
                    $committedState =
                        $entry.Record.StateSha256
                }

                'STATE_COMMITTED' {
                    $committedState =
                        $entry.Record.StateSha256
                }

                'APPROVAL_RECORDED' {
                    $approvals.Add(
                        $entry.Record.ApprovalSha256
                    )
                }

                'VERIFY_PASS' {
                    $verified[
                        $entry.Record.Phase
                    ] = $entry.Record.PhaseEvidenceSha256
                }

                'VERIFY_FAIL' {
                    $verificationFailure =
                        $entry.Record.Phase
                }
            }
        }
    }
    elseif (Test-Path -LiteralPath $path) {
        throw 'D3_AUDIT_PATH_INVALID'
    }

    return [pscustomobject]@{
        Sequence = $sequence
        Sha256 = $previous
        CommittedStateSha256 = $committedState
        ApprovalHashes = @($approvals.ToArray())
        VerifiedPhaseEvidence = $verified
        VerificationFailurePhase = $verificationFailure
    }
}

function Write-AijD3Audit {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Workspace,

        [Parameter(Mandatory = $true)]
        [ValidateSet(
            'ORCHESTRATION_INITIALIZED',
            'APPROVAL_RECORDED',
            'PHASE_STARTED',
            'PHASE_RESULT',
            'STATE_COMMITTED',
            'VERIFY_PASS',
            'VERIFY_FAIL',
            'EXECUTION_DENIED'
        )]
        [string]$Event,

        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[A-F0-9]{64}$')]
        [string]$PlanSha256,

        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[A-F0-9]{64}$')]
        [string]$StateSha256,

        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[0-9]{3}$')]
        [string]$Phase,

        [ValidatePattern('^[A-F0-9]{64}$')]
        [string]$ApprovalSha256 = ('0' * 64),

        [ValidatePattern('^[A-F0-9]{64}$')]
        [string]$PhaseEvidenceSha256 = ('0' * 64),

        [ValidatePattern('^[A-F0-9]{64}$')]
        [string]$EvidenceSha256 = ('0' * 64),

        [Nullable[int]]$ExitCode = $null
    )

    if ($Phase -in @('000', '999')) {
        throw 'D3_AUDIT_PHASE_INVALID'
    }

    $tail = Get-AijD3AuditTail `
        -Workspace $Workspace

    $record = [pscustomobject][ordered]@{
        Schema = 1
        Kind = 'MOCK_ORCHESTRATION_AUDIT'
        Sequence = $tail.Sequence + 1
        PreviousSha256 = $tail.Sha256
        Utc = [DateTime]::UtcNow.ToString('o')
        Event = $Event
        Phase = $Phase
        PlanSha256 = $PlanSha256
        StateSha256 = $StateSha256
        ApprovalSha256 = $ApprovalSha256
        PhaseEvidenceSha256 = $PhaseEvidenceSha256
        EvidenceSha256 = $EvidenceSha256
        ExitCode = $ExitCode
    }

    $entry = New-AijD2Document $record

    $text = (
        ConvertTo-Json `
            -InputObject $entry `
            -Depth 50 `
            -Compress
    ) + "`n"

    $encoding = New-Object Text.UTF8Encoding(
        $false,
        $true
    )

    $bytes = $encoding.GetBytes($text)

    $path = Get-AijD3AuditPath `
        -Workspace $Workspace

    Assert-AijD2Path $path

    $stream = [IO.File]::Open(
        $path,
        [IO.FileMode]::Append,
        [IO.FileAccess]::Write,
        [IO.FileShare]::Read
    )

    try {
        $stream.Write(
            $bytes,
            0,
            $bytes.Length
        )

        $stream.Flush($true)
    }
    finally {
        $stream.Dispose()
    }

    return $entry
}

function Assert-AijD3StateBinding {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Plan,

        [Parameter(Mandatory = $true)]
        $State
    )

    Assert-AijStateWrapper -StateDraft $State

    $record = $State.Record

    if ($null -eq $record.PSObject.Properties['ExecutionScope'] -or
        $record.ExecutionScope -cne 'MOCK_ONLY' -or
        $record.ExecutionAuthorized -ne $false -or
        $record.Plan.SnapshotSha256 -cne $Plan.Sha256 -or
        $record.Plan.ConfigurationSha256 -cne
            $Plan.Record.ConfigurationSha256 -or
        (New-AijD2Document @($record.SourceFiles)).Sha256 -cne
            $Plan.Record.SourceLockSha256 -or
        $record.Target.StoragePathCandidate -cne
            $Plan.Record.Target.Path -or
        $record.Target.Distro -cne
            ('mock-' + $Plan.Record.Target.Id)) {

        throw 'D3_STATE_BINDING_CHANGED'
    }

    if ($record.State -cnotin @(
        'PLAN_BLOCKED',
        'PROGRESS_BLOCKED',
        'REBOOT_PENDING',
        'EXECUTION_FAILED',
        'FAILED_CLOSED'
    )) {
        throw 'D3_STATE_INVALID'
    }

    if ($record.State -ceq 'PLAN_BLOCKED') {
        if ($null -ne $record.Plan.ArtifactLockSha256) {
            throw 'D3_STATE_ARTIFACT_LOCK_INVALID'
        }
    }
    else {
        if ($record.Plan.ArtifactLockSha256 -cne
            $Plan.Record.ArtifactLockSha256) {

            throw 'D3_STATE_ARTIFACT_LOCK_INVALID'
        }
    }

    $phaseEvidence = @($record.PhaseEvidence)

    if ($phaseEvidence.Count -ne
        @($Plan.Record.PhasePlans).Count) {

        throw 'D3_STATE_PHASE_INVALID'
    }

    foreach ($phasePlan in @($Plan.Record.PhasePlans)) {
        $matches = @(
            $phaseEvidence |
                Where-Object {
                    $_.Phase -ceq $phasePlan.Phase
                }
        )

        if ($matches.Count -ne 1) {
            throw 'D3_STATE_PHASE_INVALID'
        }
    }

    if ($record.State -ceq 'REBOOT_PENDING') {
        $directive = Get-AijResumeDirective `
            -StateDraft $State `
            -ExpectedPlanSha256 $Plan.Sha256

        if ($directive.Phase -cne
            $record.Resume.FromPhase) {

            throw 'D3_RESUME_PHASE_CHANGED'
        }
    }
}

function Get-AijD3NextPhase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Plan,

        [Parameter(Mandatory = $true)]
        $State
    )

    Assert-AijD3StateBinding `
        -Plan $Plan `
        -State $State

    if ($State.Record.State -ceq 'REBOOT_PENDING') {
        $directive = Get-AijResumeDirective `
            -StateDraft $State `
            -ExpectedPlanSha256 $Plan.Sha256

        return $directive.Phase
    }

    if ($State.Record.State -in @(
        'EXECUTION_FAILED',
        'FAILED_CLOSED'
    )) {
        throw 'D3_STATE_NOT_EXECUTABLE'
    }

    foreach ($phasePlan in @($Plan.Record.PhasePlans)) {
        $phase = @(
            $State.Record.PhaseEvidence |
                Where-Object {
                    $_.Phase -ceq $phasePlan.Phase
                }
        )[0]

        if ($phase.State -ceq 'UNVERIFIED') {
            return $phase.Phase
        }
    }

    return $null
}

function Assert-AijD3Dependencies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Plan,

        [Parameter(Mandatory = $true)]
        $State,

        [Parameter(Mandatory = $true)]
        [string]$Phase,

        [Parameter(Mandatory = $true)]
        $AuditTail
    )

    $phasePlan = Get-AijD3PhasePlan `
        -Plan $Plan `
        -Phase $Phase

    foreach ($dependency in @($phasePlan.Dependencies)) {
        $prior = @(
            $State.Record.PhaseEvidence |
                Where-Object {
                    $_.Phase -ceq $dependency.Phase
                }
        )

        if ($prior.Count -ne 1) {
            throw 'D3_DEPENDENCY_UNSATISFIED'
        }

        $prior = $prior[0]

        switch ($dependency.RequiredState) {
            'APPLIED' {
                if ($prior.State -cne 'APPLIED_UNVERIFIED' -or
                    $prior.ExitCode -ne 0 -or
                    $prior.EvidenceSha256 -isnot [string] -or
                    $prior.EvidenceSha256 -cnotmatch
                        '^[A-F0-9]{64}$') {

                    throw 'D3_DEPENDENCY_UNSATISFIED'
                }
            }

            'RUNTIME_PASS' {
                if ($prior.State -cne 'APPLIED_UNVERIFIED' -or
                    $prior.ExitCode -ne 0 -or
                    $prior.EvidenceSha256 -isnot [string] -or
                    $prior.EvidenceSha256 -cnotmatch
                        '^[A-F0-9]{64}$' -or
                    -not $AuditTail.VerifiedPhaseEvidence.ContainsKey(
                        $dependency.Phase
                    ) -or
                    $AuditTail.VerifiedPhaseEvidence[
                        $dependency.Phase
                    ] -cne $prior.EvidenceSha256) {

                    throw 'D3_DEPENDENCY_UNSATISFIED'
                }
            }

            default {
                throw 'D3_DEPENDENCY_STATE_UNSUPPORTED'
            }
        }
    }
}

function Initialize-AijD3Orchestration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Plan,

        [Parameter(Mandatory = $true)]
        [string]$Workspace
    )

    $mutex = Enter-AijMockLock $Workspace

    try {
        Assert-AijD3Plan `
            -Plan $Plan `
            -Workspace $Workspace

        $planPath =
            Get-AijD3PlanPath `
                -Workspace $Workspace

        $auditPath =
            Get-AijD3AuditPath `
                -Workspace $Workspace

        $pendingPath =
            Get-AijD3PendingPath `
                -Workspace $Workspace

        $approvalDirectory =
            Get-AijD3ApprovalDirectory `
                -Workspace $Workspace

        foreach ($path in @(
            $planPath,
            $auditPath,
            $pendingPath
        )) {
            Assert-AijD2Path $path

            if (Test-Path -LiteralPath $path) {
                throw 'D3_WORKSPACE_ALREADY_INITIALIZED'
            }
        }

        $statePath = Join-Path (
            Join-Path $Workspace 'state'
        ) 'phase-000-state.json'

        if (Test-Path -LiteralPath $statePath) {
            throw 'D3_WORKSPACE_ALREADY_INITIALIZED'
        }

        if (Test-Path -LiteralPath $approvalDirectory) {
            throw 'D3_WORKSPACE_ALREADY_INITIALIZED'
        }

        $null = [IO.Directory]::CreateDirectory(
            $approvalDirectory
        )

        Assert-AijD2Path $approvalDirectory

        Save-AijD2Document `
            $planPath `
            $Plan

        $baseSnapshot = New-AijPlanSnapshot `
            -Root $script:AijD3Root

        $draft = New-AijStateDraft `
            -Snapshot $baseSnapshot

        $record = Copy-AijStateRecord `
            -Record $draft.Record

        $record.Plan.SnapshotSha256 =
            $Plan.Sha256

        $record.Plan.ConfigurationSha256 =
            $Plan.Record.ConfigurationSha256

        $record.Approval.SnapshotSha256 =
            $Plan.Sha256

        $record.SourceFiles =
            @($Plan.Record.SourceFiles)

        $record.Target.Drive = (
            [IO.Path]::GetPathRoot(
                $Plan.Record.Target.Path
            )
        ).TrimEnd([char]'\')

        $record.Target.Distro =
            'mock-' + $Plan.Record.Target.Id

        $record.Target.StoragePathCandidate =
            $Plan.Record.Target.Path

        $record |
            Add-Member `
                -NotePropertyName ExecutionScope `
                -NotePropertyValue 'MOCK_ONLY'

        $state =
            New-AijStateWrapperFromRecord `
                -Record $record

        $null = Write-AijStateDraftFile `
            -StateDraft $state `
            -Directory (Join-Path $Workspace 'state')

        $firstPhase =
            @($Plan.Record.PhasePlans)[0].Phase

        $null = Write-AijD3Audit `
            -Workspace $Workspace `
            -Event 'ORCHESTRATION_INITIALIZED' `
            -PlanSha256 $Plan.Sha256 `
            -StateSha256 $state.Sha256 `
            -Phase $firstPhase

        return [pscustomobject]@{
            Plan = $Plan
            State = $state
            PlanPath = $planPath
        }
    }
    finally {
        Exit-AijMockLock $mutex
    }
}

function Read-AijD3Plan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Workspace
    )

    $path =
        Get-AijD3PlanPath `
            -Workspace $Workspace

    Assert-AijD2Path $path

    if (-not [IO.File]::Exists($path)) {
        throw 'D3_PLAN_MISSING'
    }

    $plan = Read-AijD2Document $path

    Assert-AijD3Plan `
        -Plan $plan `
        -Workspace $Workspace

    return $plan
}

function Get-AijD3ApprovalText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Plan,

        [Parameter(Mandatory = $true)]
        $State
    )

    $phase = Get-AijD3NextPhase `
        -Plan $Plan `
        -State $State

    if ($null -eq $phase) {
        throw 'D3_ORCHESTRATION_COMPLETE'
    }

    return (
        'APPROVE ORCHESTRATION ' +
        $Plan.Sha256 + ' ' +
        $phase + ' ' +
        $State.Sha256
    )
}

function New-AijD3Approval {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Workspace,

        [Parameter(Mandatory = $true)]
        [string]$ConfirmationText
    )

    $mutex = Enter-AijMockLock $Workspace

    try {
        $plan = Read-AijD3Plan `
            -Workspace $Workspace

        if (Test-Path -LiteralPath (
            Get-AijD3PendingPath `
                -Workspace $Workspace
        )) {
            throw 'D3_RECOVERY_REQUIRED'
        }

        $state = Read-AijStateFile `
            -Directory (Join-Path $Workspace 'state')

        Assert-AijD3StateBinding `
            -Plan $plan `
            -State $state

        $tail = Get-AijD3AuditTail `
            -Workspace $Workspace

        if ($tail.CommittedStateSha256 -cne
            $state.Sha256) {

            throw 'D3_STATE_AUDIT_MISMATCH'
        }

        if ($null -ne
            $tail.VerificationFailurePhase) {

            throw 'D3_VERIFY_FAILED'
        }

        $phase = Get-AijD3NextPhase `
            -Plan $plan `
            -State $state

        if ($null -eq $phase) {
            throw 'D3_ORCHESTRATION_COMPLETE'
        }

        Assert-AijD3Dependencies `
            -Plan $plan `
            -State $state `
            -Phase $phase `
            -AuditTail $tail

        $phasePlan = Get-AijD3PhasePlan `
            -Plan $plan `
            -Phase $phase

        $phaseEvidence = @(
            $state.Record.PhaseEvidence |
                Where-Object {
                    $_.Phase -ceq $phase
                }
        )[0]

        if ($phaseEvidence.Attempt -ge
            @($phasePlan.ExitCodes).Count) {

            throw 'D3_RESULT_SEQUENCE_EXHAUSTED'
        }

        $expected = Get-AijD3ApprovalText `
            -Plan $plan `
            -State $state

        if ($ConfirmationText -cne $expected) {
            throw 'D3_EXPLICIT_APPROVAL_REQUIRED'
        }

        $record = [pscustomobject][ordered]@{
            Schema = 1
            Kind = 'MOCK_ORCHESTRATION_APPROVAL'
            Id = [guid]::NewGuid().ToString('N')
            PlanSha256 = $plan.Sha256
            StateSha256 = $state.Sha256
            Phase = $phase
            ConfigurationSha256 =
                $plan.Record.ConfigurationSha256
            SourceLockSha256 =
                $plan.Record.SourceLockSha256
            ArtifactLockSha256 =
                $plan.Record.ArtifactLockSha256
            TargetSha256 =
                $plan.Record.TargetSha256
            Resume = (
                $state.Record.State -ceq
                'REBOOT_PENDING'
            )
            ApprovedBy = (
                [Security.Principal.WindowsIdentity]::
                    GetCurrent().Name
            )
            ApprovedAtUtc =
                [DateTime]::UtcNow.ToString('o')
        }

        $approval = New-AijD2Document $record

        $null = Write-AijD3Audit `
            -Workspace $Workspace `
            -Event 'APPROVAL_RECORDED' `
            -PlanSha256 $plan.Sha256 `
            -StateSha256 $state.Sha256 `
            -Phase $phase `
            -ApprovalSha256 $approval.Sha256

        $directory =
            Get-AijD3ApprovalDirectory `
                -Workspace $Workspace

        $path = Join-Path $directory (
            $record.Id + '.json'
        )

        Save-AijD2Document `
            $path `
            $approval

        return [pscustomobject]@{
            Path = $path
            Approval = $approval
        }
    }
    finally {
        Exit-AijMockLock $mutex
    }
}

function Invoke-AijD3MockVerify {
    param(
        [Parameter(Mandatory = $true)]
        $Plan,

        [Parameter(Mandatory = $true)]
        [string]$Workspace,

        [Parameter(Mandatory = $true)]
        $State,

        [Parameter(Mandatory = $true)]
        $Result,

        [Parameter(Mandatory = $true)]
        $Approval,

        [Parameter(Mandatory = $true)]
        $PhasePlan
    )

    Assert-AijD3Plan `
        -Plan $Plan `
        -Workspace $Workspace

    $readback = Read-AijStateFile `
        -Directory (Join-Path $Workspace 'state') `
        -ExpectedStateSha256 $State.Sha256

    Assert-AijD3StateBinding `
        -Plan $Plan `
        -State $readback

    $phase = @(
        $readback.Record.PhaseEvidence |
            Where-Object {
                $_.Phase -ceq $PhasePlan.Phase
            }
    )

    if ($phase.Count -ne 1 -or
        $phase[0].State -cne 'APPLIED_UNVERIFIED' -or
        $phase[0].ExitCode -ne 0 -or
        $phase[0].EvidenceSha256 -cne
            $Result.Sha256) {

        throw 'D3_VERIFY_BINDING_FAILED'
    }

    $targetIdentity =
        Get-AijMockTargetIdentity $Workspace

    $targetSha =
        (New-AijD2Document $targetIdentity).Sha256

    if ($targetSha -cne
        $Plan.Record.TargetSha256) {

        throw 'D3_TARGET_CHANGED'
    }

    $passed = [bool]$PhasePlan.VerifyPass

    $verificationRecord =
        [pscustomobject][ordered]@{
            Schema = 1
            Kind = 'MOCK_ORCHESTRATION_VERIFY_RESULT'
            Phase = $PhasePlan.Phase
            PlanSha256 = $Plan.Sha256
            StateSha256 = $readback.Sha256
            ApplyEvidenceSha256 = $Result.Sha256
            MockVerificationPassed = $passed
            DependencyState = if ($passed) {
                'RUNTIME_PASS'
            }
            else {
                'VERIFY_FAILED'
            }
            ProductionRuntimeVerified = $false
        }

    $verification =
        New-AijD2Document $verificationRecord

    $path = Join-Path $Workspace (
        'orchestration-verify-' +
        $Approval.Record.Id +
        '.json'
    )

    Save-AijD2Document `
        $path `
        $verification

    $event = if ($passed) {
        'VERIFY_PASS'
    }
    else {
        'VERIFY_FAIL'
    }

    $null = Write-AijD3Audit `
        -Workspace $Workspace `
        -Event $event `
        -PlanSha256 $Plan.Sha256 `
        -StateSha256 $readback.Sha256 `
        -Phase $PhasePlan.Phase `
        -ApprovalSha256 $Approval.Sha256 `
        -PhaseEvidenceSha256 $Result.Sha256 `
        -EvidenceSha256 $verification.Sha256 `
        -ExitCode 0

    return $verification
}

function Invoke-AijD3NextPhase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Workspace,

        [Parameter(Mandatory = $true)]
        [string]$ApprovalPath,

        [switch]$Resume
    )

    $mutex = Enter-AijMockLock $Workspace

    $knownPlan = '0' * 64
    $knownState = '0' * 64
    $knownPhase = '010'

    try {
        $plan = Read-AijD3Plan `
            -Workspace $Workspace

        $knownPlan = $plan.Sha256

        $pendingPath =
            Get-AijD3PendingPath `
                -Workspace $Workspace

        if (Test-Path -LiteralPath $pendingPath) {
            throw 'D3_RECOVERY_REQUIRED'
        }

        $state = Read-AijStateFile `
            -Directory (Join-Path $Workspace 'state')

        $knownState = $state.Sha256

        Assert-AijD3StateBinding `
            -Plan $plan `
            -State $state

        $tail = Get-AijD3AuditTail `
            -Workspace $Workspace

        if ($tail.CommittedStateSha256 -cne
            $state.Sha256) {

            throw 'D3_STATE_AUDIT_MISMATCH'
        }

        if ($null -ne
            $tail.VerificationFailurePhase) {

            throw 'D3_VERIFY_FAILED'
        }

        $phase = Get-AijD3NextPhase `
            -Plan $plan `
            -State $state

        if ($null -eq $phase) {
            throw 'D3_ORCHESTRATION_COMPLETE'
        }

        $knownPhase = $phase

        Assert-AijD3Dependencies `
            -Plan $plan `
            -State $state `
            -Phase $phase `
            -AuditTail $tail

        $phasePlan = Get-AijD3PhasePlan `
            -Plan $plan `
            -Phase $phase

        $approvalFull =
            [IO.Path]::GetFullPath(
                $ApprovalPath
            )

        $approvalDirectory =
            [IO.Path]::GetFullPath((
                Get-AijD3ApprovalDirectory `
                    -Workspace $Workspace
            ))

        if ([IO.Path]::GetDirectoryName(
            $approvalFull
        ) -ine $approvalDirectory) {

            throw 'D3_APPROVAL_PATH_INVALID'
        }

        $approval =
            Read-AijD2Document $approvalFull

        $approvalRecord =
            $approval.Record

        if ($approvalRecord.Schema -ne 1 -or
            $approvalRecord.Kind -cne
                'MOCK_ORCHESTRATION_APPROVAL' -or
            $approvalRecord.Id -isnot [string] -or
            $approvalRecord.Id -cnotmatch
                '^[a-f0-9]{32}$' -or
            [IO.Path]::GetFileName(
                $approvalFull
            ) -cne ($approvalRecord.Id + '.json')) {

            throw 'D3_APPROVAL_INVALID'
        }

        $usedPath = Join-Path (
            Get-AijD3ApprovalDirectory `
                -Workspace $Workspace
        ) ($approvalRecord.Id + '.used')

        if (Test-Path -LiteralPath $usedPath) {
            throw 'D3_APPROVAL_CONSUMED'
        }

        if ($tail.ApprovalHashes -cnotcontains
            $approval.Sha256) {

            throw 'D3_APPROVAL_NOT_RECORDED'
        }

        foreach ($name in @(
            'ConfigurationSha256',
            'SourceLockSha256',
            'ArtifactLockSha256',
            'TargetSha256'
        )) {
            if ($approvalRecord.$name -cne
                $plan.Record.$name) {

                throw 'D3_APPROVAL_BINDING_CHANGED'
            }
        }

        if ($approvalRecord.PlanSha256 -cne
            $plan.Sha256) {

            throw 'D3_APPROVAL_PLAN_CHANGED'
        }

        if ($approvalRecord.StateSha256 -cne
            $state.Sha256) {

            throw 'D3_APPROVAL_STATE_CHANGED'
        }

        if ($approvalRecord.Phase -cne $phase) {
            throw 'D3_APPROVAL_PHASE_CHANGED'
        }

        if ($approvalRecord.ApprovedBy -cne
            [Security.Principal.WindowsIdentity]::
                GetCurrent().Name -or
            $approvalRecord.ApprovedAtUtc -isnot [string] -or
            $approvalRecord.ApprovedAtUtc -notmatch
                '^\d{4}-\d{2}-\d{2}T') {

            throw 'D3_APPROVER_INVALID'
        }

        $isResume =
            $state.Record.State -ceq
            'REBOOT_PENDING'

        if ($approvalRecord.Resume -isnot [bool] -or
            $approvalRecord.Resume -ne $isResume -or
            $Resume.IsPresent -ne $isResume) {

            throw 'D3_RESUME_APPROVAL_REQUIRED'
        }

        $phaseEvidence = @(
            $state.Record.PhaseEvidence |
                Where-Object {
                    $_.Phase -ceq $phase
                }
        )[0]

        if ($phaseEvidence.Attempt -ge
            @($phasePlan.ExitCodes).Count) {

            throw 'D3_RESULT_SEQUENCE_EXHAUSTED'
        }

        $null = Write-AijD3Audit `
            -Workspace $Workspace `
            -Event 'PHASE_STARTED' `
            -PlanSha256 $plan.Sha256 `
            -StateSha256 $state.Sha256 `
            -Phase $phase `
            -ApprovalSha256 $approval.Sha256

        Save-AijD2Document `
            $pendingPath `
            $approval

        Write-AijD2NewFile `
            $usedPath `
            $approval.Sha256

        $authorizedRecord =
            Copy-AijStateRecord `
                -Record $state.Record

        $authorizedRecord.State =
            'EXECUTION_AUTHORIZED'

        $authorizedRecord.ExecutionAuthorized =
            $true

        $authorizedRecord.Target.IdentityVerified =
            $true

        $authorizedRecord.Target.StoragePathVerified =
            $true

        $authorizedRecord.Plan.ArtifactLockSha256 =
            $plan.Record.ArtifactLockSha256

        $authorizedRecord.Approval.Status =
            'RECORDED'

        $authorizedRecord.Approval.ApprovedBy =
            $approvalRecord.ApprovedBy

        $authorizedRecord.Approval.ApprovedAtUtc =
            $approvalRecord.ApprovedAtUtc

        if ($isResume) {
            $authorizedRecord.Resume.Status =
                'RESUME_AUTHORIZED'
        }

        $authorized =
            New-AijStateWrapperFromRecord `
                -Record $authorizedRecord

        Assert-AijD3Plan `
            -Plan $plan `
            -Workspace $Workspace

        $null = Read-AijStateFile `
            -Directory (Join-Path $Workspace 'state') `
            -ExpectedStateSha256 $state.Sha256

        $code = [int]$phasePlan.ExitCodes[
            $phaseEvidence.Attempt
        ]

        $resultRecord =
            [pscustomobject][ordered]@{
                Schema = 1
                Kind = 'MOCK_ORCHESTRATION_RESULT'
                Phase = $phase
                PlanSha256 = $plan.Sha256
                PreviousStateSha256 = $state.Sha256
                ApprovalSha256 = $approval.Sha256
                Attempt = $phaseEvidence.Attempt + 1
                ExitCode = $code
                ProductionRuntimeVerified = $false
            }

        $result =
            New-AijD2Document $resultRecord

        $resultPath = Join-Path $Workspace (
            'orchestration-result-' +
            $approvalRecord.Id +
            '.json'
        )

        Save-AijD2Document `
            $resultPath `
            $result

        $null = Write-AijD3Audit `
            -Workspace $Workspace `
            -Event 'PHASE_RESULT' `
            -PlanSha256 $plan.Sha256 `
            -StateSha256 $state.Sha256 `
            -Phase $phase `
            -ApprovalSha256 $approval.Sha256 `
            -PhaseEvidenceSha256 $result.Sha256 `
            -EvidenceSha256 $result.Sha256 `
            -ExitCode $code

        $next =
            Apply-AijPhaseResultTransition `
                -StateDraft $authorized `
                -Phase $phase `
                -ExitCode $code `
                -EvidenceSha256 $result.Sha256

        $null = Write-AijStateFile `
            -StateDraft $next `
            -Directory (Join-Path $Workspace 'state') `
            -ExpectedPreviousSha256 $state.Sha256

        $null = Write-AijD3Audit `
            -Workspace $Workspace `
            -Event 'STATE_COMMITTED' `
            -PlanSha256 $plan.Sha256 `
            -StateSha256 $next.Sha256 `
            -Phase $phase `
            -ApprovalSha256 $approval.Sha256 `
            -PhaseEvidenceSha256 $result.Sha256 `
            -EvidenceSha256 $result.Sha256 `
            -ExitCode $code

        $disposition =
            Get-AijExitDisposition `
                -ExitCode $code

        $verification = $null

        $exitCode =
            $disposition.NormalizedExitCode

        if ($exitCode -eq 0) {
            $verification =
                Invoke-AijD3MockVerify `
                    -Plan $plan `
                    -Workspace $Workspace `
                    -State $next `
                    -Result $result `
                    -Approval $approval `
                    -PhasePlan $phasePlan

            if (-not
                $verification.Record.MockVerificationPassed) {

                $exitCode = 1
            }
        }

        Assert-AijD2Path $pendingPath

        [IO.File]::Delete($pendingPath)

        return [pscustomobject]@{
            Phase = $phase
            State = $next
            Result = $result
            Verification = $verification
            ExitCode = $exitCode
        }
    }
    catch {
        try {
            $null = Write-AijD3Audit `
                -Workspace $Workspace `
                -Event 'EXECUTION_DENIED' `
                -PlanSha256 $knownPlan `
                -StateSha256 $knownState `
                -Phase $knownPhase
        }
        catch {
            [Console]::Error.WriteLine(
                'D3_FAILURE_AUDIT_UNAVAILABLE'
            )
        }

        throw
    }
    finally {
        Exit-AijMockLock $mutex
    }
}