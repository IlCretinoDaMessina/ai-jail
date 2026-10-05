# Phase 000 - Runtime state regression
# Windows PowerShell 5.1

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

$root = $PSScriptRoot
$temp = $null
$utf8 = New-Object Text.UTF8Encoding($false, $true)

. (Join-Path $root '000-manifest.ps1')
. (Join-Path $root '000-state.ps1')
. (Join-Path $root '000-state-store.ps1')

function New-TestAuthorizedState {
    param(
        [Parameter(Mandatory = $true)]
        $StateDraft,

        [Parameter(Mandatory = $true)]
        [string]$Phase,

        [switch]$Resume
    )

    Assert-AijStateWrapper -StateDraft $StateDraft

    $record = Copy-AijStateRecord `
        -Record $StateDraft.Record

    $record.State = 'EXECUTION_AUTHORIZED'
    $record.ExecutionAuthorized = $true

    $record.Plan.ArtifactLockSha256 = ('B' * 64)

    $record.Target.IdentityVerified = $true
    $record.Target.StoragePathVerified = $true

    $record.Approval.Status = 'RECORDED'
    $record.Approval.SnapshotSha256 =
        $record.Plan.SnapshotSha256
    $record.Approval.ApprovedBy = 'CONTROLLED_TEST'
    $record.Approval.ApprovedAtUtc =
        '2000-01-01T00:00:00Z'

    if ($Resume) {
        $record.Resume.Status = 'RESUME_AUTHORIZED'
        $record.Resume.FromPhase = $Phase
        $record.Resume.RebootPending = $false
        $record.Resume.RebootPhase = $Phase
    }
    else {
        $record.Resume.Status = 'NONE'
        $record.Resume.FromPhase = $null
        $record.Resume.RebootPending = $false
        $record.Resume.RebootPhase = $null
    }

    return New-AijStateWrapperFromRecord `
        -Record $record
}

function Assert-Rejection {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,

        [Parameter(Mandatory = $true)]
        [scriptblock]$Operation,

        [Parameter(Mandatory = $true)]
        [string]$Expected
    )

    $actual = $null

    try {
        $null = & $Operation
    }
    catch {
        $actual = $_.Exception.Message
    }

    if ($null -eq $actual) {
        throw (
            "ASSERTION_FAILURE: ${Label}: " +
            'accepted or not executed.'
        )
    }

    if ($actual -cne $Expected) {
        throw (
            "ASSERTION_FAILURE: ${Label}: " +
            "expected [$Expected], received [$actual]."
        )
    }

    Write-Output "PASS: $Label"
}

function Assert-Guard {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,

        [Parameter(Mandatory = $true)]
        [scriptblock]$Operation,

        [Parameter(Mandatory = $true)]
        [string]$Expected
    )

    $actual = $null

    try {
        $null = & $Operation
    }
    catch {
        $actual = $_.Exception.Message
    }

    if ($actual -cne $Expected) {
        throw "TEST_GUARD_FAILURE: $Label"
    }

    Write-Output "PASS: GUARD_$Label"
}

