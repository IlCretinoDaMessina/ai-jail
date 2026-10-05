
# ============================================================
# Phase 000 - Configuration encoding regression tests
# Windows PowerShell 5.1
#
# Tests the real Read-AijConfig file-reading boundary.
# Does not modify config.env or perform installation operations.
# ============================================================

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

$libraryPath = Join-Path $PSScriptRoot '000-config.ps1'

if (-not [System.IO.File]::Exists($libraryPath)) {
    throw 'TEST_SETUP_FAILURE: 000-config.ps1 is missing.'
}

. $libraryPath

$null = Get-Command Read-AijConfig -CommandType Function -ErrorAction Stop

$script:ownedFixtures = New-Object 'System.Collections.Generic.List[string]'

function New-AijEncodingFixture {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [byte[]]$Bytes
    )

    $path = [System.IO.Path]::GetTempFileName()

    $script:ownedFixtures.Add($path)

    [System.IO.File]::WriteAllBytes($path, $Bytes)

    return $path
}

function Assert-AijValidFixture {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    # Invoke the real production file-reading boundary.

    $parsed = Read-AijConfig -Path $Path

    if ($null -eq $parsed) {
        throw "VALID_FIXTURE_FAILURE: $Label returned no configuration."
    }

    if ($parsed.Count -ne 13) {
        throw "VALID_FIXTURE_FAILURE: $Label returned an incorrect key count."
    }

    if ($parsed['TARGET_DRIVE'] -cne 'E:') {
        throw "VALID_FIXTURE_FAILURE: $Label lost or changed TARGET_DRIVE."
    }

    if ($parsed['DISTRO'] -cne 'AIJail') {
        throw "VALID_FIXTURE_FAILURE: $Label changed DISTRO."
    }

    Write-Output "PASS: $Label"
}

function Assert-AijExpectedRejection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,

        [Parameter(Mandatory = $true)]
        [scriptblock]$Operation,

        [Parameter(Mandatory = $true)]
        [ValidateSet('ExactMessage', 'DecoderFallback')]
        [string]$ExpectedKind,

        [string]$ExpectedMessage = ''
    )

    $caught = $null

    try {
        $null = & $Operation
    }
    catch {
        $caught = $_
    }

    # An accepted invalid fixture, or an operation returning
    # without performing its required validation, cannot pass.

    if ($null -eq $caught) {
        throw "ASSERTION_FAILURE: $Label was accepted or did not execute."
    }

    if ($ExpectedKind -eq 'ExactMessage') {

        if ($caught.Exception.Message -cne $ExpectedMessage) {
            throw (
                "ASSERTION_FAILURE: $Label returned an unexpected error. " +
                "Expected: $ExpectedMessage; " +
                "Actual: $($caught.Exception.Message)"
            )
        }
    }
    elseif ($ExpectedKind -eq 'DecoderFallback') {

        # PowerShell 5.1 may wrap a .NET method exception.
        # Inspect the exception chain rather than depending on
        # a localized text message.

        $current = $caught.Exception
        $decoderFailureFound = $false

        while ($null -ne $current) {

            if ($current -is [System.Text.DecoderFallbackException]) {
                $decoderFailureFound = $true
                break
            }

            $current = $current.InnerException
        }

        if (-not $decoderFailureFound) {
            throw (
                "ASSERTION_FAILURE: $Label did not reject invalid UTF-8 " +
                "with DecoderFallbackException. Actual: " +
                $caught.Exception.ToString()
            )
        }
    }

    Write-Output "PASS: $Label"
}

function Assert-AijAssertionGuardFails {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,

        [Parameter(Mandatory = $true)]
        [scriptblock]$Probe
    )

    $caught = $null

    try {
        $null = & $Probe
    }
    catch {
        $caught = $_
    }

    if ($null -eq $caught) {
        throw "TEST_GUARD_FAILURE: $Label did not detect the faulty operation."
    }

    if (-not $caught.Exception.Message.StartsWith(
        'ASSERTION_FAILURE:',
        [System.StringComparison]::Ordinal
    )) {
        throw (
            "TEST_GUARD_FAILURE: $Label produced an unrelated exception: " +
            $caught.Exception.ToString()
        )
    }

    Write-Output "PASS: GUARD_$Label"
}

# ------------------------------------------------------------
# Known-valid synthetic configuration.
#
# The first line deliberately begins with '#', reproducing the
# condition that exposed the original BOM-detection defect.
# ------------------------------------------------------------

$validLines = @(
    '# =====================================================================',
    'TARGET_DRIVE=E:',
    'DISTRO=AIJail',
    'BASE_DISTRO=Ubuntu',
    'LINUX_USER=aijail',
    'MIN_WSL_VERSION=2.0.0',
    'MIN_FREE_GB=20',
    'ALLOW_HOSTS_OPENCODE=',
    'ALLOW_HOSTS_COMFYUI=',
    'ALLOW_HOSTS_INSTALL=',
    'INSTALL_COMFYUI=0',
    'INSTALL_OPENCODE=1',
    'INSTALL_VSCODE=0',
    'ENABLE_NONO=1'
)

$validText = [string]::Join(
    "`r`n",
    [string[]]$validLines
) + "`r`n"

$utf8 = New-Object System.Text.UTF8Encoding($false, $true)

[byte[]]$validBytes = $utf8.GetBytes($validText)
[byte[]]$bom = @(0xEF, 0xBB, 0xBF)

# ------------------------------------------------------------
# Test assertion integrity first.
#
# These isolated mock operations deliberately behave incorrectly.
# They never modify the production parser or installation.
# ------------------------------------------------------------

