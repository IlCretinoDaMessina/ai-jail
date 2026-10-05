# ============================================================
# AI Jail - Phase 050 Hard Isolation Gate
#
# MODE: OFFLINE_REVIEW_ONLY
#
# This script validates security requirements as DATA.
#
# It does NOT:
#   - Invoke wsl.exe
#   - Start or execute commands inside any distribution
#   - Inspect live Linux state
#   - Modify Windows or Linux configuration
#   - Satisfy the actual runtime isolation gate
#   - Authorize subsequent installation phases
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

    $requirementsPath = Join-Path $root '050-requirements.json'
    $configPath = Join-Path $root 'config.env'

    $phase030Path = Join-Path $root '030-requirements.json'
    $phase040Path = Join-Path $root '040-requirements.json'

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
    # 2. Phase 050 requirements and mode
    # --------------------------------------------------------

    Write-Output '[2/5] Validating Phase 050 requirements...'

    foreach ($path in @(
        $requirementsPath,
        $configPath,
        $phase030Path,
        $phase040Path
    )) {
        Assert-Requirement (
            Test-Path -LiteralPath $path -PathType Leaf
        ) "Required file missing: $(Split-Path -Leaf $path)"
    }

    $r = Get-Content -LiteralPath $requirementsPath -Raw |
        ConvertFrom-Json -ErrorAction Stop

    Assert-Requirement (
        $r.schema -eq 1 -and
        $r.phase -ceq '050' -and
        $r.status -ceq 'MODERNIZATION_CANDIDATE' -and
        $r.mode -ceq 'OFFLINE_REVIEW_ONLY'
    ) 'Invalid Phase 050 identity or execution mode.'

    Assert-Requirement (
        $r.configuration.source -ceq 'config.env'
    ) 'Unexpected configuration source.'

    $expectedKeys = @(
        'DISTRO',
        'LINUX_USER'
    )

    $declaredKeys = @($r.configuration.required_keys) -join ','
    $requiredKeys = $expectedKeys -join ','

    Assert-Requirement (
        $declaredKeys -ceq $requiredKeys
    ) 'Unexpected required configuration keys.'

    foreach ($property in @(
        'administrator_required',
        'validate_requirements',
        'validate_check_inventory',
        'offline_only'
    )) {
        Assert-Requirement (
            $r.review.$property -ceq $true
        ) "Required offline review setting disabled: $property"
    }

    Write-Output 'Requirements identity: PASS'
    Write-Output 'Execution mode: OFFLINE_REVIEW_ONLY'

    # --------------------------------------------------------
    # 3. Configuration and dependencies
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '[3/5] Validating configuration and dependencies...'

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
        $linuxUser -cmatch '^[a-z_][a-z0-9_-]{0,31}$'
    ) 'LINUX_USER contains unsupported characters.'

    foreach ($property in @(
        'require_phase_030_verified',
        'require_phase_040_configuration_applied',
        'require_fresh_runtime_verification'
    )) {
        Assert-Requirement (
            $r.dependencies.$property -ceq $true
        ) "Required dependency disabled: $property"
    }

    Assert-Requirement (
        $r.dependencies.accept_offline_policy_review_as_runtime_proof -ceq
            $false
    ) 'Offline review must not count as runtime isolation proof.'

    # Check dependency declarations only.
    # Reading their requirements does not establish that
    # either phase successfully configured this machine.

    $phase030 = Get-Content -LiteralPath $phase030Path -Raw |
        ConvertFrom-Json -ErrorAction Stop

    $phase040 = Get-Content -LiteralPath $phase040Path -Raw |
        ConvertFrom-Json -ErrorAction Stop

    Assert-Requirement (
        $phase030.schema -eq 1 -and
        $phase030.phase -ceq '030' -and
        $phase030.mode -ceq 'REVIEW_ONLY' -and
        $phase030.security.production_apply_authorized -ceq $false
    ) 'Invalid Phase 030 dependency declaration.'

    Assert-Requirement (
        $phase040.schema -eq 1 -and
        $phase040.phase -ceq '040' -and
        $phase040.mode -ceq 'OFFLINE_REVIEW_ONLY' -and
        $phase040.security.production_apply_authorized -ceq $false
    ) 'Invalid Phase 040 dependency declaration.'

    Write-Output "Target distribution: $distro"
    Write-Output "Expected Linux user: $linuxUser"
    Write-Output 'Phase 030 dependency declaration: VALID'
    Write-Output 'Phase 040 dependency declaration: VALID'
    Write-Output 'Phase 030 machine completion: NOT VERIFIED'
    Write-Output 'Phase 040 live configuration: NOT VERIFIED'

    # --------------------------------------------------------
    # 4. Validate the complete runtime check inventory
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '[4/5] Validating hard isolation check inventory...'

    Assert-Requirement (
        $r.runtime_verification.enabled -ceq $false -and
        $r.runtime_verification.explicit_approval_required -ceq $true -and
        $r.runtime_verification.fail_fast -ceq $true
    ) 'Invalid runtime-verification execution policy.'

    $expectedChecks = @(
        'effective_linux_user',
        'windows_c_drive_unmounted',
        'windows_d_drive_unmounted',
        'no_drvfs_mounts',
        'cmd_exe_unreachable',
        'powershell_exe_unreachable',
        'linux_path_isolated',
        'independent_mount_inventory'
    )

    $declaredChecks = @($r.runtime_verification.checks)

    Assert-Requirement (
        $declaredChecks.Count -eq $expectedChecks.Count
    ) 'Unexpected number of hard isolation checks.'

    Assert-Requirement (
        ($declaredChecks -join ',') -ceq ($expectedChecks -join ',')
    ) 'Hard isolation check inventory differs from the required sequence.'

    foreach ($property in @(
        'require_positive_check_execution',
        'treat_unavailable_checks_as_failure',
        'treat_ambiguous_results_as_failure',
        'require_all_checks_to_pass'
    )) {
        Assert-Requirement (
            $r.runtime_verification.$property -ceq $true
        ) "Fail-closed verification requirement disabled: $property"
    }

    foreach ($check in $expectedChecks) {
        Write-Output "DECLARED: $check"
    }

    Write-Output ''
    Write-Output 'All eight mandatory checks are declared.'
    Write-Output 'Unavailable checks must fail: PASS'
    Write-Output 'Ambiguous results must fail: PASS'
    Write-Output 'Actual runtime checks executed: 0'

    # --------------------------------------------------------
    # 5. Security restrictions and installation gate
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '[5/5] Validating security and installation gate...'

    Assert-Requirement (
        $r.security.allow_offline_review -ceq $true
    ) 'Offline review is not authorized.'

    foreach ($property in @(
        'allow_distribution_execution',
        'allow_distribution_modification',
        'allow_distribution_termination',
        'allow_wsl_shutdown',
        'allow_windows_drive_mounts',
        'allow_drvfs',
        'allow_windows_interop',
        'allow_windows_path_injection',
        'allow_security_bypass',
        'production_apply_authorized'
    )) {
        Assert-Requirement (
            $r.security.$property -ceq $false
        ) "Prohibited security permission enabled: $property"
    }

    Assert-Requirement (
        $r.installation_gate.blocking -ceq $true -and
        $r.installation_gate.requires_runtime_pass -ceq $true -and
        $r.installation_gate.offline_review_satisfies_gate -ceq $false -and
        $r.installation_gate.continue_on_failure -ceq $false -and
        $r.installation_gate.allow_skip -ceq $false
    ) 'Invalid hard isolation installation gate.'

    Assert-Requirement (
        $r.exit_codes.success -eq 0 -and
        $r.exit_codes.failure -eq 1 -and
        $r.exit_codes.unknown -ceq 'FAIL_CLOSED'
    ) 'Invalid exit-code contract.'

    Write-Output 'Security requirements: PASS'
    Write-Output 'Installation gate is blocking: PASS'
    Write-Output 'Skipping the runtime gate: PROHIBITED'
    Write-Output 'Offline review satisfies runtime gate: NO'
    Write-Output 'Production apply: DISABLED'

    # --------------------------------------------------------
    # Final result
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '========================================'
    Write-Output 'PHASE 050 OFFLINE REVIEW: PASS'
    Write-Output '========================================'
    Write-Output 'Declared hard isolation requirements are valid.'
    Write-Output ''
    Write-Output 'IMPORTANT:'
    Write-Output 'RUNTIME ISOLATION: NOT VERIFIED'
    Write-Output 'HARD ISOLATION GATE: NOT SATISFIED'
    Write-Output 'INSTALLATION READINESS: NOT ESTABLISHED'
    Write-Output ''
    Write-Output 'WSL INVOCATION: NONE'
    Write-Output 'DISTRIBUTION MODIFICATIONS: NONE'
    Write-Output 'PRODUCTION APPLY: DISABLED'

    exit 0
}
catch {
    [Console]::Error.WriteLine(
        "PHASE 050 OFFLINE REVIEW FAILED: $($_.Exception.Message)"
    )

    exit 1
}