# Phase 000 - State record
# Windows PowerShell 5.1

function Get-AijTextSha256 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    $hasher = [Security.Cryptography.SHA256]::Create()

    try {
        $bytes = [Text.Encoding]::UTF8.GetBytes($Text)

        return [BitConverter]::ToString(
            $hasher.ComputeHash($bytes)
        ).Replace('-', '')
    }
    finally {
        $hasher.Dispose()
    }
}

function ConvertTo-AijCanonicalStateJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Record
    )

    return ConvertTo-Json `
        -InputObject $Record `
        -Depth 30 `
        -Compress
}

function New-AijStateWrapperFromRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Record
    )

    $json = ConvertTo-AijCanonicalStateJson -Record $Record

    return [pscustomobject]@{
        Record = $Record
        Json = $json
        Sha256 = Get-AijTextSha256 -Text $json
    }
}

function Assert-AijStateWrapper {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $StateDraft
    )

    if ($null -eq $StateDraft -or
        $null -eq $StateDraft.Record -or
        $StateDraft.Json -isnot [string] -or
        $StateDraft.Sha256 -isnot [string] -or
        $StateDraft.Sha256 -cnotmatch '^[A-F0-9]{64}$') {
        throw 'Invalid state wrapper.'
    }

    if ($StateDraft.Record.Kind -cne 'PHASE_000_STATE') {
        throw 'Invalid state record kind.'
    }

    if ((Get-AijTextSha256 -Text $StateDraft.Json) -cne
        $StateDraft.Sha256) {
        throw 'State fingerprint mismatch.'
    }

    $currentJson = ConvertTo-AijCanonicalStateJson `
        -Record $StateDraft.Record

    if ($currentJson -cne $StateDraft.Json) {
        throw 'State content mismatch.'
    }
}

function Copy-AijStateRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Record
    )

    $json = ConvertTo-AijCanonicalStateJson -Record $Record

    return ConvertFrom-Json `
        -InputObject $json `
        -ErrorAction Stop
}

function Get-AijExitDisposition {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $ExitCode
    )

    if ($ExitCode -isnot [int] -and
        $ExitCode -isnot [long]) {
        throw 'Exit code must be an integer.'
    }

    if ($ExitCode -lt [int]::MinValue -or
        $ExitCode -gt [int]::MaxValue) {
        throw 'Exit code is outside Int32 range.'
    }

    $code = [int]$ExitCode

    switch ($code) {
        0 {
            return [pscustomobject][ordered]@{
                ObservedExitCode = 0
                Disposition = 'SUCCESS'
                NormalizedExitCode = 0
                StopRequired = $false
                RebootRequired = $false
                ResumeRequired = $false
                KnownExitCode = $true
                FailClosed = $false
                ExecutionAuthorized = $false
            }
        }

        1 {
            return [pscustomobject][ordered]@{
                ObservedExitCode = 1
                Disposition = 'FAILURE'
                NormalizedExitCode = 1
                StopRequired = $true
                RebootRequired = $false
                ResumeRequired = $false
                KnownExitCode = $true
                FailClosed = $false
                ExecutionAuthorized = $false
            }
        }

        3010 {
            return [pscustomobject][ordered]@{
                ObservedExitCode = 3010
                Disposition = 'REBOOT_REQUIRED'
                NormalizedExitCode = 3010
                StopRequired = $true
                RebootRequired = $true
                ResumeRequired = $true
                KnownExitCode = $true
                FailClosed = $false
                ExecutionAuthorized = $false
            }
        }

        default {
            return [pscustomobject][ordered]@{
                ObservedExitCode = $code
                Disposition = 'UNKNOWN_FAIL_CLOSED'
                NormalizedExitCode = 1
                StopRequired = $true
                RebootRequired = $false
                ResumeRequired = $false
                KnownExitCode = $false
                FailClosed = $true
                ExecutionAuthorized = $false
            }
        }
    }
}

