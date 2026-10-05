
# ============================================================
# AI Jail - Phase 000 configuration validation regressions
# Windows PowerShell 5.1 compatible.
#
# Tests the production Read-AijConfig boundary.
# Uses isolated temporary fixtures only.
# No installation, WSL, network or provider operations.
# ============================================================

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

$libraryPath = Join-Path $PSScriptRoot '000-config.ps1'

if (-not [System.IO.File]::Exists($libraryPath)) {
    throw 'TEST_SETUP_FAILURE: 000-config.ps1 is missing.'
}

. $libraryPath

$null = Get-Command Read-AijConfig -CommandType Function -ErrorAction Stop

if ($ErrorActionPreference -ne 'Stop') {
    throw 'TEST_SETUP_FAILURE: Library changed error preferences.'
}

$script:utf8 = New-Object System.Text.UTF8Encoding($false, $true)

$script:ownedFixtures = New-Object 'System.Collections.Generic.List[string]'

$script:positiveCount = 0
$script:negativeCount = 0
$script:guardCount = 0

# This baseline is independent of the user's real config.env.
# Every negative fixture starts from these known-valid values.

[string[]]$script:baselineLines = @(
    '# Phase 000 regression baseline',
    'TARGET_DRIVE=E:',
    'DISTRO=AIJail',
    'BASE_DISTRO=Ubuntu',
    'LINUX_USER=aijail',
    'MIN_WSL_VERSION=2.10.0',
    'MIN_FREE_GB=20',
    'ALLOW_HOSTS_OPENCODE=example.com;api.example.com',
    'ALLOW_HOSTS_COMFYUI=',
    'ALLOW_HOSTS_INSTALL=updates.example.com',
    'INSTALL_COMFYUI=0',
    'INSTALL_OPENCODE=1',
    'INSTALL_VSCODE=0',
    'ENABLE_NONO=1'
)

function New-AijTestFixture {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Lines
    )

    $path = [System.IO.Path]::GetTempFileName()

    $script:ownedFixtures.Add($path)

    $content = [string]::Join(
        "`r`n",
        [string[]]$Lines
    ) + "`r`n"

    [System.IO.File]::WriteAllBytes(
        $path,
        $script:utf8.GetBytes($content)
    )

    return $path
}

function New-AijModifiedFixture {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Key,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Value
    )

    [string[]]$lines = @($script:baselineLines)

    $found = 0
    $prefix = $Key + '='

    for ($i = 0; $i -lt $lines.Length; $i++) {

        if ($lines[$i].StartsWith(
            $prefix,
            [System.StringComparison]::Ordinal
        )) {
            $lines[$i] = $prefix + $Value
            $found++
        }
    }

    if ($found -ne 1) {
        throw "TEST_SETUP_FAILURE: Expected exactly one baseline key: $Key."
    }

    return New-AijTestFixture -Lines $lines
}

