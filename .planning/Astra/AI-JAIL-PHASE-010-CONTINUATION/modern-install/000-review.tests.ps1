
# Phase 000 - Offline REVIEW regressions
# Windows PowerShell 5.1

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

$utf8 = New-Object System.Text.UTF8Encoding($false, $true)
$ownedFolders = New-Object 'System.Collections.Generic.List[string]'
$sourceRoot = $PSScriptRoot

$baseConfig = @'
# Valid offline test configuration
TARGET_DRIVE=E:
DISTRO=AIJail
BASE_DISTRO=Ubuntu
LINUX_USER=aijail
MIN_WSL_VERSION=2.10.0
MIN_FREE_GB=20
ALLOW_HOSTS_OPENCODE=
ALLOW_HOSTS_COMFYUI=
ALLOW_HOSTS_INSTALL=
INSTALL_COMFYUI=0
INSTALL_OPENCODE=1
INSTALL_VSCODE=0
ENABLE_NONO=1
'@

foreach ($name in @(
    '000-review.ps1',
    '000-config.ps1',
    '000-requirements.json'
)) {
    if (-not [IO.File]::Exists((Join-Path $sourceRoot $name))) {
        throw "TEST_SETUP_FAILURE: Missing $name."
    }
}

function New-ReviewFixture {
    $folder = Join-Path ([IO.Path]::GetTempPath()) (
        'AIJ-P000-REVIEW-' + [guid]::NewGuid().ToString('N')
    )

    if ([IO.Directory]::Exists($folder)) {
        throw 'TEST_SETUP_FAILURE: Fixture directory already exists.'
    }

    $null = [IO.Directory]::CreateDirectory($folder)
    $ownedFolders.Add($folder)

    foreach ($name in @(
        '000-review.ps1',
        '000-config.ps1',
        '000-requirements.json'
    )) {
        [IO.File]::Copy(
            (Join-Path $sourceRoot $name),
            (Join-Path $folder $name)
        )
    }

    [IO.File]::WriteAllText(
        (Join-Path $folder 'config.env'),
        $baseConfig,
        $utf8
    )

    [IO.File]::WriteAllText(
        (Join-Path $folder '_common.bat'),
        "@echo off`r`n",
        $utf8
    )

    $mockBat = '@echo off' + "`r`n" +
        'echo EXECUTED>"%~dp0phase-executed.marker"' + "`r`n"

    [IO.File]::WriteAllText(
        (Join-Path $folder '010-mock.bat'),
        $mockBat,
        $utf8
    )

    [IO.File]::WriteAllText(
        (Join-Path $folder '010-requirements.json'),
        '{"schema":1,"phase":"010"}',
        $utf8
    )

    return $folder
}

function Invoke-ReviewFixture {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Folder
    )

    $reviewPath = Join-Path $Folder '000-review.ps1'

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = Join-Path $PSHOME 'powershell.exe'
    $psi.Arguments = (
        '-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' +
        $reviewPath + '"'
    )

    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi

    try {
        if (-not $process.Start()) {
            throw 'TEST_INFRA_FAILURE: Reviewer process did not start.'
        }

        $stdout = $process.StandardOutput.ReadToEnd()
        $stderr = $process.StandardError.ReadToEnd()

        if (-not $process.WaitForExit(30000)) {
            $process.Kill()
            $process.WaitForExit()
            throw 'TEST_INFRA_FAILURE: Reviewer process timed out.'
        }

        return [pscustomobject]@{
            Executed = $true
            ExitCode = $process.ExitCode
            StdOut   = $stdout
            StdErr   = $stderr
        }
    }
    finally {
        $process.Dispose()
    }
}

function Assert-NoPhaseExecution {
    param([string]$Folder)

    $marker = Join-Path $Folder 'phase-executed.marker'

    if ([IO.File]::Exists($marker)) {
        throw 'ASSERTION_FAILURE: Mock installation BAT was executed.'
    }
}

