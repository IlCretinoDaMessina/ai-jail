# Phase 000 - PLAN snapshot regressions
# Windows PowerShell 5.1

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

$script:root = $PSScriptRoot
$script:utf8 = New-Object System.Text.UTF8Encoding($false, $true)
$script:owned = New-Object 'System.Collections.Generic.List[string]'
$script:positive = 0
$script:negative = 0
$script:guards = 0

$library = Join-Path $script:root '000-manifest.ps1'

if (-not [IO.File]::Exists($library)) {
    throw 'TEST_SETUP_FAILURE: Missing manifest library.'
}

. $library

$null = Get-Command New-AijPlanSnapshot -CommandType Function -ErrorAction Stop
$null = Get-Command Format-AijPlanSnapshot -CommandType Function -ErrorAction Stop

[string[]]$script:baseLines = @(
    '# Phase 000 test configuration',
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
)

$script:baseText = [string]::Join(
    "`r`n",
    $script:baseLines
) + "`r`n"

function Assert-NoExecution {
    param([string]$Folder)

    if ([IO.File]::Exists(
        (Join-Path $Folder 'phase-executed.marker')
    )) {
        throw 'ASSERTION_FAILURE: Discovered BAT executed.'
    }
}

function Assert-Blocked {
    param($Snapshot)

    $m = $Snapshot.Manifest

    if ($m.Kind -cne 'PHASE_000_PLAN_SNAPSHOT' -or
        $m.State -cne 'DRAFT_BLOCKED' -or
        $m.ExecutionAuthorized -ne $false -or
        $m.ApprovalRecorded -ne $false -or
        $m.ReadyForApproval -ne $false -or
        $null -ne $m.ArtifactLock -or
        @($m.SelectedActions).Count -ne 0) {
        throw 'ASSERTION_FAILURE: Unsafe snapshot state.'
    }

    if (@($m.PhaseCandidates).Count -ne 11 -or
        @($m.SourceFiles).Count -ne 33) {
        throw 'ASSERTION_FAILURE: Incomplete snapshot inventory.'
    }

    if ($Snapshot.Sha256 -cnotmatch '^[A-F0-9]{64}$' -or
        $m.ConfigurationSha256 -cnotmatch '^[A-F0-9]{64}$') {
        throw 'ASSERTION_FAILURE: Invalid snapshot identity.'
    }
}

function New-Fixture {
    $folder = Join-Path ([IO.Path]::GetTempPath()) (
        'AIJ-MANIFEST-' + [guid]::NewGuid().ToString('N')
    )

    if ([IO.Directory]::Exists($folder)) {
        throw 'TEST_SETUP_FAILURE: Fixture already exists.'
    }

    [void][IO.Directory]::CreateDirectory($folder)
    $script:owned.Add($folder)

    $names = @(
        '000-engine.ps1',
        '000-review.ps1',
        '000-config.ps1',
        '000-dependencies.ps1',
        '000-manifest.ps1',
        '000-state.ps1',
        '000-state-store.ps1',
        '_common.bat'
    )

    $files = @(
        Get-ChildItem -LiteralPath $script:root -File |
            Where-Object {
                $_.Name -cmatch '^[0-9]{3}-.+\.bat$' -or
                $_.Name -cmatch '^[0-9]{3}-requirements\.json$' -or
                $_.Name -cin $names
            }
    )

    if ($files.Count -ne 32) {
        throw "TEST_SETUP_FAILURE: Expected 32 source files; found $($files.Count)."
    }

    foreach ($file in $files) {
        [IO.File]::Copy(
            $file.FullName,
            (Join-Path $folder $file.Name)
        )
    }

    [IO.File]::WriteAllText(
        (Join-Path $folder 'config.env'),
        $script:baseText,
        $script:utf8
    )

    $mock = "@echo off`r`n" +
        'echo EXECUTED>"%~dp0phase-executed.marker"' +
        "`r`n"

    $mockPath = Join-Path $folder '010-preflight.bat'

    [IO.File]::WriteAllText(
        $mockPath,
        $mock,
        $script:utf8
    )

    $baseline = New-AijPlanSnapshot -Root $folder

    Assert-Blocked -Snapshot $baseline

    $record = @(
        $baseline.Manifest.SourceFiles |
            Where-Object { $_.Name -ceq '010-preflight.bat' }
    )

    if ($record.Count -ne 1 -or
        $record[0].Sha256 -cne (
            Get-FileHash `
                -LiteralPath $mockPath `
                -Algorithm SHA256
        ).Hash) {
        throw 'TEST_SETUP_FAILURE: Mock BAT was not correctly inventoried.'
    }

    Assert-NoExecution -Folder $folder

    return $folder
}

