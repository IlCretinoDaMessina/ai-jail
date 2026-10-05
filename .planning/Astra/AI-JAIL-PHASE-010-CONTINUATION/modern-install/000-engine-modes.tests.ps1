# Phase 000 - Engine mode regressions
# Windows PowerShell 5.1

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

$source = $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false, $true)
$folder = Join-Path ([IO.Path]::GetTempPath()) (
    'AIJ-MODES-' + [guid]::NewGuid().ToString('N')
)

$script:reviews = 0
$script:blocked = 0
$script:guards = 0

function Assert-NoPhaseExecution {
    if ([IO.File]::Exists(
        (Join-Path $folder 'phase-executed.marker')
    )) {
        throw 'ASSERTION_FAILURE: Installation phase BAT was executed.'
    }
}

function Invoke-TestEntry {
    param(
        [ValidateSet('ENGINE', 'BAT')]
        [string]$Kind,

        [string[]]$Tokens = @()
    )

    $tail = $Tokens -join ' '
    $psi = New-Object System.Diagnostics.ProcessStartInfo

    if ($Kind -ceq 'ENGINE') {
        $psi.FileName = Join-Path $PSHOME 'powershell.exe'
        $psi.Arguments = (
            '-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' +
            (Join-Path $folder '000-engine.ps1') + '" ' + $tail
        )
    }
    else {
        $psi.FileName = $env:ComSpec
        $command = 'call 000-run-all.bat'

        if ($tail.Length -gt 0) {
            $command += ' ' + $tail
        }

        $psi.Arguments = '/D /C "' + $command + '"'
    }

    $psi.WorkingDirectory = $folder
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true
    $psi.EnvironmentVariables['PHASE_LOG'] = 'AIJ_MODE_TEST'

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi

    try {
        if (-not $process.Start()) {
            throw 'TEST_INFRA_FAILURE: Child process did not start.'
        }

        $outputTask = $process.StandardOutput.ReadToEndAsync()
        $errorTask = $process.StandardError.ReadToEndAsync()

        if (-not $process.WaitForExit(60000)) {
            $process.Kill()
            $process.WaitForExit()
            throw 'TEST_INFRA_FAILURE: Child process timed out.'
        }

        return [pscustomobject]@{
            ExitCode = $process.ExitCode
            StdOut = $outputTask.Result
            StdErr = $errorTask.Result.Trim()
        }
    }
    finally {
        $process.Dispose()
    }
}

function Assert-Review {
    param(
        [string]$Label,
        $Result,
        [bool]$IsBat
    )

    if ($null -eq $Result -or
        $Result.ExitCode -ne 0 -or
        $Result.StdErr.Length -ne 0 -or
        -not $Result.StdOut.Contains('PHASE INVENTORY: VALIDATED') -or
        -not $Result.StdOut.Contains('PHASE 000 REVIEW: PASS') -or
        -not $Result.StdOut.Contains('RESULT: REVIEW_PASS')) {
        throw "ASSERTION_FAILURE: ${Label}: REVIEW did not pass correctly."
    }

    if ($IsBat -and
        -not $Result.StdOut.Contains('PHASE 000 EXIT CODE: 0')) {
        throw "ASSERTION_FAILURE: ${Label}: BAT exit mapping mismatch."
    }

    Assert-NoPhaseExecution

    $script:reviews++
    Write-Output "PASS: $Label"
}

function Assert-Blocked {
    param(
        [string]$Label,
        $Result,
        [string]$ExpectedError = ''
    )

    if ($null -eq $Result) {
        throw "ASSERTION_FAILURE: ${Label}: no process result."
    }

    if ($Result.ExitCode -ne 1) {
        throw "ASSERTION_FAILURE: ${Label}: expected exit 1, got $($Result.ExitCode)."
    }

    foreach ($forbidden in @(
        'RESULT: REVIEW_PASS',
        'RESULT: PLAN_DRAFT_BLOCKED',
        'PLAN_JSON_BEGIN',
        'PHASE INVENTORY: VALIDATED'
    )) {
        if ($Result.StdOut.Contains($forbidden)) {
            throw "ASSERTION_FAILURE: ${Label}: false success marker."
        }
    }

    if ($ExpectedError.Length -gt 0 -and
        $Result.StdErr -cne $ExpectedError) {
        throw (
            "ASSERTION_FAILURE: ${Label}: expected [$ExpectedError], " +
            "received [$($Result.StdErr)]."
        )
    }

    Assert-NoPhaseExecution

    $script:blocked++
    Write-Output "PASS: $Label"
}

