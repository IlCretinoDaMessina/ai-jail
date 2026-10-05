
# Phase 000 - Discovery regressions
# Windows PowerShell 5.1

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

$sourceRoot = $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false, $true)
$ownedFolders = New-Object 'System.Collections.Generic.List[string]'

$script:positiveCount = 0
$script:negativeCount = 0
$script:guardCount = 0

$library = Join-Path $sourceRoot '000-dependencies.ps1'

if (-not [IO.File]::Exists($library)) {
    throw 'TEST_SETUP_FAILURE: Dependency library missing.'
}

. $library

$null = Get-Command Get-AijPhaseInventory -CommandType Function -ErrorAction Stop

function Assert-NoExecution {
    param([string]$Folder)

    if ([IO.File]::Exists((Join-Path $Folder 'phase-executed.marker'))) {
        throw 'ASSERTION_FAILURE: Discovered BAT was executed.'
    }
}

function New-AijFixture {
    $folder = Join-Path ([IO.Path]::GetTempPath()) (
        'AIJ-P000-DEP-' + [guid]::NewGuid().ToString('N')
    )

    if ([IO.Directory]::Exists($folder)) {
        throw 'TEST_SETUP_FAILURE: Fixture already exists.'
    }

    [void][IO.Directory]::CreateDirectory($folder)
    $ownedFolders.Add($folder)

    $files = @(
        Get-ChildItem -LiteralPath $sourceRoot -File |
            Where-Object {
                $_.Name -cmatch '^[0-9]{3}-.+\.bat$' -or
                $_.Name -cmatch '^[0-9]{3}-requirements\.json$'
            }
    )

    foreach ($file in $files) {
        [IO.File]::Copy(
            $file.FullName,
            (Join-Path $folder $file.Name)
        )
    }

    $mock = "@echo off`r`n" +
        'echo EXECUTED>"%~dp0phase-executed.marker"' +
        "`r`n"

    [IO.File]::WriteAllText(
        (Join-Path $folder '010-preflight.bat'),
        $mock,
        $utf8
    )

    # Positive control for every negative fixture.

    $inventory = @(Get-AijPhaseInventory -Root $folder)

    if ($inventory.Count -ne 11 -or
        ($inventory.Id -join ',') -cne
        '010,020,030,040,050,060,070,080,090,091,092') {
        throw 'TEST_SETUP_FAILURE: Temporary baseline invalid.'
    }

    Assert-NoExecution -Folder $folder

    return $folder
}

function Update-AijRequirement {
    param(
        [string]$Folder,
        [string]$Phase,
        [scriptblock]$Change
    )

    $path = Join-Path $Folder "$Phase-requirements.json"

    $document = [IO.File]::ReadAllText($path, $utf8) |
        ConvertFrom-Json -ErrorAction Stop

    $null = & $Change $document

    [IO.File]::WriteAllText(
        $path,
        (ConvertTo-Json -InputObject $document -Depth 60),
        $utf8
    )
}

function Assert-AijExpectedFailure {
    param(
        [string]$Label,
        [scriptblock]$Operation,
        [string]$Expected
    )

    $actual = $null

    try {
        $null = & $Operation
    }
    catch {
        $actual = $_.Exception.Message
    }

    if ($null -eq $actual) {
        throw "ASSERTION_FAILURE: ${Label}: accepted or not executed."
    }

    if ($actual -cne $Expected) {
        throw "ASSERTION_FAILURE: ${Label}: expected [$Expected], actual [$actual]."
    }

    Write-Output "PASS: $Label"
}

function Assert-AijGuard {
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
        throw "TEST_GUARD_FAILURE: $Label."
    }

    $script:guardCount++

    Write-Output "PASS: GUARD_$Label"
}

