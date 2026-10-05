# Phase 000 - Engine integration regressions
# Windows PowerShell 5.1

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

$sourceRoot = $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false, $true)
$owned = New-Object 'System.Collections.Generic.List[string]'

function New-AijEngineFixture {
    $folder = Join-Path ([IO.Path]::GetTempPath()) (
        'AIJ-ENGINE-' + [guid]::NewGuid().ToString('N')
    )

    [void][IO.Directory]::CreateDirectory($folder)
    $owned.Add($folder)

    Get-ChildItem -LiteralPath $sourceRoot -File |
        Where-Object {
            $_.Name -cmatch '^[0-9]{3}-.+\.bat$' -or
            $_.Name -cmatch '^[0-9]{3}-requirements\.json$' -or
            $_.Name -in @(
                '000-engine.ps1',
                '000-review.ps1',
                '000-config.ps1',
                '000-dependencies.ps1',
                '_common.bat',
                'config.env'
            )
        } |
        ForEach-Object {
            [IO.File]::Copy(
                $_.FullName,
                (Join-Path $folder $_.Name)
            )
        }

    return $folder
}

function Invoke-AijEngine {
    param(
        [string]$Folder
    )

    $engine = Join-Path $Folder '000-engine.ps1'

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = Join-Path $PSHOME 'powershell.exe'
    $psi.Arguments = (
        '-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' +
        $engine + '" /review'
    )
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi

    try {
        if (-not $process.Start()) {
            throw 'TEST_INFRA_FAILURE: Engine process did not start.'
        }

        $stdout = $process.StandardOutput.ReadToEnd()
        $stderr = $process.StandardError.ReadToEnd()

        if (-not $process.WaitForExit(30000)) {
            $process.Kill()
            $process.WaitForExit()
            throw 'TEST_INFRA_FAILURE: Engine process timed out.'
        }

        return [pscustomobject]@{
            ExitCode = $process.ExitCode
            StdOut = $stdout
            StdErr = $stderr.Trim()
        }
    }
    finally {
        $process.Dispose()
    }
}

function Assert-AijFailure {
    param(
        [string]$Label,
        $Result,
        [string]$Expected
    )

    if ($Result.ExitCode -ne 1) {
        throw "ASSERTION_FAILURE: ${Label}: exit code $($Result.ExitCode)."
    }

    if ($Result.StdErr -cne $Expected) {
        throw (
            "ASSERTION_FAILURE: ${Label}: expected [$Expected], " +
            "received [$($Result.StdErr)]."
        )
    }

    if ($Result.StdOut.Contains('RESULT: REVIEW_PASS')) {
        throw "ASSERTION_FAILURE: ${Label}: false REVIEW_PASS."
    }

    Write-Output "PASS: $Label"
}

try {
    # Positive control

    $folder = New-AijEngineFixture
    $result = Invoke-AijEngine -Folder $folder

    if ($result.ExitCode -ne 0 -or
        -not $result.StdOut.Contains('PHASE INVENTORY: VALIDATED') -or
        -not $result.StdOut.Contains('RESULT: REVIEW_PASS') -or
        $result.StdErr.Length -ne 0) {
        throw 'TEST_SETUP_FAILURE: Valid engine fixture failed.'
    }

    Write-Output 'PASS: VALID_ENGINE_BASELINE'

    # Unsafe dependency denial

    $folder = New-AijEngineFixture
    $path = Join-Path $folder '050-requirements.json'

    $doc = [IO.File]::ReadAllText($path, $utf8) |
        ConvertFrom-Json -ErrorAction Stop

    $doc.dependencies.accept_offline_policy_review_as_runtime_proof = $true

    [IO.File]::WriteAllText(
        $path,
        (ConvertTo-Json -InputObject $doc -Depth 60),
        $utf8
    )

    $result = Invoke-AijEngine -Folder $folder

    Assert-AijFailure `
        -Label 'UNSAFE_DEPENDENCY_BLOCKED_BEFORE_REVIEW_PASS' `
        -Result $result `
        -Expected 'PHASE 000 ENGINE FAILED: Unsafe dependency policy: 050-requirements.json.dependencies.accept_offline_policy_review_as_runtime_proof.'

    # Missing requirements

    $folder = New-AijEngineFixture

    [IO.File]::Delete(
        (Join-Path $folder '090-requirements.json')
    )

    $result = Invoke-AijEngine -Folder $folder

    Assert-AijFailure `
        -Label 'MISSING_REQUIREMENTS_BLOCKED' `
        -Result $result `
        -Expected 'PHASE 000 ENGINE FAILED: Required file missing: 090-requirements.json.'

    # Duplicate phase ID

    $folder = New-AijEngineFixture

    [IO.File]::Copy(
        (Join-Path $folder '090-setup-opencode.bat'),
        (Join-Path $folder '090-duplicate.bat')
    )

    $result = Invoke-AijEngine -Folder $folder

    Assert-AijFailure `
        -Label 'DUPLICATE_PHASE_BLOCKED' `
        -Result $result `
        -Expected 'PHASE 000 ENGINE FAILED: Duplicate installation phase ID: 090.'

    # Missing dependency library

    $folder = New-AijEngineFixture

    [IO.File]::Delete(
        (Join-Path $folder '000-dependencies.ps1')
    )

    $result = Invoke-AijEngine -Folder $folder

    Assert-AijFailure `
        -Label 'MISSING_DEPENDENCY_LIBRARY_BLOCKED' `
        -Result $result `
        -Expected 'PHASE 000 ENGINE FAILED: Required file missing: 000-dependencies.ps1'

    Write-Output 'ENGINE_FAIL_CLOSED_REGRESSIONS_OK'
}
finally {
    foreach ($folder in $owned) {
        if ([IO.Directory]::Exists($folder)) {
            [IO.Directory]::Delete($folder, $true)
        }
    }
}