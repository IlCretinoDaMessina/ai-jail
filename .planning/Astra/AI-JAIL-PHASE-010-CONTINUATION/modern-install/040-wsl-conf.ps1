# ============================================================
# AI Jail - Phase 040 WSL Configuration and Isolation Review
#
# MODE: OFFLINE_REVIEW_ONLY
#
# No wsl.exe calls, distribution execution, file writes,
# user creation, termination, shutdown, or installation.
#
# This review validates the declared configuration policy.
# It does NOT establish live runtime isolation.
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

try {
    $root = $PSScriptRoot

    $requirementsPath = Join-Path $root '040-requirements.json'
    $configPath = Join-Path $root 'config.env'
    $phase030Path = Join-Path $root '030-requirements.json'

    Write-Output '========================================'
    Write-Output 'AI JAIL - PHASE 040'
    Write-Output 'OFFLINE WSL CONFIGURATION REVIEW'
    Write-Output '========================================'
    Write-Output ''

    # --------------------------------------------------------
    # 1. Administrator privileges
    # --------------------------------------------------------

    Write-Output '[1/5] Administrator privileges...'

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()

    $principal = [Security.Principal.WindowsPrincipal]::new(
        $identity
    )

    Assert-Requirement (
        $principal.IsInRole(
            [Security.Principal.WindowsBuiltInRole]::Administrator
        )
    ) 'Administrator privileges required.'

    Write-Output 'PASS'

    # --------------------------------------------------------
    # 2. Requirements identity and execution restrictions
    # --------------------------------------------------------

    Write-Output '[2/5] Validating Phase 040 requirements...'

    foreach ($path in @(
        $requirementsPath,
        $configPath,
        $phase030Path
    )) {
        Assert-Requirement (
            Test-Path -LiteralPath $path -PathType Leaf
        ) "Required file missing: $(Split-Path -Leaf $path)"
    }

    $r = Get-Content -LiteralPath $requirementsPath -Raw |
        ConvertFrom-Json -ErrorAction Stop

    Assert-Requirement (
        $r.schema -eq 1 -and
        $r.phase -ceq '040' -and
        $r.status -ceq 'MODERNIZATION_CANDIDATE' -and
        $r.mode -ceq 'OFFLINE_REVIEW_ONLY'
    ) 'Invalid Phase 040 identity or execution mode.'

    Assert-Requirement (
        $r.configuration.source -ceq 'config.env' -and
        $r.configuration.target_file -ceq '/etc/wsl.conf' -and
        $r.configuration.encoding -ceq 'UTF-8' -and
        $r.configuration.line_endings -ceq 'LF' -and
        $r.configuration.comparison -ceq 'EXACT'
    ) 'Invalid WSL configuration contract.'

    $expectedKeys = @('DISTRO', 'LINUX_USER')

    $declaredKeys = @($r.configuration.required_keys) -join ','
    $requiredKeys = $expectedKeys -join ','

    Assert-Requirement (
        $declaredKeys -ceq $requiredKeys
    ) 'Unexpected required configuration keys.'

    foreach ($property in @(
        'administrator_required',
        'validate_configuration',
        'validate_expected_isolation_policy',
        'require_phase_030_verified',
        'offline_only'
    )) {
        Assert-Requirement (
            $r.review.$property -ceq $true
        ) "Required review protection disabled: $property"
    }

    foreach ($property in @(
        'inspect_live_wsl_conf',
        'verify_runtime_isolation'
    )) {
        Assert-Requirement (
            $r.review.$property -ceq $false
        ) "Live access unexpectedly enabled: $property"
    }

    Assert-Requirement (
        $r.runtime_verification.enabled -ceq $false -and
        $r.runtime_verification.explicit_approval_required -ceq $true
    ) 'Invalid runtime-verification approval policy.'

    foreach ($property in @(
        'verify_default_user',
        'verify_windows_mounts_absent',
        'verify_drvfs_absent',
        'verify_windows_interop_disabled',
        'verify_windows_paths_absent'
    )) {
        Assert-Requirement (
            $r.runtime_verification.$property -ceq $true
        ) "Missing future runtime-verification requirement: $property"
    }

    Assert-Requirement (
        $r.installation.enabled -ceq $false -and
        $r.installation.explicit_approval_required -ceq $true -and
        $r.installation.create_linux_user_if_missing -ceq $true -and
        $r.installation.modify_wsl_conf_only_if_different -ceq $true -and
        $r.installation.verify_before_and_after -ceq $true -and
        $r.installation.automatic_termination -ceq $false -and
        $r.installation.termination_requires_separate_approval -ceq $true -and
        $r.installation.overwrite_unrelated_configuration -ceq $false -and
        $r.installation.automatic_shutdown -ceq $false -and
        $r.installation.automatic_reboot -ceq $false
    ) 'Invalid installation safeguards.'

    Assert-Requirement (
        $r.security.allow_offline_configuration_review -ceq $true
    ) 'Offline review is not authorized.'

    foreach ($property in @(
        'allow_distribution_execution',
        'allow_linux_user_creation',
        'allow_wsl_conf_modification',
        'allow_distribution_termination',
        'allow_other_distribution_changes',
        'allow_global_wslconfig_changes',
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
    Write-Output 'Runtime verification: DISABLED'
    Write-Output 'Installation: DISABLED'

    # --------------------------------------------------------
    # 3. Configuration values
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '[3/5] Validating config.env...'

    $config = Read-Configuration $configPath

    foreach ($key in $expectedKeys) {
        Assert-Requirement (
            $config.ContainsKey($key)
        ) "Missing configuration key: $key"

        Assert-Requirement (
            -not [string]::IsNullOrWhiteSpace($config[$key])
        ) "Empty configuration value: $key"
    }

    $distro = $config['DISTRO']
    $linuxUser = $config['LINUX_USER']

    Assert-Requirement (
        $distro -cmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$'
    ) 'DISTRO contains unsupported characters.'

    Assert-Requirement (
        $linuxUser -cmatch '^[a-z_][a-z0-9_-]{0,31}$' -and
        $linuxUser -cnotmatch '^-$'
    ) 'LINUX_USER is not a supported Linux username.'

    Write-Output "Target distro: $distro"
    Write-Output "Default user:  $linuxUser"
    Write-Output 'PASS'

    # --------------------------------------------------------
    # 4. Verify the exact expected isolation policy
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '[4/5] Validating declared isolation policy...'

    $expectedValues = @(
        @('boot',      'systemd',           'true'),
        @('automount', 'enabled',           'false'),
        @('automount', 'mountFsTab',        'false'),
        @('interop',   'enabled',           'false'),
        @('interop',   'appendWindowsPath', 'false'),
        @('user',      'default',           'CONFIG:LINUX_USER')
    )

    $expectedSections = @(
        'boot',
        'automount',
        'interop',
        'user'
    )

    $actualSections = @(
        $r.configuration.expected_content.PSObject.Properties.Name
    )

    Assert-Requirement (
        ($actualSections -join ',') -ceq
        ($expectedSections -join ',')
    ) 'Unexpected isolation policy sections.'

    foreach ($section in $expectedSections) {
        $expectedPropertyNames = @(
            $expectedValues |
                Where-Object { $_[0] -ceq $section } |
                ForEach-Object { $_[1] }
        )

        $actualPropertyNames = @(
            $r.configuration.expected_content.$section.PSObject.Properties.Name
        )

        Assert-Requirement (
            ($actualPropertyNames -join ',') -ceq
            ($expectedPropertyNames -join ',')
        ) "Unexpected configuration properties in [$section]."
    }

    foreach ($entry in $expectedValues) {
        $section = $entry[0]
        $property = $entry[1]
        $requiredValue = $entry[2]

        $actualValue = [string](
            $r.configuration.expected_content.$section.$property
        )

        Assert-Requirement (
            $actualValue -ceq $requiredValue
        ) "Invalid isolation setting: [$section] $property"
    }

    # Construct the expected file in memory only.
    # Nothing is written to disk or to the distribution.

    $expectedConf = @(
        '[boot]'
        'systemd=true'
        ''
        '[automount]'
        'enabled=false'
        'mountFsTab=false'
        ''
        '[interop]'
        'enabled=false'
        'appendWindowsPath=false'
        ''
        '[user]'
        "default=$linuxUser"
        ''
    ) -join "`n"

    Assert-Requirement (
        -not [string]::IsNullOrWhiteSpace($expectedConf)
    ) 'Expected WSL configuration could not be constructed.'

    Write-Output 'systemd enabled: PASS'
    Write-Output 'Windows automount disabled: PASS'
    Write-Output 'Windows interop disabled: PASS'
    Write-Output 'Windows PATH injection disabled: PASS'
    Write-Output 'Default Linux user policy: PASS'
    Write-Output 'Expected file format: UTF-8 / LF'
    Write-Output ''
    Write-Output 'NOTE: These results validate the declared policy only.'
    Write-Output 'The live /etc/wsl.conf has NOT been inspected.'

    # --------------------------------------------------------
    # 5. Phase 030 dependency declaration
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '[5/5] Checking Phase 030 dependency declaration...'

    $phase030 = Get-Content -LiteralPath $phase030Path -Raw |
        ConvertFrom-Json -ErrorAction Stop

    Assert-Requirement (
        $phase030.schema -eq 1 -and
        $phase030.phase -ceq '030' -and
        $phase030.mode -ceq 'REVIEW_ONLY' -and
        $phase030.security.production_apply_authorized -ceq $false
    ) 'Invalid or unexpected Phase 030 dependency requirements.'

    Write-Output 'Phase 030 requirements file: VALID'
    Write-Output 'Phase 030 machine completion record: NOT VERIFIED'
    Write-Output 'Live WSL configuration: NOT VERIFIED'
    Write-Output 'Runtime isolation: NOT VERIFIED'

    Write-Output ''
    Write-Output '========================================'
    Write-Output 'PHASE 040 OFFLINE REVIEW: PASS'
    Write-Output '========================================'
    Write-Output 'Declared isolation policy is valid.'
    Write-Output 'Installation readiness: NOT ESTABLISHED'
    Write-Output ''
    Write-Output 'WSL INVOCATION: NONE'
    Write-Output 'DISTRIBUTION MODIFICATIONS: NONE'
    Write-Output 'PRODUCTION APPLY: DISABLED'

    exit 0
}
catch {
    [Console]::Error.WriteLine(
        "PHASE 040 OFFLINE REVIEW FAILED: $($_.Exception.Message)"
    )

    exit 1
}