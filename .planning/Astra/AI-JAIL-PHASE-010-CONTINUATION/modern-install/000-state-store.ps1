# Phase 000 - State persistence
# Windows PowerShell 5.1

$stateLibrary = Join-Path $PSScriptRoot '000-state.ps1'

if (-not (
    Get-Command Assert-AijStateWrapper `
        -CommandType Function `
        -ErrorAction SilentlyContinue
)) {
    if (-not [IO.File]::Exists($stateLibrary)) {
        throw 'Required file missing: 000-state.ps1.'
    }

    . $stateLibrary
}

function Assert-AijStatePathNoReparse {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $full = [IO.Path]::GetFullPath($Path)
    $root = [IO.Path]::GetPathRoot($full)

    if ([string]::IsNullOrWhiteSpace($root)) {
        throw 'State path has no filesystem root.'
    }

    $relative = $full.Substring($root.Length)

    $parts = @(
        $relative.Split(
            [char[]]@('\', '/'),
            [StringSplitOptions]::RemoveEmptyEntries
        )
    )

    $current = $root

    for ($i = 0; $i -lt $parts.Count; $i++) {
        $current = Join-Path $current $parts[$i]

        if (-not [IO.Directory]::Exists($current)) {
            continue
        }

        $attributes = [IO.File]::GetAttributes($current)

        if (($attributes -band
            [IO.FileAttributes]::ReparsePoint) -ne 0) {

            if ($i -eq ($parts.Count - 1)) {
                throw 'State directory reparse point rejected.'
            }

            throw 'State path ancestor reparse point rejected.'
        }
    }
}

function Resolve-AijStateDirectory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Alias('Directory')]
        [string]$StateDirectory
    )

    Assert-AijStatePathNoReparse -Path $StateDirectory

    if (-not (
        Test-Path `
            -LiteralPath $StateDirectory `
            -PathType Container
    )) {
        throw 'State directory does not exist.'
    }

    $resolved = (
        Resolve-Path `
            -LiteralPath $StateDirectory `
            -ErrorAction Stop
    ).ProviderPath

    Assert-AijStatePathNoReparse -Path $resolved

    return $resolved
}

function Assert-AijExactExitPolicy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Policy
    )

    if ($null -eq $Policy -or
        $Policy.Success -ne 0 -or
        $Policy.Failure -ne 1 -or
        $Policy.RebootRequired -ne 3010 -or
        $Policy.Unknown -cne 'FAIL_CLOSED') {
        throw 'Invalid state exit policy.'
    }
}

function Assert-AijSourceIdentities {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Sources
    )

    $items = @($Sources)

    if ($items.Count -eq 0) {
        throw 'Persisted state has no source identities.'
    }

    $seen = @{}

    foreach ($source in $items) {
        if ($null -eq $source -or
            $source.Name -isnot [string] -or
            [string]::IsNullOrWhiteSpace($source.Name) -or
            $source.Sha256 -isnot [string] -or
            $source.Sha256 -cnotmatch '^[A-F0-9]{64}$') {
            throw 'Invalid persisted source identity.'
        }

        if ($seen.ContainsKey($source.Name)) {
            throw 'Duplicate persisted source identity.'
        }

        $seen[$source.Name] = $true
    }
}