function Invoke-AijNegativeFixture {
    param(
        [string]$Label,
        [scriptblock]$Mutation,
        [string]$Expected
    )

    $folder = New-AijFixture

    $null = & $Mutation $folder

    Assert-AijExpectedFailure `
        -Label $Label `
        -Operation { Get-AijPhaseInventory -Root $folder } `
        -Expected $Expected

    Assert-NoExecution -Folder $folder

    $script:negativeCount++
}

try {
    $folder = New-AijFixture

    $script:positiveCount++

    Write-Output 'PASS: VALID_TEMPORARY_INVENTORY'
    Write-Output 'PASS: DISCOVERED_BAT_NOT_EXECUTED'

    # Assertion integrity

    Assert-AijGuard `
        -Label 'UNEXPECTED_ACCEPTANCE' `
        -Probe {
            Assert-AijExpectedFailure `
                -Label 'GUARD_ACCEPT' `
                -Operation { 'accepted' } `
                -Expected 'EXPECTED'
        } `
        -Expected 'ASSERTION_FAILURE: GUARD_ACCEPT: accepted or not executed.'

    Assert-AijGuard `
        -Label 'UNRELATED_EXCEPTION' `
        -Probe {
            Assert-AijExpectedFailure `
                -Label 'GUARD_WRONG' `
                -Operation { throw 'UNRELATED_SENTINEL' } `
                -Expected 'EXPECTED'
        } `
        -Expected 'ASSERTION_FAILURE: GUARD_WRONG: expected [EXPECTED], actual [UNRELATED_SENTINEL].'

    Assert-AijGuard `
        -Label 'OPERATION_NOT_EXECUTED' `
        -Probe {
            Assert-AijExpectedFailure `
                -Label 'GUARD_SKIP' `
                -Operation { } `
                -Expected 'EXPECTED'
        } `
        -Expected 'ASSERTION_FAILURE: GUARD_SKIP: accepted or not executed.'

    # Duplicate numeric ID

    Invoke-AijNegativeFixture `
        -Label 'DUPLICATE_PHASE_ID' `
        -Mutation {
            param($f)
            [IO.File]::Copy(
                (Join-Path $f '090-setup-opencode.bat'),
                (Join-Path $f '090-duplicate.bat')
            )
        } `
        -Expected 'Duplicate installation phase ID: 090.'

    # Missing prerequisite

    Invoke-AijNegativeFixture `
        -Label 'MISSING_PREREQUISITE' `
        -Mutation {
            param($f)
            [IO.File]::Delete(
                (Join-Path $f '060-base-toolchain.bat')
            )
        } `
        -Expected 'Missing prerequisite phase: 070 requires 060.'

    # Missing requirements file

    Invoke-AijNegativeFixture `
        -Label 'MISSING_REQUIREMENTS' `
        -Mutation {
            param($f)
            [IO.File]::Delete(
                (Join-Path $f '091-requirements.json')
            )
        } `
        -Expected 'Required file missing: 091-requirements.json.'

    # Unsupported schema

    Invoke-AijNegativeFixture `
        -Label 'UNSUPPORTED_SCHEMA' `
        -Mutation {
            param($f)
            Update-AijRequirement $f '090' {
                param($d)
                $d.schema = 2
            }
        } `
        -Expected 'Invalid integer contract: 090-requirements.json.schema.'

    # Incorrectly typed dependency

    Invoke-AijNegativeFixture `
        -Label 'INVALID_DEPENDENCY_TYPE' `
        -Mutation {
            param($f)
            Update-AijRequirement $f '090' {
                param($d)
                $d.dependencies.require_phase_060_toolchain_verified = 'true'
            }
        } `
        -Expected 'Invalid dependency flag: 090-requirements.json.require_phase_060_toolchain_verified.'

    # Undeclared prerequisite mapping

    Invoke-AijNegativeFixture `
        -Label 'UNKNOWN_PREREQUISITE' `
        -Mutation {
            param($f)
            Update-AijRequirement $f '090' {
                param($d)
                $d.dependencies | Add-Member `
                    -NotePropertyName 'require_phase_099_verified' `
                    -NotePropertyValue $true
            }
        } `
        -Expected 'Unrecognised prerequisite: 090-requirements.json.dependencies.require_phase_099_verified.'

    # Requirements identity

    Invoke-AijNegativeFixture `
        -Label 'PHASE_ID_MISMATCH' `
        -Mutation {
            param($f)
            Update-AijRequirement $f '090' {
                param($d)
                $d.phase = '091'
            }
        } `
        -Expected 'Requirements phase mismatch: 090-requirements.json.'

    # Unknown phase

    Invoke-AijNegativeFixture `
        -Label 'UNKNOWN_PHASE' `
        -Mutation {
            param($f)
            [IO.File]::WriteAllText(
                (Join-Path $f '093-unknown.bat'),
                "@echo off`r`n",
                $utf8
            )
        } `
        -Expected 'Unknown installation phase: 093.'

    # Invalid JSON

    Invoke-AijNegativeFixture `
        -Label 'MALFORMED_REQUIREMENTS_JSON' `
        -Mutation {
            param($f)
            [IO.File]::WriteAllText(
                (Join-Path $f '091-requirements.json'),
                '{"schema":',
                $utf8
            )
        } `
        -Expected 'Invalid requirements JSON: 091-requirements.json.'

    # Installation must remain disabled

    Invoke-AijNegativeFixture `
        -Label 'INSTALLATION_ENABLED_REJECTED' `
        -Mutation {
            param($f)
            Update-AijRequirement $f '090' {
                param($d)
                $d.installation.enabled = $true
            }
        } `
        -Expected 'Installation policy not disabled: 090-requirements.json.enabled.'

    # Unsupported execution mode

    Invoke-AijNegativeFixture `
        -Label 'UNSUPPORTED_MODE' `
        -Mutation {
            param($f)
            Update-AijRequirement $f '090' {
                param($d)
                $d.mode = 'APPLY'
            }
        } `
        -Expected 'Unsupported phase mode: 090-requirements.json.'

    # Invalid exit-code contract

    Invoke-AijNegativeFixture `
        -Label 'INVALID_EXIT_CODE' `
        -Mutation {
            param($f)
            Update-AijRequirement $f '090' {
                param($d)
                $d.exit_codes.success = 9
            }
        } `
        -Expected 'Invalid integer contract: 090-requirements.json.success.'

    # Completeness

    if ($script:positiveCount -ne 1 -or
        $script:negativeCount -ne 12 -or
        $script:guardCount -ne 3) {
        throw 'TEST_COUNT_FAILURE: Required checks incomplete.'
    }

    Write-Output 'DISCOVERY_REGRESSIONS_OK positive=1 negative=12 guard=3'
}
finally {
    foreach ($folder in $ownedFolders) {
        if ([IO.Directory]::Exists($folder)) {
            [IO.Directory]::Delete($folder, $true)
        }
    }
}
