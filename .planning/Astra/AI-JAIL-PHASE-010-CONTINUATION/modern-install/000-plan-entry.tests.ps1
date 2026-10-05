# Phase 000 - PLAN entry integration
# Windows PowerShell 5.1

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

$process = $null

try {
    $root = [IO.Directory]::GetParent($PSScriptRoot).FullName
    $configPath = Join-Path $PSScriptRoot 'config.env'

    $beforeConfig = (
        Get-FileHash -LiteralPath $configPath -Algorithm SHA256
    ).Hash

    # Child CMD entry point

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $env:ComSpec
    $psi.WorkingDirectory = $root
    $psi.Arguments = '/D /C "call modern-install\000-run-all.bat /plan"'
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true
    $psi.EnvironmentVariables['PHASE_LOG'] = 'AIJ_PHASE000_TEST'

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
    $errors = $errorTask.Result.Trim()

    if ($process.ExitCode -ne 1) {
        throw "EXPECTED_BLOCKED_EXIT_1_GOT_$($process.ExitCode)"
    }

    if ($errors.Length -ne 0) {
        throw "UNEXPECTED_STDERR: $errors"
    }

    foreach ($marker in @(
        'PHASE INVENTORY: VALIDATED',
        'PHASE 000 REVIEW: PASS',
        'PLAN SNAPSHOT: DRAFT_BLOCKED',
        'Source files: 33',
        'RESULT: PLAN_DRAFT_BLOCKED',
        'PHASE 000 EXIT CODE: 1'
    )) {
        if (-not $output.Contains($marker)) {
            throw "MISSING_PLAN_EVIDENCE: $marker"
        }
    }

    Write-Output 'PASS: BAT_PLAN_DISPATCH_AND_BLOCKED_EXIT'

    # Machine-readable output

    $pattern = '(?m)^PLAN_JSON_BEGIN\r?\n(?<json>[^\r\n]+)\r?\nPLAN_JSON_END\r?$'
    $match = [regex]::Match($output, $pattern)

    if (-not $match.Success) {
        throw 'PLAN_JSON_NOT_EMITTED'
    }

    $json = $match.Groups['json'].Value
    $document = ConvertFrom-Json -InputObject $json -ErrorAction Stop

    if ($document.Kind -cne 'PHASE_000_PLAN_SNAPSHOT' -or
        $document.State -cne 'DRAFT_BLOCKED' -or
        $document.ExecutionAuthorized -ne $false -or
        $document.ApprovalRecorded -ne $false -or
        $document.ReadyForApproval -ne $false -or
        $null -ne $document.ArtifactLock -or
        @($document.SelectedActions).Count -ne 0) {
        throw 'UNSAFE_PLAN_JSON'
    }

    Write-Output 'PASS: MACHINE_READABLE_FAIL_CLOSED_PLAN'

    # Source identities

    if (@($document.PhaseCandidates).Count -ne 11 -or
        @($document.SourceFiles).Count -ne 33) {
        throw 'INCOMPLETE_PLAN_INVENTORY'
    }

    foreach ($name in @(
        '000-engine.ps1',
        '000-state.ps1',
        '000-state-store.ps1'
    )) {
        $record = @(
            $document.SourceFiles |
                Where-Object { $_.Name -ceq $name }
        )

        if ($record.Count -ne 1) {
            throw "SOURCE_IDENTITY_MISSING: $name"
        }

        $actualHash = (
            Get-FileHash `
                -LiteralPath (Join-Path $PSScriptRoot $name) `
                -Algorithm SHA256
        ).Hash

        if ($record[0].Sha256 -cne $actualHash) {
            throw "SOURCE_IDENTITY_MISMATCH: $name"
        }
    }

    if ($document.ConfigurationSha256 -cne $beforeConfig) {
        throw 'CONFIGURATION_IDENTITY_MISMATCH'
    }

    Write-Output 'PASS: ACTUAL_SOURCE_IDENTITIES'

    # Independent fingerprint

    $hasher = [Security.Cryptography.SHA256]::Create()

    try {
        $bytes = [Text.Encoding]::UTF8.GetBytes($json)

        $fingerprint = [BitConverter]::ToString(
            $hasher.ComputeHash($bytes)
        ).Replace('-', '')
    }
    finally {
        $hasher.Dispose()
    }

    if (-not $output.Contains(
        "Snapshot SHA256: $fingerprint"
    )) {
        throw 'SNAPSHOT_FINGERPRINT_MISMATCH'
    }

    Write-Output 'PASS: JSON_FINGERPRINT'

    # Real configuration unchanged

    $afterConfig = (
        Get-FileHash -LiteralPath $configPath -Algorithm SHA256
    ).Hash

    if ($afterConfig -cne $beforeConfig) {
        throw 'REAL_CONFIGURATION_CHANGED'
    }

    Write-Output 'PASS: CONFIG_UNCHANGED'
    Write-Output 'PLAN_ENTRY_REGRESSIONS_OK'

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