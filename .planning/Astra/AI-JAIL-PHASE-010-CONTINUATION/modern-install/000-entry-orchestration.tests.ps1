# Phase 000 - Mock entry integration tests
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

function Assert-Contains {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,

        [Parameter(Mandatory = $true)]
        [string]$Expected,

        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    if ($Text.IndexOf(
        $Expected,
        [StringComparison]::Ordinal
    ) -lt 0) {
        throw (
            "ASSERTION_FAILURE: $Label; missing=[" +
            $Expected +
            ']'
        )
    }

    $script:Assertions++
}

function Invoke-RunAll {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    $batPath =
        Join-Path $PSScriptRoot '000-run-all.bat'

    if (-not [IO.File]::Exists($batPath)) {
        throw 'TEST_SETUP_FAILURE: 000-run-all.bat missing.'
    }

    $commandParts =
        New-Object 'System.Collections.Generic.List[string]'

    $commandParts.Add(
        '"' + $batPath + '"'
    )

    foreach ($argument in $Arguments) {
        if ($argument.Contains('"')) {
            throw 'TEST_SETUP_FAILURE: Quote in test argument.'
        }

        $commandParts.Add(
            '"' + $argument + '"'
        )
    }

    $command =
        $commandParts -join ' '

    $comSpec =
        [Environment]::GetEnvironmentVariable(
            'ComSpec'
        )

    if ([string]::IsNullOrWhiteSpace($comSpec)) {
        $comSpec = Join-Path $env:SystemRoot `
            'System32\cmd.exe'
    }

    $psi =
        New-Object Diagnostics.ProcessStartInfo

    $psi.FileName = $comSpec

    $psi.Arguments =
        '/d /s /c "' + $command + '"'

    $psi.WorkingDirectory = $PSScriptRoot
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true

    $psi.EnvironmentVariables[
        'PHASE_LOG'
    ] = 'D3_ENTRY_TEST_NO_PAUSE'

    $process =
        New-Object Diagnostics.Process

    $process.StartInfo = $psi

    try {
        if (-not $process.Start()) {
            throw 'TEST_SETUP_FAILURE: Entry process did not start.'
        }

        $stdoutTask =
            $process.StandardOutput.ReadToEndAsync()

        $stderrTask =
            $process.StandardError.ReadToEndAsync()

        if (-not $process.WaitForExit(120000)) {
            $process.Kill()
            $process.WaitForExit()

            throw 'TEST_SETUP_FAILURE: Entry process timed out.'
        }

        return [pscustomobject]@{
            ExitCode = $process.ExitCode
            Stdout = $stdoutTask.Result.TrimEnd()
            Stderr = $stderrTask.Result.TrimEnd()
        }
    }
    finally {
        $process.Dispose()
    }
}

function New-EntryCase {
    param(
        [hashtable]$ExitCodeOverrides = @{}
    )

    $workspace =
        New-AijMockWorkspace `
            -ParentDirectory $script:EvidenceRoot

    $plan =
        New-AijD3Plan `
            -Workspace $workspace `
            -ExitCodeOverrides $ExitCodeOverrides

    $null =
        Initialize-AijD3Orchestration `
            -Plan $plan `
            -Workspace $workspace

    return [pscustomobject]@{
        Workspace = $workspace
        Plan = $plan
    }
}

function New-EntryApproval {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Workspace
    )

    $plan =
        Read-AijD3Plan `
            -Workspace $Workspace

    $state =
        Read-AijStateFile `
            -Directory (Join-Path $Workspace 'state')

    $text =
        Get-AijD3ApprovalText `
            -Plan $plan `
            -State $state

    return New-AijD3Approval `
        -Workspace $Workspace `
        -ConfirmationText $text
}