try {
    # Baseline

    $snapshot = New-AijPlanSnapshot -Root $root
    $draft = New-AijStateDraft -Snapshot $snapshot

    Assert-AijStateWrapper -StateDraft $draft

    if ($draft.Record.State -cne 'PLAN_BLOCKED' -or
        $draft.Record.ExecutionAuthorized -ne $false) {
        throw 'Invalid blocked baseline.'
    }

    Write-Output 'PASS: BLOCKED_BASELINE'

    # Success

    $authorized = New-TestAuthorizedState `
        -StateDraft $draft `
        -Phase '010'

    $success = Apply-AijPhaseResultTransition `
        -StateDraft $authorized `
        -Phase '010' `
        -ExitCode 0 `
        -EvidenceSha256 ('A' * 64)

    $phase = @(
        $success.Record.PhaseEvidence |
            Where-Object { $_.Phase -ceq '010' }
    )[0]

    if ($success.Record.State -cne 'PROGRESS_BLOCKED' -or
        $success.Record.ExecutionAuthorized -ne $false -or
        $success.Record.LastCompletedPhase -cne '010' -or
        $phase.State -cne 'APPLIED_UNVERIFIED' -or
        $phase.Attempt -ne 1 -or
        $phase.ExitCode -ne 0 -or
        $phase.RuntimeVerified -ne $false -or
        $phase.RebootRequired -ne $false -or
        $phase.EvidenceSha256 -cne ('A' * 64)) {
        throw 'Success transition was not applied safely.'
    }

    Write-Output 'PASS: SUCCESS_TRANSITION_APPLIED'

    # Failure

    $authorized = New-TestAuthorizedState `
        -StateDraft $draft `
        -Phase '010'

    $failure = Apply-AijPhaseResultTransition `
        -StateDraft $authorized `
        -Phase '010' `
        -ExitCode 1 `
        -EvidenceSha256 ('C' * 64)

    $phase = @(
        $failure.Record.PhaseEvidence |
            Where-Object { $_.Phase -ceq '010' }
    )[0]

    if ($failure.Record.State -cne 'EXECUTION_FAILED' -or
        $failure.Record.ExecutionAuthorized -ne $false -or
        $phase.State -cne 'FAILED' -or
        $phase.ExitCode -ne 1) {
        throw 'Failure transition was not applied safely.'
    }

    Write-Output 'PASS: FAILURE_TRANSITION_APPLIED'

    # Unknown exit

    $authorized = New-TestAuthorizedState `
        -StateDraft $draft `
        -Phase '010'

    $unknown = Apply-AijPhaseResultTransition `
        -StateDraft $authorized `
        -Phase '010' `
        -ExitCode 42 `
        -EvidenceSha256 ('D' * 64)

    $phase = @(
        $unknown.Record.PhaseEvidence |
            Where-Object { $_.Phase -ceq '010' }
    )[0]

    if ($unknown.Record.State -cne 'FAILED_CLOSED' -or
        $unknown.Record.ExecutionAuthorized -ne $false -or
        $phase.State -cne 'FAILED_CLOSED' -or
        $phase.ExitCode -ne 42) {
        throw 'Unknown exit did not fail closed.'
    }

    Write-Output 'PASS: UNKNOWN_TRANSITION_FAILS_CLOSED'

    # 3010

    $authorized = New-TestAuthorizedState `
        -StateDraft $draft `
        -Phase '010'

    $reboot = Apply-AijPhaseResultTransition `
        -StateDraft $authorized `
        -Phase '010' `
        -ExitCode 3010 `
        -EvidenceSha256 ('E' * 64)

    $phase = @(
        $reboot.Record.PhaseEvidence |
            Where-Object { $_.Phase -ceq '010' }
    )[0]

    if ($reboot.Record.State -cne 'REBOOT_PENDING' -or
        $reboot.Record.ExecutionAuthorized -ne $false -or
        $reboot.Record.Resume.Status -cne
            'REBOOT_PENDING' -or
        $reboot.Record.Resume.FromPhase -cne '010' -or
        $reboot.Record.Resume.RebootPhase -cne '010' -or
        $reboot.Record.Resume.RebootPending -ne $true -or
        $phase.State -cne 'REBOOT_PENDING' -or
        $phase.ExitCode -ne 3010 -or
        $phase.RebootRequired -ne $true -or
        $phase.RuntimeVerified -ne $false) {
        throw '3010 transition was not applied safely.'
    }

    Write-Output 'PASS: REBOOT_TRANSITION_APPLIED'

    # No unauthorized transition

    Assert-Rejection `
        -Label 'BLOCKED_STATE_CANNOT_EXECUTE' `
        -Operation {
            Apply-AijPhaseResultTransition `
                -StateDraft $draft `
                -Phase '010' `
                -ExitCode 0 `
                -EvidenceSha256 ('F' * 64)
        } `
        -Expected 'State is not authorized for one phase execution.'

    # Persistence

    $temp = Join-Path ([IO.Path]::GetTempPath()) (
        'AIJ-D1-' +
        [guid]::NewGuid().ToString('N')
    )

    [void][IO.Directory]::CreateDirectory($temp)

    $null = Write-AijStateDraftFile `
        -StateDraft $draft `
        -StateDirectory $temp

    $readDraft = Read-AijStateDraftFile `
        -StateDirectory $temp `
        -ExpectedStateSha256 $draft.Sha256

    if ($readDraft.Json -cne $draft.Json) {
        throw 'Initial persisted state changed.'
    }

    Write-Output 'PASS: INITIAL_STATE_PERSISTED'

    # Authorized state must never be persisted

    $authorized = New-TestAuthorizedState `
        -StateDraft $draft `
        -Phase '010'

    Assert-Rejection `
        -Label 'ACTIVE_AUTHORIZATION_NOT_PERSISTABLE' `
        -Operation {
            Assert-AijPersistableState `
                -StateDraft $authorized
        } `
        -Expected 'Persisted execution authorization rejected.'

    # Persist 3010 with compare-and-replace

    $null = Write-AijStateFile `
        -StateDraft $reboot `
        -StateDirectory $temp `
        -ExpectedPreviousSha256 $draft.Sha256

    $readReboot = Read-AijStateFile `
        -StateDirectory $temp `
        -ExpectedStateSha256 $reboot.Sha256

    if ($readReboot.Json -cne $reboot.Json) {
        throw 'Persisted reboot state changed.'
    }

    Write-Output 'PASS: REBOOT_STATE_ATOMICALLY_PERSISTED'

    # Stale writer cannot replace it

    Assert-Rejection `
        -Label 'STALE_STATE_UPDATE_REJECTED' `
        -Operation {
            Write-AijStateFile `
                -StateDraft $failure `
                -StateDirectory $temp `
                -ExpectedPreviousSha256 $draft.Sha256
        } `
        -Expected 'Previous state fingerprint mismatch.'

    # Durable same-phase resume directive

    $directive = Get-AijResumeDirective `
        -StateDraft $readReboot `
        -ExpectedPlanSha256 $snapshot.Sha256

    if ($directive.Kind -cne
            'PHASE_000_RESUME_DIRECTIVE' -or
        $directive.Phase -cne '010' -or
        $directive.PriorExitCode -ne 3010 -or
        $directive.PlanSha256 -cne $snapshot.Sha256 -or
        $directive.StateSha256 -cne $reboot.Sha256 -or
        $directive.RequiresFreshAuthorization -ne $true -or
        $directive.ExecutionAuthorized -ne $false) {
        throw 'Resume directive is unsafe.'
    }

    Write-Output 'PASS: RESUME_DIRECTIVE_USES_SAME_PHASE'

    # Wrong PLAN cannot resume

    Assert-Rejection `
        -Label 'STALE_PLAN_RESUME_REJECTED' `
        -Operation {
            Get-AijResumeDirective `
                -StateDraft $readReboot `
                -ExpectedPlanSha256 ('0' * 64)
        } `
        -Expected 'Resume PLAN fingerprint mismatch.'

    # 3010 is not completion

    if ($readReboot.Record.LastCompletedPhase -ceq '010') {
        throw '3010 incorrectly marked phase complete.'
    }

    Write-Output 'PASS: REBOOT_IS_NOT_COMPLETION'

    # Guard controls

    Assert-Guard `
        -Label 'UNEXPECTED_ACCEPTANCE' `
        -Operation {
            Assert-Rejection `
                -Label 'CONTROL_ACCEPT' `
                -Operation { 'accepted' } `
                -Expected 'EXPECTED'
        } `
        -Expected (
            'ASSERTION_FAILURE: CONTROL_ACCEPT: ' +
            'accepted or not executed.'
        )

    Assert-Guard `
        -Label 'UNRELATED_EXCEPTION' `
        -Operation {
            Assert-Rejection `
                -Label 'CONTROL_WRONG' `
                -Operation {
                    throw 'UNRELATED_SENTINEL'
                } `
                -Expected 'EXPECTED'
        } `
        -Expected (
            'ASSERTION_FAILURE: CONTROL_WRONG: ' +
            'expected [EXPECTED], ' +
            'received [UNRELATED_SENTINEL].'
        )

    Assert-Guard `
        -Label 'SKIPPED_OPERATION' `
        -Operation {
            Assert-Rejection `
                -Label 'CONTROL_SKIP' `
                -Operation { } `
                -Expected 'EXPECTED'
        } `
        -Expected (
            'ASSERTION_FAILURE: CONTROL_SKIP: ' +
            'accepted or not executed.'
        )

    # No temporary residue

    $residue = @(
        Get-ChildItem `
            -LiteralPath $temp `
            -Force |
        Where-Object {
            $_.Name -like '.phase-000-state.*.tmp'
        }
    )

    if ($residue.Count -ne 0) {
        throw 'State-store temporary residue remains.'
    }

    Write-Output 'PASS: NO_TEMPORARY_RESIDUE'
    Write-Output 'RUNTIME_STATE_REGRESSIONS_OK'

    exit 0
}
catch {
    [Console]::Error.WriteLine($_.ToString())
    exit 1
}
finally {
    if ($null -ne $temp -and
        [IO.Directory]::Exists($temp)) {

        foreach ($child in @(
            Get-ChildItem `
                -LiteralPath $temp `
                -Force
        )) {
            if ($child.PSIsContainer) {
                throw 'TEST_CLEANUP_FAILURE: Unexpected subdirectory.'
            }

            [IO.File]::Delete($child.FullName)
        }

        [IO.Directory]::Delete($temp)
    }
}