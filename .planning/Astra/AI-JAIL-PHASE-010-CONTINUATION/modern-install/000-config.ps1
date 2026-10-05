
# ============================================================
# AI Jail - Phase 000 authoritative configuration parser
# Windows PowerShell 5.1 compatible.
#
# This file defines functions only.
# Loading it does not execute installation operations.
#
# config.env contract:
# - UTF-8, with or without BOM.
# - LF or CRLF line endings.
# - Empty lines and full-line # comments are allowed.
# - Active entries must use KEY=VALUE.
# - No whitespace around keys or values.
# - No inline comments, quoting or environment expansion.
# - Empty allowlists are valid and mean deny all.
# - Unknown and duplicate keys are rejected.
# ============================================================

function ConvertTo-AijVersionParts {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    if ($Value -cnotmatch '^(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)(?:\.(?:0|[1-9][0-9]*))?$') {
        throw 'Invalid version format.'
    }

    $parts = $Value.Split('.')
    $numbers = New-Object 'System.Int32[]' 4

    for ($i = 0; $i -lt $parts.Length; $i++) {
        [int]$component = 0

        if (-not [int]::TryParse($parts[$i], [ref]$component)) {
            throw 'Invalid or out-of-range version component.'
        }

        $numbers[$i] = $component
    }

    return ,$numbers
}

function Compare-AijVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Actual,

        [Parameter(Mandatory = $true)]
        [string]$Minimum
    )

    $actualParts = ConvertTo-AijVersionParts -Value $Actual
    $minimumParts = ConvertTo-AijVersionParts -Value $Minimum

    for ($i = 0; $i -lt 4; $i++) {
        if ($actualParts[$i] -gt $minimumParts[$i]) {
            return 1
        }

        if ($actualParts[$i] -lt $minimumParts[$i]) {
            return -1
        }
    }

    return 0
}

