# Phase 000 - Deliverable 1 runner
# Windows PowerShell 5.1

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

$root = $PSScriptRoot

$tests = @(
    [pscustomobject]@{
        Name = 'Manifest source binding'
        File = '000-manifest-source-lock.tests.ps1'
    },
    [pscustomobject]@{
        Name = 'Manifest regression'
        File = '000-manifest.tests.ps1'
    },
    [pscustomobject]@{
        Name = 'State regression'
        File = '000-state.tests.ps1'
    },
    [pscustomobject]@{
        Name = 'State binding'
        File = '000-state-binding.tests.ps1'
    },
    [pscustomobject]@{
        Name = 'State-store binding'
        File = '000-state-store-binding.tests.ps1'
    },
    [pscustomobject]@{
        Name = 'State-store corruption'
        File = '000-state-store.tests.ps1'
    },
    [pscustomobject]@{
        Name = 'State-store reparse'
        File = '000-state-store-reparse.tests.ps1'
    },
    [pscustomobject]@{
        Name = 'PLAN state integration'
        File = '000-plan-state-entry.tests.ps1'
    },
    [pscustomobject]@{
        Name = 'Runtime state and resume'
        File = '000-runtime-state.tests.ps1'
    }
)

$powerShellPath = Join-Path $PSHOME 'powershell.exe'

try {
    foreach ($test in $tests) {
        $path = Join-Path $root $test.File

        if (-not [IO.File]::Exists($path)) {
            throw "Required test missing: $($test.File)"
        }

        Write-Output ''
        Write-Output "=== $($test.Name) ==="

        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $powerShellPath
        $psi.Arguments = (
            '-NoProfile -NonInteractive ' +
            '-ExecutionPolicy Bypass ' +
            '-File "' + $path + '"'
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
                throw "Could not start test: $($test.File)"
            }

            $stdoutTask =
                $process.StandardOutput.ReadToEndAsync()

            $stderrTask =
                $process.StandardError.ReadToEndAsync()

            if (-not $process.WaitForExit(120000)) {
                $process.Kill()
                $process.WaitForExit()

                throw "Test timed out: $($test.File)"
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
                    "Milestone test failed: " +
                    "$($test.File), exit " +
                    "$($process.ExitCode)."
                )
            }

            if ($stderr.Length -gt 0) {
                throw (
                    "Unexpected stderr from " +
                    "$($test.File): $stderr"
                )
            }
        }
        finally {
            $process.Dispose()
        }
    }

    Write-Output ''
    Write-Output 'DELIVERABLE_1_ACCEPTANCE_OK'
    Write-Output 'Behavior: deterministic PLAN/state binding preserved'
    Write-Output 'Behavior: phase results persist without runtime verification'
    Write-Output 'Behavior: active execution authorization is not durable'
    Write-Output 'Behavior: 3010 persists a same-phase reboot resume directive'
    Write-Output 'Behavior: stale state and stale PLAN resume are rejected'

    exit 0
}
catch {
    [Console]::Error.WriteLine($_.ToString())
    exit 1
}