function Assert-Rejection {
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
        throw (
            "ASSERTION_FAILURE: ${Label}: expected [$Expected], " +
            "received [$actual]."
        )
    }

    Write-Output "PASS: $Label"
}

function Assert-InvalidFixture {
    param(
        [string]$Label,
        [string]$Folder,
        [string]$Expected
    )

    Assert-Rejection `
        -Label $Label `
        -Operation { New-AijPlanSnapshot -Root $Folder } `
        -Expected $Expected

    Assert-NoExecution -Folder $Folder

    $script:negative++
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

    if ($null -eq $actual -or
        $actual -cne $Expected) {
        throw "TEST_GUARD_FAILURE: $Label."
    }

    $script:guards++
    Write-Output "PASS: GUARD_$Label"
}

try {
    # Positive controls

    $folder = New-Fixture
    $first = New-AijPlanSnapshot -Root $folder

    Assert-Blocked -Snapshot $first

    $script:positive++
    Write-Output 'PASS: KNOWN_VALID_BLOCKED_SNAPSHOT'

    $second = New-AijPlanSnapshot -Root $folder

    if ($first.Json -cne $second.Json -or
        $first.Sha256 -cne $second.Sha256) {
        throw 'ASSERTION_FAILURE: Snapshot is not deterministic.'
    }

    $script:positive++
    Write-Output 'PASS: DETERMINISTIC_REPEATED_SNAPSHOT'

    $summary = @(Format-AijPlanSnapshot -Snapshot $first)

    foreach ($line in @(
        'PLAN SNAPSHOT: DRAFT_BLOCKED',
        'Selected actions: NONE',
        'Artifact lock: MISSING',
        'Approval: NOT RECORDED',
        'Execution: DISABLED'
    )) {
        if ($summary -cnotcontains $line) {
            throw "ASSERTION_FAILURE: Missing summary evidence: $line."
        }
    }

    $script:positive++
    Write-Output 'PASS: READABLE_BLOCKED_SUMMARY'

    Assert-NoExecution -Folder $folder

    $script:positive++
    Write-Output 'PASS: DISCOVERED_MOCK_BAT_NOT_EXECUTED'

    # Source fingerprint sensitivity

    $batPath = Join-Path $folder '010-preflight.bat'

    $beforeHash = @(
        $first.Manifest.SourceFiles |
            Where-Object { $_.Name -ceq '010-preflight.bat' }
    )[0].Sha256

    [IO.File]::AppendAllText(
        $batPath,
        "REM SOURCE_CHANGE`r`n",
        $script:utf8
    )

    $changedSource = New-AijPlanSnapshot -Root $folder

    Assert-Blocked -Snapshot $changedSource

    $afterHash = @(
        $changedSource.Manifest.SourceFiles |
            Where-Object { $_.Name -ceq '010-preflight.bat' }
    )[0].Sha256

    if ($beforeHash -ceq $afterHash -or
        $first.Sha256 -ceq $changedSource.Sha256) {
        throw 'ASSERTION_FAILURE: Source change did not invalidate snapshot identity.'
    }

    Assert-NoExecution -Folder $folder

    $script:positive++
    Write-Output 'PASS: SOURCE_CHANGE_INVALIDATES_SNAPSHOT'

    # Configuration fingerprint sensitivity

    $configPath = Join-Path $folder 'config.env'

    $newConfig = $script:baseText.Replace(
        'DISTRO=AIJail',
        'DISTRO=AIJailTest'
    )

    if ($newConfig -ceq $script:baseText) {
        throw 'TEST_SETUP_FAILURE: Configuration mutation failed.'
    }

    [IO.File]::WriteAllText(
        $configPath,
        $newConfig,
        $script:utf8
    )

    $changedConfig = New-AijPlanSnapshot -Root $folder

    Assert-Blocked -Snapshot $changedConfig

    if ($changedConfig.Manifest.ConfigurationSha256 -ceq
        $changedSource.Manifest.ConfigurationSha256 -or
        $changedConfig.Sha256 -ceq $changedSource.Sha256 -or
        $changedConfig.Manifest.ProposedTarget.Distro -cne
            'AIJailTest') {
        throw 'ASSERTION_FAILURE: Configuration change did not invalidate snapshot identity.'
    }

    Assert-NoExecution -Folder $folder

    $script:positive++
    Write-Output 'PASS: CONFIG_CHANGE_INVALIDATES_SNAPSHOT'

    # Assertion integrity

    Assert-Guard `
        -Label 'UNEXPECTED_ACCEPTANCE' `
        -Probe {
            Assert-Rejection `
                -Label 'CONTROL_ACCEPT' `
                -Operation { 'accepted' } `
                -Expected 'EXPECTED'
        } `
        -Expected 'ASSERTION_FAILURE: CONTROL_ACCEPT: accepted or not executed.'

    Assert-Guard `
        -Label 'UNRELATED_EXCEPTION' `
        -Probe {
            Assert-Rejection `
                -Label 'CONTROL_WRONG' `
                -Operation { throw 'UNRELATED_SENTINEL' } `
                -Expected 'EXPECTED'
        } `
        -Expected 'ASSERTION_FAILURE: CONTROL_WRONG: expected [EXPECTED], received [UNRELATED_SENTINEL].'

    Assert-Guard `
        -Label 'OPERATION_NOT_EXECUTED' `
        -Probe {
            Assert-Rejection `
                -Label 'CONTROL_SKIP' `
                -Operation { } `
                -Expected 'EXPECTED'
        } `
        -Expected 'ASSERTION_FAILURE: CONTROL_SKIP: accepted or not executed.'

    # Unknown configuration key

    $folder = New-Fixture

    [IO.File]::AppendAllText(
        (Join-Path $folder 'config.env'),
        "UNKNOWN_KEY=1`r`n",
        $script:utf8
    )

    Assert-InvalidFixture `
        -Label 'UNKNOWN_CONFIG_REJECTED' `
        -Folder $folder `
        -Expected 'Unknown configuration key at line 15.'

    # Unsafe dependency declaration

    $folder = New-Fixture
    $path = Join-Path $folder '050-requirements.json'

    $doc = [IO.File]::ReadAllText(
        $path,
        $script:utf8
    ) | ConvertFrom-Json -ErrorAction Stop

    $doc.dependencies.accept_offline_policy_review_as_runtime_proof = $true

    [IO.File]::WriteAllText(
        $path,
        (ConvertTo-Json -InputObject $doc -Depth 60),
        $script:utf8
    )

    Assert-InvalidFixture `
        -Label 'UNSAFE_DEPENDENCY_REJECTED' `
        -Folder $folder `
        -Expected 'Unsafe dependency policy: 050-requirements.json.dependencies.accept_offline_policy_review_as_runtime_proof.'

    # Missing manifest source

    $folder = New-Fixture

    [IO.File]::Delete(
        (Join-Path $folder '000-manifest.ps1')
    )

    Assert-InvalidFixture `
        -Label 'MISSING_MANIFEST_SOURCE_REJECTED' `
        -Folder $folder `
        -Expected 'Required file missing: 000-manifest.ps1.'

    # Approval policy cannot be disabled

    $folder = New-Fixture
    $path = Join-Path $folder '000-requirements.json'

    $doc = [IO.File]::ReadAllText(
        $path,
        $script:utf8
    ) | ConvertFrom-Json -ErrorAction Stop

    $doc.approvals.explicit_installation_approval = $false

    [IO.File]::WriteAllText(
        $path,
        (ConvertTo-Json -InputObject $doc -Depth 60),
        $script:utf8
    )

    Assert-InvalidFixture `
        -Label 'DISABLED_APPROVAL_REQUIREMENT_REJECTED' `
        -Folder $folder `
        -Expected 'Phase 000 planning policy mismatch.'

    if ($script:positive -ne 6 -or
        $script:negative -ne 4 -or
        $script:guards -ne 3) {
        throw 'TEST_COUNT_FAILURE: Required checks incomplete.'
    }
}
finally {
    foreach ($folder in $script:owned) {
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
}

Write-Output 'MANIFEST_REGRESSIONS_OK positive=6 negative=4 guard=3'