function Assert-ReviewSuccess {
    param(
        [string]$Label,
        $Result
    )

    if (-not $Result.Executed) {
        throw "ASSERTION_FAILURE: $Label`: not executed."
    }

    if ($Result.ExitCode -ne 0) {
        throw "ASSERTION_FAILURE: $Label`: exit code $($Result.ExitCode)."
    }

    if ($Result.StdErr.Trim().Length -ne 0) {
        throw "ASSERTION_FAILURE: $Label`: unexpected stderr."
    }

    foreach ($expected in @(
        'Authoritative parser: PASS',
        '010-mock.bat: REQUIREMENTS PRESENT',
        'PHASE 000 REVIEW: PASS'
    )) {
        if (-not $Result.StdOut.Contains($expected)) {
            throw "ASSERTION_FAILURE: $Label`: missing $expected."
        }
    }

    Write-Output "PASS: $Label"
}

function Assert-ReviewFailure {
    param(
        [string]$Label,
        $Result,
        [string]$ExpectedDiagnostic
    )

    if (-not $Result.Executed) {
        throw "ASSERTION_FAILURE: $Label`: not executed."
    }

    if ($Result.ExitCode -ne 1) {
        throw "ASSERTION_FAILURE: $Label`: exit code $($Result.ExitCode)."
    }

    $actual = $Result.StdErr.Trim()

    if ($actual -cne $ExpectedDiagnostic) {
        throw "ASSERTION_FAILURE: $Label`: wrong diagnostic [$actual]."
    }

    if ($Result.StdOut.Contains('PHASE 000 REVIEW: PASS')) {
        throw "ASSERTION_FAILURE: $Label`: false success reported."
    }

    Write-Output "PASS: $Label"
}

function Assert-GuardTrip {
    param(
        [string]$Label,
        [scriptblock]$Probe,
        [string]$Expected
    )

    $actual = $null

    try {
        $null = & $Probe
    }
    catch {
        $actual = $_.Exception.Message
    }

    if ($null -eq $actual -or $actual -cne $Expected) {
        throw "TEST_GUARD_FAILURE: $Label did not fail as expected."
    }

    Write-Output "PASS: GUARD_$Label"
}

