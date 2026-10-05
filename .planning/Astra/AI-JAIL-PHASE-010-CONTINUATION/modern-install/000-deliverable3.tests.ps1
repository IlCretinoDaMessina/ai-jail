# Phase 000 - Deliverable 3 acceptance
# Windows PowerShell 5.1

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

$root = $PSScriptRoot
$powerShellPath = Join-Path $PSHOME 'powershell.exe'

$suites = @(
    [pscustomobject]@{
        Name = 'Deliverable 1 and 2 regression'
        File = '000-deliverable2.tests.ps1'
        Marker = 'DELIVERABLE_2_ACCEPTANCE_OK'
        AllowedStderrLine = 'D2_FAILURE_AUDIT_UNAVAILABLE'
    },
    [pscustomobject]@{
        Name = 'Deliverable 3 orchestration'
        File = '000-orchestration.tests.ps1'
        Marker = 'D3_ORCHESTRATION_FOCUSED_OK'
        AllowedStderrLine = $null
    },
    [pscustomobject]@{
        Name = 'Deliverable 3 entry integration'
        File = '000-entry-orchestration.tests.ps1'
        Marker = 'D3_ENTRY_INTEGRATION_OK'
        AllowedStderrLine = $null
    }
)

function Assert-AijSuiteStderr {
    param(
        [Parameter(Mandatory = $true)]
        $Suite,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Stderr
    )

    if ([string]::IsNullOrWhiteSpace($Stderr)) {
        return
    }

    $lines = @(
        $Stderr -split "`r?`n" |
            Where-Object {
                -not [string]::IsNullOrWhiteSpace($_)
            }
    )

    if ([string]::IsNullOrWhiteSpace(
        [string]$Suite.AllowedStderrLine
    )) {
        throw (
            'Unexpected stderr from ' +
            "$($Suite.File): $Stderr"
        )
    }

    foreach ($line in $lines) {
        if ($line -cne $Suite.AllowedStderrLine) {
            throw (
                'Unexpected stderr from ' +
                "$($Suite.File): $line"
            )
        }
    }

    Write-Output (
        'EXPECTED_STDERR: ' +
        $Suite.AllowedStderrLine +
        ' count=' +
        $lines.Count
    )
}

function Invoke-AijAcceptanceSuite {
    param(
        [Parameter(Mandatory = $true)]
        $Suite
    )

    $path = Join-Path $root $Suite.File

    if (-not [IO.File]::Exists($path)) {
        throw "Required suite missing: $($Suite.File)"
    }

    Write-Output ''
    Write-Output "=== $($Suite.Name) ==="

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $powerShellPath
    $psi.Arguments = (
        '-NoProfile -NonInteractive ' +
        '-ExecutionPolicy Bypass -File "' +
        $path +
        '"'
    )
    $psi.WorkingDirectory = $root
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi

    try {
        if (-not $process.Start()) {
            throw "Could not start suite: $($Suite.File)"
        }

        $stdoutTask =
            $process.StandardOutput.ReadToEndAsync()

        $stderrTask =
            $process.StandardError.ReadToEndAsync()

        if (-not $process.WaitForExit(180000)) {
            try {
                $process.Kill()
                $process.WaitForExit()
            }
            catch {
            }

            throw "Suite timed out: $($Suite.File)"
        }

        $stdout = $stdoutTask.Result.TrimEnd()
        $stderr = $stderrTask.Result.TrimEnd()

        if ($stdout.Length -gt 0) {
            Write-Output $stdout
        }

        if ($process.ExitCode -ne 0) {
            if ($stderr.Length -gt 0) {
                [Console]::Error.WriteLine($stderr)
            }

            throw (
                'Acceptance suite failed: ' +
                "$($Suite.File), exit " +
                "$($process.ExitCode)."
            )
        }

        if ($stdout.IndexOf(
            $Suite.Marker,
            [StringComparison]::Ordinal
        ) -lt 0) {
            throw (
                'Required success marker missing from ' +
                "$($Suite.File): $($Suite.Marker)"
            )
        }

        Assert-AijSuiteStderr `
            -Suite $Suite `
            -Stderr $stderr

        Write-Output "SUITE_OK: $($Suite.File)"
    }
    finally {
        $process.Dispose()
    }
}

try {
    foreach ($suite in $suites) {
        Invoke-AijAcceptanceSuite -Suite $suite
    }

    Write-Output ''
    Write-Output 'DELIVERABLE_3_ACCEPTANCE_OK'
    Write-Output 'PHASE_000_MOCK_ACCEPTANCE_OK'
    Write-Output 'Behavior: D1 persistence and reboot-safe state regressions preserved'
    Write-Output 'Behavior: D2 approval, audit and strict-helper regressions preserved'
    Write-Output 'Behavior: dependency-ordered multi-phase mock orchestration verified'
    Write-Output 'Behavior: failure and unknown exits stop orchestration fail-closed'
    Write-Output 'Behavior: 3010 stops and resumes the same phase with fresh approval'
    Write-Output 'Behavior: resume works across a new PowerShell process'
    Write-Output 'Behavior: BAT and engine preserve 0, 1 and 3010'
    Write-Output 'Behavior: production APPLY and VERIFY remain blocked'
    Write-Output 'Behavior: mock verification does not assert production runtime proof'

    exit 0
}
catch {
    [Console]::Error.WriteLine($_.ToString())
    exit 1
}