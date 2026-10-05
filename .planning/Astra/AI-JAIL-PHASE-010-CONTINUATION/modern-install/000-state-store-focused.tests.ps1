# Phase 000 - Focused state-store acceptance
# Windows PowerShell 5.1

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

$root = $PSScriptRoot
$powerShellPath = Join-Path $PSHOME 'powershell.exe'

$tests = @(
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
        Name = 'Runtime state and resume'
        File = '000-runtime-state.tests.ps1'
    },
    [pscustomobject]@{
        Name = 'Concurrent writers'
        File = '000-state-store-concurrency.tests.ps1'
    }
)

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
                    "Focused state-store test failed: " +
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
    Write-Output 'STATE_STORE_FOCUSED_ACCEPTANCE_OK'
    Write-Output 'Behavior: established draft API preserved'
    Write-Output 'Behavior: exact corruption diagnostics preserved'
    Write-Output 'Behavior: reparse protections preserved'
    Write-Output 'Behavior: durable runtime and 3010 resume state accepted'
    Write-Output 'Behavior: competing writers serialize on previous-state SHA'

    exit 0
}
catch {
    [Console]::Error.WriteLine($_.ToString())
    exit 1
}