try {
    # Positive control

    $folder = New-ReviewFixture
    $result = Invoke-ReviewFixture -Folder $folder

    Assert-ReviewSuccess -Label 'VALID_OFFLINE_REVIEW' -Result $result
    Assert-NoPhaseExecution -Folder $folder

    Write-Output 'PASS: MOCK_BAT_NOT_EXECUTED'

    # Assertion integrity

    Assert-GuardTrip `
        -Label 'UNEXPECTED_ACCEPTANCE' `
        -Probe {
            Assert-ReviewFailure `
                -Label 'CONTROL_ACCEPT' `
                -Result ([pscustomobject]@{
                    Executed = $true
                    ExitCode = 0
                    StdOut = ''
                    StdErr = ''
                }) `
                -ExpectedDiagnostic 'EXPECTED'
        } `
        -Expected 'ASSERTION_FAILURE: CONTROL_ACCEPT: exit code 0.'

    Assert-GuardTrip `
        -Label 'UNRELATED_ERROR' `
        -Probe {
            Assert-ReviewFailure `
                -Label 'CONTROL_ERROR' `
                -Result ([pscustomobject]@{
                    Executed = $true
                    ExitCode = 1
                    StdOut = ''
                    StdErr = 'UNRELATED_SENTINEL'
                }) `
                -ExpectedDiagnostic 'EXPECTED'
        } `
        -Expected 'ASSERTION_FAILURE: CONTROL_ERROR: wrong diagnostic [UNRELATED_SENTINEL].'

    Assert-GuardTrip `
        -Label 'MISSING_EXECUTION' `
        -Probe {
            Assert-ReviewFailure `
                -Label 'CONTROL_SKIP' `
                -Result ([pscustomobject]@{
                    Executed = $false
                    ExitCode = 1
                    StdOut = ''
                    StdErr = 'EXPECTED'
                }) `
                -ExpectedDiagnostic 'EXPECTED'
        } `
        -Expected 'ASSERTION_FAILURE: CONTROL_SKIP: not executed.'

    # Unknown configuration key

    $folder = New-ReviewFixture
    $path = Join-Path $folder 'config.env'

    [IO.File]::AppendAllText(
        $path,
        "`r`nUNKNOWN_KEY=1",
        $utf8
    )

    $result = Invoke-ReviewFixture -Folder $folder

    Assert-ReviewFailure `
        -Label 'UNKNOWN_CONFIG_KEY' `
        -Result $result `
        -ExpectedDiagnostic 'PHASE 000 REVIEW FAILED: Unknown configuration key at line 15.'

    Assert-NoPhaseExecution -Folder $folder

    # Reserved distribution name

    $folder = New-ReviewFixture
    $path = Join-Path $folder 'config.env'

    $content = [IO.File]::ReadAllText($path, $utf8)

    $content = $content.Replace(
        'DISTRO=AIJail',
        'DISTRO=CON.txt'
    )

    [IO.File]::WriteAllText($path, $content, $utf8)

    $result = Invoke-ReviewFixture -Folder $folder

    Assert-ReviewFailure `
        -Label 'RESERVED_DISTRO_REJECTED' `
        -Result $result `
        -ExpectedDiagnostic 'PHASE 000 REVIEW FAILED: Unsafe distribution identifier: DISTRO.'

    Assert-NoPhaseExecution -Folder $folder

    # Missing authoritative parser

    $folder = New-ReviewFixture

    [IO.File]::Delete(
        (Join-Path $folder '000-config.ps1')
    )

    $result = Invoke-ReviewFixture -Folder $folder

    Assert-ReviewFailure `
        -Label 'MISSING_PARSER_FAIL_CLOSED' `
        -Result $result `
        -ExpectedDiagnostic 'PHASE 000 REVIEW FAILED: Required file missing: 000-config.ps1'

    Assert-NoPhaseExecution -Folder $folder

    # Missing per-phase requirements

    $folder = New-ReviewFixture

    [IO.File]::Delete(
        (Join-Path $folder '010-requirements.json')
    )

    $result = Invoke-ReviewFixture -Folder $folder

    Assert-ReviewFailure `
        -Label 'MISSING_PHASE_REQUIREMENTS' `
        -Result $result `
        -ExpectedDiagnostic 'PHASE 000 REVIEW FAILED: 1 installation phase(s) lack valid requirements.'

    if (-not $result.StdOut.Contains(
        '010-mock.bat: REQUIREMENTS MISSING'
    )) {
        throw 'ASSERTION_FAILURE: Missing requirements check did not execute.'
    }

    Assert-NoPhaseExecution -Folder $folder

    # Unsupported per-phase schema

    $folder = New-ReviewFixture

    [IO.File]::WriteAllText(
        (Join-Path $folder '010-requirements.json'),
        '{"schema":2,"phase":"010"}',
        $utf8
    )

    $result = Invoke-ReviewFixture -Folder $folder

    Assert-ReviewFailure `
        -Label 'UNSUPPORTED_PHASE_SCHEMA' `
        -Result $result `
        -ExpectedDiagnostic 'PHASE 000 REVIEW FAILED: Invalid requirements: 010-requirements.json'

    Assert-NoPhaseExecution -Folder $folder

    # Production APPLY must remain disabled

    $folder = New-ReviewFixture
    $path = Join-Path $folder '000-requirements.json'

    $requirements = [IO.File]::ReadAllText($path, $utf8) |
        ConvertFrom-Json -ErrorAction Stop

    $requirements.approvals.production_apply_authorized = $true

    [IO.File]::WriteAllText(
        $path,
        (ConvertTo-Json -InputObject $requirements -Depth 16),
        $utf8
    )

    $result = Invoke-ReviewFixture -Folder $folder

    Assert-ReviewFailure `
        -Label 'PRODUCTION_APPLY_POLICY_REJECTED' `
        -Result $result `
        -ExpectedDiagnostic 'PHASE 000 REVIEW FAILED: Installation approval policy mismatch.'

    Assert-NoPhaseExecution -Folder $folder

    Write-Output 'REVIEW_REGRESSIONS_OK'
}
finally {
    # Remove only test-created temporary directories.

    foreach ($folder in $ownedFolders) {
        if ([IO.Directory]::Exists($folder)) {
            [IO.Directory]::Delete($folder, $true)
        }
    }
}