function Assert-AijValidFixture {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,

        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$ExpectedDistro,

        [Parameter(Mandatory = $true)]
        [string]$ExpectedBaseDistro,

        [switch]$EmptyAllowlists
    )

    # Exercise the real file-reading and validation boundary.

    $actual = Read-AijConfig -Path $Path

    if ($null -eq $actual -or $actual.Count -ne 13) {
        throw "VALID_FIXTURE_FAILURE: $Label returned an invalid key count."
    }

    if ($actual['TARGET_DRIVE'] -cne 'E:') {
        throw "VALID_FIXTURE_FAILURE: $Label changed TARGET_DRIVE."
    }

    if ($actual['DISTRO'] -cne $ExpectedDistro) {
        throw "VALID_FIXTURE_FAILURE: $Label changed DISTRO."
    }

    if ($actual['BASE_DISTRO'] -cne $ExpectedBaseDistro) {
        throw "VALID_FIXTURE_FAILURE: $Label changed BASE_DISTRO."
    }

    if ($EmptyAllowlists) {

        foreach ($key in @(
            'ALLOW_HOSTS_OPENCODE',
            'ALLOW_HOSTS_COMFYUI',
            'ALLOW_HOSTS_INSTALL'
        )) {
            if ($actual[$key] -cne '') {
                throw "VALID_FIXTURE_FAILURE: $Label did not preserve empty $key."
            }
        }
    }
    else {
        if ($actual['ALLOW_HOSTS_OPENCODE'] -cne 'example.com;api.example.com') {
            throw "VALID_FIXTURE_FAILURE: $Label changed a valid host allowlist."
        }

        if ($actual['ALLOW_HOSTS_COMFYUI'] -cne '') {
            throw "VALID_FIXTURE_FAILURE: $Label changed the empty ComfyUI allowlist."
        }

        if ($actual['ALLOW_HOSTS_INSTALL'] -cne 'updates.example.com') {
            throw "VALID_FIXTURE_FAILURE: $Label changed the install allowlist."
        }
    }

    $script:positiveCount++

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
        [string]$ExpectedMessage
    )

    $caught = $null

    try {
        $null = & $Operation
    }
    catch {
        $caught = $_
    }

    if ($null -eq $caught) {
        throw (
            'ASSERTION_FAILURE: {0}: input accepted or operation did not execute.' -f
            $Label
        )
    }

    $actualMessage = $caught.Exception.Message

    if ($actualMessage -cne $ExpectedMessage) {
        throw (
            'ASSERTION_FAILURE: {0}: expected [{1}], got [{2}].' -f
            $Label,
            $ExpectedMessage,
            $actualMessage
        )
    }

    Write-Output "PASS: $Label"
}

