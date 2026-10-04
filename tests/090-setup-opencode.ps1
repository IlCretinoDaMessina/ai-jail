
# ============================================================
# AI Jail - Phase 090 OpenCode Installation Review
#
# MODE: OFFLINE_REVIEW_ONLY
#
# No WSL invocation, downloads, installation, provider requests,
# pilot access, launcher changes, state writes or production apply.
#
# The historical experimental baseline is validated as evidence
# only. It is NOT a resolved modern installation version.
# ============================================================

[CmdletBinding()]
param(
    [string]$Mode = '--review'
)

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

function Assert-TrueProperties {
    param(
        [object]$Source,
        [string[]]$Names,
        [string]$Description
    )

    foreach ($name in $Names) {
        Assert-Requirement (
            $null -ne $Source -and $Source.$name -ceq $true
        ) "Required ${Description} setting missing or disabled: $name"
    }
}

function Assert-FalseProperties {
    param(
        [object]$Source,
        [string[]]$Names,
        [string]$Description
    )

    foreach ($name in $Names) {
        Assert-Requirement (
            $null -ne $Source -and $Source.$name -ceq $false
        ) "Prohibited ${Description} setting missing or enabled: $name"
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
    ) "Unexpected number of entries in $Description."

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
    # --------------------------------------------------------
    # 0. Enforce the approval boundary immediately.
    # --------------------------------------------------------

    if ($Mode -cne '--review') {
        throw (
            "Unsupported mode: $Mode. " +
            'Pilot installation and production apply are disabled.'
        )
    }

    Assert-Requirement (
        $args.Count -eq 0
    ) 'Unexpected additional arguments.'

    $root = $PSScriptRoot

    $requirementsPath = Join-Path $root '090-requirements.json'
    $configPath = Join-Path $root 'config.env'

    Write-Output '[1/7] Validating review mode and required files...'

    foreach ($path in @($requirementsPath, $configPath)) {
        Assert-Requirement (
            Test-Path -LiteralPath $path -PathType Leaf
        ) "Required file missing: $(Split-Path -Leaf $path)"
    }

    $r = Get-Content -LiteralPath $requirementsPath -Raw |
        ConvertFrom-Json -ErrorAction Stop

    Assert-Requirement (
        $r.schema -eq 1 -and
        $r.phase -ceq '090' -and
        $r.status -ceq 'MODERNIZATION_CANDIDATE' -and
        $r.mode -ceq 'OFFLINE_REVIEW_ONLY'
    ) 'Invalid Phase 090 identity or execution mode.'

    Write-Output 'Requirements identity: PASS'
    Write-Output 'Execution mode: OFFLINE_REVIEW_ONLY'

    # --------------------------------------------------------
    # 2. Scope and configuration.
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '[2/7] Validating scope and config.env...'

    Assert-TrueProperties $r.scope @(
        'install_opencode',
        'preserve_existing_pilot',
        'preserve_existing_production_installation'
    ) 'scope'

    Assert-FalseProperties $r.scope @(
        'install_gsd_in_this_phase',
        'install_tps_plugin_in_this_phase',
        'install_vscode',
        'enable_nono'
    ) 'scope'

    Assert-Requirement (
        $r.configuration.source -ceq 'config.env'
    ) 'Unexpected configuration source.'

    Assert-ExactList `
        -Actual @($r.configuration.required_keys) `
        -Expected @(
            'DISTRO',
            'LINUX_USER',
            'INSTALL_OPENCODE',
            'INSTALL_VSCODE',
            'ENABLE_NONO',
            'ALLOW_HOSTS_INSTALL'
        ) `
        -Description 'configuration keys'

    $config = Read-Configuration $configPath

    foreach ($key in @($r.configuration.required_keys)) {
        Assert-Requirement (
            $config.ContainsKey([string]$key)
        ) "Missing configuration key: $key"
    }

    Assert-Requirement (
        $config['DISTRO'] -ceq 'ai-jail' -and
        $config['LINUX_USER'] -ceq 'aijail'
    ) 'Unexpected installation target.'

    foreach ($key in @(
        'INSTALL_OPENCODE',
        'INSTALL_VSCODE',
        'ENABLE_NONO'
    )) {
        $requiredValue = [string](
            $r.configuration.required_feature_flags.$key
        )

        Assert-Requirement (
            $requiredValue -cmatch '^[01]$'
        ) "Invalid required feature flag: $key"

        Assert-Requirement (
            $config[$key] -ceq $requiredValue
        ) "Feature flag differs from reviewed scope: $key"
    }

    Assert-Requirement (
        $config['INSTALL_OPENCODE'] -ceq '1' -and
        $config['INSTALL_VSCODE'] -ceq '0' -and
        $config['ENABLE_NONO'] -ceq '0'
    ) 'Unexpected OpenCode installation feature policy.'

    # This is a configuration presence check, not authorization
    # to use the hosts or to perform any downloads.

    Assert-Requirement (
        -not [string]::IsNullOrWhiteSpace(
            $config['ALLOW_HOSTS_INSTALL']
        )
    ) 'Installation host configuration is missing or empty.'

    Write-Output 'Target distro and Linux user: PASS'
    Write-Output 'OpenCode scope: PASS'
    Write-Output 'VS Code and nono: DISABLED'
    Write-Output 'GSD and TPS installation: SEPARATE PHASES'
    Write-Output 'No host contacted.'

    # --------------------------------------------------------
    # 3. Runtime dependencies.
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '[3/7] Validating dependency policy...'

    Assert-TrueProperties $r.dependencies @(
        'require_phase_030_verified',
        'require_phase_040_configuration_applied',
        'require_phase_050_runtime_pass',
        'require_phase_060_toolchain_verified',
        'require_phase_070_sandbox_verified',
        'require_phase_080_approved_state',
        'block_installation_without_runtime_proof'
    ) 'dependency'

    Assert-FalseProperties $r.dependencies @(
        'accept_offline_reviews_as_runtime_proof'
    ) 'dependency'

    Write-Output 'Runtime dependency requirements: VALID'
    Write-Output 'Phase 050 actual runtime isolation: NOT ESTABLISHED'
    Write-Output 'Phase 070 sandbox runtime verification: NOT ESTABLISHED'
    Write-Output 'Phase 080 approved installation state: NOT ESTABLISHED'
    Write-Output 'Offline review authorizes installation: NO'

    # --------------------------------------------------------
    # 4. Historical experimental evidence.
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '[4/7] Validating historical baseline declaration...'

    $historical = $r.historical_baseline

    Assert-Requirement (
        $historical.opencode_version -ceq '1.18.34' -and
        $historical.archive_sha256 -ceq
            '24b0d458d21ef548b2752166303defcf7f4945b049fb4876ab78dfaf86d81b27' -and
        $historical.binary_sha256 -ceq
            '9ca0b9953d49997601655e54f846a3efa464f237e47c6f1b04716d0f2e64c4c2' -and
        $historical.gsd_version -ceq '1.15.0'
    ) 'Historical experimental baseline differs from reviewed evidence.'

    Assert-TrueProperties $historical @(
        'experimental_evidence_only'
    ) 'historical baseline'

    Assert-FalseProperties $historical @(
        'production_provenance_approved',
        'authorize_reuse_of_pilot_artifacts'
    ) 'historical baseline'

    Write-Output 'Historical OpenCode version: 1.18.34'
    Write-Output "Historical archive SHA-256: $($historical.archive_sha256)"
    Write-Output "Historical binary SHA-256:  $($historical.binary_sha256)"
    Write-Output 'Historical GSD version: 1.15.0'
    Write-Output 'Production artifact provenance: NOT APPROVED'
    Write-Output 'Pilot artifact reuse: PROHIBITED'
    Write-Output 'No pilot files were inspected or changed.'

    # --------------------------------------------------------
    # 5. Future version resolution and installation policy.
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '[5/7] Validating version and installation policy...'

    $v = $r.version_policy

    Assert-Requirement (
        $v.target -ceq 'LATEST_APPROVED_COMPATIBLE_STABLE' -and
        $v.official_repository -ceq
            'https://github.com/anomalyco/opencode' -and
        $v.state_directory -ceq '.state'
    ) 'Unexpected OpenCode version policy.'

    Assert-TrueProperties $v @(
        'resolve_release_before_installation',
        'reject_prereleases_by_default',
        'verify_cpu_and_os_compatibility',
        'verify_artifact_provenance',
        'verify_archive_integrity',
        'verify_extracted_binary_integrity',
        'record_resolved_version',
        'record_installed_version',
        'record_artifact_source',
        'record_artifact_integrity',
        'record_approval_reference'
    ) 'version policy'

    Assert-FalseProperties $v @(
        'automatic_security_downgrades',
        'automatic_replacement_of_existing_installation'
    ) 'version policy'

    $installation = $r.installation

    Assert-TrueProperties $installation @(
        'explicit_approval_required',
        'fresh_machine_supported_target',
        'official_sources_only',
        'approved_download_hosts_only',
        'verify_redirect_destinations',
        'require_resolved_installation_plan',
        'require_artifact_integrity_verification',
        'require_pre_install_conflict_review',
        'require_post_install_version_verification'
    ) 'installation'

    Assert-FalseProperties $installation @(
        'enabled',
        'reuse_temporary_staging_artifacts',
        'reuse_phase092_pilot_artifacts',
        'overwrite_existing_binary_without_approval',
        'modify_existing_runtime_without_approval',
        'production_apply_authorized'
    ) 'installation'

    Write-Output 'Target: LATEST APPROVED COMPATIBLE STABLE'
    Write-Output 'Official repository policy: VALID'
    Write-Output 'Platform and artifact verification: REQUIRED'
    Write-Output 'Automatic replacement/downgrade: PROHIBITED'
    Write-Output 'Resolved modern OpenCode version: NONE'
    Write-Output 'Download and installation: DISABLED'

    # --------------------------------------------------------
    # 6. Runtime provider restrictions.
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '[6/7] Validating provider and runtime restrictions...'

    $runtime = $r.runtime

    Assert-Requirement (
        $runtime.initial_model_candidate -ceq 'opencode/big-pickle' -and
        $runtime.provider_host_candidate -ceq 'opencode.ai'
    ) 'Unexpected candidate provider/model.'

    Assert-TrueProperties $runtime @(
        'remove_installation_hosts_from_runtime_allowlist',
        'loopback_exception_only_after_namespace_entry',
        'authenticated_loopback_server_required_if_enabled',
        'managed_config_precedence_must_be_verified',
        'prevent_windows_opencode_fallback'
    ) 'runtime'

    Assert-FalseProperties $runtime @(
        'verification_enabled',
        'provider_hosts_approved_for_production',
        'production_loopback_exception_approved',
        'persistent_sessions_approved',
        'server_auth_design_approved',
        'secrets_in_writable_project'
    ) 'runtime'

    Assert-Requirement (
        $runtime.explicit_approval_required -ceq $true
    ) 'Runtime verification requires separate approval.'

    Write-Output 'Experimental model candidate: opencode/big-pickle'
    Write-Output 'Provider host candidate: opencode.ai'
    Write-Output 'Production provider allowlist: NOT APPROVED'
    Write-Output 'Loopback and persistent-session policies: NOT APPROVED'
    Write-Output 'Secrets in writable project: PROHIBITED'
    Write-Output 'Live provider requests: DISABLED'

    # --------------------------------------------------------
    # 7. Acceptance gates and explicit approval restrictions.
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '[7/7] Validating acceptance and approval gates...'

    $acceptance = $r.acceptance_gates

    $pendingGates = @(
        'A1_upstream_provenance_and_platform',
        'A2_complete_gsd_dependency_and_generated_tree_audit',
        'A3_installation_hosts_and_redirect_evidence',
        'A4_A5_provider_model_and_runtime_network_policy',
        'A6_versioned_paths_and_config_precedence',
        'A7_windows_launcher_review',
        'A8_runtime_wrapper_and_config_approval',
        'A9_mocked_orchestrator_and_exit_codes',
        'A10_persistence_and_secret_scope',
        'A12_separate_execution_approvals',
        'production_loopback_threat_review',
        'authenticated_server_lifecycle_review',
        'final_regression_and_negative_tests'
    )

    Assert-FalseProperties `
        $acceptance $pendingGates 'pending acceptance gate'

    Assert-TrueProperties $acceptance @(
        'A11_no_vscode_integration'
    ) 'accepted scope'

    Assert-FalseProperties $r.approval @(
        'download_and_install',
        'live_provider_requests',
        'runtime_verification',
        'windows_launcher_replacement',
        'production_wrapper_changes',
        'production_config_changes',
        'wsl_termination',
        'production_apply',
        'direct_powershell_installation',
        'implicit_orchestrator_installation'
    ) 'approval'

    Assert-TrueProperties $r.security @(
        'allow_offline_review'
    ) 'security'

    Assert-FalseProperties $r.security @(
        'allow_distribution_execution',
        'allow_downloads',
        'allow_installation',
        'allow_provider_requests',
        'allow_launcher_replacement',
        'allow_distribution_termination',
        'allow_wsl_shutdown',
        'allow_other_distribution_changes',
        'allow_global_wslconfig_changes',
        'allow_isolation_gate_bypass'
    ) 'security'

    Assert-Requirement (
        $r.exit_codes.success -eq 0 -and
        $r.exit_codes.failure -eq 1 -and
        $r.exit_codes.reboot_required -eq 3010 -and
        $r.exit_codes.unknown -ceq 'FAIL_CLOSED'
    ) 'Invalid Phase 090 exit-code contract.'

    Write-Output 'Acceptance gates: VALIDATED AS DECLARED'
    Write-Output 'Pending production approvals: NOT GRANTED'
    Write-Output 'Direct PowerShell pilot/apply: DISABLED'
    Write-Output 'Implicit orchestrator installation: DISABLED'
    Write-Output 'Production apply: DISABLED'

    # --------------------------------------------------------
    # Final offline review result.
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '========================================'
    Write-Output 'PHASE 090 OFFLINE REVIEW: PASS'
    Write-Output '========================================'
    Write-Output 'OpenCode modernization requirements are valid.'
    Write-Output ''
    Write-Output 'IMPORTANT:'
    Write-Output 'PHASE 050 RUNTIME GATE: NOT SATISFIED'
    Write-Output 'MODERN OPENCODE VERSION: NOT RESOLVED'
    Write-Output 'ARTIFACT PROVENANCE: NOT APPROVED'
    Write-Output 'INSTALLATION READINESS: NOT ESTABLISHED'
    Write-Output ''
    Write-Output 'WSL INVOCATION: NONE'
    Write-Output 'DOWNLOADS: NONE'
    Write-Output 'PILOT MODIFICATIONS: NONE'
    Write-Output 'PRODUCTION MODIFICATIONS: NONE'
    Write-Output 'PROVIDER REQUESTS: NONE'
    Write-Output 'PRODUCTION APPLY: DISABLED'

    exit 0
}
catch {
    [Console]::Error.WriteLine(
        "PHASE 090 OFFLINE REVIEW FAILED: $($_.Exception.Message)"
    )

    exit 1
}