function Assert-AijPhaseEvidence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Evidence
    )

    $items = @($Evidence)

    if ($items.Count -eq 0) {
        throw 'Persisted state has no phase evidence.'
    }

    $seen = @{}

    foreach ($phase in $items) {
        if ($null -eq $phase -or
            $phase.Phase -isnot [string] -or
            $phase.Phase -cnotmatch '^[0-9]{3}$' -or
            $phase.Phase -in @('000', '999')) {
            throw 'Invalid persisted phase identifier.'
        }

        if ($seen.ContainsKey($phase.Phase)) {
            throw 'Duplicate persisted phase identifier.'
        }

        $seen[$phase.Phase] = $true

        if ($phase.Attempt -isnot [int] -and
            $phase.Attempt -isnot [long]) {
            throw 'Invalid persisted phase attempt.'
        }

        if ($phase.Attempt -lt 0 -or
            $phase.Attempt -gt [int]::MaxValue) {
            throw 'Invalid persisted phase attempt.'
        }

        if ($phase.RuntimeVerified -isnot [bool] -or
            $phase.RebootRequired -isnot [bool]) {
            throw 'Invalid persisted phase flags.'
        }

        if ($phase.State -cnotin @(
            'UNVERIFIED',
            'APPLIED_UNVERIFIED',
            'FAILED',
            'FAILED_CLOSED',
            'REBOOT_PENDING'
        )) {
            throw 'Invalid persisted phase state.'
        }

        if ($phase.Attempt -eq 0) {
            if ($phase.State -cne 'UNVERIFIED' -or
                $null -ne $phase.ExitCode -or
                $phase.RuntimeVerified -ne $false -or
                $phase.RebootRequired -ne $false -or
                $null -ne $phase.EvidenceSha256) {
                throw 'Unused phase contains unexpected evidence.'
            }

            continue
        }

        if ($phase.ExitCode -isnot [int] -and
            $phase.ExitCode -isnot [long]) {
            throw 'Executed phase lacks an integer exit code.'
        }

        if ($phase.EvidenceSha256 -isnot [string] -or
            $phase.EvidenceSha256 -cnotmatch '^[A-F0-9]{64}$') {
            throw 'Executed phase lacks valid evidence.'
        }

        if ($phase.RuntimeVerified -ne $false) {
            throw 'Runtime verification cannot be persisted by Phase 000 execution.'
        }

        switch ($phase.State) {
            'APPLIED_UNVERIFIED' {
                if ($phase.ExitCode -ne 0 -or
                    $phase.RebootRequired -ne $false) {
                    throw 'Applied phase evidence is inconsistent.'
                }
            }

            'FAILED' {
                if ($phase.ExitCode -ne 1 -or
                    $phase.RebootRequired -ne $false) {
                    throw 'Failed phase evidence is inconsistent.'
                }
            }

            'REBOOT_PENDING' {
                if ($phase.ExitCode -ne 3010 -or
                    $phase.RebootRequired -ne $true) {
                    throw 'Reboot phase evidence is inconsistent.'
                }
            }

            'FAILED_CLOSED' {
                if ($phase.ExitCode -in @(0, 1, 3010) -or
                    $phase.RebootRequired -ne $false) {
                    throw 'Fail-closed phase evidence is inconsistent.'
                }
            }

            default {
                throw 'Executed phase has invalid state.'
            }
        }
    }
}

function Assert-AijPersistableStateDraft {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $StateDraft
    )

    Assert-AijStateWrapper -StateDraft $StateDraft

    $record = $StateDraft.Record

    if ($record.Schema -ne 1 -or
        $record.Kind -cne 'PHASE_000_STATE' -or
        $record.State -cne 'PLAN_BLOCKED' -or
        $record.ExecutionAuthorized -ne $false) {
        throw 'State draft is not persistable.'
    }

    if ($record.Plan.SnapshotSha256 -isnot [string] -or
        $record.Plan.SnapshotSha256 -cnotmatch '^[A-F0-9]{64}$' -or
        $record.Plan.ConfigurationSha256 -isnot [string] -or
        $record.Plan.ConfigurationSha256 -cnotmatch '^[A-F0-9]{64}$' -or
        $null -ne $record.Plan.ArtifactLockSha256) {
        throw 'Invalid blocked PLAN binding.'
    }

    if ($record.Target.IdentityVerified -ne $false -or
        $record.Target.StoragePathVerified -ne $false) {
        throw 'Blocked state contains verified target evidence.'
    }

    if ($record.Approval.Status -cne 'NOT_RECORDED' -or
        $record.Approval.SnapshotSha256 -cne
            $record.Plan.SnapshotSha256 -or
        $null -ne $record.Approval.ApprovedBy -or
        $null -ne $record.Approval.ApprovedAtUtc) {
        throw 'Blocked state contains approval evidence.'
    }

    if ($record.Resume.Status -cne 'NONE' -or
        $null -ne $record.Resume.FromPhase -or
        $record.Resume.RebootPending -ne $false -or
        $null -ne $record.Resume.RebootPhase) {
        throw 'Blocked state contains resume evidence.'
    }

    Assert-AijExactExitPolicy -Policy $record.ExitPolicy
    Assert-AijSourceIdentities -Sources $record.SourceFiles

    $phases = @($record.PhaseEvidence)

    if ($phases.Count -eq 0) {
        throw 'Blocked state has no phase evidence.'
    }

    foreach ($phase in $phases) {
        if ($phase.State -cne 'UNVERIFIED' -or
            $phase.Attempt -ne 0 -or
            $null -ne $phase.ExitCode -or
            $phase.RuntimeVerified -ne $false -or
            $phase.RebootRequired -ne $false -or
            $null -ne $phase.EvidenceSha256) {
            throw "Unsafe persisted phase evidence: $($phase.Phase)."
        }
    }

    Assert-AijPhaseEvidence -Evidence $record.PhaseEvidence

    if ($null -ne $record.LastCompletedPhase) {
        throw 'Blocked state contains completed phase evidence.'
    }
}

