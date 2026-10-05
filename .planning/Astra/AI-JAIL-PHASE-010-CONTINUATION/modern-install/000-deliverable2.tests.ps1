# Consolidated D2 acceptance. Supplied, NOT executed by the author.
# Existing D1 contracts are exercised without changing their test files.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
$suites = @(
    @{File='000-deliverable1.tests.ps1'; Marker='DELIVERABLE_1_ACCEPTANCE_OK'},
    @{File='000-state-store-concurrency.tests.ps1'; Marker='STATE_STORE_CONCURRENCY_REGRESSION_OK'},
    @{File='000-authorization.tests.ps1'; Marker='DELIVERABLE_2_FOCUSED_OK'}
)
try {
    if ($PSVersionTable.PSVersion.Major -ne 5 -or $PSVersionTable.PSVersion.Minor -ne 1) {
        throw 'Run this acceptance command with Windows PowerShell 5.1 (powershell.exe).'
    }
    foreach ($suite in $suites) {
        $path = Join-Path $PSScriptRoot $suite.File
        if (-not [IO.File]::Exists($path)) { throw ('Required test missing: ' + $suite.File) }
        Write-Output ('=== ' + $suite.File + ' ===')
        $psi = New-Object Diagnostics.ProcessStartInfo
        $psi.FileName = Join-Path $PSHOME 'powershell.exe'
        $psi.Arguments = '-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' + $path + '"'
        $psi.WorkingDirectory = $PSScriptRoot
        $psi.UseShellExecute = $false; $psi.CreateNoWindow = $true
        $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true
        $process = New-Object Diagnostics.Process
        $process.StartInfo = $psi
        try {
            if (-not $process.Start()) { throw ('Could not start: ' + $suite.File) }
            $stdoutTask = $process.StandardOutput.ReadToEndAsync()
            $stderrTask = $process.StandardError.ReadToEndAsync()
            if (-not $process.WaitForExit(300000)) {
                $process.Kill(); $process.WaitForExit()
                throw ('Suite timed out: ' + $suite.File)
            }
            $stdout = $stdoutTask.Result; $stderr = $stderrTask.Result
            if ($stdout.Length -gt 0) { Write-Output ($stdout.TrimEnd()) }
            if ($stderr.Length -gt 0) { [Console]::Error.WriteLine($stderr.TrimEnd()) }
            if ($process.ExitCode -ne 0) { throw ('Suite failed: ' + $suite.File + ', exit ' + $process.ExitCode) }
            if ($null -ne $suite.Marker -and -not $stdout.Contains($suite.Marker)) {
                throw ('Acceptance marker missing: ' + $suite.File)
            }
        } finally { $process.Dispose() }
    }
    Write-Output 'DELIVERABLE_2_ACCEPTANCE_OK'
    exit 0
} catch {
    [Console]::Error.WriteLine('DELIVERABLE_2_ACCEPTANCE_FAILED: ' + $_.Exception.Message)
    exit 1
}
