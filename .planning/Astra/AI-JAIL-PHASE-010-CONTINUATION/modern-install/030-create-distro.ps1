# ============================================================
# AI Jail - Phase 030 Distribution Review
#
# REVIEW ONLY
#
# No installation, import, unregister, distro launch,
# shutdown, file creation or configuration modification.
# ============================================================

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

function Assert-Requirement {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Normalize-WindowsPath {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw 'Missing registered storage path.'
    }

    $value = [Environment]::ExpandEnvironmentVariables($Path)

    # Handle extended-length Windows paths.
    if ($value.StartsWith('\\?\')) {
        $value = $value.Substring(4)
    }

    if ($value -cnotmatch '^[A-Za-z]:\\') {
        throw "Unsupported storage path format: $value"
    }

    return [IO.Path]::GetFullPath($value).TrimEnd('\')
}

function Read-Configuration {
    param([string]$Path)

    $result = @{}

    foreach ($line in (Get-Content -LiteralPath $Path)) {
        $entry = $line.Trim()

        if ($entry.Length -eq 0 -or $entry.StartsWith('#')) {
            continue
        }

        if ($entry -cnotmatch '^([A-Z][A-Z0-9_]*)=(.*)$') {
            throw 'Malformed config.env entry.'
        }

        $key = $Matches[1]
        $value = $Matches[2]

        if ($result.ContainsKey($key)) {
            throw "Duplicate configuration key: $key"
        }

        $result[$key] = $value
    }

    return $result
}

function Assert-NoReparseComponents {
    param([string]$Path)

    $current = Normalize-WindowsPath $Path

    while ($true) {
        if (Test-Path -LiteralPath $current) {
            $item = Get-Item -LiteralPath $current -Force

            if (
                ($item.Attributes -band
                    [IO.FileAttributes]::ReparsePoint) -ne 0
            ) {
                throw "Reparse-point path requires manual review: $current"
            }
        }

        $parent = Split-Path -Path $current -Parent

        if (
            [string]::IsNullOrWhiteSpace($parent) -or
            $parent -eq $current
        ) {
            break
        }

        $current = $parent
    }
}

try {
    $root = $PSScriptRoot

    $requirementsPath = Join-Path $root '030-requirements.json'
    $configPath = Join-Path $root 'config.env'

    Write-Output '========================================'
    Write-Output 'AI JAIL - PHASE 030'
    Write-Output 'DEDICATED WSL DISTRIBUTION REVIEW'
    Write-Output '========================================'
    Write-Output ''

    # --------------------------------------------------------
    # 1. Administrator privileges
    # --------------------------------------------------------

    Write-Output '[1/5] Administrator privileges...'

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)

    Assert-Requirement (
        $principal.IsInRole(
            [Security.Principal.WindowsBuiltInRole]::Administrator
        )
    ) 'Administrator privileges required.'

    Write-Output 'PASS'

    # --------------------------------------------------------
    # 2. Validate Phase 030 requirements
    # --------------------------------------------------------

    Write-Output '[2/5] Validating Phase 030 requirements...'

    foreach ($path in @($requirementsPath, $configPath)) {
        Assert-Requirement (
            Test-Path -LiteralPath $path -PathType Leaf
        ) "Required file missing: $(Split-Path -Leaf $path)"
    }

    $r = Get-Content -LiteralPath $requirementsPath -Raw |
        ConvertFrom-Json -ErrorAction Stop

    Assert-Requirement (
        $r.schema -eq 1 -and
        $r.phase -ceq '030' -and
        $r.status -ceq 'MODERNIZATION_CANDIDATE' -and
        $r.mode -ceq 'REVIEW_ONLY'
    ) 'Invalid Phase 030 identity or review mode.'

    Assert-Requirement (
        $r.version_policy -ceq 'approved-compatible-stable'
    ) 'Unexpected Phase 030 version policy.'

    Assert-Requirement (
        $r.configuration.source -ceq 'config.env' -and
        $r.configuration.destination_pattern -ceq
            'TARGET_DRIVE\DISTRO\wsl' -and
        $r.configuration.vhdx_filename -ceq 'ext4.vhdx'
    ) 'Invalid distribution destination contract.'

    $expectedKeys = @(
        'TARGET_DRIVE',
        'DISTRO',
        'BASE_DISTRO'
    )

    # FIX: PowerShell supports -join, not -cjoin.
    # Apply -ceq to compare the resulting strings case-sensitively.

    $declaredKeys = @($r.configuration.required_keys) -join ','
    $requiredKeys = $expectedKeys -join ','

    Assert-Requirement (
        $declaredKeys -ceq $requiredKeys
    ) 'Unexpected required configuration keys.'

    foreach ($property in @(
        'require_administrator',
        'query_registered_distributions',
        'verify_wsl_version_2',
        'verify_registered_storage_path',
        'verify_destination_vhdx',
        'detect_orphan_destination',
        'fail_on_registration_conflict',
        'fail_on_storage_path_mismatch',
        'fail_on_ambiguous_state'
    )) {
        Assert-Requirement (
            $r.review.$property -ceq $true
        ) "Required review protection disabled: $property"
    }

    Assert-Requirement (
        $r.installation.enabled -ceq $false -and
        $r.installation.explicit_approval_required -ceq $true -and
        $r.installation.overwrite_existing_distribution -ceq $false -and
        $r.installation.overwrite_existing_vhdx -ceq $false -and
        $r.installation.automatic_unregister -ceq $false -and
        $r.installation.automatic_import -ceq $false -and
        $r.installation.automatic_shutdown -ceq $false -and
        $r.installation.automatic_reboot -ceq $false
    ) 'Invalid installation safeguards.'

    Assert-Requirement (
        $r.security.allow_read_only_wsl_queries -ceq $true -and
        $r.security.allow_read_only_registry_queries -ceq $true
    ) 'Required read-only permissions missing.'

    foreach ($property in @(
        'allow_distribution_creation',
        'allow_distribution_execution',
        'allow_global_wslconfig_changes',
        'allow_other_distribution_changes',
        'production_apply_authorized'
    )) {
        Assert-Requirement (
            $r.security.$property -ceq $false
        ) "Prohibited permission enabled: $property"
    }

    Assert-Requirement (
        $r.exit_codes.success -eq 0 -and
        $r.exit_codes.failure -eq 1 -and
        $r.exit_codes.reboot_required -eq 3010 -and
        $r.exit_codes.unknown -ceq 'FAIL_CLOSED'
    ) 'Invalid exit-code contract.'

    Write-Output 'Requirements: PASS'
    Write-Output 'Installation: DISABLED'

    # --------------------------------------------------------
    # 3. Configuration and expected destination
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '[3/5] Reviewing distribution configuration...'

    $config = Read-Configuration $configPath

    foreach ($key in $expectedKeys) {
        Assert-Requirement (
            $config.ContainsKey($key)
        ) "Missing configuration key: $key"

        Assert-Requirement (
            -not [string]::IsNullOrWhiteSpace($config[$key])
        ) "Empty configuration key: $key"
    }

    $drive = $config['TARGET_DRIVE']
    $distro = $config['DISTRO']
    $baseDistro = $config['BASE_DISTRO']

    Assert-Requirement (
        $drive -match '^[A-Za-z]:$'
    ) 'TARGET_DRIVE must be a drive letter such as D:.'

    Assert-Requirement (
        $distro -cmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$'
    ) 'DISTRO contains unsupported characters.'

    Assert-Requirement (
        $baseDistro -cmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$'
    ) 'BASE_DISTRO contains unsupported characters.'

    $destination = Normalize-WindowsPath (
        Join-Path (Join-Path "$drive\" $distro) 'wsl'
    )

    $expectedVhdx = Join-Path $destination 'ext4.vhdx'

    Assert-NoReparseComponents $destination
    Assert-NoReparseComponents $expectedVhdx

    Write-Output "Target distro: $distro"
    Write-Output "Base distro:   $baseDistro"
    Write-Output "Destination:   $destination"
    Write-Output 'PASS'

    # --------------------------------------------------------
    # 4. Inspect current-user WSL registration
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '[4/5] Inspecting WSL registration...'

    $lxssRoot = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss'

    $registrations = @()

    if (Test-Path -LiteralPath $lxssRoot) {
        $keys = @(
            Get-ChildItem -LiteralPath $lxssRoot -ErrorAction Stop
        )

        foreach ($key in $keys) {
            $entry = Get-ItemProperty -LiteralPath $key.PSPath `
                -ErrorAction Stop

            if ([string]$entry.DistributionName -ieq $distro) {
                $registrations += [pscustomobject]@{
                    Name        = [string]$entry.DistributionName
                    BasePath    = [string]$entry.BasePath
                    RegistryKey = $key.PSPath
                }
            }
        }
    }

    if ($registrations.Count -gt 1) {
        throw "Multiple WSL registrations found for $distro."
    }

    $registered = ($registrations.Count -eq 1)

    if ($registered) {
        Write-Output 'Target registration: PRESENT'
    }
    else {
        Write-Output 'Target registration: ABSENT'
    }

    # --------------------------------------------------------
    # 5. Assess actual storage and WSL2 status
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '[5/5] Verifying storage and distribution state...'

    $destinationExists = Test-Path -LiteralPath $destination
    $vhdxExists = Test-Path -LiteralPath $expectedVhdx -PathType Leaf

    if (-not $registered) {
        # Never use an unregistered, nonempty destination.
        # Even an empty existing destination is only reviewed;
        # it is not modified or claimed by this phase.

        if ($destinationExists) {
            $destinationItem = Get-Item -LiteralPath $destination -Force

            if (-not $destinationItem.PSIsContainer) {
                throw 'Destination exists but is not a directory.'
            }

            $contents = @(
                Get-ChildItem -LiteralPath $destination -Force `
                    -ErrorAction Stop
            )

            if ($contents.Count -gt 0) {
                throw (
                    'Destination contains files but the target distro ' +
                    'is not registered. Manual review required.'
                )
            }

            Write-Output 'Existing destination: EMPTY'
        }
        else {
            Write-Output 'Destination: ABSENT'
        }

        Write-Output ''
        Write-Output '========================================'
        Write-Output 'PHASE 030 REVIEW: PASS'
        Write-Output 'STATE: CLEAN - DISTRO NOT CREATED'
        Write-Output '========================================'
        Write-Output 'A future installation plan may be prepared.'
        Write-Output 'No distribution was created.'
        Write-Output 'Production apply remains disabled.'

        exit 0
    }

    # Independently compare the Windows registration's BasePath
    # against the destination calculated from config.env.

    $registration = $registrations[0]

    $registeredBase = Normalize-WindowsPath $registration.BasePath

    if ($registeredBase.EndsWith(
        '.vhdx',
        [StringComparison]::OrdinalIgnoreCase
    )) {
        $registeredVhdx = $registeredBase
    }
    else {
        $registeredVhdx = Join-Path $registeredBase 'ext4.vhdx'
    }

    Assert-NoReparseComponents $registeredVhdx

    if (-not [string]::Equals(
        $registeredVhdx,
        $expectedVhdx,
        [StringComparison]::OrdinalIgnoreCase
    )) {
        throw (
            "Registered storage path mismatch.`n" +
            "Expected:   $expectedVhdx`n" +
            "Registered: $registeredVhdx"
        )
    }

    if (-not $vhdxExists) {
        throw (
            'The distro is registered at the expected location, ' +
            'but ext4.vhdx is missing.'
        )
    }

    # wsl.exe --list --verbose is a read-only query.
    # Select exactly one executable, as fixed in Phase 020.

    $wsl = Get-Command 'wsl.exe' -CommandType Application `
        -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if ($null -eq $wsl) {
        throw 'wsl.exe not found.'
    }

    $wslPath = [string]$wsl.Source

    Assert-Requirement (
        Test-Path -LiteralPath $wslPath -PathType Leaf
    ) 'Selected wsl.exe executable is missing.'

    $env:WSL_UTF8 = '1'

    $wslOutput = @(& $wslPath --list --verbose 2>&1)
    $wslRC = $LASTEXITCODE

    if ($wslRC -ne 0) {
        throw "WSL registration query failed with exit code $wslRC."
    }

    $escapedName = [regex]::Escape($distro)
    $matchingVersions = @()

    foreach ($line in $wslOutput) {
        $lineText = ("$line" -replace "`0", '').Trim()

        # Accommodate the '*' prefix used for the default
        # distribution. State labels may be localized.

        $linePattern = '^\*?\s*' + $escapedName + '\s+.+?\s+([12])\s*$'

        if ($lineText -match $linePattern) {
            $matchingVersions += $Matches[1]
        }
    }

    if ($matchingVersions.Count -ne 1) {
        throw (
            'Could not independently verify exactly one WSL ' +
            "registration for $distro."
        )
    }

    if ($matchingVersions[0] -ne '2') {
        throw "$distro is not registered as a WSL2 distribution."
    }

    Write-Output "WSL registration: $distro"
    Write-Output 'WSL version:      2'
    Write-Output "Registered VHDX:  $registeredVhdx"
    Write-Output 'Storage path:     MATCH'
    Write-Output 'VHDX presence:    PASS'

    Write-Output ''
    Write-Output '========================================'
    Write-Output 'PHASE 030 REVIEW: PASS'
    Write-Output 'STATE: EXISTING DISTRO VERIFIED'
    Write-Output '========================================'
    Write-Output 'No distribution was created or launched.'
    Write-Output 'No WSL shutdown or configuration change occurred.'
    Write-Output 'Production apply remains disabled.'

    exit 0
}
catch {
    [Console]::Error.WriteLine(
        "PHASE 030 REVIEW FAILED: $($_.Exception.Message)"
    )

    exit 1
}