Assert-AijAssertionGuardFails -Label 'ACCEPTED_INVALID_INPUT' -Probe {

    Assert-AijExpectedRejection `
        -Label 'DELIBERATE_ACCEPTANCE' `
        -Operation { return 'accepted' } `
        -ExpectedKind 'ExactMessage' `
        -ExpectedMessage 'Unexpected Unicode BOM in configuration.'
}

Assert-AijAssertionGuardFails -Label 'UNRELATED_EXCEPTION' -Probe {

    Assert-AijExpectedRejection `
        -Label 'DELIBERATE_WRONG_EXCEPTION' `
        -Operation { throw 'UNRELATED_SENTINEL' } `
        -ExpectedKind 'ExactMessage' `
        -ExpectedMessage 'Unexpected Unicode BOM in configuration.'
}

Assert-AijAssertionGuardFails -Label 'OPERATION_NOT_EXECUTED' -Probe {

    Assert-AijExpectedRejection `
        -Label 'DELIBERATE_NO_OPERATION' `
        -Operation { } `
        -ExpectedKind 'ExactMessage' `
        -ExpectedMessage 'Unexpected Unicode BOM in configuration.'
}

# ------------------------------------------------------------
# Real file-reading regression cases.
# All encoding fixtures are written to temporary files.
# ------------------------------------------------------------

try {

    # Test 1: UTF-8 without BOM.
    # The opening '#' must not be removed.

    $noBomPath = New-AijEncodingFixture -Bytes $validBytes

    Assert-AijValidFixture `
        -Label 'UTF8_NO_BOM_FIRST_HASH_PRESERVED' `
        -Path $noBomPath


    # Test 2: UTF-8 with exactly one leading BOM.
    # The BOM must be removed without removing the following '#'.

    [byte[]]$singleBomBytes = $bom + $validBytes

    $singleBomPath = New-AijEncodingFixture -Bytes $singleBomBytes

    Assert-AijValidFixture `
        -Label 'UTF8_SINGLE_LEADING_BOM' `
        -Path $singleBomPath


    # Test 3: Two leading BOMs.
    # One leading BOM may be removed, but the remaining BOM
    # must trigger the specific Unicode BOM rejection.

    [byte[]]$repeatedBomBytes = $bom + $bom + $validBytes

    $repeatedBomPath = New-AijEncodingFixture -Bytes $repeatedBomBytes

    Assert-AijExpectedRejection `
        -Label 'REPEATED_BOM_REJECTED' `
        -Operation { Read-AijConfig -Path $repeatedBomPath } `
        -ExpectedKind 'ExactMessage' `
        -ExpectedMessage 'Unexpected Unicode BOM in configuration.'


    # Test 4: Embedded BOM.
    # Introduce U+FEFF inside a configuration value.
    # It must be rejected by the explicit remaining-BOM guard.

    $embeddedBomText = $validText.Replace(
        'BASE_DISTRO=Ubuntu',
        ('BASE_DISTRO=Ub' + [string][char]0xFEFF + 'untu')
    )

    [byte[]]$embeddedBomBytes = $utf8.GetBytes($embeddedBomText)

    $embeddedBomPath = New-AijEncodingFixture -Bytes $embeddedBomBytes

    Assert-AijExpectedRejection `
        -Label 'EMBEDDED_BOM_REJECTED' `
        -Operation { Read-AijConfig -Path $embeddedBomPath } `
        -ExpectedKind 'ExactMessage' `
        -ExpectedMessage 'Unexpected Unicode BOM in configuration.'


    # Test 5: Malformed UTF-8.
    # C3 28 is an invalid two-byte UTF-8 sequence.
    # An unrelated parser error is not accepted as success.

    [byte[]]$malformedBytes = $validBytes + [byte[]]@(0xC3, 0x28)

    $malformedPath = New-AijEncodingFixture -Bytes $malformedBytes

    Assert-AijExpectedRejection `
        -Label 'MALFORMED_UTF8_REJECTED' `
        -Operation { Read-AijConfig -Path $malformedPath } `
        -ExpectedKind 'DecoderFallback'


    # Test 6: Preserve the first character of an assignment.
    # This configuration starts directly with TARGET_DRIVE=E:.
    #
    # If 'T' were removed, the parser would see ARGET_DRIVE,
    # producing an unknown-key rejection instead of success.

    $assignmentLines = $validLines[1..($validLines.Count - 1)]

    $assignmentFirstText = [string]::Join(
        "`r`n",
        [string[]]$assignmentLines
    ) + "`r`n"

    [byte[]]$assignmentFirstBytes = $utf8.GetBytes($assignmentFirstText)

    $assignmentFirstPath = New-AijEncodingFixture -Bytes $assignmentFirstBytes

    Assert-AijValidFixture `
        -Label 'FIRST_ASSIGNMENT_CHARACTER_PRESERVED' `
        -Path $assignmentFirstPath


    # Test 7: Read the actual configuration through the repaired
    # file-reading boundary.
    #
    # Read-only. Do not output configuration values.
    # Do not change config.env to obtain a PASS.

    $realConfigPath = Join-Path $PSScriptRoot 'config.env'

    $realConfig = Read-AijConfig -Path $realConfigPath

    if ($null -eq $realConfig -or $realConfig.Count -ne 13) {
        throw 'REAL_CONFIG_FAILURE: Expected 13 validated configuration keys.'
    }

    Write-Output 'PASS: REAL_CONFIG_READONLY'
}
finally {

    # Remove only the exact temporary files this test created.
    # No recursive deletion and no installation-target cleanup.

    foreach ($ownedPath in $script:ownedFixtures) {

        if ([System.IO.File]::Exists($ownedPath)) {
            [System.IO.File]::Delete($ownedPath)
        }
    }
}

# This message is reached only when every required assertion
# and temporary-fixture cleanup completed successfully.

Write-Output 'ENCODING_REGRESSIONS_OK'