function Get-AijPhaseResultTransition {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Phase,

        [Parameter(Mandatory = $true)]
        $ExitCode,

        [Parameter(Mandatory = $true)]
        [string]$EvidenceSha256
    )

    if ($Phase -cnotmatch '^[0-9]{3}$' -or
        $Phase -in @('000', '999')) {
        throw 'Invalid transition phase identifier.'
    }

    if ($EvidenceSha256 -cnotmatch '^[A-F0-9]{64}$') {
        throw 'Invalid phase evidence fingerprint.'
    }

    $exit = Get-AijExitDisposition -ExitCode $ExitCode

    $phaseState = $null
    $resumeStatus = 'NONE'
    $resumeFrom = $null
    $rebootPending = $false

    switch ($exit.Disposition) {
        'SUCCESS' {
            $phaseState = 'APPLIED_UNVERIFIED'
        }

        'FAILURE' {
            $phaseState = 'FAILED'
        }

        'REBOOT_REQUIRED' {
            $phaseState = 'REBOOT_PENDING'
            $resumeStatus = 'REBOOT_PENDING'
            $resumeFrom = $Phase
            $rebootPending = $true
        }

        'UNKNOWN_FAIL_CLOSED' {
            $phaseState = 'FAILED_CLOSED'
        }

        default {
            throw 'Unsupported exit disposition.'
        }
    }

    return [pscustomobject][ordered]@{
        Schema = 1
        Kind = 'PHASE_RESULT_TRANSITION'
        Phase = $Phase
        ObservedExitCode = $exit.ObservedExitCode
        NormalizedExitCode = $exit.NormalizedExitCode
        Disposition = $exit.Disposition
        PhaseState = $phaseState
        AttemptIncrement = 1
        RuntimeVerified = $false
        EvidenceSha256 = $EvidenceSha256
        StopRequired = $exit.StopRequired
        RebootRequired = $exit.RebootRequired
        FailClosed = $exit.FailClosed

        Resume = [pscustomobject][ordered]@{
            Status = $resumeStatus
            FromPhase = $resumeFrom
            RebootPending = $rebootPending
        }

        ExecutionAuthorized = $false
    }
}