function Assert-AijPersistableState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $StateDraft
    )

    Assert-AijStateWrapper -StateDraft $StateDraft

    $record = $StateDraft.Record

    if ($record.State -ceq 'PLAN_BLOCKED') {
        Assert-AijPersistableStateDraft -StateDraft $StateDraft
        return
    }

    if ($record.Schema -ne 1 -or
        $record.Kind -cne 'PHASE_000_STATE') {
        throw 'Unsupported persisted state schema.'
    }

    if ($record.ExecutionAuthorized -ne $false) {
        throw 'Persisted execution authorization rejected.'
    }

    if ($record.State -cnotin @(
        'PROGRESS_BLOCKED',
        'EXECUTION_FAILED',
        'REBOOT_PENDING',
        'FAILED_CLOSED'
    )) {
        throw 'Unsupported persistable runtime state.'
    }

    if ($record.Plan.SnapshotSha256 -isnot [string] -or
        $record.Plan.SnapshotSha256 -cnotmatch '^[A-F0-9]{64}$' -or
        $record.Plan.ConfigurationSha256 -isnot [string] -or
        $record.Plan.ConfigurationSha256 -cnotmatch '^[A-F0-9]{64}$' -or
        $record.Plan.ArtifactLockSha256 -isnot [string] -or
        $record.Plan.ArtifactLockSha256 -cnotmatch '^[A-F0-9]{64}$') {
        throw 'Invalid runtime PLAN binding.'
    }

    if ($record.Target.IdentityVerified -ne $true -or
        $record.Target.StoragePathVerified -ne $true) {
        throw 'Runtime state lacks verified target identity.'
    }

    if ($record.Approval.Status -cne 'RECORDED' -or
        $record.Approval.SnapshotSha256 -cne
            $record.Plan.SnapshotSha256 -or
        $record.Approval.ApprovedBy -isnot [string] -or
        [string]::IsNullOrWhiteSpace(
            $record.Approval.ApprovedBy
        ) -or
        $record.Approval.ApprovedAtUtc -isnot [string] -or
        [string]::IsNullOrWhiteSpace(
            $record.Approval.ApprovedAtUtc
        )) {
        throw 'Runtime state lacks approval binding.'
    }

    Assert-AijExactExitPolicy -Policy $record.ExitPolicy
    Assert-AijSourceIdentities -Sources $record.SourceFiles
    Assert-AijPhaseEvidence -Evidence $record.PhaseEvidence

    if ($null -ne $record.LastCompletedPhase -and
        (
            $record.LastCompletedPhase -isnot [string] -or
            $record.LastCompletedPhase -cnotmatch '^[0-9]{3}$'
        )) {
        throw 'Invalid last-completed phase.'
    }

    if ($record.State -ceq 'REBOOT_PENDING') {
        if ($record.Resume.Status -cne 'REBOOT_PENDING' -or
            $record.Resume.RebootPending -ne $true -or
            $record.Resume.FromPhase -isnot [string] -or
            $record.Resume.FromPhase -cnotmatch '^[0-9]{3}$' -or
            $record.Resume.RebootPhase -cne
                $record.Resume.FromPhase) {
            throw 'Invalid persisted reboot state.'
        }

        $rebootRecords = @(
            $record.PhaseEvidence |
                Where-Object {
                    $_.Phase -ceq $record.Resume.FromPhase -and
                    $_.State -ceq 'REBOOT_PENDING'
                }
        )

        if ($rebootRecords.Count -ne 1) {
            throw 'Persisted reboot phase is inconsistent.'
        }
    }
    else {
        if ($record.Resume.Status -cne 'NONE' -or
            $null -ne $record.Resume.FromPhase -or
            $record.Resume.RebootPending -ne $false -or
            $null -ne $record.Resume.RebootPhase) {
            throw 'Non-reboot state contains resume evidence.'
        }
    }
}