function Assert-Guard {
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

    if ($actual -cne $Expected) {
        throw "TEST_GUARD_FAILURE: $Label."
    }

    $script:guards++
    Write-Output "PASS: GUARD_$Label"
}

if ([IO.Directory]::Exists($folder)) {
    throw 'TEST_SETUP_FAILURE: Fixture directory already exists.'
}

[void][IO.Directory]::CreateDirectory($folder)

try {
    # Isolated installer copy

    $fixedNames = @(
        '000-run-all.bat',
        '000-engine.ps1',
        '000-review.ps1',
        '000-config.ps1',
        '000-dependencies.ps1',
        '000-manifest.ps1',
        '_common.bat'
    )

    $files = @(
        Get-ChildItem -LiteralPath $source -File |
            Where-Object {
                $_.Name -cmatch '^[0-9]{3}-.+\.bat$' -or
                $_.Name -cmatch '^[0-9]{3}-requirements\.json$' -or
                $_.Name -cin $fixedNames
            }
    )

    if ($files.Count -ne 30) {
        throw "TEST_SETUP_FAILURE: Expected 30 source files; found $($files.Count)."
    }

    foreach ($file in $files) {
        [IO.File]::Copy(
            $file.FullName,
            (Join-Path $folder $file.Name)
        )
    }

    # Synthetic configuration

    $config = @(
        '# Mode test configuration',
        'TARGET_DRIVE=E:',
        'DISTRO=AIJail',
        'BASE_DISTRO=Ubuntu',
        'LINUX_USER=aijail',
        'MIN_WSL_VERSION=2.10.0',
        'MIN_FREE_GB=20',
        'ALLOW_HOSTS_OPENCODE=',
        'ALLOW_HOSTS_COMFYUI=',
        'ALLOW_HOSTS_INSTALL=',
        'INSTALL_COMFYUI=0',
        'INSTALL_OPENCODE=1',
        'INSTALL_VSCODE=0',
        'ENABLE_NONO=0'
    ) -join "`r`n"

    [IO.File]::WriteAllText(
        (Join-Path $folder 'config.env'),
        ($config + "`r`n"),
        $utf8
    )

    # Replace every discoverable installation BAT with a marker

    $phases = @(
        Get-ChildItem -LiteralPath $folder -Filter '*.bat' -File |
            Where-Object {
                $_.Name -cmatch '^[0-9]{3}-.+\.bat$' -and
                $_.Name -cnotmatch '^(000|999)-'
            }
    )

    if ($phases.Count -ne 11) {
        throw 'TEST_SETUP_FAILURE: Mock phase count mismatch.'
    }

    $mock = "@echo off`r`n" +
        'echo EXECUTED>"%~dp0phase-executed.marker"' +
        "`r`nexit /b 1`r`n"

    foreach ($phase in $phases) {
        [IO.File]::WriteAllText($phase.FullName, $mock, $utf8)
    }

    # Positive REVIEW controls

    Assert-Review `
        -Label 'ENGINE_DEFAULT_REVIEW' `
        -Result (Invoke-TestEntry -Kind ENGINE) `
        -IsBat $false

    Assert-Review `
        -Label 'ENGINE_EXPLICIT_REVIEW' `
        -Result (Invoke-TestEntry -Kind ENGINE -Tokens @('/review')) `
        -IsBat $false

    Assert-Review `
        -Label 'BAT_EXPLICIT_REVIEW' `
        -Result (Invoke-TestEntry -Kind BAT -Tokens @('/review')) `
        -IsBat $true

    # Disabled and invalid modes

    $cases = @(
        @{
            Label = 'ENGINE_APPLY_BLOCKED'
            Kind = 'ENGINE'
            Tokens = @('/apply')
            Error = 'PHASE 000 ENGINE FAILED: Mode APPLY is not implemented; no operation executed.'
        },
        @{
            Label = 'BAT_APPLY_BLOCKED'
            Kind = 'BAT'
            Tokens = @('/apply')
            Error = ''
        },
        @{
            Label = 'ENGINE_VERIFY_BLOCKED'
            Kind = 'ENGINE'
            Tokens = @('/verify')
            Error = 'PHASE 000 ENGINE FAILED: Mode VERIFY is not implemented; no operation executed.'
        },
        @{
            Label = 'BAT_VERIFY_BLOCKED'
            Kind = 'BAT'
            Tokens = @('/verify')
            Error = ''
        },
        @{
            Label = 'ENGINE_RESUME_BLOCKED'
            Kind = 'ENGINE'
            Tokens = @('/review', '/from', '030')
            Error = 'PHASE 000 ENGINE FAILED: Resume and skip are blocked until dependency validation is implemented.'
        },
        @{
            Label = 'ENGINE_SKIP_BLOCKED'
            Kind = 'ENGINE'
            Tokens = @('/review', '/skip', '050')
            Error = 'PHASE 000 ENGINE FAILED: Resume and skip are blocked until dependency validation is implemented.'
        },
        @{
            Label = 'BAT_RESUME_BLOCKED'
            Kind = 'BAT'
            Tokens = @('/from', '030')
            Error = ''
        },
        @{
            Label = 'BAT_SKIP_BLOCKED'
            Kind = 'BAT'
            Tokens = @('/skip', '050')
            Error = ''
        },
        @{
            Label = 'DUPLICATE_MODE_BLOCKED'
            Kind = 'ENGINE'
            Tokens = @('/review', '/apply')
            Error = 'PHASE 000 ENGINE FAILED: Conflicting or repeated execution mode.'
        },
        @{
            Label = 'UNKNOWN_ARGUMENT_BLOCKED'
            Kind = 'ENGINE'
            Tokens = @('/bogus')
            Error = 'PHASE 000 ENGINE FAILED: Unsupported argument: /bogus'
        }
    )

    foreach ($case in $cases) {
        $result = Invoke-TestEntry `
            -Kind $case.Kind `
            -Tokens $case.Tokens

        Assert-Blocked `
            -Label $case.Label `
            -Result $result `
            -ExpectedError $case.Error
    }

    # Assertion integrity

    Assert-Guard `
        -Label 'UNEXPECTED_ACCEPTANCE' `
        -Probe {
            Assert-Blocked -Label 'GUARD_ACCEPT' -Result (
                [pscustomobject]@{
                    ExitCode = 0
                    StdOut = ''
                    StdErr = ''
                }
            )
        } `
        -Expected 'ASSERTION_FAILURE: GUARD_ACCEPT: expected exit 1, got 0.'

    Assert-Guard `
        -Label 'FALSE_SUCCESS_MARKER' `
        -Probe {
            Assert-Blocked -Label 'GUARD_SUCCESS' -Result (
                [pscustomobject]@{
                    ExitCode = 1
                    StdOut = 'RESULT: REVIEW_PASS'
                    StdErr = ''
                }
            )
        } `
        -Expected 'ASSERTION_FAILURE: GUARD_SUCCESS: false success marker.'

    Assert-Guard `
        -Label 'UNRELATED_DIAGNOSTIC' `
        -Probe {
            Assert-Blocked `
                -Label 'GUARD_ERROR' `
                -Result (
                    [pscustomobject]@{
                        ExitCode = 1
                        StdOut = ''
                        StdErr = 'UNRELATED'
                    }
                ) `
                -ExpectedError 'EXPECTED'
        } `
        -Expected 'ASSERTION_FAILURE: GUARD_ERROR: expected [EXPECTED], received [UNRELATED].'

    Assert-Guard `
        -Label 'SKIPPED_OPERATION' `
        -Probe {
            Assert-Blocked -Label 'GUARD_SKIP' -Result $null
        } `
        -Expected 'ASSERTION_FAILURE: GUARD_SKIP: no process result.'

    Assert-NoPhaseExecution

    if ($script:reviews -ne 3 -or
        $script:blocked -ne 10 -or
        $script:guards -ne 4) {
        throw 'TEST_COUNT_FAILURE: Required checks incomplete.'
    }

    Write-Output 'ENGINE_MODE_REGRESSIONS_OK reviews=3 blocked=10 guard=4'
}
finally {
    if ([IO.Directory]::Exists($folder)) {
        foreach ($child in @(
            Get-ChildItem -LiteralPath $folder -Force
        )) {
            if ($child.PSIsContainer) {
                throw 'TEST_CLEANUP_FAILURE: Unexpected subdirectory.'
            }

            [IO.File]::Delete($child.FullName)
        }

        [IO.Directory]::Delete($folder)
    }
}