try {
    $script:EvidenceRoot = Join-Path (
        [IO.Path]::GetTempPath()
    ) (
        'AIJ-D3-ENTRY-' +
        [guid]::NewGuid().ToString('N')
    )

    [void][IO.Directory]::CreateDirectory(
        $script:EvidenceRoot
    )

    # REVIEW remains intact

    $review =
        Invoke-RunAll `
            -Arguments @('/review')

    Assert-Equal `
        -Actual $review.ExitCode `
        -Expected 0 `
        -Label 'REVIEW_ENTRY_EXIT_ZERO'

    Assert-Contains `
        -Text $review.Stdout `
        -Expected 'RESULT: REVIEW_PASS' `
        -Label 'REVIEW_ENTRY_MARKER'

    Assert-Equal `
        -Actual $review.Stderr `
        -Expected '' `
        -Label 'REVIEW_ENTRY_STDERR_EMPTY'

    # Production APPLY remains blocked

    $apply =
        Invoke-RunAll `
            -Arguments @('/apply')

    Assert-Equal `
        -Actual $apply.ExitCode `
        -Expected 1 `
        -Label 'PRODUCTION_APPLY_BLOCKED_EXIT'

    Assert-Contains `
        -Text $apply.Stderr `
        -Expected (
            'PHASE 000 ENGINE FAILED: ' +
            'Mode APPLY is not implemented; no operation executed.'
        ) `
        -Label 'PRODUCTION_APPLY_BLOCKED_DIAGNOSTIC'

    # Production VERIFY remains blocked

    $verify =
        Invoke-RunAll `
            -Arguments @('/verify')

    Assert-Equal `
        -Actual $verify.ExitCode `
        -Expected 1 `
        -Label 'PRODUCTION_VERIFY_BLOCKED_EXIT'

    Assert-Contains `
        -Text $verify.Stderr `
        -Expected (
            'PHASE 000 ENGINE FAILED: ' +
            'Mode VERIFY is not implemented; no operation executed.'
        ) `
        -Label 'PRODUCTION_VERIFY_BLOCKED_DIAGNOSTIC'

    # Generic skip remains blocked

    $skip =
        Invoke-RunAll `
            -Arguments @(
                '/review',
                '/skip',
                '010'
            )

    Assert-Equal `
        -Actual $skip.ExitCode `
        -Expected 1 `
        -Label 'GENERIC_SKIP_BLOCKED'

    Assert-Contains `
        -Text $skip.Stdout `
        -Expected 'Resume and skip remain disabled' `
        -Label 'GENERIC_SKIP_USAGE_DIAGNOSTIC'

    # Success mapping

    $successCase =
        New-EntryCase

    $successApproval =
        New-EntryApproval `
            -Workspace $successCase.Workspace

    $success =
        Invoke-RunAll `
            -Arguments @(
                '/mock-execute',
                $successCase.Workspace,
                $successApproval.Path
            )

    Assert-Equal `
        -Actual $success.ExitCode `
        -Expected 0 `
        -Label 'MOCK_SUCCESS_PROCESS_EXIT'

    Assert-Equal `
        -Actual $success.Stderr `
        -Expected '' `
        -Label 'MOCK_SUCCESS_STDERR_EMPTY'

    Assert-Contains `
        -Text $success.Stdout `
        -Expected 'RESULT: MOCK_PHASE_EXIT_0' `
        -Label 'MOCK_SUCCESS_ENGINE_MARKER'

    Assert-Contains `
        -Text $success.Stdout `
        -Expected 'PHASE 000 EXIT CODE: 0' `
        -Label 'MOCK_SUCCESS_BAT_MAPPING'

    # Failure mapping

    $failureCase =
        New-EntryCase `
            -ExitCodeOverrides @{
                '010' = @(1)
            }

    $failureApproval =
        New-EntryApproval `
            -Workspace $failureCase.Workspace

    $failure =
        Invoke-RunAll `
            -Arguments @(
                '/mock-execute',
                $failureCase.Workspace,
                $failureApproval.Path
            )

    Assert-Equal `
        -Actual $failure.ExitCode `
        -Expected 1 `
        -Label 'MOCK_FAILURE_PROCESS_EXIT'

    Assert-Equal `
        -Actual $failure.Stderr `
        -Expected '' `
        -Label 'MOCK_FAILURE_STDERR_EMPTY'

    Assert-Contains `
        -Text $failure.Stdout `
        -Expected 'RESULT: MOCK_PHASE_EXIT_1' `
        -Label 'MOCK_FAILURE_ENGINE_MARKER'

    Assert-Contains `
        -Text $failure.Stdout `
        -Expected 'PHASE 000 EXIT CODE: 1' `
        -Label 'MOCK_FAILURE_BAT_MAPPING'

    # Unknown exit mapping

    $unknownCase =
        New-EntryCase `
            -ExitCodeOverrides @{
                '010' = @(77)
            }

    $unknownApproval =
        New-EntryApproval `
            -Workspace $unknownCase.Workspace

    $unknown =
        Invoke-RunAll `
            -Arguments @(
                '/mock-execute',
                $unknownCase.Workspace,
                $unknownApproval.Path
            )

    Assert-Equal `
        -Actual $unknown.ExitCode `
        -Expected 1 `
        -Label 'MOCK_UNKNOWN_PROCESS_EXIT'

    Assert-Contains `
        -Text $unknown.Stdout `
        -Expected 'RESULT: MOCK_PHASE_EXIT_1' `
        -Label 'MOCK_UNKNOWN_FAIL_CLOSED_MARKER'

    $unknownState =
        Read-AijStateFile `
            -Directory (
                Join-Path $unknownCase.Workspace 'state'
            )

    Assert-Equal `
        -Actual $unknownState.Record.State `
        -Expected 'FAILED_CLOSED' `
        -Label 'MOCK_UNKNOWN_STATE_FAILED_CLOSED'

    # Reboot mapping

    $rebootCase =
        New-EntryCase `
            -ExitCodeOverrides @{
                '010' = @(3010, 0)
            }

    $rebootApproval =
        New-EntryApproval `
            -Workspace $rebootCase.Workspace

    $reboot =
        Invoke-RunAll `
            -Arguments @(
                '/mock-execute',
                $rebootCase.Workspace,
                $rebootApproval.Path
            )

    Assert-Equal `
        -Actual $reboot.ExitCode `
        -Expected 3010 `
        -Label 'MOCK_REBOOT_PROCESS_EXIT'

    Assert-Equal `
        -Actual $reboot.Stderr `
        -Expected '' `
        -Label 'MOCK_REBOOT_STDERR_EMPTY'

    Assert-Contains `
        -Text $reboot.Stdout `
        -Expected 'RESULT: MOCK_PHASE_EXIT_3010' `
        -Label 'MOCK_REBOOT_ENGINE_MARKER'

    Assert-Contains `
        -Text $reboot.Stdout `
        -Expected 'PHASE 000 EXIT CODE: 3010' `
        -Label 'MOCK_REBOOT_BAT_MAPPING'

    $rebootState =
        Read-AijStateFile `
            -Directory (
                Join-Path $rebootCase.Workspace 'state'
            )

    Assert-Equal `
        -Actual $rebootState.Record.State `
        -Expected 'REBOOT_PENDING' `
        -Label 'MOCK_REBOOT_STATE_PERSISTED'

    Assert-Equal `
        -Actual $rebootState.Record.Resume.FromPhase `
        -Expected '010' `
        -Label 'MOCK_REBOOT_SAME_PHASE'

    # Fresh resume approval

    $resumeApproval =
        New-EntryApproval `
            -Workspace $rebootCase.Workspace

    $wrongResumeMode =
        Invoke-RunAll `
            -Arguments @(
                '/mock-execute',
                $rebootCase.Workspace,
                $resumeApproval.Path
            )

    Assert-Equal `
        -Actual $wrongResumeMode.ExitCode `
        -Expected 1 `
        -Label 'RESUME_REQUIRES_EXPLICIT_MODE'

    Assert-Contains `
        -Text $wrongResumeMode.Stderr `
        -Expected 'D3_RESUME_APPROVAL_REQUIRED' `
        -Label 'RESUME_MODE_DIAGNOSTIC'

    $resume =
        Invoke-RunAll `
            -Arguments @(
                '/mock-resume',
                $rebootCase.Workspace,
                $resumeApproval.Path
            )

    Assert-Equal `
        -Actual $resume.ExitCode `
        -Expected 0 `
        -Label 'MOCK_RESUME_PROCESS_EXIT'

    Assert-Equal `
        -Actual $resume.Stderr `
        -Expected '' `
        -Label 'MOCK_RESUME_STDERR_EMPTY'

    Assert-Contains `
        -Text $resume.Stdout `
        -Expected 'RESULT: MOCK_PHASE_EXIT_0' `
        -Label 'MOCK_RESUME_ENGINE_MARKER'

    Assert-Contains `
        -Text $resume.Stdout `
        -Expected 'PHASE 000 EXIT CODE: 0' `
        -Label 'MOCK_RESUME_BAT_MAPPING'

    $resumedState =
        Read-AijStateFile `
            -Directory (
                Join-Path $rebootCase.Workspace 'state'
            )

    $phase010 = @(
        $resumedState.Record.PhaseEvidence |
            Where-Object {
                $_.Phase -ceq '010'
            }
    )[0]

    Assert-Equal `
        -Actual $phase010.Attempt `
        -Expected 2 `
        -Label 'MOCK_RESUME_ATTEMPT_TWO'

    Assert-Equal `
        -Actual $phase010.State `
        -Expected 'APPLIED_UNVERIFIED' `
        -Label 'MOCK_RESUME_APPLIED_UNVERIFIED'

    Assert-Equal `
        -Actual $phase010.RuntimeVerified `
        -Expected $false `
        -Label 'MOCK_RESUME_NO_PRODUCTION_RUNTIME_PROOF'

    Write-Output (
        'D3_ENTRY_INTEGRATION_OK assertions=' +
        $script:Assertions
    )

    Write-Output (
        'D3_ENTRY_EVIDENCE_ROOT=' +
        $script:EvidenceRoot
    )

    exit 0
}
catch {
    if ($null -ne $script:EvidenceRoot) {
        [Console]::Error.WriteLine(
            'D3_ENTRY_EVIDENCE_ROOT=' +
            $script:EvidenceRoot
        )
    }

    [Console]::Error.WriteLine($_.ToString())
    exit 1
}