function Read-AijStrictUtf8StateText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $bytes = [IO.File]::ReadAllBytes($Path)

    if ($bytes.Length -eq 0) {
        throw 'State file is empty.'
    }

    if ($bytes.Length -ge 3 -and
        $bytes[0] -eq 0xEF -and
        $bytes[1] -eq 0xBB -and
        $bytes[2] -eq 0xBF) {
        throw 'State file UTF-8 BOM rejected.'
    }

    $encoding = New-Object Text.UTF8Encoding(
        $false,
        $true
    )

    try {
        return $encoding.GetString($bytes)
    }
    catch {
        throw 'State file is not valid UTF-8.'
    }
}

function Read-AijStateFile {
    [CmdletBinding(DefaultParameterSetName = 'Directory')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'Directory')]
        [Alias('Directory')]
        [string]$StateDirectory,

        [Parameter(Mandatory = $true, ParameterSetName = 'File')]
        [string]$Path,

        [string]$ExpectedStateSha256
    )

    $hasExpectedState = $PSBoundParameters.ContainsKey('ExpectedStateSha256')
    if ($hasExpectedState -and $ExpectedStateSha256 -cnotmatch '^[A-F0-9]{64}$') {
        throw 'Invalid expected state fingerprint.'
    }

    if ($PSCmdlet.ParameterSetName -ceq 'File') {
        # -Path is a file, not an alias for the directory parameter.
        $path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
        $path = [IO.Path]::GetFullPath($path)
        $directory = [IO.Path]::GetDirectoryName($path)
        Assert-AijStatePathNoReparse -Path $directory
        if (-not [IO.File]::Exists($path)) {
            throw 'State file missing.'
        }
        $directory = Resolve-AijStateDirectory -StateDirectory $directory
    }
    else {
        $directory = Resolve-AijStateDirectory -StateDirectory $StateDirectory
        $path = Join-Path $directory 'phase-000-state.json'
    }

    if (-not [IO.File]::Exists($path)) {
        throw 'State file missing.'
    }

    Assert-AijStatePathNoReparse -Path $directory
    $attributes = [IO.File]::GetAttributes($path)
    if (($attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw 'State file reparse point rejected.'
    }

    $text = Read-AijStrictUtf8StateText -Path $path
    try {
        $envelope = ConvertFrom-Json -InputObject $text -ErrorAction Stop
    }
    catch {
        throw 'State file JSON is invalid.'
    }

    if ($null -eq $envelope -or $envelope -is [Array]) {
        throw 'Invalid state file envelope.'
    }

    $properties = @($envelope.PSObject.Properties.Name)
    if ($properties.Count -ne 4 -or
        $properties -cnotcontains 'Schema' -or
        $properties -cnotcontains 'Kind' -or
        $properties -cnotcontains 'StateSha256' -or
        $properties -cnotcontains 'StateJson') {
        throw 'Invalid state file envelope.'
    }

    if (($envelope.Schema -isnot [int] -and $envelope.Schema -isnot [long]) -or
        $envelope.Schema -ne 1 -or
        $envelope.Kind -cne 'PHASE_000_STATE_FILE' -or
        $envelope.StateSha256 -isnot [string] -or
        $envelope.StateSha256 -cnotmatch '^[A-F0-9]{64}$' -or
        $envelope.StateJson -isnot [string] -or
        [string]::IsNullOrWhiteSpace($envelope.StateJson)) {
        throw 'Invalid state file envelope.'
    }

    if ((Get-AijTextSha256 -Text $envelope.StateJson) -cne $envelope.StateSha256) {
        throw 'Persisted state fingerprint mismatch.'
    }
    if ($hasExpectedState -and $envelope.StateSha256 -cne $ExpectedStateSha256) {
        throw 'State file hash binding mismatch.'
    }

    try {
        $record = ConvertFrom-Json -InputObject $envelope.StateJson -ErrorAction Stop
    }
    catch {
        throw 'Persisted state JSON is invalid.'
    }
    if ($null -eq $record -or $record -is [Array]) {
        throw 'Persisted state JSON is invalid.'
    }

    $canonical = ConvertTo-AijCanonicalStateJson -Record $record
    if ($canonical -cne $envelope.StateJson) {
        throw 'Persisted state content mismatch.'
    }

    $wrapper = [pscustomobject]@{
        Record = $record
        Json = $envelope.StateJson
        Sha256 = $envelope.StateSha256
    }
    Assert-AijPersistableState -StateDraft $wrapper
    return $wrapper
}

