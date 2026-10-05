# =========================================================
# AI Jail - Phase 020 WSL Verification
# Read-only. Never installs, updates or shuts down WSL.
# =========================================================

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

try {
    $root = $PSScriptRoot

    $requirementsPath = Join-Path $root '020-requirements.json'
    $configPath = Join-Path $root 'config.env'

    # -----------------------------------------------------
    # 1. Administrator privileges
    # -----------------------------------------------------

    Write-Output '[1/4] Administrator privileges...'

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()

    $principal = [Security.Principal.WindowsPrincipal]::new(
        $identity
    )

    if (-not $principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )) {
        throw 'Administrator privileges are required.'
    }

    Write-Output 'PASS'

    # -----------------------------------------------------
    # 2. Requirements validation
    # -----------------------------------------------------

    Write-Output '[2/4] Validating Phase 020 requirements...'

    foreach ($path in @($requirementsPath, $configPath)) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Required file missing: $(Split-Path -Leaf $path)"
        }
    }

    $r = Get-Content -LiteralPath $requirementsPath -Raw |
        ConvertFrom-Json -ErrorAction Stop

    if ($r.schema -ne 1 -or $r.phase -cne '020') {
        throw 'Invalid Phase 020 requirements schema or identity.'
    }

    if (
        $r.version_policy -cne 'minimum' -or
        $r.version_source.command -cne 'wsl.exe --version' -or
        $r.version_source.minimum_version_key -cne 'MIN_WSL_VERSION' -or
        $r.version_source.configuration -cne 'config.env'
    ) {
        throw 'Invalid WSL version requirements.'
    }

    if (
        $r.execution.read_only -cne $true -or
        $r.execution.administrator_required -cne $true -or
        $r.execution.standalone_auto_elevation -cne $true -or
        $r.execution.orchestrated_auto_elevation -cne $false -or
        $r.execution.fail_fast -cne $true
    ) {
        throw 'Invalid Phase 020 execution policy.'
    }

    if ($r.security.allow_wsl_version_query -cne $true) {
        throw 'WSL version query is not authorised.'
    }

    foreach ($property in @(
        'allow_distro_execution',
        'allow_wsl_installation',
        'allow_wsl_update',
        'allow_wsl_shutdown',
        'allow_system_modifications',
        'allow_downloads'
    )) {
        if ($r.security.$property -cne $false) {
            throw "Prohibited Phase 020 permission: $property"
        }
    }

    if (
        $r.exit_codes.success -ne 0 -or
        $r.exit_codes.failure -ne 1
    ) {
        throw 'Invalid Phase 020 exit-code contract.'
    }

    Write-Output 'PASS'

    # -----------------------------------------------------
    # 3. Read minimum version from config.env
    # -----------------------------------------------------

    Write-Output '[3/4] Reading minimum WSL version...'

    $config = @{}

    foreach ($line in (Get-Content -LiteralPath $configPath)) {
        $entry = $line.Trim()

        if ($entry.Length -eq 0 -or $entry.StartsWith('#')) {
            continue
        }

        if ($entry -cnotmatch '^([A-Z][A-Z0-9_]*)=(.*)$') {
            throw 'Malformed config.env entry.'
        }

        $key = $Matches[1]
        $value = $Matches[2]

        if ($config.ContainsKey($key)) {
            throw "Duplicate configuration key: $key"
        }

        $config[$key] = $value
    }

    if (-not $config.ContainsKey('MIN_WSL_VERSION')) {
        throw 'MIN_WSL_VERSION missing from config.env.'
    }

    $minimumText = $config['MIN_WSL_VERSION']

    $pattern = '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$'

    if ($minimumText -cnotmatch $pattern) {
        throw 'MIN_WSL_VERSION must use N.N.N format without leading zeros.'
    }

    try {
        $minimum = [version]::Parse("$minimumText.0")
    }
    catch {
        throw 'MIN_WSL_VERSION contains unsupported numeric values.'
    }

    Write-Output "Minimum required: $minimumText"
    Write-Output 'PASS'

    # -----------------------------------------------------
    # 4. Query installed WSL version
    # -----------------------------------------------------

    Write-Output '[4/4] Checking installed WSL version...'

    # FIX:
    # Get-Command may find multiple wsl.exe executables.
    # Select exactly ONE executable. Never pass an array
    # of executable paths to PowerShell's call operator.

    $wsl = Get-Command 'wsl.exe' -CommandType Application `
        -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if ($null -eq $wsl) {
        throw 'wsl.exe not found. Installation requires separate approval.'
    }

    $wslPath = [string]$wsl.Source

    if (-not (Test-Path -LiteralPath $wslPath -PathType Leaf)) {
        throw "Selected WSL executable does not exist: $wslPath"
    }

    # Preserve the original UTF-8 output handling.
    $env:WSL_UTF8 = '1'

    $output = @(& $wslPath --version 2>&1)
    $wslExitCode = $LASTEXITCODE

    if ($wslExitCode -ne 0) {
        throw "wsl.exe --version failed with exit code $wslExitCode."
    }

    $lines = @(
        $output |
            ForEach-Object { "$_" } |
            Where-Object {
                -not [string]::IsNullOrWhiteSpace($_)
            }
    )

    if ($lines.Count -eq 0) {
        throw 'WSL returned empty version information.'
    }

    # Parse the first labelled version line.
    # Ignore the localized text before the colon.

    $versionLine = $lines[0].Trim()

    if (
        $versionLine -cnotmatch
        '^[^:]+:\s*([0-9]+\.[0-9]+\.[0-9]+(?:\.[0-9]+)?)\s*$'
    ) {
        throw "Could not parse WSL version: $versionLine"
    }

    $installedText = $Matches[1]

    try {
        $installed = [version]::Parse($installedText)

        if ($installed.Build -lt 0) {
            $installed = [version]::Parse("$installedText.0")
        }
    }
    catch {
        throw 'WSL reported an invalid numeric version.'
    }

    Write-Output "Installed WSL: $installedText"
    Write-Output "Required WSL:  $minimumText"

    if ($installed -lt $minimum) {
        throw (
            "WSL $installedText is below the required $minimumText. " +
            'Review and approve a WSL update before proceeding.'
        )
    }

    Write-Output 'PASS'

    Write-Output ''
    Write-Output '========================================'
    Write-Output 'PHASE 020: PASS'
    Write-Output '========================================'
    Write-Output 'WSL is installed and meets the minimum version.'
    Write-Output 'No distributions were accessed.'
    Write-Output 'No installation, update or shutdown performed.'

    exit 0
}
catch {
    [Console]::Error.WriteLine(
        "PHASE 020 FAILED: $($_.Exception.Message)"
    )

    exit 1
}