function Assert-AijInvalidFixture {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,

        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$ExpectedMessage
    )

    # The operation invokes the actual production parser.
    # An arbitrary exception does not satisfy the assertion.

    Assert-AijExpectedRejection `
        -Label $Label `
        -Operation { Read-AijConfig -Path $Path } `
        -ExpectedMessage $ExpectedMessage

    $script:negativeCount++
}

function Assert-AijGuardFailure {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,

        [Parameter(Mandatory = $true)]
        [scriptblock]$Probe,

        [Parameter(Mandatory = $true)]
        [string]$ExpectedFailure
    )

    $caught = $null

    try {
        $null = & $Probe
    }
    catch {
        $caught = $_
    }

    if ($null -eq $caught) {
        throw "TEST_GUARD_FAILURE: $Label failed to detect defective behaviour."
    }

    if ($caught.Exception.Message -cne $ExpectedFailure) {
        throw (
            'TEST_GUARD_FAILURE: {0}: expected [{1}], got [{2}].' -f
            $Label,
            $ExpectedFailure,
            $caught.Exception.Message
        )
    }

    $script:guardCount++

    Write-Output "PASS: GUARD_$Label"
}

try {

    # ========================================================
    # POSITIVE CONTROL
    # Establish that a known-valid file can actually be read.
    # ========================================================

    $baselinePath = New-AijTestFixture -Lines $script:baselineLines

    Assert-AijValidFixture `
        -Label 'KNOWN_VALID_BASELINE' `
        -Path $baselinePath `
        -ExpectedDistro 'AIJail' `
        -ExpectedBaseDistro 'Ubuntu'


    # ========================================================
    # ASSERTION-INTEGRITY CONTROLS
    # All deliberately incorrect operations must fail.
    # ========================================================

    Assert-AijGuardFailure `
        -Label 'INVALID_INPUT_ACCEPTED' `
        -Probe {
            Assert-AijExpectedRejection `
                -Label 'CONTROL_ACCEPT' `
                -Operation { 'accepted' } `
                -ExpectedMessage 'EXPECTED_REJECTION'
        } `
        -ExpectedFailure 'ASSERTION_FAILURE: CONTROL_ACCEPT: input accepted or operation did not execute.'


    Assert-AijGuardFailure `
        -Label 'UNRELATED_EXCEPTION' `
        -Probe {
            Assert-AijExpectedRejection `
                -Label 'CONTROL_WRONG' `
                -Operation { throw 'UNRELATED_SENTINEL' } `
                -ExpectedMessage 'EXPECTED_REJECTION'
        } `
        -ExpectedFailure 'ASSERTION_FAILURE: CONTROL_WRONG: expected [EXPECTED_REJECTION], got [UNRELATED_SENTINEL].'


    Assert-AijGuardFailure `
        -Label 'OPERATION_NOT_EXECUTED' `
        -Probe {
            Assert-AijExpectedRejection `
                -Label 'CONTROL_SKIP' `
                -Operation { } `
                -ExpectedMessage 'EXPECTED_REJECTION'
        } `
        -ExpectedFailure 'ASSERTION_FAILURE: CONTROL_SKIP: input accepted or operation did not execute.'


    # ========================================================
    # POSITIVE REGRESSIONS
    # ========================================================

    # All three empty allowlists must be valid and preserved.

    [string[]]$emptyLines = @($script:baselineLines)

    foreach ($key in @(
        'ALLOW_HOSTS_OPENCODE',
        'ALLOW_HOSTS_COMFYUI',
        'ALLOW_HOSTS_INSTALL'
    )) {
        $prefix = $key + '='
        $matchesFound = 0

        for ($i = 0; $i -lt $emptyLines.Length; $i++) {

            if ($emptyLines[$i].StartsWith(
                $prefix,
                [System.StringComparison]::Ordinal
            )) {
                $emptyLines[$i] = $prefix
                $matchesFound++
            }
        }

        if ($matchesFound -ne 1) {
            throw "TEST_SETUP_FAILURE: Missing allowlist key: $key."
        }
    }

    $emptyPath = New-AijTestFixture -Lines $emptyLines

    Assert-AijValidFixture `
        -Label 'ALL_EMPTY_ALLOWLISTS' `
        -Path $emptyPath `
        -ExpectedDistro 'AIJail' `
        -ExpectedBaseDistro 'Ubuntu' `
        -EmptyAllowlists


    # COM10 and LPT10 are not COM1-9 or LPT1-9.

    [string[]]$nonReservedLines = @($script:baselineLines)

    for ($i = 0; $i -lt $nonReservedLines.Length; $i++) {

        if ($nonReservedLines[$i].StartsWith(
            'DISTRO=',
            [System.StringComparison]::Ordinal
        )) {
            $nonReservedLines[$i] = 'DISTRO=COM10.log'
        }

        if ($nonReservedLines[$i].StartsWith(
            'BASE_DISTRO=',
            [System.StringComparison]::Ordinal
        )) {
            $nonReservedLines[$i] = 'BASE_DISTRO=LPT10.backup'
        }
    }

    $nonReservedPath = New-AijTestFixture -Lines $nonReservedLines

    Assert-AijValidFixture `
        -Label 'NON_RESERVED_DEVICE_NAMES' `
        -Path $nonReservedPath `
        -ExpectedDistro 'COM10.log' `
        -ExpectedBaseDistro 'LPT10.backup'


    # ========================================================
    # UNKNOWN AND DUPLICATE KEYS
    # ========================================================

    $unknownPath = New-AijTestFixture -Lines (
        $script:baselineLines + @('UNKNOWN_KEY=1')
    )

    Assert-AijInvalidFixture `
        -Label 'UNKNOWN_KEY' `
        -Path $unknownPath `
        -ExpectedMessage (
            'Unknown configuration key at line {0}.' -f
            ($script:baselineLines.Count + 1)
        )


    $duplicatePath = New-AijTestFixture -Lines (
        $script:baselineLines + @('TARGET_DRIVE=F:')
    )

    Assert-AijInvalidFixture `
        -Label 'DUPLICATE_KEY' `
        -Path $duplicatePath `
        -ExpectedMessage 'Duplicate configuration key: TARGET_DRIVE.'


    # ========================================================
    # RESERVED WINDOWS DEVICE NAMES
    #
    # Validate both destination-facing distribution identifiers.
    # ========================================================

    $reservedNames = @(
        'CON',
        'CON.txt',
        'NUL.backup',
        'COM1.log',
        'PRN.doc',
        'AUX.data',
        'LPT9.cfg',
        'con.txt',
        'COM9',
        'LPT1'
    )

    foreach ($key in @('DISTRO', 'BASE_DISTRO')) {

        foreach ($name in $reservedNames) {

            $path = New-AijModifiedFixture `
                -Key $key `
                -Value $name

            Assert-AijInvalidFixture `
                -Label ("RESERVED_{0}_{1}" -f $key, $name) `
                -Path $path `
                -ExpectedMessage "Unsafe distribution identifier: $key."
        }
    }


    # ========================================================
    # TRAVERSAL, ABSOLUTE PATHS AND SEPARATORS
    # ========================================================

    $unsafeNames = @(
        '../escape',
        'C:\escape',
        'dir/child',
        'good..bad',
        '\absolute'
    )

    foreach ($key in @('DISTRO', 'BASE_DISTRO')) {

        foreach ($name in $unsafeNames) {

            $path = New-AijModifiedFixture `
                -Key $key `
                -Value $name

            Assert-AijInvalidFixture `
                -Label ("UNSAFE_PATH_{0}_{1}" -f $key, $name) `
                -Path $path `
                -ExpectedMessage "Unsafe distribution identifier: $key."
        }
    }


    # ========================================================
    # TYPED CONFIGURATION VALUES
    # ========================================================

    $path = New-AijModifiedFixture `
        -Key 'TARGET_DRIVE' `
        -Value 'E:\'

    Assert-AijInvalidFixture `
        -Label 'TARGET_DRIVE_PATH_INJECTION' `
        -Path $path `
        -ExpectedMessage 'TARGET_DRIVE must be a single Windows drive designator.'


    $path = New-AijModifiedFixture `
        -Key 'LINUX_USER' `
        -Value 'root'

    Assert-AijInvalidFixture `
        -Label 'ROOT_LINUX_USER' `
        -Path $path `
        -ExpectedMessage 'Unsafe LINUX_USER.'


    $path = New-AijModifiedFixture `
        -Key 'MIN_WSL_VERSION' `
        -Value '2.10'

    Assert-AijInvalidFixture `
        -Label 'INVALID_VERSION_FORMAT' `
        -Path $path `
        -ExpectedMessage 'Invalid version format.'


    $path = New-AijModifiedFixture `
        -Key 'MIN_FREE_GB' `
        -Value '0'

    Assert-AijInvalidFixture `
        -Label 'ZERO_MIN_FREE_GB' `
        -Path $path `
        -ExpectedMessage 'MIN_FREE_GB must be greater than zero.'


    $path = New-AijModifiedFixture `
        -Key 'MIN_FREE_GB' `
        -Value '2147483648'

    Assert-AijInvalidFixture `
        -Label 'OVERFLOW_MIN_FREE_GB' `
        -Path $path `
        -ExpectedMessage 'MIN_FREE_GB is outside the supported numeric range.'


    $path = New-AijModifiedFixture `
        -Key 'INSTALL_OPENCODE' `
        -Value 'true'

    Assert-AijInvalidFixture `
        -Label 'INVALID_BOOLEAN_FLAG' `
        -Path $path `
        -ExpectedMessage 'Invalid boolean configuration value: INSTALL_OPENCODE.'


    # ========================================================
    # HOSTNAME ALLOWLIST VALIDATION
    # ========================================================

    $path = New-AijModifiedFixture `
        -Key 'ALLOW_HOSTS_INSTALL' `
        -Value 'https://example.com'

    Assert-AijInvalidFixture `
        -Label 'ALLOWLIST_URL_REJECTED' `
        -Path $path `
        -ExpectedMessage 'Invalid hostname in ALLOW_HOSTS_INSTALL.'


    $path = New-AijModifiedFixture `
        -Key 'ALLOW_HOSTS_INSTALL' `
        -Value '*.example.com'

    Assert-AijInvalidFixture `
        -Label 'ALLOWLIST_WILDCARD_REJECTED' `
        -Path $path `
        -ExpectedMessage 'Invalid hostname in ALLOW_HOSTS_INSTALL.'


    $path = New-AijModifiedFixture `
        -Key 'ALLOW_HOSTS_INSTALL' `
        -Value '192.0.2.1'

    Assert-AijInvalidFixture `
        -Label 'ALLOWLIST_IP_REJECTED' `
        -Path $path `
        -ExpectedMessage 'IP addresses are not permitted in ALLOW_HOSTS_INSTALL.'


    $path = New-AijModifiedFixture `
        -Key 'ALLOW_HOSTS_INSTALL' `
        -Value 'example.com;EXAMPLE.COM'

    Assert-AijInvalidFixture `
        -Label 'ALLOWLIST_DUPLICATE_HOST_REJECTED' `
        -Path $path `
        -ExpectedMessage 'Duplicate hostname in ALLOW_HOSTS_INSTALL.'


    # ========================================================
    # MALFORMED, MISSING AND WHITESPACE CASES
    # ========================================================

    $path = New-AijTestFixture -Lines (
        $script:baselineLines + @('BROKENLINE')
    )

    Assert-AijInvalidFixture `
        -Label 'MALFORMED_ASSIGNMENT' `
        -Path $path `
        -ExpectedMessage (
            'Malformed configuration assignment at line {0}.' -f
            ($script:baselineLines.Count + 1)
        )


    [string[]]$missingLines = @(
        $script:baselineLines | Where-Object {
            -not $_.StartsWith(
                'BASE_DISTRO=',
                [System.StringComparison]::Ordinal
            )
        }
    )

    if ($missingLines.Count -ne ($script:baselineLines.Count - 1)) {
        throw 'TEST_SETUP_FAILURE: Missing-key fixture was not constructed correctly.'
    }

    $path = New-AijTestFixture -Lines $missingLines

    Assert-AijInvalidFixture `
        -Label 'MISSING_REQUIRED_KEY' `
        -Path $path `
        -ExpectedMessage 'Missing configuration key: BASE_DISTRO.'


    $path = New-AijModifiedFixture `
        -Key 'DISTRO' `
        -Value ' AIJail'

    Assert-AijInvalidFixture `
        -Label 'UNEXPECTED_SURROUNDING_WHITESPACE' `
        -Path $path `
        -ExpectedMessage 'Unexpected surrounding whitespace at line 3.'


    # ========================================================
    # COMPLETENESS CHECK
    #
    # A partial run cannot print the final success marker.
    # ========================================================

    if ($script:positiveCount -ne 3) {
        throw (
            'TEST_COUNT_FAILURE: Expected 3 positive checks; got {0}.' -f
            $script:positiveCount
        )
    }

    if ($script:negativeCount -ne 45) {
        throw (
            'TEST_COUNT_FAILURE: Expected 45 negative checks; got {0}.' -f
            $script:negativeCount
        )
    }

    if ($script:guardCount -ne 3) {
        throw (
            'TEST_COUNT_FAILURE: Expected 3 assertion guards; got {0}.' -f
            $script:guardCount
        )
    }

    Write-Output (
        'VALIDATION_REGRESSIONS_OK positive={0} negative={1} guard={2}' -f
        $script:positiveCount,
        $script:negativeCount,
        $script:guardCount
    )
}
finally {

    # Delete only temporary fixtures created by this test.
    # Never touch config.env or the installation target.

    foreach ($ownedPath in $script:ownedFixtures) {

        if ([System.IO.File]::Exists($ownedPath)) {
            [System.IO.File]::Delete($ownedPath)
        }
    }
}
