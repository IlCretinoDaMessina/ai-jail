# Phase 000 - PLAN state integration
# Windows PowerShell 5.1

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

$process = $null

try {
    $enginePath = Join-Path $PSScriptRoot '000-engine.ps1'
    $powerShellPath = Join-Path $PSHOME 'powershell.exe'

    # Syntax control

    $tokens = $null
    $errors = $null

    [void][System.Management.Automation.Language.Parser]::ParseFile(
        $enginePath,
        [ref]$tokens,
        [ref]$errors
    )

    if ($errors.Count -ne 0) {
        throw (
            'ENGINE_SYNTAX_FAILURE: ' +
            (($errors | ForEach-Object { $_.Message }) -join '; ')
        )
    }

    Write-Output 'PASS: ENGINE_SYNTAX'

    # Child PLAN process

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $powerShellPath
    $psi.Arguments = (
        '-NoProfile -NonInteractive -ExecutionPolicy Bypass ' +
        '-File "' + $enginePath + '" /plan'
    )
    $psi.WorkingDirectory = $PSScriptRoot
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi

    if (-not $process.Start()) {
        throw 'PLAN_PROCESS_NOT_STARTED'
    }

    $outputTask = $process.StandardOutput.ReadToEndAsync()
    $errorTask = $process.StandardError.ReadToEndAsync()

    if (-not $process.WaitForExit(60000)) {
        $process.Kill()
        $process.WaitForExit()
        throw 'PLAN_PROCESS_TIMEOUT'
    }

    $output = $outputTask.Result
    $stderr = $errorTask.Result.Trim()

    if ($process.ExitCode -ne 1) {
        throw (
            'EXPECTED_PLAN_EXIT_1_GOT_' +
            $process.ExitCode
        )
    }

    if ($stderr.Length -ne 0) {
        throw "UNEXPECTED_STDERR: $stderr"
    }

    foreach ($marker in @(
        'PHASE INVENTORY: VALIDATED',
        'PHASE 000 REVIEW: PASS',
        'PLAN SNAPSHOT: DRAFT_BLOCKED',
        'Source files: 33',
        'STATE: PLAN_BLOCKED',
        'Approval: NOT RECORDED',
        'Resume: NONE',
        'Reboot pending: FALSE',
        'Execution: DISABLED',
        'RESULT: PLAN_DRAFT_BLOCKED'
    )) {
        if (-not $output.Contains($marker)) {
            throw "MISSING_EVIDENCE: $marker"
        }
    }

    Write-Output 'PASS: PLAN_EMITS_BLOCKED_STATE'

    # Machine-readable PLAN

    $planPattern = (
        '(?m)^PLAN_JSON_BEGIN\r?\n' +
        '(?<json>[^\r\n]+)\r?\n' +
        'PLAN_JSON_END\r?$'
    )

    $planMatch = [regex]::Match(
        $output,
        $planPattern
    )

    if (-not $planMatch.Success) {
        throw 'PLAN_JSON_NOT_EMITTED'
    }

    $planJson = $planMatch.Groups['json'].Value

    $plan = ConvertFrom-Json `
        -InputObject $planJson `
        -ErrorAction Stop

    if ($plan.Kind -cne 'PHASE_000_PLAN_SNAPSHOT' -or
        $plan.State -cne 'DRAFT_BLOCKED' -or
        $plan.ExecutionAuthorized -ne $false -or
        $plan.ApprovalRecorded -ne $false -or
        $plan.ReadyForApproval -ne $false -or
        @($plan.SourceFiles).Count -ne 33 -or
        @($plan.PhaseCandidates).Count -ne 11) {
        throw 'INVALID_PLAN_JSON'
    }

    # Machine-readable state

    $statePattern = (
        '(?m)^STATE_JSON_BEGIN\r?\n' +
        '(?<json>[^\r\n]+)\r?\n' +
        'STATE_JSON_END\r?$'
    )

    $stateMatch = [regex]::Match(
        $output,
        $statePattern
    )

    if (-not $stateMatch.Success) {
        throw 'STATE_JSON_NOT_EMITTED'
    }

    $stateJson = $stateMatch.Groups['json'].Value

    $state = ConvertFrom-Json `
        -InputObject $stateJson `
        -ErrorAction Stop

    if ($state.Kind -cne 'PHASE_000_STATE' -or
        $state.State -cne 'PLAN_BLOCKED' -or
        $state.ExecutionAuthorized -ne $false -or
        $state.Approval.Status -cne 'NOT_RECORDED' -or
        $state.Resume.Status -cne 'NONE' -or
        $state.Resume.RebootPending -ne $false -or
        @($state.PhaseEvidence).Count -ne 11) {
        throw 'INVALID_STATE_JSON'
    }

    Write-Output 'PASS: MACHINE_READABLE_PLAN_AND_STATE'

    # Exact PLAN binding

    $hasher = [Security.Cryptography.SHA256]::Create()

    try {
        $planHash = [BitConverter]::ToString(
            $hasher.ComputeHash(
                [Text.Encoding]::UTF8.GetBytes($planJson)
            )
        ).Replace('-', '')
    }
    finally {
        $hasher.Dispose()
    }

    if ($state.Plan.SnapshotSha256 -cne $planHash) {
        throw 'STATE_NOT_BOUND_TO_EMITTED_PLAN'
    }

    if (-not $output.Contains(
        "Plan SHA256: $planHash"
    )) {
        throw 'READABLE_PLAN_BINDING_MISMATCH'
    }

    Write-Output 'PASS: STATE_BOUND_TO_EXACT_PLAN'

    # State fingerprint

    $hasher = [Security.Cryptography.SHA256]::Create()

    try {
        $stateHash = [BitConverter]::ToString(
            $hasher.ComputeHash(
                [Text.Encoding]::UTF8.GetBytes($stateJson)
            )
        ).Replace('-', '')
    }
    finally {
        $hasher.Dispose()
    }

    if (-not $output.Contains(
        "State SHA256: $stateHash"
    )) {
        throw 'STATE_FINGERPRINT_MISMATCH'
    }

    Write-Output 'PASS: STATE_FINGERPRINT'

    # No invented runtime evidence

    $unsafe = @(
        $state.PhaseEvidence |
            Where-Object {
                $_.State -cne 'UNVERIFIED' -or
                $_.Attempt -ne 0 -or
                $null -ne $_.ExitCode -or
                $_.RuntimeVerified -ne $false -or
                $_.RebootRequired -ne $false -or
                $null -ne $_.EvidenceSha256
            }
    )

    if ($unsafe.Count -ne 0) {
        throw 'UNSAFE_PHASE_EVIDENCE'
    }

    Write-Output 'PASS: ALL_PHASE_EVIDENCE_UNVERIFIED'
    Write-Output 'PLAN_STATE_INTEGRATION_OK'

    exit 0
}
catch {
    [Console]::Error.WriteLine($_.ToString())
    exit 1
}
finally {
    if ($null -ne $process) {
        $process.Dispose()
    }
}