function Apply-AijPhaseResultTransition {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $StateDraft,

        [Parameter(Mandatory = $true)]
        [string]$Phase,

        [Parameter(Mandatory = $true)]
        $ExitCode,

        [Parameter(Mandatory = $true)]
        [string]$EvidenceSha256
    )

    Assert-AijStateWrapper -StateDraft $StateDraft

    if ($StateDraft.Record.ExecutionAuthorized -ne $true -or
        $StateDraft.Record.State -cne 'EXECUTION_AUTHORIZED') {
        throw 'State is not authorized for one phase execution.'
    }

    $phaseRecords = @(
        $StateDraft.Record.PhaseEvidence |
            Where-Object { $_.Phase -ceq $Phase }
    )

    if ($phaseRecords.Count -ne 1) {
        throw 'Transition phase is not present exactly once.'
    }

    $prior = $phaseRecords[0]

    if ($prior.State -cnotin @(
        'UNVERIFIED',
        'REBOOT_PENDING'
    )) {
        throw 'Transition phase is not executable from its current state.'
    }

    if ($prior.State -ceq 'REBOOT_PENDING') {
        if ($StateDraft.Record.Resume.Status -cne
                'RESUME_AUTHORIZED' -or
            $StateDraft.Record.Resume.FromPhase -cne $Phase -or
            $StateDraft.Record.Resume.RebootPhase -cne $Phase) {
            throw 'Reboot-pending phase lacks matching resume authorization.'
        }
    }
    elseif ($StateDraft.Record.Resume.Status -cne 'NONE') {
        throw 'Non-resume execution contains unexpected resume state.'
    }

    $transition = Get-AijPhaseResultTransition `
        -Phase $Phase `
        -ExitCode $ExitCode `
        -EvidenceSha256 $EvidenceSha256

    $record = Copy-AijStateRecord -Record $StateDraft.Record

    $target = @(
        $record.PhaseEvidence |
            Where-Object { $_.Phase -ceq $Phase }
    )[0]

    $target.Attempt = [int]$target.Attempt + 1
    $target.State = $transition.PhaseState
    $target.ExitCode = $transition.ObservedExitCode
    $target.RuntimeVerified = $false
    $target.RebootRequired = $transition.RebootRequired
    $target.EvidenceSha256 = $transition.EvidenceSha256

    $record.ExecutionAuthorized = $false

    switch ($transition.Disposition) {
        'SUCCESS' {
            $record.State = 'PROGRESS_BLOCKED'
            $record.LastCompletedPhase = $Phase

            $record.Resume.Status = 'NONE'
            $record.Resume.FromPhase = $null
            $record.Resume.RebootPending = $false
            $record.Resume.RebootPhase = $null
        }

        'FAILURE' {
            $record.State = 'EXECUTION_FAILED'

            $record.Resume.Status = 'NONE'
            $record.Resume.FromPhase = $null
            $record.Resume.RebootPending = $false
            $record.Resume.RebootPhase = $null
        }

        'REBOOT_REQUIRED' {
            $record.State = 'REBOOT_PENDING'

            $record.Resume.Status = 'REBOOT_PENDING'
            $record.Resume.FromPhase = $Phase
            $record.Resume.RebootPending = $true
            $record.Resume.RebootPhase = $Phase
        }

        'UNKNOWN_FAIL_CLOSED' {
            $record.State = 'FAILED_CLOSED'

            $record.Resume.Status = 'NONE'
            $record.Resume.FromPhase = $null
            $record.Resume.RebootPending = $false
            $record.Resume.RebootPhase = $null
        }

        default {
            throw 'Unsupported applied transition.'
        }
    }

    return New-AijStateWrapperFromRecord -Record $record
}

function Get-AijResumeDirective {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $StateDraft,

        [Parameter(Mandatory = $true)]
        [string]$ExpectedPlanSha256
    )

    Assert-AijStateWrapper -StateDraft $StateDraft

    if ($ExpectedPlanSha256 -cnotmatch '^[A-F0-9]{64}$') {
        throw 'Invalid expected PLAN fingerprint.'
    }

    if ($StateDraft.Record.Plan.SnapshotSha256 -cne
        $ExpectedPlanSha256) {
        throw 'Resume PLAN fingerprint mismatch.'
    }

    if ($StateDraft.Record.State -cne 'REBOOT_PENDING' -or
        $StateDraft.Record.ExecutionAuthorized -ne $false) {
        throw 'State is not reboot-pending.'
    }

    $resume = $StateDraft.Record.Resume

    if ($resume.Status -cne 'REBOOT_PENDING' -or
        $resume.RebootPending -ne $true -or
        $resume.FromPhase -isnot [string] -or
        $resume.FromPhase -cnotmatch '^[0-9]{3}$' -or
        $resume.RebootPhase -cne $resume.FromPhase) {
        throw 'Invalid reboot resume state.'
    }

    $records = @(
        $StateDraft.Record.PhaseEvidence |
            Where-Object {
                $_.Phase -ceq $resume.FromPhase
            }
    )

    if ($records.Count -ne 1) {
        throw 'Resume phase is not present exactly once.'
    }

    $phase = $records[0]

    if ($phase.State -cne 'REBOOT_PENDING' -or
        $phase.ExitCode -ne 3010 -or
        $phase.RebootRequired -ne $true -or
        $phase.RuntimeVerified -ne $false -or
        $phase.Attempt -lt 1 -or
        $phase.EvidenceSha256 -isnot [string] -or
        $phase.EvidenceSha256 -cnotmatch '^[A-F0-9]{64}$') {
        throw 'Reboot phase evidence is inconsistent.'
    }

    return [pscustomobject][ordered]@{
        Schema = 1
        Kind = 'PHASE_000_RESUME_DIRECTIVE'
        PlanSha256 = $ExpectedPlanSha256
        StateSha256 = $StateDraft.Sha256
        Phase = $resume.FromPhase
        PriorExitCode = 3010
        RequiresFreshAuthorization = $true
        ExecutionAuthorized = $false
    }
}

function New-AijStateDraft {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Snapshot
    )

    # Snapshot contract

    if ($null -eq $Snapshot -or
        $null -eq $Snapshot.Manifest -or
        $Snapshot.Sha256 -isnot [string] -or
        $Snapshot.Sha256 -cnotmatch '^[A-F0-9]{64}$' -or
        $Snapshot.Json -isnot [string]) {
        throw 'Invalid PLAN snapshot wrapper.'
    }

    if ((Get-AijTextSha256 -Text $Snapshot.Json) -cne
        $Snapshot.Sha256) {
        throw 'PLAN snapshot fingerprint mismatch.'
    }

    $currentManifestJson = ConvertTo-Json `
        -InputObject $Snapshot.Manifest `
        -Depth 20 `
        -Compress

    if ($currentManifestJson -cne $Snapshot.Json) {
        throw 'PLAN snapshot content mismatch.'
    }

    $manifest = $Snapshot.Manifest

    if ($manifest.Kind -cne 'PHASE_000_PLAN_SNAPSHOT' -or
        $manifest.State -cne 'DRAFT_BLOCKED' -or
        $manifest.ExecutionAuthorized -ne $false -or
        $manifest.ApprovalRecorded -ne $false -or
        $manifest.ReadyForApproval -ne $false -or
        $null -ne $manifest.ArtifactLock -or
        @($manifest.SelectedActions).Count -ne 0) {
        throw 'PLAN snapshot is not in the required blocked state.'
    }

    if ($manifest.ConfigurationSha256 -isnot [string] -or
        $manifest.ConfigurationSha256 -cnotmatch '^[A-F0-9]{64}$') {
        throw 'Invalid configuration identity.'
    }

    if ($null -eq $manifest.ProposedTarget -or
        $manifest.ProposedTarget.IdentityVerified -ne $false -or
        $manifest.ProposedTarget.StoragePathVerified -ne $false) {
        throw 'Unexpected target verification state.'
    }

    # Source identities

    $sourceRecords = New-Object 'System.Collections.Generic.List[object]'
    $seenSources = @{}

    foreach ($source in @($manifest.SourceFiles)) {
        if ($null -eq $source -or
            $source.Name -isnot [string] -or
            [string]::IsNullOrWhiteSpace($source.Name) -or
            $source.Sha256 -isnot [string] -or
            $source.Sha256 -cnotmatch '^[A-F0-9]{64}$') {
            throw 'Invalid source-file identity.'
        }

        if ($seenSources.ContainsKey($source.Name)) {
            throw "Duplicate source-file identity: $($source.Name)."
        }

        $seenSources[$source.Name] = $true

        $sourceRecords.Add([pscustomobject][ordered]@{
            Name = $source.Name
            Sha256 = $source.Sha256
        })
    }

    if ($sourceRecords.Count -eq 0) {
        throw 'PLAN snapshot contains no source identities.'
    }

    # Phase evidence

    $phaseRecords = New-Object 'System.Collections.Generic.List[object]'
    $seenPhases = @{}

    foreach ($phase in @($manifest.PhaseCandidates)) {
        if ($null -eq $phase -or
            $phase.Id -isnot [string] -or
            $phase.Id -cnotmatch '^[0-9]{3}$') {
            throw 'Invalid phase candidate.'
        }

        if ($seenPhases.ContainsKey($phase.Id)) {
            throw "Duplicate phase candidate: $($phase.Id)."
        }

        if ($phase.ExecutionAuthorized -ne $false) {
            throw "Unexpected phase authorization: $($phase.Id)."
        }

        if ($phase.EntryPointSha256 -isnot [string] -or
            $phase.EntryPointSha256 -cnotmatch '^[A-F0-9]{64}$' -or
            $phase.RequirementsSha256 -isnot [string] -or
            $phase.RequirementsSha256 -cnotmatch '^[A-F0-9]{64}$') {
            throw "Invalid phase identity: $($phase.Id)."
        }

        $seenPhases[$phase.Id] = $true

        $phaseRecords.Add([pscustomobject][ordered]@{
            Phase = $phase.Id
            State = 'UNVERIFIED'
            Attempt = 0
            ExitCode = $null
            RuntimeVerified = $false
            RebootRequired = $false
            EvidenceSha256 = $null
        })
    }

    if ($phaseRecords.Count -eq 0) {
        throw 'PLAN snapshot contains no phase candidates.'
    }

    # Draft state

    $record = [pscustomobject][ordered]@{
        Schema = 1
        Kind = 'PHASE_000_STATE'
        State = 'PLAN_BLOCKED'

        Plan = [pscustomobject][ordered]@{
            SnapshotSha256 = $Snapshot.Sha256
            ConfigurationSha256 = $manifest.ConfigurationSha256
            ArtifactLockSha256 = $null
        }

        Target = [pscustomobject][ordered]@{
            Drive = $manifest.ProposedTarget.Drive
            Distro = $manifest.ProposedTarget.Distro
            StoragePathCandidate =
                $manifest.ProposedTarget.StoragePathCandidate
            IdentityVerified = $false
            StoragePathVerified = $false
        }

        Approval = [pscustomobject][ordered]@{
            Status = 'NOT_RECORDED'
            SnapshotSha256 = $Snapshot.Sha256
            ApprovedBy = $null
            ApprovedAtUtc = $null
        }

        Resume = [pscustomobject][ordered]@{
            Status = 'NONE'
            FromPhase = $null
            RebootPending = $false
            RebootPhase = $null
        }

        ExitPolicy = [pscustomobject][ordered]@{
            Success = 0
            Failure = 1
            RebootRequired = 3010
            Unknown = 'FAIL_CLOSED'
        }

        SourceFiles = @($sourceRecords.ToArray())
        PhaseEvidence = @($phaseRecords.ToArray())

        LastCompletedPhase = $null
        ExecutionAuthorized = $false
    }

    return New-AijStateWrapperFromRecord -Record $record
}

function Format-AijStateDraft {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $StateDraft
    )

    Assert-AijStateWrapper -StateDraft $StateDraft

    if ($StateDraft.Record.State -cne 'PLAN_BLOCKED') {
        throw 'Invalid state draft.'
    }

    $record = $StateDraft.Record

    Write-Output 'STATE: PLAN_BLOCKED'
    Write-Output "State SHA256: $($StateDraft.Sha256)"
    Write-Output "Plan SHA256: $($record.Plan.SnapshotSha256)"
    Write-Output 'Approval: NOT RECORDED'
    Write-Output 'Resume: NONE'
    Write-Output 'Reboot pending: FALSE'
    Write-Output 'Execution: DISABLED'
}