function ConvertFrom-AijConfigText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Text
    )

    $allowedKeys = @(
        'TARGET_DRIVE',
        'DISTRO',
        'BASE_DISTRO',
        'LINUX_USER',
        'MIN_WSL_VERSION',
        'MIN_FREE_GB',
        'ALLOW_HOSTS_OPENCODE',
        'ALLOW_HOSTS_COMFYUI',
        'ALLOW_HOSTS_INSTALL',
        'INSTALL_COMFYUI',
        'INSTALL_OPENCODE',
        'INSTALL_VSCODE',
        'ENABLE_NONO'
    )

    $allowlistKeys = @(
        'ALLOW_HOSTS_OPENCODE',
        'ALLOW_HOSTS_COMFYUI',
        'ALLOW_HOSTS_INSTALL'
    )

    $flagKeys = @(
        'INSTALL_COMFYUI',
        'INSTALL_OPENCODE',
        'INSTALL_VSCODE',
        'ENABLE_NONO'
    )

    $values = @{}

    $normalized = $Text.Replace("`r`n", "`n")

    if ($normalized.Contains("`r")) {
        throw 'Unsupported line endings in config.env.'
    }

    $lines = $normalized.Split([char]10)

    for ($i = 0; $i -lt $lines.Length; $i++) {
        $line = $lines[$i]
        $lineNumber = $i + 1

        if ($line.Trim().Length -eq 0) {
            continue
        }

        if ($line.TrimStart().StartsWith('#')) {
            continue
        }

        if ($line -cnotmatch '^([A-Z][A-Z0-9_]*)=(.*)$') {
            throw "Malformed configuration assignment at line $lineNumber."
        }

        $key = $Matches[1]
        $value = $Matches[2]

        if ($allowedKeys -cnotcontains $key) {
            throw "Unknown configuration key at line $lineNumber."
        }

        if ($values.ContainsKey($key)) {
            throw "Duplicate configuration key: $key."
        }

        if ($value -cne $value.Trim()) {
            throw "Unexpected surrounding whitespace at line $lineNumber."
        }

        if ($value -match '[\x00-\x1F\x7F]') {
            throw "Control character in configuration at line $lineNumber."
        }

        $values[$key] = $value
    }

    # Every supported key is required.
    # Only network allowlists may contain an empty value.

    foreach ($key in $allowedKeys) {
        if (-not $values.ContainsKey($key)) {
            throw "Missing configuration key: $key."
        }

        if ($allowlistKeys -cnotcontains $key) {
            if ([string]::IsNullOrWhiteSpace($values[$key])) {
                throw "Empty required configuration value: $key."
            }
        }
    }

    # Target drive must be a drive designator, not an arbitrary path.

    if ($values['TARGET_DRIVE'] -cnotmatch '^[A-Za-z]:$') {
        throw 'TARGET_DRIVE must be a single Windows drive designator.'
    }

    # Distribution identifiers must not contain paths, traversal,
    # whitespace or shell characters.
    #
    # Windows device names are reserved even with extensions.
    # Examples:
    # CON, CON.txt, NUL.backup, COM1.log, LPT9.data.
    #
    # Check both DISTRO and BASE_DISTRO.
    # Match case-insensitively and reject only the actual reserved
    # device-name token, optionally followed by a period.
    #
    # COM10 and LPT10 are not in the Windows COM1-9/LPT1-9
    # reserved-name ranges.

    $reservedDevicePattern = '^(?i:(?:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9]))(?:\.|$)'

    foreach ($key in @('DISTRO', 'BASE_DISTRO')) {
        $name = $values[$key]

        if ($name.Length -gt 64 -or
            $name -cnotmatch '^[A-Za-z][A-Za-z0-9_.-]*$' -or
            $name.Contains('..') -or
            $name.EndsWith('.') -or
            $name.EndsWith('-') -or
            $name -match $reservedDevicePattern) {

            throw "Unsafe distribution identifier: $key."
        }
    }

    # A dedicated, non-root Linux user is required.

    if ($values['LINUX_USER'] -cnotmatch '^[a-z_][a-z0-9_-]{0,31}$' -or
        $values['LINUX_USER'] -ceq 'root') {

        throw 'Unsafe LINUX_USER.'
    }

    # The minimum WSL version is parsed numerically, not compared
    # lexicographically.

    $null = ConvertTo-AijVersionParts -Value $values['MIN_WSL_VERSION']

    # Disk requirement must be a positive Int32 value.

    if ($values['MIN_FREE_GB'] -cnotmatch '^(?:0|[1-9][0-9]*)$') {
        throw 'Invalid MIN_FREE_GB.'
    }

    [int]$minimumFree = 0

    if (-not [int]::TryParse(
        $values['MIN_FREE_GB'],
        [ref]$minimumFree
    )) {
        throw 'MIN_FREE_GB is outside the supported numeric range.'
    }

    if ($minimumFree -le 0) {
        throw 'MIN_FREE_GB must be greater than zero.'
    }

    # Boolean values are exactly 0 or 1.

    foreach ($key in $flagKeys) {
        if ($values[$key] -cnotin @('0', '1')) {
            throw "Invalid boolean configuration value: $key."
        }
    }

    # Validate semicolon-separated hostname allowlists.
    #
    # Empty list = deny all.
    # URLs, ports, wildcards, IP addresses, duplicate hosts and
    # shell expressions are not accepted.

    $hostPattern = '^(?=.{1,253}$)[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*$'

    foreach ($key in $allowlistKeys) {
        $raw = $values[$key]

        if ($raw.Length -eq 0) {
            continue
        }

        $hosts = $raw.Split(';')
        $seen = @{}

        foreach ($hostName in $hosts) {
            if ($hostName -cnotmatch $hostPattern) {
                throw "Invalid hostname in $key."
            }

            [System.Net.IPAddress]$parsedAddress = $null

            if ([System.Net.IPAddress]::TryParse(
                $hostName,
                [ref]$parsedAddress
            )) {
                throw "IP addresses are not permitted in $key."
            }

            if ($seen.ContainsKey($hostName)) {
                throw "Duplicate hostname in $key."
            }

            $seen[$hostName] = $true
        }
    }

    return $values
}

function Read-AijConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw 'Configuration file does not exist.'
    }

    $resolvedPath = (
        Resolve-Path -LiteralPath $Path -ErrorAction Stop
    ).ProviderPath

    # Strict UTF-8 decoding prevents locale-dependent parsing
    # differences between Windows PowerShell installations.

    $encoding = New-Object System.Text.UTF8Encoding($false, $true)

    [byte[]]$bytes = [System.IO.File]::ReadAllBytes($resolvedPath)

    $content = $encoding.GetString($bytes)

    # Accept one UTF-8 BOM at the beginning only.
    #
    # Ordinal comparison is required here. The culture-sensitive
    # StartsWith(string) overload can incorrectly report a match for
    # U+FEFF when the decoded text begins with another character.

    if ($content.StartsWith(
        [string][char]0xFEFF,
        [System.StringComparison]::Ordinal
    )) {
        $content = $content.Substring(1)
    }

    # Reject every remaining BOM character, including a repeated
    # leading BOM or one embedded anywhere else in the document.

    if ($content.IndexOf([char]0xFEFF) -ge 0) {
        throw 'Unexpected Unicode BOM in configuration.'
    }

    return ConvertFrom-AijConfigText -Text $content
}
