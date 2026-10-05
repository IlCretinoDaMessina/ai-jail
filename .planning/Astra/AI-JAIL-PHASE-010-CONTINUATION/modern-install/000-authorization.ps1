# Phase 000 Deliverable 2. Windows PowerShell 5.1. Functions only after imports.
# MOCK_ONLY: no scriptblock, command, executable path, URL or installer callback
# can be supplied to the executor. Production approval is deliberately unsupported.
. (Join-Path $PSScriptRoot '000-state.ps1')
. (Join-Path $PSScriptRoot '000-state-store.ps1')
. (Join-Path $PSScriptRoot '000-manifest.ps1')
$script:AijD2Root = $PSScriptRoot
$script:AijD2LoadedSources = @{}
foreach ($name in @('000-authorization.ps1','000-state.ps1','000-state-store.ps1','000-manifest.ps1')) {
    $script:AijD2LoadedSources[$name] = (Get-FileHash -LiteralPath (Join-Path $PSScriptRoot $name) -Algorithm SHA256).Hash
}

function New-AijD2Document {
    param([Parameter(Mandatory=$true)]$Record)
    $json = ConvertTo-Json -InputObject $Record -Depth 40 -Compress
    [pscustomobject][ordered]@{Record=$Record; Json=$json; Sha256=(Get-AijTextSha256 -Text $json)}
}

function Assert-AijD2Document {
    param([Parameter(Mandatory=$true)]$Document)
    if ($null -eq $Document -or $Document.Sha256 -cnotmatch '^[A-F0-9]{64}$' -or
        $Document.Json -isnot [string]) { throw 'D2_DOCUMENT_INVALID' }
    $actual = New-AijD2Document -Record $Document.Record
    if ($actual.Json -cne $Document.Json -or $actual.Sha256 -cne $Document.Sha256) {
        throw 'D2_DOCUMENT_CHANGED'
    }
}