function Read-AijStateDraftFile {
    [CmdletBinding(DefaultParameterSetName = 'Directory')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'Directory')]
        [Alias('Directory')]
        [string]$StateDirectory,

        [Parameter(Mandatory = $true, ParameterSetName = 'File')]
        [string]$Path,

        [string]$ExpectedStateSha256
    )

    $readParameters = @{}
    if ($PSCmdlet.ParameterSetName -ceq 'File') {
        $readParameters['Path'] = $Path
    }
    else {
        $readParameters['StateDirectory'] = $StateDirectory
    }
    # Omitted optional arguments must stay omitted when forwarding.
    if ($PSBoundParameters.ContainsKey('ExpectedStateSha256')) {
        $readParameters['ExpectedStateSha256'] = $ExpectedStateSha256
    }

    $wrapper = Read-AijStateFile @readParameters
    Assert-AijPersistableStateDraft -StateDraft $wrapper
    return $wrapper
}

function Write-AijStateFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $StateDraft,

        [Parameter(Mandatory = $true)]
        [Alias('Directory')]
        [string]$StateDirectory,

        [string]$ExpectedPreviousSha256,

        # Used by the legacy draft writer to preserve create-only semantics.
        [switch]$CreateOnly
    )

    $hasExpectedPrevious = $PSBoundParameters.ContainsKey('ExpectedPreviousSha256')
    if ($CreateOnly -and $hasExpectedPrevious) {
        throw 'Create-only state write cannot specify a previous fingerprint.'
    }
    if ($hasExpectedPrevious -and $ExpectedPreviousSha256 -cnotmatch '^[A-F0-9]{64}$') {
        throw 'Invalid expected previous state fingerprint.'
    }

    Assert-AijPersistableState -StateDraft $StateDraft
    $directory = Resolve-AijStateDirectory -StateDirectory $StateDirectory
    $path = Join-Path $directory 'phase-000-state.json'

    # All cooperating writers use the same cross-process, cross-session lock.
    # Hold it from the first previous-state read through commit and readback.
    # This is coordination between installer writers, not a hostile-user boundary.
    $lockIdentity = [IO.Path]::GetFullPath($path).ToUpperInvariant()
    $mutexName = 'Global\AIJail.StateStore.' + (Get-AijTextSha256 -Text $lockIdentity)
    $mutex = $null
    $lockHeld = $false
    $temporary = $null
    $stream = $null

    try {
        $mutex = New-Object System.Threading.Mutex($false, $mutexName)
        try {
            $lockHeld = $mutex.WaitOne(30000)
        }
        catch [System.Threading.AbandonedMutexException] {
            # Ownership transfers to us; validate the saved state below before use.
            $lockHeld = $true
        }
        if (-not $lockHeld) {
            throw 'State writer lock timed out.'
        }

        Assert-AijStatePathNoReparse -Path $directory
        $exists = [IO.File]::Exists($path)
        if ($exists) {
            if ($CreateOnly) {
                throw 'State file already exists.'
            }
            if (-not $hasExpectedPrevious) {
                throw 'Existing state requires expected previous fingerprint.'
            }

            $current = Read-AijStateFile -StateDirectory $directory
            if ($current.Sha256 -cne $ExpectedPreviousSha256) {
                throw 'Previous state fingerprint mismatch.'
            }
            if ($current.Record.Plan.SnapshotSha256 -cne $StateDraft.Record.Plan.SnapshotSha256 -or
                $current.Record.Plan.ConfigurationSha256 -cne $StateDraft.Record.Plan.ConfigurationSha256) {
                throw 'State update PLAN binding mismatch.'
            }
        }
        elseif ($hasExpectedPrevious) {
            throw 'Previous state file is missing.'
        }

        $envelope = [pscustomobject][ordered]@{
            Schema = 1
            Kind = 'PHASE_000_STATE_FILE'
            StateSha256 = $StateDraft.Sha256
            StateJson = $StateDraft.Json
        }
        $text = ConvertTo-Json -InputObject $envelope -Depth 5 -Compress
        $encoding = New-Object Text.UTF8Encoding($false, $true)
        $bytes = $encoding.GetBytes($text)
        $temporary = Join-Path $directory (
            '.phase-000-state.' + [guid]::NewGuid().ToString('N') + '.tmp'
        )

        $stream = New-Object IO.FileStream(
            $temporary,
            [IO.FileMode]::CreateNew,
            [IO.FileAccess]::Write,
            [IO.FileShare]::None
        )
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Flush($true)
        $stream.Dispose()
        $stream = $null

        Assert-AijStatePathNoReparse -Path $directory
        if ($exists) {
            if (-not [IO.File]::Exists($path)) {
                throw 'State file disappeared before commit.'
            }
            $current = Read-AijStateFile -StateDirectory $directory
            if ($current.Sha256 -cne $ExpectedPreviousSha256) {
                throw 'Previous state changed before commit.'
            }
            # Pass a real null string to the .NET Framework backup-path argument.
            [IO.File]::Replace($temporary, $path, [NullString]::Value)
        }
        else {
            if ([IO.File]::Exists($path)) {
                throw 'State file appeared before commit.'
            }
            [IO.File]::Move($temporary, $path)
        }

        $readback = Read-AijStateFile -StateDirectory $directory `
            -ExpectedStateSha256 $StateDraft.Sha256
        if ($readback.Json -cne $StateDraft.Json) {
            throw 'Persisted state readback mismatch.'
        }
        return $path
    }
    finally {
        # Release the lock even if temporary-file cleanup fails.
        try {
            if ($null -ne $stream) {
                $stream.Dispose()
            }
            if ($null -ne $temporary -and [IO.File]::Exists($temporary)) {
                Assert-AijStatePathNoReparse -Path $directory
                [IO.File]::Delete($temporary)
            }
        }
        finally {
            if ($null -ne $mutex) {
                try {
                    if ($lockHeld) {
                        $mutex.ReleaseMutex()
                    }
                }
                finally {
                    $mutex.Dispose()
                }
            }
        }
    }
}

function Write-AijStateDraftFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $StateDraft,

        [Parameter(Mandatory = $true)]
        [Alias('Directory')]
        [string]$StateDirectory
    )

    Assert-AijPersistableStateDraft -StateDraft $StateDraft
    # The existence check is inside the same writer lock as file creation.
    $path = Write-AijStateFile -StateDraft $StateDraft `
        -StateDirectory $StateDirectory -CreateOnly

    # Preserve the established draft-writer return object.
    return [pscustomobject]@{
        Path = $path
        Sha256 = $StateDraft.Sha256
        Json = $StateDraft.Json
        Record = $StateDraft.Record
    }
}
