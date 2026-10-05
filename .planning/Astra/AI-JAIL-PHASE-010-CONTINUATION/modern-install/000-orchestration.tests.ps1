# Phase 000 - Deliverable 3 orchestration tests
# Windows PowerShell 5.1

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

. (Join-Path $PSScriptRoot '000-orchestration.ps1')

$script:Assertions = 0
$script:EvidenceRoot = $null

function Assert-True {
    param(
        [Parameter(Mandatory = $true)]
        [bool]$Condition,

        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    if (-not $Condition) {
        throw "ASSERTION_FAILURE: $Label"
    }

    $script:Assertions++
}

function Assert-Equal {
    param(
        [Parameter(Mandatory = $true)]
        $Actual,

        [Parameter(Mandatory = $true)]
        $Expected,

        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    if ($Actual -cne $Expected) {
        throw (
            "ASSERTION_FAILURE: $Label; expected=[" +
            $Expected +
            '] actual=[' +
            $Actual +
            ']'
        )
    }

    $script:Assertions++
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

    $accepted = $false

    try {
        $null = & $Operation
        $accepted = $true
    }
    catch {
        if ($_.Exception.Message -cne $Expected) {
            throw (
                "ASSERTION_FAILURE: $Label; expected=[" +
                $Expected +
                '] actual=[' +
                $_.Exception.Message +
                ']'
            )
        }
    }

    if ($accepted) {
        throw (
            "ASSERTION_FAILURE: $Label unexpectedly accepted."
        )
    }

    $script:Assertions++
}

function New-D3Case {
    param(
        [hashtable]$ExitCodeOverrides = @{},

        [string[]]$VerifyFailurePhases = @()
    )

    $workspace = New-AijMockWorkspace `
        -ParentDirectory $script:EvidenceRoot

    $plan = New-AijD3Plan `
        -Workspace $workspace `
        -ExitCodeOverrides $ExitCodeOverrides `
        -VerifyFailurePhases $VerifyFailurePhases

    $initialized =
        Initialize-AijD3Orchestration `
            -Plan $plan `
            -Workspace $workspace

    return [pscustomobject]@{
        Workspace = $workspace
        Plan = $plan
        InitialState = $initialized.State
    }
}

function Invoke-D3Fresh {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Workspace,

        [switch]$Resume
    )

    $plan = Read-AijD3Plan `
        -Workspace $Workspace

    $state = Read-AijStateFile `
        -Directory (Join-Path $Workspace 'state')

    $text = Get-AijD3ApprovalText `
        -Plan $plan `
        -State $state

    $approval = New-AijD3Approval `
        -Workspace $Workspace `
        -ConfirmationText $text

    if ($Resume) {
        return Invoke-AijD3NextPhase `
            -Workspace $Workspace `
            -ApprovalPath $approval.Path `
            -Resume
    }

    return Invoke-AijD3NextPhase `
        -Workspace $Workspace `
        -ApprovalPath $approval.Path
}

function Start-D3ResumeWorker {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Workspace,

        [Parameter(Mandatory = $true)]
        [string]$ApprovalPath
    )

    $workerPath = Join-Path $script:EvidenceRoot (
        'resume-worker-' +
        [guid]::NewGuid().ToString('N') +
        '.ps1'
    )

    $worker = @'
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

$root = $args[0]
$workspace = $args[1]
$approval = $args[2]

. (Join-Path $root '000-orchestration.ps1')

try {
    $result = Invoke-AijD3NextPhase `
        -Workspace $workspace `
        -ApprovalPath $approval `
        -Resume

    Write-Output (
        'RESUME_WORKER_EXIT=' +
        $result.ExitCode
    )

    exit $result.ExitCode
}
catch {
    [Console]::Error.WriteLine($_.ToString())
    exit 1
}
'@

    [IO.File]::WriteAllText(
        $workerPath,
        $worker,
        (New-Object Text.UTF8Encoding($false))
    )

    $powerShellPath =
        Join-Path $PSHOME 'powershell.exe'

    $psi = New-Object Diagnostics.ProcessStartInfo
    $psi.FileName = $powerShellPath
    $psi.Arguments = (
        '-NoProfile -NonInteractive ' +
        '-ExecutionPolicy Bypass -File "' +
        $workerPath +
        '" "' +
        $PSScriptRoot +
        '" "' +
        $Workspace +
        '" "' +
        $ApprovalPath +
        '"'
    )
    $psi.WorkingDirectory = $PSScriptRoot
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true

    $process = New-Object Diagnostics.Process
    $process.StartInfo = $psi

    try {
        if (-not $process.Start()) {
            throw 'TEST_SETUP_FAILURE: Resume worker did not start.'
        }

        $stdoutTask =
            $process.StandardOutput.ReadToEndAsync()

        $stderrTask =
            $process.StandardError.ReadToEndAsync()

        if (-not $process.WaitForExit(60000)) {
            $process.Kill()
            $process.WaitForExit()

            throw 'TEST_SETUP_FAILURE: Resume worker timed out.'
        }

        $stdout = $stdoutTask.Result.Trim()
        $stderr = $stderrTask.Result.Trim()

        if ($stderr.Length -gt 0) {
            throw (
                'TEST_SETUP_FAILURE: Resume worker stderr: ' +
                $stderr
            )
        }

        return [pscustomobject]@{
            ExitCode = $process.ExitCode
            Output = $stdout
        }
    }
    finally {
        $process.Dispose()
    }
}

try {
    $script:EvidenceRoot = Join-Path (
        [IO.Path]::GetTempPath()
    ) (
        'AIJ-D3-' +
        [guid]::NewGuid().ToString('N')
    )

    [void][IO.Directory]::CreateDirectory(
        $script:EvidenceRoot
    )

    # Complete success path

    $case = New-D3Case

    Assert-Equal `
        -Actual $case.Plan.Record.ProductionExecutionAuthorized `
        -Expected $false `
        -Label 'PRODUCTION_EXECUTION_REMAINS_BLOCKED'

    Assert-Equal `
        -Actual @($case.Plan.Record.ArtifactLock.Artifacts).Count `
        -Expected 0 `
        -Label 'ARTIFACT_LOCK_IS_EMPTY'

    Assert-Equal `
        -Actual $case.Plan.Record.ArtifactLock.NetworkAcquisitionAllowed `
        -Expected $false `
        -Label 'NETWORK_ACQUISITION_BLOCKED'

    $executed = 0

    while ($true) {
        $plan = Read-AijD3Plan `
            -Workspace $case.Workspace

        $state = Read-AijStateFile `
            -Directory (Join-Path $case.Workspace 'state')

        $next = Get-AijD3NextPhase `
            -Plan $plan `
            -State $state

        if ($null -eq $next) {
            break
        }

        $result = Invoke-D3Fresh `
            -Workspace $case.Workspace

        Assert-Equal `
            -Actual $result.ExitCode `
            -Expected 0 `
            -Label "SUCCESS_EXIT_$next"

        Assert-Equal `
            -Actual $result.Phase `
            -Expected $next `
            -Label "STRICT_ORDER_$next"

        Assert-True `
            -Condition (
                $null -ne $result.Verification -and
                $result.Verification.Record.MockVerificationPassed
            ) `
            -Label "VERIFY_PASS_$next"

        Assert-Equal `
            -Actual $result.Verification.Record.ProductionRuntimeVerified `
            -Expected $false `
            -Label "NO_PRODUCTION_RUNTIME_PROOF_$next"

        $executed++
    }

    Assert-Equal `
        -Actual $executed `
        -Expected @($case.Plan.Record.PhasePlans).Count `
        -Label 'ALL_PHASES_EXECUTED'

    $finalState = Read-AijStateFile `
        -Directory (Join-Path $case.Workspace 'state')

    foreach ($phase in @($finalState.Record.PhaseEvidence)) {
        Assert-Equal `
            -Actual $phase.State `
            -Expected 'APPLIED_UNVERIFIED' `
            -Label "PERSISTED_APPLY_STATE_$($phase.Phase)"

        Assert-Equal `
            -Actual $phase.RuntimeVerified `
            -Expected $false `
            -Label "D1_RUNTIME_FLAG_UNCHANGED_$($phase.Phase)"

        Assert-Equal `
            -Actual $phase.ExitCode `
            -Expected 0 `
            -Label "PHASE_EXIT_ZERO_$($phase.Phase)"
    }

    $tail = Get-AijD3AuditTail `
        -Workspace $case.Workspace

    Assert-Equal `
        -Actual $tail.VerifiedPhaseEvidence.Count `
        -Expected @($case.Plan.Record.PhasePlans).Count `
        -Label 'ALL_MOCK_VERIFY_EVIDENCE_PRESENT'

    Assert-True `
        -Condition ($null -eq $tail.VerificationFailurePhase) `
        -Label 'NO_VERIFY_FAILURE_IN_SUCCESS_PATH'

    # Dependency proof

    $dependencyCase = New-D3Case

    $first = Invoke-D3Fresh `
        -Workspace $dependencyCase.Workspace

    Assert-Equal `
        -Actual $first.Phase `
        -Expected '010' `
        -Label 'DEPENDENCY_FIXTURE_PHASE_010'

    $dependencyPlan = Read-AijD3Plan `
        -Workspace $dependencyCase.Workspace

    $dependencyState = Read-AijStateFile `
        -Directory (Join-Path $dependencyCase.Workspace 'state')

    $badTail = [pscustomobject]@{
        VerifiedPhaseEvidence = @{}
    }

    Assert-Rejection `
        -Label 'RUNTIME_DEPENDENCY_REQUIRED' `
        -Expected 'D3_DEPENDENCY_UNSATISFIED' `
        -Operation {
            Assert-AijD3Dependencies `
                -Plan $dependencyPlan `
                -State $dependencyState `
                -Phase '020' `
                -AuditTail $badTail
        }

    # Failure stop

    $failureCase = New-D3Case `
        -ExitCodeOverrides @{
            '020' = @(1)
        }

    $null = Invoke-D3Fresh `
        -Workspace $failureCase.Workspace

    $failure = Invoke-D3Fresh `
        -Workspace $failureCase.Workspace

    Assert-Equal `
        -Actual $failure.Phase `
        -Expected '020' `
        -Label 'FAILURE_PHASE_IS_020'

    Assert-Equal `
        -Actual $failure.ExitCode `
        -Expected 1 `
        -Label 'FAILURE_EXIT_NORMALIZED'

    $failureState = Read-AijStateFile `
        -Directory (Join-Path $failureCase.Workspace 'state')

    Assert-Equal `
        -Actual $failureState.Record.State `
        -Expected 'EXECUTION_FAILED' `
        -Label 'FAILURE_STATE_PERSISTED'

    $phase030 = @(
        $failureState.Record.PhaseEvidence |
            Where-Object {
                $_.Phase -ceq '030'
            }
    )[0]

    Assert-Equal `
        -Actual $phase030.State `
        -Expected 'UNVERIFIED' `
        -Label 'FAILURE_STOPS_LATER_PHASES'

    Assert-Rejection `
        -Label 'FAILED_STATE_NOT_EXECUTABLE' `
        -Expected 'D3_STATE_NOT_EXECUTABLE' `
        -Operation {
            $plan = Read-AijD3Plan `
                -Workspace $failureCase.Workspace

            $state = Read-AijStateFile `
                -Directory (
                    Join-Path $failureCase.Workspace 'state'
                )

            Get-AijD3NextPhase `
                -Plan $plan `
                -State $state
        }

    # Unknown exit fail-closed

    $unknownCase = New-D3Case `
        -ExitCodeOverrides @{
            '020' = @(77)
        }

    $null = Invoke-D3Fresh `
        -Workspace $unknownCase.Workspace

    $unknown = Invoke-D3Fresh `
        -Workspace $unknownCase.Workspace

    Assert-Equal `
        -Actual $unknown.ExitCode `
        -Expected 1 `
        -Label 'UNKNOWN_EXIT_NORMALIZED_TO_FAILURE'

    $unknownState = Read-AijStateFile `
        -Directory (Join-Path $unknownCase.Workspace 'state')

    Assert-Equal `
        -Actual $unknownState.Record.State `
        -Expected 'FAILED_CLOSED' `
        -Label 'UNKNOWN_EXIT_FAILED_CLOSED'

    $unknownPhase = @(
        $unknownState.Record.PhaseEvidence |
            Where-Object {
                $_.Phase -ceq '020'
            }
    )[0]

    Assert-Equal `
        -Actual $unknownPhase.State `
        -Expected 'FAILED_CLOSED' `
        -Label 'UNKNOWN_PHASE_FAILED_CLOSED'

    # Reboot and process-boundary resume

    $rebootCase = New-D3Case `
        -ExitCodeOverrides @{
            '010' = @(3010, 0)
        }

    $reboot = Invoke-D3Fresh `
        -Workspace $rebootCase.Workspace

    Assert-Equal `
        -Actual $reboot.ExitCode `
        -Expected 3010 `
        -Label 'REBOOT_EXIT_PRESERVED'

    $rebootState = Read-AijStateFile `
        -Directory (Join-Path $rebootCase.Workspace 'state')

    Assert-Equal `
        -Actual $rebootState.Record.State `
        -Expected 'REBOOT_PENDING' `
        -Label 'REBOOT_STATE_PERSISTED'

    Assert-Equal `
        -Actual $rebootState.Record.Resume.FromPhase `
        -Expected '010' `
        -Label 'REBOOT_RESUME_SAME_PHASE'

    $rebootPlan = Read-AijD3Plan `
        -Workspace $rebootCase.Workspace

    $approvalText = Get-AijD3ApprovalText `
        -Plan $rebootPlan `
        -State $rebootState

    $resumeApproval = New-AijD3Approval `
        -Workspace $rebootCase.Workspace `
        -ConfirmationText $approvalText

    Assert-Rejection `
        -Label 'EXPLICIT_RESUME_REQUIRED' `
        -Expected 'D3_RESUME_APPROVAL_REQUIRED' `
        -Operation {
            Invoke-AijD3NextPhase `
                -Workspace $rebootCase.Workspace `
                -ApprovalPath $resumeApproval.Path
        }

    $worker = Start-D3ResumeWorker `
        -Workspace $rebootCase.Workspace `
        -ApprovalPath $resumeApproval.Path

    Assert-Equal `
        -Actual $worker.ExitCode `
        -Expected 0 `
        -Label 'RESUME_NEW_PROCESS_EXIT_ZERO'

    Assert-True `
        -Condition (
            $worker.Output -match
            'RESUME_WORKER_EXIT=0'
        ) `
        -Label 'RESUME_NEW_PROCESS_MARKER'

    $resumedState = Read-AijStateFile `
        -Directory (Join-Path $rebootCase.Workspace 'state')

    $resumed010 = @(
        $resumedState.Record.PhaseEvidence |
            Where-Object {
                $_.Phase -ceq '010'
            }
    )[0]

    Assert-Equal `
        -Actual $resumed010.State `
        -Expected 'APPLIED_UNVERIFIED' `
        -Label 'RESUME_COMPLETED_PHASE_010'

    Assert-Equal `
        -Actual $resumed010.Attempt `
        -Expected 2 `
        -Label 'RESUME_ATTEMPT_INCREMENTED'

    Assert-Rejection `
        -Label 'APPROVAL_ONE_USE_ONLY' `
        -Expected 'D3_APPROVAL_CONSUMED' `
        -Operation {
            Invoke-AijD3NextPhase `
                -Workspace $rebootCase.Workspace `
                -ApprovalPath $resumeApproval.Path
        }

    # Pending recovery

    $pendingCase = New-D3Case

    $pendingPlan = Read-AijD3Plan `
        -Workspace $pendingCase.Workspace

    $pendingState = Read-AijStateFile `
        -Directory (Join-Path $pendingCase.Workspace 'state')

    $pendingApproval = New-AijD3Approval `
        -Workspace $pendingCase.Workspace `
        -ConfirmationText (
            Get-AijD3ApprovalText `
                -Plan $pendingPlan `
                -State $pendingState
        )

    Save-AijD2Document `
        (Get-AijD3PendingPath `
            -Workspace $pendingCase.Workspace) `
        $pendingApproval.Approval

    Assert-Rejection `
        -Label 'PENDING_BLOCKS_RETRY' `
        -Expected 'D3_RECOVERY_REQUIRED' `
        -Operation {
            Invoke-AijD3NextPhase `
                -Workspace $pendingCase.Workspace `
                -ApprovalPath $pendingApproval.Path
        }

    # Audit truncation

    $auditCase = New-D3Case

    [IO.File]::AppendAllText(
        (Get-AijD3AuditPath `
            -Workspace $auditCase.Workspace),
        'BROKEN',
        (New-Object Text.UTF8Encoding($false))
    )

    Assert-Rejection `
        -Label 'TRUNCATED_AUDIT_REJECTED' `
        -Expected 'D3_AUDIT_TRUNCATED' `
        -Operation {
            New-AijD3Approval `
                -Workspace $auditCase.Workspace `
                -ConfirmationText 'INVALID'
        }

    # Verification failure is terminal

    $verifyCase = New-D3Case `
        -VerifyFailurePhases @('010')

    $verifyFailure = Invoke-D3Fresh `
        -Workspace $verifyCase.Workspace

    Assert-Equal `
        -Actual $verifyFailure.ExitCode `
        -Expected 1 `
        -Label 'VERIFY_FAILURE_RETURNS_FAILURE'

    $verifyTail = Get-AijD3AuditTail `
        -Workspace $verifyCase.Workspace

    Assert-Equal `
        -Actual $verifyTail.VerificationFailurePhase `
        -Expected '010' `
        -Label 'VERIFY_FAILURE_AUDITED'

    Assert-Rejection `
        -Label 'VERIFY_FAILURE_STOPS_ORCHESTRATION' `
        -Expected 'D3_VERIFY_FAILED' `
        -Operation {
            New-AijD3Approval `
                -Workspace $verifyCase.Workspace `
                -ConfirmationText 'INVALID'
        }

    Write-Output (
        'D3_ORCHESTRATION_FOCUSED_OK assertions=' +
        $script:Assertions
    )

    Write-Output (
        'D3_EVIDENCE_ROOT=' +
        $script:EvidenceRoot
    )

    exit 0
}
catch {
    if ($null -ne $script:EvidenceRoot) {
        [Console]::Error.WriteLine(
            'D3_EVIDENCE_ROOT=' +
            $script:EvidenceRoot
        )
    }

    [Console]::Error.WriteLine($_.ToString())
    exit 1
}