function Assert-AijD2Path {
    param([Parameter(Mandatory=$true)][string]$Path)
    $full = [IO.Path]::GetFullPath($Path)
    if ($full -notmatch '^[A-Za-z]:\\' -or $full.Substring(3).Contains(':')) {
        throw 'D2_LOCAL_PATH_REQUIRED'
    }
    $part = [IO.Path]::GetPathRoot($full)
    foreach ($segment in $full.Substring($part.Length).Split([char]'\')) {
        if ($segment.Length -eq 0) { continue }
        if ($segment.EndsWith('.') -or $segment.EndsWith(' ')) { throw 'D2_PATH_ALIAS_REJECTED' }
        $part = Join-Path $part $segment
        if (Test-Path -LiteralPath $part) {
            if (([IO.File]::GetAttributes($part) -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw 'D2_REPARSE_REJECTED'
            }
        }
    }
}

function Write-AijD2NewFile {
    param([Parameter(Mandatory=$true)][string]$Path,
          [Parameter(Mandatory=$true)][string]$Text)
    Assert-AijD2Path $Path
    $bytes = (New-Object Text.UTF8Encoding($false,$true)).GetBytes($Text)
    $stream = [IO.File]::Open($Path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
    try { $stream.Write($bytes,0,$bytes.Length); $stream.Flush($true) }
    finally { $stream.Dispose() }
}

function Read-AijD2Document {
    param([Parameter(Mandatory=$true)][string]$Path)
    Assert-AijD2Path $Path
    if (-not [IO.File]::Exists($Path)) { throw 'D2_DOCUMENT_MISSING' }
    $text = Read-AijStrictUtf8StateText -Path $Path
    $doc = ConvertFrom-Json -InputObject $text -ErrorAction Stop
    Assert-AijD2Document $doc
    return $doc
}

function Save-AijD2Document {
    param([Parameter(Mandatory=$true)][string]$Path,
          [Parameter(Mandatory=$true)]$Document)
    Assert-AijD2Document $Document
    Write-AijD2NewFile -Path $Path -Text (ConvertTo-Json -InputObject $Document -Depth 45 -Compress)
}

function New-AijMockWorkspace {
    param([Parameter(Mandatory=$true)][string]$ParentDirectory)
    Assert-AijD2Path $ParentDirectory
    if (-not [IO.Directory]::Exists($ParentDirectory)) { throw 'D2_PARENT_MISSING' }
    $id = [guid]::NewGuid().ToString('N')
    $path = Join-Path ([IO.Path]::GetFullPath($ParentDirectory)) ('aij-mock-' + $id)
    if (Test-Path -LiteralPath $path) { throw 'D2_WORKSPACE_EXISTS' }
    $null = [IO.Directory]::CreateDirectory($path)
    $marker = New-AijD2Document ([pscustomobject][ordered]@{Schema=1; Kind='MOCK_ONLY_WORKSPACE'; Id=$id})
    Save-AijD2Document (Join-Path $path 'workspace.json') $marker
    $null = [IO.Directory]::CreateDirectory((Join-Path $path 'state'))
    $null = [IO.Directory]::CreateDirectory((Join-Path $path 'approvals'))
    return $path
}

function Get-AijMockTargetIdentity {
    param([Parameter(Mandatory=$true)][string]$Workspace)
    Assert-AijD2Path $Workspace
    $path = [IO.Path]::GetFullPath($Workspace).TrimEnd([char]'\')
    $marker = Read-AijD2Document (Join-Path $path 'workspace.json')
    if ($marker.Record.Schema -ne 1 -or $marker.Record.Kind -cne 'MOCK_ONLY_WORKSPACE' -or
        $marker.Record.Id -cnotmatch '^[a-f0-9]{32}$' -or
        [IO.Path]::GetFileName($path) -cne ('aij-mock-' + $marker.Record.Id)) {
        throw 'D2_TARGET_INVALID'
    }
    foreach ($name in @('state','approvals')) {
        $child = Join-Path $path $name
        Assert-AijD2Path $child
        if (-not [IO.Directory]::Exists($child)) { throw 'D2_TARGET_INVALID' }
    }
    return [pscustomobject][ordered]@{
        Kind='MOCK_ONLY_DIRECTORY'; Path=$path; Id=$marker.Record.Id
        MarkerSha256=$marker.Sha256
        CreatedUtcTicks=([IO.Directory]::GetCreationTimeUtc($path).Ticks.ToString())
    }
}

function Enter-AijMockLock {
    param([Parameter(Mandatory=$true)][string]$Workspace)
    $null = Get-AijMockTargetIdentity $Workspace
    $identity = [IO.Path]::GetFullPath($Workspace).TrimEnd([char]'\').ToUpperInvariant()
    $mutex = New-Object Threading.Mutex($false,('Global\AIJail.MockExecution.' + (Get-AijTextSha256 $identity)))
    $held = $false
    try {
        try { $held = $mutex.WaitOne(30000) }
        catch [Threading.AbandonedMutexException] { $held = $true }
        if (-not $held) { throw 'D2_LOCK_TIMEOUT' }
        return $mutex
    } catch { $mutex.Dispose(); throw }
}

function Exit-AijMockLock {
    param([Parameter(Mandatory=$true)]$Mutex)
    try { $Mutex.ReleaseMutex() } finally { $Mutex.Dispose() }
}

function Get-AijD2AuditTail {
    param([Parameter(Mandatory=$true)][string]$Workspace)
    $path = Join-Path $Workspace 'audit.jsonl'
    Assert-AijD2Path $path
    $previous = ('0' * 64); $sequence = 0
    $approvals = New-Object 'System.Collections.Generic.List[string]'
    $committedState = $null
    if ([IO.File]::Exists($path)) {
        $text = Read-AijStrictUtf8StateText $path
        if (-not $text.EndsWith("`n")) { throw 'D2_AUDIT_TRUNCATED' }
        foreach ($line in $text.Split([char]10)) {
            if ($line.Length -eq 0) { continue }
            $entry = ConvertFrom-Json -InputObject $line -ErrorAction Stop
            Assert-AijD2Document $entry
            if ($entry.Record.Kind -cne 'MOCK_ONLY_AUDIT' -or
                $entry.Record.Sequence -ne ($sequence + 1) -or
                $entry.Record.PreviousSha256 -cne $previous) { throw 'D2_AUDIT_CHAIN_INVALID' }
            $sequence++; $previous = $entry.Sha256
            if ($entry.Record.Event -ceq 'APPROVAL_RECORDED') { $approvals.Add($entry.Record.ApprovalSha256) }
            if ($entry.Record.Event -cin @('STATE_INITIALIZED','STATE_COMMITTED')) {
                $committedState = $entry.Record.StateSha256
            }
        }
    } elseif (Test-Path -LiteralPath $path) { throw 'D2_AUDIT_PATH_INVALID' }
    [pscustomobject]@{Sequence=$sequence; Sha256=$previous; ApprovalHashes=@($approvals.ToArray()); CommittedStateSha256=$committedState}
}

function Write-AijD2Audit {
    # The executor's shared workspace lock must be held by callers.
    # Deliberate allowlist: no free-form messages, config, target paths, user
    # names, stdout, stderr, exception text, tokens or arbitrary object payloads.
    param([Parameter(Mandatory=$true)][string]$Workspace,
          [Parameter(Mandatory=$true)][ValidateSet('STATE_INITIALIZED','APPROVAL_RECORDED','PHASE_STARTED','PHASE_RESULT','STATE_COMMITTED','EXECUTION_DENIED')][string]$Event,
          [Parameter(Mandatory=$true)][ValidatePattern('^[A-F0-9]{64}$')][string]$PlanSha256,
          [Parameter(Mandatory=$true)][ValidatePattern('^[A-F0-9]{64}$')][string]$StateSha256,
          [ValidatePattern('^[A-F0-9]{64}$')][string]$ApprovalSha256=('0'*64),
          [ValidateSet('010')][string]$Phase='010',
          [Nullable[int]]$ExitCode=$null)
    $tail = Get-AijD2AuditTail $Workspace
    $record = [pscustomobject][ordered]@{
        Schema=1; Kind='MOCK_ONLY_AUDIT'; Sequence=($tail.Sequence+1)
        PreviousSha256=$tail.Sha256; Utc=[DateTime]::UtcNow.ToString('o')
        Event=$Event; Phase=$Phase; PlanSha256=$PlanSha256; StateSha256=$StateSha256
        ApprovalSha256=$ApprovalSha256; ExitCode=$ExitCode
    }
    $entry = New-AijD2Document $record
    $bytes = (New-Object Text.UTF8Encoding($false,$true)).GetBytes(
        (ConvertTo-Json -InputObject $entry -Depth 45 -Compress) + "`n")
    $path = Join-Path $Workspace 'audit.jsonl'
    Assert-AijD2Path $path
    $stream = [IO.File]::Open($path,[IO.FileMode]::Append,[IO.FileAccess]::Write,[IO.FileShare]::Read)
    try { $stream.Write($bytes,0,$bytes.Length); $stream.Flush($true) }
    finally { $stream.Dispose() }
    return $entry
}

function Get-AijD2SourceLock {
    param([Parameter(Mandatory=$true)]$Snapshot)
    $sources = @($Snapshot.Manifest.SourceFiles)
    foreach ($name in @('000-authorization.ps1','000-config-export.ps1','000-mock-control.ps1')) {
        $path = Join-Path $script:AijD2Root $name
        Assert-AijD2Path $path
        if (-not [IO.File]::Exists($path)) { throw 'D2_SOURCE_MISSING' }
        $sources += [pscustomobject][ordered]@{Name=$name; Sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash}
    }
    return @($sources | Sort-Object Name)
}

function New-AijMockPlan {
    param([Parameter(Mandatory=$true)][string]$Workspace,
          [int[]]$ExitCodes=@(0))
    # Bound result sequence is data interpreted by the built-in mock body.
    # It is never a command or code supplied by a plan/approval/config file.
    if ($ExitCodes.Count -lt 1 -or $ExitCodes.Count -gt 8) { throw 'D2_RESULT_SEQUENCE_INVALID' }
    for ($i=0; $i -lt ($ExitCodes.Count-1); $i++) {
        if ($ExitCodes[$i] -ne 3010) { throw 'D2_RESULT_SEQUENCE_INVALID' }
    }
    foreach ($name in $script:AijD2LoadedSources.Keys) {
        $path = Join-Path $script:AijD2Root $name
        Assert-AijD2Path $path
        if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $script:AijD2LoadedSources[$name]) {
            throw 'D2_SOURCE_RELOAD_REQUIRED'
        }
    }
    $snapshot = New-AijPlanSnapshot -Root $script:AijD2Root
    $target = Get-AijMockTargetIdentity $Workspace
    $sources = @(Get-AijD2SourceLock $snapshot)
    # Empty is an explicit lock: no downloaded artifacts or versions are used.
    $artifacts = [pscustomobject][ordered]@{
        Schema=1; Kind='MOCK_ONLY_ARTIFACT_LOCK'; Artifacts=@()
        NetworkAcquisitionAllowed=$false; DownloadedCodeExecutionAllowed=$false
        ExecutorVersion=1
    }
    $record = [pscustomobject][ordered]@{
        Schema=1; Kind='MOCK_ONLY_PLAN'; Scope='MOCK_ONLY'; Phase='010'
        BaseSnapshotSha256=$snapshot.Sha256
        ConfigurationSha256=$snapshot.Manifest.ConfigurationSha256
        SourceFiles=$sources; SourceLockSha256=(New-AijD2Document $sources).Sha256
        ArtifactLock=$artifacts; ArtifactLockSha256=(New-AijD2Document $artifacts).Sha256
        Target=$target; TargetSha256=(New-AijD2Document $target).Sha256
        ExitCodes=@($ExitCodes); ProductionExecutionAuthorized=$false
    }
    return New-AijD2Document $record
}

function Assert-AijMockPlan {
    param([Parameter(Mandatory=$true)]$Plan,
          [Parameter(Mandatory=$true)][string]$Workspace)
    Assert-AijD2Document $Plan
    $p = $Plan.Record
    if ($p.Kind -cne 'MOCK_ONLY_PLAN' -or $p.Scope -cne 'MOCK_ONLY' -or
        $p.ProductionExecutionAuthorized -isnot [bool] -or $p.ProductionExecutionAuthorized -ne $false) {
        throw 'D2_PRODUCTION_BLOCKED'
    }
    if ($p.Phase -cne '010') { throw 'D2_DEPENDENCY_PROOF_REQUIRED' }
    if ($null -eq $p.ArtifactLock) { throw 'D2_ARTIFACT_LOCK_REQUIRED' }
    if ((New-AijD2Document $p.ArtifactLock).Sha256 -cne $p.ArtifactLockSha256) { throw 'D2_ARTIFACT_LOCK_CHANGED' }
    if ((New-AijD2Document (Get-AijMockTargetIdentity $Workspace)).Sha256 -cne $p.TargetSha256) {
        throw 'D2_TARGET_CHANGED'
    }
    # Check locked bytes BEFORE New-AijPlanSnapshot dot-sources its parser and
    # dependency library. A stale source lock must not execute changed code.
    $configPath = Join-Path $script:AijD2Root 'config.env'
    Assert-AijD2Path $configPath
    if ((Get-FileHash -LiteralPath $configPath -Algorithm SHA256).Hash -cne $p.ConfigurationSha256) {
        throw 'D2_CONFIG_CHANGED'
    }
    $names = @{}
    foreach ($source in @($p.SourceFiles)) {
        if ($source.Name -cnotmatch '^[A-Za-z0-9_][A-Za-z0-9_.-]*$' -or
            $source.Name.Contains('..') -or $names.ContainsKey($source.Name)) { throw 'D2_SOURCE_LOCK_INVALID' }
        $names[$source.Name] = $true
        $path = Join-Path $script:AijD2Root $source.Name
        Assert-AijD2Path $path
        if (-not [IO.File]::Exists($path) -or
            (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $source.Sha256) { throw 'D2_SOURCE_CHANGED' }
    }
    foreach ($required in @('000-config.ps1','000-dependencies.ps1','000-state.ps1','000-state-store.ps1',
        '000-manifest.ps1','000-authorization.ps1','000-config-export.ps1','000-mock-control.ps1','_common.bat','config.env')) {
        if (-not $names.ContainsKey($required)) { throw 'D2_SOURCE_LOCK_INVALID' }
    }
    $current = New-AijMockPlan -Workspace $Workspace -ExitCodes $p.ExitCodes
    if ($p.ConfigurationSha256 -cne $current.Record.ConfigurationSha256) { throw 'D2_CONFIG_CHANGED' }
    if ($p.SourceLockSha256 -cne $current.Record.SourceLockSha256) { throw 'D2_SOURCE_CHANGED' }
    if ($Plan.Sha256 -cne $current.Sha256) { throw 'D2_PLAN_CHANGED' }
    # Also enforce the base dependency inventory, rather than assuming 010
    # always has no prerequisites in future versions of the requirements.
    $snapshot = New-AijPlanSnapshot -Root $script:AijD2Root
    $phases = @($snapshot.Manifest.PhaseCandidates | Where-Object { $_.Id -ceq $p.Phase })
    if ($phases.Count -ne 1 -or @($phases[0].Dependencies).Count -ne 0) {
        throw 'D2_DEPENDENCY_PROOF_REQUIRED'
    }
}

function Initialize-AijMockState {
    param([Parameter(Mandatory=$true)]$Plan,
          [Parameter(Mandatory=$true)][string]$Workspace)
    $mutex = Enter-AijMockLock $Workspace
    try {
        Assert-AijMockPlan $Plan $Workspace
        $draft = New-AijStateDraft -Snapshot (New-AijPlanSnapshot -Root $script:AijD2Root)
        $r = Copy-AijStateRecord $draft.Record
        $r.Plan.SnapshotSha256 = $Plan.Sha256
        $r.Approval.SnapshotSha256 = $Plan.Sha256
        $r.SourceFiles = $Plan.Record.SourceFiles
        $r.Target.Drive = [IO.Path]::GetPathRoot($Plan.Record.Target.Path).TrimEnd([char]'\')
        $r.Target.Distro = 'mock-' + $Plan.Record.Target.Id
        $r.Target.StoragePathCandidate = $Plan.Record.Target.Path
        $r | Add-Member -NotePropertyName ExecutionScope -NotePropertyValue 'MOCK_ONLY'
        $state = New-AijStateWrapperFromRecord -Record $r
        $null = Write-AijStateDraftFile -StateDraft $state -Directory (Join-Path $Workspace 'state')
        $null = Write-AijD2Audit $Workspace 'STATE_INITIALIZED' $Plan.Sha256 $state.Sha256
        return $state
    } finally { Exit-AijMockLock $mutex }
}

function Assert-AijMockStateBinding {
    param([Parameter(Mandatory=$true)]$Plan,[Parameter(Mandatory=$true)]$State)
    Assert-AijStateWrapper -StateDraft $State
    $r = $State.Record
    if ($r.ExecutionScope -cne 'MOCK_ONLY' -or $r.ExecutionAuthorized -ne $false -or
        $r.Plan.SnapshotSha256 -cne $Plan.Sha256 -or
        $r.Plan.ConfigurationSha256 -cne $Plan.Record.ConfigurationSha256 -or
        (New-AijD2Document $r.SourceFiles).Sha256 -cne $Plan.Record.SourceLockSha256 -or
        $r.Target.StoragePathCandidate -cne $Plan.Record.Target.Path -or
        $r.Target.Distro -cne ('mock-' + $Plan.Record.Target.Id)) { throw 'D2_STATE_BINDING_CHANGED' }
    $phase = @($r.PhaseEvidence | Where-Object { $_.Phase -ceq $Plan.Record.Phase })
    if ($phase.Count -ne 1) { throw 'D2_STATE_PHASE_INVALID' }
    if ($r.State -ceq 'PLAN_BLOCKED') {
        if ($phase[0].Attempt -ne 0) { throw 'D2_STATE_PHASE_INVALID' }
    } elseif ($r.State -ceq 'REBOOT_PENDING') {
        $directive = Get-AijResumeDirective -StateDraft $State -ExpectedPlanSha256 $Plan.Sha256
        if ($directive.Phase -cne $Plan.Record.Phase) { throw 'D2_RESUME_PHASE_CHANGED' }
        if ($r.Plan.ArtifactLockSha256 -cne $Plan.Record.ArtifactLockSha256) { throw 'D2_ARTIFACT_LOCK_CHANGED' }
    } else { throw 'D2_STATE_NOT_EXECUTABLE' }
    if ($phase[0].Attempt -ge @($Plan.Record.ExitCodes).Count) { throw 'D2_RESULT_SEQUENCE_EXHAUSTED' }
}

function Get-AijMockApprovalText {
    param([Parameter(Mandatory=$true)]$Plan,[Parameter(Mandatory=$true)]$State)
    'APPROVE MOCK ' + $Plan.Sha256 + ' ' + $Plan.Record.Phase + ' ' + $State.Sha256
}

function New-AijMockApproval {
    param([Parameter(Mandatory=$true)]$Plan,
          [Parameter(Mandatory=$true)][string]$Workspace,
          [Parameter(Mandatory=$true)][string]$ConfirmationText)
    $mutex = Enter-AijMockLock $Workspace
    try {
        Assert-AijMockPlan $Plan $Workspace
        if (Test-Path -LiteralPath (Join-Path $Workspace 'pending.json')) { throw 'D2_RECOVERY_REQUIRED' }
        $state = Read-AijStateFile -Directory (Join-Path $Workspace 'state')
        Assert-AijMockStateBinding $Plan $state
        if ((Get-AijD2AuditTail $Workspace).CommittedStateSha256 -cne $state.Sha256) { throw 'D2_STATE_AUDIT_MISMATCH' }
        if ($ConfirmationText -cne (Get-AijMockApprovalText $Plan $state)) { throw 'D2_EXPLICIT_APPROVAL_REQUIRED' }
        $record = [pscustomobject][ordered]@{
            Schema=1; Kind='MOCK_ONLY_APPROVAL'; Id=[guid]::NewGuid().ToString('N')
            PlanSha256=$Plan.Sha256; StateSha256=$state.Sha256; Phase=$Plan.Record.Phase
            ConfigurationSha256=$Plan.Record.ConfigurationSha256
            SourceLockSha256=$Plan.Record.SourceLockSha256
            ArtifactLockSha256=$Plan.Record.ArtifactLockSha256
            TargetSha256=$Plan.Record.TargetSha256
            Resume=($state.Record.State -ceq 'REBOOT_PENDING')
            ApprovedBy=[Security.Principal.WindowsIdentity]::GetCurrent().Name
            ApprovedAtUtc=[DateTime]::UtcNow.ToString('o')
        }
        $approval = New-AijD2Document $record
        # A durable audit entry must exist before the approval becomes usable.
        $null = Write-AijD2Audit $Workspace 'APPROVAL_RECORDED' $Plan.Sha256 $state.Sha256 $approval.Sha256
        $path = Join-Path (Join-Path $Workspace 'approvals') ($record.Id + '.json')
        Save-AijD2Document $path $approval
        return [pscustomobject]@{Path=$path; Approval=$approval}
    } finally { Exit-AijMockLock $mutex }
}

function Invoke-AijApprovedMockPhase {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)]$Plan,
          [Parameter(Mandatory=$true)][string]$Workspace,
          [Parameter(Mandatory=$true)][string]$ApprovalPath,
          [switch]$Resume)
    $mutex = Enter-AijMockLock $Workspace
    $knownPlan = '0'*64; $knownState = '0'*64
    try {
        Assert-AijMockPlan $Plan $Workspace
        $knownPlan = $Plan.Sha256
        if (Test-Path -LiteralPath (Join-Path $Workspace 'pending.json')) { throw 'D2_RECOVERY_REQUIRED' }
        $state = Read-AijStateFile -Directory (Join-Path $Workspace 'state')
        $knownState = $state.Sha256
        Assert-AijMockStateBinding $Plan $state
        $tail = Get-AijD2AuditTail $Workspace
        if ($tail.CommittedStateSha256 -cne $state.Sha256) { throw 'D2_STATE_AUDIT_MISMATCH' }
        $approvalFull = [IO.Path]::GetFullPath($ApprovalPath)
        $approvalDirectory = [IO.Path]::GetFullPath((Join-Path $Workspace 'approvals'))
        if ([IO.Path]::GetDirectoryName($approvalFull) -ine $approvalDirectory) { throw 'D2_APPROVAL_PATH_INVALID' }
        $approval = Read-AijD2Document $approvalFull
        $a = $approval.Record
        if ($tail.ApprovalHashes -cnotcontains $approval.Sha256) { throw 'D2_APPROVAL_NOT_RECORDED' }
        if ($a.Kind -cne 'MOCK_ONLY_APPROVAL' -or $a.Schema -ne 1 -or
            $a.Id -cnotmatch '^[a-f0-9]{32}$' -or
            [IO.Path]::GetFileName($approvalFull) -cne ($a.Id + '.json')) { throw 'D2_APPROVAL_INVALID' }
        foreach ($key in @('ConfigurationSha256','SourceLockSha256','ArtifactLockSha256','TargetSha256','Phase')) {
            if ($a.$key -cne $Plan.Record.$key) { throw 'D2_APPROVAL_BINDING_CHANGED' }
        }
        if ($a.PlanSha256 -cne $Plan.Sha256) { throw 'D2_APPROVAL_PLAN_CHANGED' }
        if ($a.StateSha256 -cne $state.Sha256) { throw 'D2_APPROVAL_STATE_CHANGED' }
        if ($a.ApprovedBy -cne [Security.Principal.WindowsIdentity]::GetCurrent().Name -or
            $a.ApprovedAtUtc -isnot [string] -or $a.ApprovedAtUtc -notmatch '^\d{4}-\d{2}-\d{2}T') {
            throw 'D2_APPROVER_INVALID'
        }
        $isResume = $state.Record.State -ceq 'REBOOT_PENDING'
        if ($a.Resume -isnot [bool] -or $a.Resume -ne $isResume -or $Resume.IsPresent -ne $isResume) {
            throw 'D2_RESUME_APPROVAL_REQUIRED'
        }
        $used = Join-Path (Join-Path $Workspace 'approvals') ($a.Id + '.used')
        if (Test-Path -LiteralPath $used) { throw 'D2_APPROVAL_CONSUMED' }
        # Detect damaged/unwritable audit before authorization or mock effects.
        $null = Write-AijD2Audit $Workspace 'PHASE_STARTED' $Plan.Sha256 $state.Sha256 $approval.Sha256
        $pending = Join-Path $Workspace 'pending.json'
        Save-AijD2Document $pending $approval
        Write-AijD2NewFile $used $approval.Sha256
        # Only a transient, in-memory authorization exists. It is never saved.
        $r = Copy-AijStateRecord $state.Record
        $r.State = 'EXECUTION_AUTHORIZED'; $r.ExecutionAuthorized = $true
        $r.Target.IdentityVerified = $true; $r.Target.StoragePathVerified = $true
        $r.Plan.ArtifactLockSha256 = $Plan.Record.ArtifactLockSha256
        $r.Approval.Status = 'RECORDED'; $r.Approval.ApprovedBy = $a.ApprovedBy
        $r.Approval.ApprovedAtUtc = $a.ApprovedAtUtc
        if ($isResume) { $r.Resume.Status = 'RESUME_AUTHORIZED' }
        $authorized = New-AijStateWrapperFromRecord -Record $r
        # Final binding and CAS read immediately before the only mock effect.
        Assert-AijMockPlan $Plan $Workspace
        $null = Read-AijStateFile -Directory (Join-Path $Workspace 'state') -ExpectedStateSha256 $state.Sha256
        $phase = @($state.Record.PhaseEvidence | Where-Object { $_.Phase -ceq $Plan.Record.Phase })[0]
        $code = [int]$Plan.Record.ExitCodes[$phase.Attempt]
        $result = New-AijD2Document ([pscustomobject][ordered]@{
            Schema=1; Kind='MOCK_ONLY_RESULT'; Phase=$Plan.Record.Phase
            PlanSha256=$Plan.Sha256; PreviousStateSha256=$state.Sha256
            ApprovalSha256=$approval.Sha256; Attempt=($phase.Attempt+1)
            ExitCode=$code; RuntimeVerified=$false
        })
        Save-AijD2Document (Join-Path $Workspace ('result-' + $a.Id + '.json')) $result
        $null = Write-AijD2Audit $Workspace 'PHASE_RESULT' $Plan.Sha256 $state.Sha256 $approval.Sha256 -ExitCode $code
        $next = Apply-AijPhaseResultTransition -StateDraft $authorized -Phase $Plan.Record.Phase -ExitCode $code -EvidenceSha256 $result.Sha256
        $null = Write-AijStateFile -StateDraft $next -Directory (Join-Path $Workspace 'state') -ExpectedPreviousSha256 $state.Sha256
        $null = Write-AijD2Audit $Workspace 'STATE_COMMITTED' $Plan.Sha256 $next.Sha256 $approval.Sha256 -ExitCode $code
        Assert-AijD2Path $pending
        [IO.File]::Delete($pending)
        $disposition = Get-AijExitDisposition -ExitCode $code
        return [pscustomobject]@{State=$next; Result=$result; ExitCode=$disposition.NormalizedExitCode}
    } catch {
        # Preserve the primary error; an audit failure must never hide it or
        # turn it into success. Pending evidence survives uncertain execution.
        try { $null = Write-AijD2Audit $Workspace 'EXECUTION_DENIED' $knownPlan $knownState }
        catch { [Console]::Error.WriteLine('D2_FAILURE_AUDIT_UNAVAILABLE') }
        throw
    } finally { Exit-AijMockLock $mutex }
}
