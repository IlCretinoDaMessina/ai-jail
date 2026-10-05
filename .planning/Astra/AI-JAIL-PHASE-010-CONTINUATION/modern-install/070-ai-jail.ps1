
# ============================================================
# AI Jail - Phase 070 Sandbox Engine
#
# MODE: OFFLINE_REVIEW_ONLY
#
# Validates requirements and policy as local data.
#
# Does NOT:
#   - Invoke WSL or run any Linux commands
#   - Invoke Phase 050 or execute AI Jail
#   - Download or install packages
#   - Modify the existing distribution
#   - Write installation state
#   - Authorize production apply
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

function Assert-ExactList {
    param(
        [object[]]$Actual,
        [string[]]$Expected,
        [string]$Description
    )

    $actualValues = @($Actual)
    $expectedValues = @($Expected)

    Assert-Requirement (
        $actualValues.Count -eq $expectedValues.Count
    ) "Unexpected entry count in $Description."

    for ($i = 0; $i -lt $expectedValues.Count; $i++) {
        Assert-Requirement (
            [string]$actualValues[$i] -ceq $expectedValues[$i]
        ) "Unexpected ${Description} entry at position $($i + 1)."
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

    $requirementsPath = Join-Path $root '070-requirements.json'
    $configPath = Join-Path $root 'config.env'

    $dependencyPaths = @(
        (Join-Path $root '030-requirements.json'),
        (Join-Path $root '040-requirements.json'),
        (Join-Path $root '050-requirements.json'),
        (Join-Path $root '060-requirements.json')
    )

    # --------------------------------------------------------
    # 1. Administrator privileges
    # --------------------------------------------------------

    Write-Output '[1/6] Administrator privileges...'

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
    # 2. Requirements identity and offline review mode
    # --------------------------------------------------------

    Write-Output '[2/6] Validating Phase 070 requirements...'

    foreach ($path in (@($requirementsPath, $configPath) +
                       $dependencyPaths)) {
        Assert-Requirement (
            Test-Path -LiteralPath $path -PathType Leaf
        ) "Required file missing: $(Split-Path -Leaf $path)"
    }

    $r = Get-Content -LiteralPath $requirementsPath -Raw |
        ConvertFrom-Json -ErrorAction Stop

    Assert-Requirement (
        $r.schema -eq 1 -and
        $r.phase -ceq '070' -and
        $r.status -ceq 'MODERNIZATION_CANDIDATE' -and
        $r.mode -ceq 'OFFLINE_REVIEW_ONLY'
    ) 'Invalid Phase 070 identity or execution mode.'

    Assert-Requirement (
        $r.configuration.source -ceq 'config.env' -and
        $r.configuration.binary_path_pattern -ceq
            '/home/{LINUX_USER}/.cargo/bin/ai-jail'
    ) 'Invalid sandbox engine configuration contract.'

    Assert-ExactList `
        -Actual @($r.configuration.required_keys) `
        -Expected @('DISTRO', 'LINUX_USER') `
        -Description 'required configuration keys'

    foreach ($property in @(
        'administrator_required',
        'validate_requirements',
        'validate_check_inventory',
        'validate_version_policy',
        'validate_installation_policy',
        'offline_only'
    )) {
        Assert-Requirement (
            $r.review.$property -ceq $true
        ) "Required review setting disabled: $property"
    }

    Write-Output 'Requirements identity: PASS'
    Write-Output 'Execution mode: OFFLINE_REVIEW_ONLY'

    # --------------------------------------------------------
    # 3. Configuration and dependency declarations
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '[3/6] Validating configuration and dependencies...'

    $config = Read-Configuration $configPath

    foreach ($key in @('DISTRO', 'LINUX_USER')) {
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
        'require_phase_050_runtime_pass',
        'require_phase_060_toolchain_verified',
        'require_fresh_isolation_verification',
        'block_execution_without_runtime_proof'
    )) {
        Assert-Requirement (
            $r.dependencies.$property -ceq $true
        ) "Mandatory dependency protection disabled: $property"
    }

    Assert-Requirement (
        $r.dependencies.accept_offline_reviews_as_runtime_proof -ceq $false
    ) 'Offline reviews must not count as runtime security proof.'

    # Inspect dependency declarations only.
    # Their presence does not prove successful machine execution.

    $phase030 = Get-Content -LiteralPath $dependencyPaths[0] -Raw |
        ConvertFrom-Json -ErrorAction Stop

    $phase040 = Get-Content -LiteralPath $dependencyPaths[1] -Raw |
        ConvertFrom-Json -ErrorAction Stop

    $phase050 = Get-Content -LiteralPath $dependencyPaths[2] -Raw |
        ConvertFrom-Json -ErrorAction Stop

    $phase060 = Get-Content -LiteralPath $dependencyPaths[3] -Raw |
        ConvertFrom-Json -ErrorAction Stop

    Assert-Requirement (
        $phase030.schema -eq 1 -and
        $phase030.phase -ceq '030' -and
        $phase030.mode -ceq 'REVIEW_ONLY' -and
        $phase030.installation.enabled -ceq $false
    ) 'Unexpected Phase 030 dependency declaration.'

    Assert-Requirement (
        $phase040.schema -eq 1 -and
        $phase040.phase -ceq '040' -and
        $phase040.mode -ceq 'OFFLINE_REVIEW_ONLY' -and
        $phase040.installation.enabled -ceq $false
    ) 'Unexpected Phase 040 dependency declaration.'

    Assert-Requirement (
        $phase050.schema -eq 1 -and
        $phase050.phase -ceq '050' -and
        $phase050.mode -ceq 'OFFLINE_REVIEW_ONLY' -and
        $phase050.runtime_verification.enabled -ceq $false -and
        $phase050.installation_gate.offline_review_satisfies_gate -ceq $false
    ) 'Unexpected Phase 050 dependency declaration.'

    Assert-Requirement (
        $phase060.schema -eq 1 -and
        $phase060.phase -ceq '060' -and
        $phase060.mode -ceq 'OFFLINE_REVIEW_ONLY' -and
        $phase060.installation.enabled -ceq $false -and
        $phase060.dependencies.require_phase_050_runtime_pass -ceq $true
    ) 'Unexpected Phase 060 dependency declaration.'

    Write-Output "Target distribution: $distro"
    Write-Output "Expected Linux user: $linuxUser"
    Write-Output 'Dependency declarations: VALID'
    Write-Output 'Phase 050 runtime isolation proof: NOT ESTABLISHED'
    Write-Output 'Phase 060 installed toolchain: NOT VERIFIED'
    Write-Output 'Linux and sandbox execution: BLOCKED'

    # --------------------------------------------------------
    # 4. Sandbox runtime check inventory
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '[4/6] Validating sandbox security check inventory...'

    $runtime = $r.runtime_verification

    Assert-Requirement (
        $runtime.enabled -ceq $false -and
        $runtime.explicit_approval_required -ceq $true -and
        $runtime.fail_fast -ceq $true
    ) 'Invalid runtime verification policy.'

    $expectedChecks = @(
        'unprivileged_user_namespaces',
        'cargo_available',
        'bubblewrap_available',
        'installed_binary_version',
        'dry_run_network_namespace',
        'dry_run_landlock',
        'real_sandbox_execution',
        'allow_host_capability',
        'default_deny_network',
        'gpu_informational_checks'
    )

    Assert-ExactList `
        -Actual @($runtime.checks) `
        -Expected $expectedChecks `
        -Description 'sandbox security checks'

    $deny = $runtime.default_deny_network

    foreach ($property in @(
        'require_successful_sandbox_execution',
        'require_positive_denial_evidence',
        'treat_ambiguous_result_as_failure'
    )) {
        Assert-Requirement (
            $deny.$property -ceq $true
        ) "Default-deny network safeguard disabled: $property"
    }

    Assert-Requirement (
        $deny.treat_arbitrary_curl_failure_as_success -ceq $false
    ) 'An arbitrary curl error must not count as network denial.'

    foreach ($property in @(
        'treat_missing_checks_as_failure',
        'treat_ambiguous_results_as_failure',
        'require_all_mandatory_checks_to_pass'
    )) {
        Assert-Requirement (
            $runtime.$property -ceq $true
        ) "Mandatory runtime safeguard disabled: $property"
    }

    Assert-Requirement (
        $runtime.gpu_checks.mandatory -ceq $false -and
        $runtime.gpu_checks.missing_component_result -ceq 'WARNING'
    ) 'GPU checks must remain informational.'

    Assert-ExactList `
        -Actual @($runtime.gpu_checks.checks) `
        -Expected @(
            '/usr/lib/wsl/lib/nvidia-smi',
            '/dev/dxg',
            'nvidia_smi_execution'
        ) `
        -Description 'GPU checks'

    foreach ($check in $expectedChecks) {
        Write-Output "DECLARED: $check"
    }

    Write-Output ''
    Write-Output 'Ten sandbox checks: DECLARED'
    Write-Output 'Positive network-denial evidence: REQUIRED'
    Write-Output 'Arbitrary curl failure counts as PASS: NO'
    Write-Output 'GPU components: WARNING ONLY'
    Write-Output 'Actual runtime checks executed: 0'

    # --------------------------------------------------------
    # 5. Version-resolution and installation policy
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '[5/6] Validating version and installation policy...'

    $v = $r.version_policy

    Assert-Requirement (
        $v.existing_baseline -ceq '2.2.0' -and
        $v.installation_target -ceq
            'LATEST_APPROVED_COMPATIBLE_STABLE' -and
        $v.source -ceq 'OFFICIAL_UPSTREAM_RELEASE' -and
        $v.state_directory -ceq '.state'
    ) 'Unexpected AI Jail version policy.'

    foreach ($property in @(
        'resolve_before_installation',
        'compatibility_review_required',
        'security_baseline_required',
        'record_resolved_version',
        'record_installed_version',
        'record_source_revision',
        'record_artifact_integrity'
    )) {
        Assert-Requirement (
            $v.$property -ceq $true
        ) "Mandatory version-policy protection disabled: $property"
    }

    foreach ($property in @(
        'automatic_security_downgrades',
        'automatic_replacement'
    )) {
        Assert-Requirement (
            $v.$property -ceq $false
        ) "Prohibited version-policy setting enabled: $property"
    }

    $installation = $r.installation

    foreach ($property in @(
        'explicit_approval_required',
        'fresh_machine_supported_target',
        'official_sources_only',
        'require_resolved_installation_plan',
        'require_artifact_integrity_verification',
        'require_compatibility_review',
        'record_final_state'
    )) {
        Assert-Requirement (
            $installation.$property -ceq $true
        ) "Required installation safeguard disabled: $property"
    }

    foreach ($property in @(
        'enabled',
        'reuse_temporary_pilot_artifacts',
        'overwrite_existing_binary_without_approval',
        'automatic_downgrades',
        'production_apply_authorized'
    )) {
        Assert-Requirement (
            $installation.$property -ceq $false
        ) "Prohibited installation permission enabled: $property"
    }

    Write-Output 'Existing baseline: 2.2.0'
    Write-Output 'Installation target: LATEST APPROVED COMPATIBLE STABLE'
    Write-Output 'Official upstream source: REQUIRED'
    Write-Output 'Compatibility and integrity review: REQUIRED'
    Write-Output 'Automatic replacement or downgrade: PROHIBITED'
    Write-Output 'Resolved installation version: NONE'
    Write-Output 'Installation: DISABLED'

    # --------------------------------------------------------
    # 6. Security restrictions and exit-code contract
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '[6/6] Validating security restrictions...'

    Assert-Requirement (
        $r.security.allow_offline_review -ceq $true
    ) 'Offline review is not authorized.'

    foreach ($property in @(
        'allow_distribution_execution',
        'allow_downloads',
        'allow_package_installation',
        'allow_sandbox_execution',
        'allow_distribution_modification',
        'allow_distribution_termination',
        'allow_wsl_shutdown',
        'allow_isolation_gate_bypass',
        'allow_unapproved_network_access'
    )) {
        Assert-Requirement (
            $r.security.$property -ceq $false
        ) "Prohibited Phase 070 permission enabled: $property"
    }

    Assert-Requirement (
        $r.exit_codes.success -eq 0 -and
        $r.exit_codes.failure -eq 1 -and
        $r.exit_codes.reboot_required -eq 3010 -and
        $r.exit_codes.unknown -ceq 'FAIL_CLOSED'
    ) 'Invalid Phase 070 exit-code contract.'

    Write-Output 'Security restrictions: PASS'
    Write-Output 'Isolation-gate bypass: PROHIBITED'
    Write-Output 'Production apply: DISABLED'

    # --------------------------------------------------------
    # Final result
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '========================================'
    Write-Output 'PHASE 070 OFFLINE REVIEW: PASS'
    Write-Output '========================================'
    Write-Output 'Sandbox engine requirements and policy are valid.'
    Write-Output ''
    Write-Output 'IMPORTANT:'
    Write-Output 'PHASE 050 RUNTIME GATE: NOT SATISFIED'
    Write-Output 'PHASE 060 INSTALLED TOOLCHAIN: NOT VERIFIED'
    Write-Output 'AI JAIL ENGINE: NOT RUNTIME VERIFIED'
    Write-Output 'INSTALLATION READINESS: NOT ESTABLISHED'
    Write-Output ''
    Write-Output 'WSL INVOCATION: NONE'
    Write-Output 'SANDBOX EXECUTION: NONE'
    Write-Output 'DOWNLOADS: NONE'
    Write-Output 'DISTRIBUTION MODIFICATIONS: NONE'
    Write-Output 'PRODUCTION APPLY: DISABLED'

    exit 0
}
catch {
    [Console]::Error.WriteLine(
        "PHASE 070 OFFLINE REVIEW FAILED: $($_.Exception.Message)"
    )

    exit 1
}
