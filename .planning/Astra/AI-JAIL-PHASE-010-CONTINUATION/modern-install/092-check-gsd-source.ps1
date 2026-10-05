
# ============================================================
# AI Jail - Phase 092
# GSD Core Installation and OpenCode Integration
#
# MODE: OFFLINE_REVIEW_ONLY
#
# This script has NO installation or pilot execution path.
#
# Prohibited:
#   - WSL execution
#   - Downloads
#   - Source generation or dependency installation
#   - Access to historical staging/pilot directories
#   - Existing OpenCode configuration modifications
#   - GSD command-path migration
#   - MCP execution
#   - Production apply
#
# All checks inspect local requirements and config.env only.
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

function Assert-BooleanProperties {
    param(
        [object]$Source,
        [string[]]$Names,
        [bool]$Expected,
        [string]$Description
    )

    Assert-Requirement (
        $null -ne $Source
    ) "Missing requirements section: $Description"

    foreach ($name in $Names) {
        $property = $Source.PSObject.Properties[$name]

        Assert-Requirement (
            $null -ne $property
        ) "Missing ${Description} property: $name"

        Assert-Requirement (
            $property.Value -is [bool] -and
            $property.Value -eq $Expected
        ) "Invalid ${Description} property: $name"
    }
}

function Assert-TrueProperties {
    param(
        [object]$Source,
        [string[]]$Names,
        [string]$Description
    )

    Assert-BooleanProperties `
        -Source $Source `
        -Names $Names `
        -Expected $true `
        -Description $Description
}

function Assert-FalseProperties {
    param(
        [object]$Source,
        [string[]]$Names,
        [string]$Description
    )

    Assert-BooleanProperties `
        -Source $Source `
        -Names $Names `
        -Expected $false `
        -Description $Description
}

function Read-Configuration {
    param([string]$Path)

    $result = @{}

    foreach ($line in [IO.File]::ReadAllLines($Path)) {
        $entry = $line.Trim()

        if (
            $entry.Length -eq 0 -or
            $entry.StartsWith('#')
        ) {
            continue
        }

        if ($entry -cnotmatch '^([A-Z][A-Z0-9_]*)=(.*)$') {
            throw 'Malformed config.env entry.'
        }

        $key = $Matches[1]
        $value = $Matches[2]

        Assert-Requirement (
            -not $result.ContainsKey($key)
        ) "Duplicate configuration key: $key"

        $result[$key] = $value
    }

    return $result
}

try {

    # --------------------------------------------------------
    # 0. Reject every executable mode immediately.
    # --------------------------------------------------------

    if ($Mode -cne '--review') {
        throw (
            "Unsupported mode: $Mode. " +
            'Pilot installation, generation and production apply ' +
            'are disabled.'
        )
    }

    Assert-Requirement (
        $args.Count -eq 0
    ) 'Unexpected additional arguments.'

    $requirementsPath = Join-Path `
        $PSScriptRoot '092-requirements.json'

    $configPath = Join-Path `
        $PSScriptRoot 'config.env'

    Write-Output '[1/8] Validating Phase 092 review mode and files...'

    foreach ($path in @(
        $requirementsPath,
        $configPath
    )) {
        Assert-Requirement (
            Test-Path -LiteralPath $path -PathType Leaf
        ) "Required file missing: $(Split-Path -Leaf $path)"
    }

    $r = Get-Content -LiteralPath $requirementsPath -Raw |
        ConvertFrom-Json -ErrorAction Stop

    Assert-Requirement (
        $r.schema -eq 1 -and
        $r.phase -ceq '092' -and
        $r.name -ceq
            'GSD Core Installation and OpenCode Integration' -and
        $r.status -ceq 'MODERNIZATION_CANDIDATE' -and
        $r.mode -ceq 'OFFLINE_REVIEW_ONLY'
    ) 'Invalid Phase 092 requirements identity or mode.'

    Write-Output 'Requirements identity: PASS'
    Write-Output 'Execution mode: OFFLINE_REVIEW_ONLY'

    # --------------------------------------------------------
    # 2. Installation scope and configuration.
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '[2/8] Validating GSD scope and configuration...'

    Assert-Requirement (
        $r.scope.package -ceq '@opengsd/gsd-core' -and
        $r.scope.official_repository -ceq
            'https://github.com/open-gsd/gsd-core'
    ) 'Unexpected GSD package identity or repository.'

    Assert-TrueProperties $r.scope @(
        'install_gsd_core',
        'integrate_with_linux_opencode',
        'preserve_existing_pilot',
        'preserve_existing_runtime_plugins',
        'preserve_existing_project_data',
        'preserve_planning_directory'
    ) 'scope'

    Assert-FalseProperties $r.scope @(
        'install_opencode_in_this_phase',
        'install_tps_plugin_in_this_phase'
    ) 'scope'

    $config = Read-Configuration $configPath

    foreach ($key in @(
        'DISTRO',
        'LINUX_USER',
        'INSTALL_OPENCODE',
        'INSTALL_VSCODE',
        'ENABLE_NONO'
    )) {
        Assert-Requirement (
            $config.ContainsKey($key)
        ) "Missing configuration key: $key"
    }

    Assert-Requirement (
        $config['DISTRO'] -ceq 'ai-jail' -and
        $config['LINUX_USER'] -ceq 'aijail' -and
        $config['INSTALL_OPENCODE'] -ceq '1' -and
        $config['INSTALL_VSCODE'] -ceq '0' -and
        $config['ENABLE_NONO'] -ceq '0'
    ) 'Configuration differs from the reviewed GSD scope.'

    Write-Output 'GSD package identity: PASS'
    Write-Output 'Target distro and Linux user: PASS'
    Write-Output 'OpenCode integration: DECLARED'
    Write-Output 'OpenCode and TPS installation: SEPARATE PHASES'
    Write-Output 'Existing pilot, plugins and project data: PRESERVE'

    # --------------------------------------------------------
    # 3. Runtime dependencies and historical baseline.
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '[3/8] Validating dependencies and historical evidence...'

    Assert-TrueProperties $r.dependencies @(
        'require_phase_050_runtime_pass',
        'require_phase_060_toolchain_verified',
        'require_phase_070_sandbox_verified',
        'require_phase_080_approved_state',
        'require_phase_090_opencode_verified',
        'block_installation_without_runtime_proof'
    ) 'dependency'

    Assert-FalseProperties $r.dependencies @(
        'accept_offline_reviews_as_runtime_proof'
    ) 'dependency'

    $historical = $r.historical_baseline

    Assert-Requirement (
        $historical.gsd_version -ceq '1.15.0' -and
        $historical.opencode_version -ceq '1.18.34' -and
        $historical.original_configuration_sha256 -ceq
            'a2f07f6d83252ccd0cc1417410e04705b6234765130b392c1e18dfaf298ecbb1' -and
        $historical.generated_command_count -eq 72
    ) 'Historical GSD experimental baseline mismatch.'

    Assert-TrueProperties $historical @(
        'experimental_offline_dependency_tree_used',
        'experimental_mcp_configuration_verified',
        'experimental_command_path_migration_performed',
        'experimental_evidence_only'
    ) 'historical baseline'

    Assert-FalseProperties $historical @(
        'production_dependency_audit_complete',
        'authorize_staging_reuse',
        'authorize_pilot_reuse',
        'authorize_production_installation'
    ) 'historical baseline'

    Write-Output 'Mandatory runtime dependencies: DECLARED'
    Write-Output 'Historical GSD: 1.15.0'
    Write-Output 'Historical OpenCode: 1.18.34'
    Write-Output 'Historical generated command count: 72'
    Write-Output 'Production dependency audit: NOT ESTABLISHED'
    Write-Output 'Historical staging/pilot reuse: PROHIBITED'
    Write-Output 'Actual runtime dependency completion: NOT ESTABLISHED'

    # --------------------------------------------------------
    # 4. Version resolution and independent source acquisition.
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '[4/8] Validating fresh-install source policy...'

    $versionPolicy = $r.version_policy

    Assert-Requirement (
        $versionPolicy.target -ceq
            'LATEST_APPROVED_COMPATIBLE_STABLE' -and
        $versionPolicy.state_directory -ceq '.state'
    ) 'Invalid GSD version policy.'

    Assert-TrueProperties $versionPolicy @(
        'resolve_before_installation',
        'review_opencode_compatibility',
        'review_node_runtime_compatibility',
        'reject_prereleases_by_default',
        'use_exact_approved_package_version',
        'record_resolved_version',
        'record_installed_version',
        'record_source_commit',
        'record_package_integrity',
        'record_approval_reference'
    ) 'version policy'

    Assert-FalseProperties $versionPolicy @(
        'automatic_security_downgrades',
        'automatic_replacement'
    ) 'version policy'

    $source = $r.source_and_dependencies

    Assert-TrueProperties $source @(
        'official_sources_only',
        'independent_fresh_machine_acquisition',
        'require_source_provenance',
        'require_complete_integrity_bearing_lockfile',
        'require_transitive_dependency_review',
        'require_lifecycle_script_audit',
        'require_generation_tool_audit',
        'require_installer_transform_audit',
        'require_generated_tree_audit',
        'require_package_identity_verification',
        'require_package_version_verification',
        'require_file_manifest_and_hashes',
        'require_approved_download_hosts',
        'require_redirect_evidence'
    ) 'source/dependency'

    Assert-FalseProperties $source @(
        'reuse_phase090_staging',
        'reuse_phase092_pilot_artifacts',
        'accept_existing_node_modules_as_provenance',
        'copy_unaudited_dependency_tree'
    ) 'source/dependency'

    Write-Output 'Target: LATEST APPROVED COMPATIBLE STABLE'
    Write-Output 'Independent fresh-machine acquisition: REQUIRED'
    Write-Output 'Integrity-bearing dependency lockfile: REQUIRED'
    Write-Output 'Lifecycle, generation and generated-tree audits: REQUIRED'
    Write-Output 'Fixed historical staging dependencies: PROHIBITED'
    Write-Output 'Existing node_modules as provenance: REJECTED'
    Write-Output 'Modern GSD version resolved: NO'
    Write-Output 'Downloads and source generation: DISABLED'

    # --------------------------------------------------------
    # 5. Managed installation and OpenCode MCP integration.
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '[5/8] Validating installation and MCP policy...'

    $installation = $r.installation

    Assert-FalseProperties $installation @(
        'enabled',
        'production_apply_authorized'
    ) 'installation'

    Assert-TrueProperties $installation @(
        'explicit_approval_required',
        'require_resolved_installation_plan',
        'require_runtime_dependency_proof',
        'require_integrity_verification',
        'require_pre_install_conflict_review',
        'use_versioned_managed_installation_path',
        'require_managed_path_ownership_review',
        'reject_managed_path_symlinks',
        'preserve_existing_valid_installation',
        'refuse_conflicting_existing_installation',
        'never_silently_overwrite_runtime_configuration',
        'never_silently_overwrite_plugins'
    ) 'installation'

    $integration = $r.opencode_integration

    Assert-TrueProperties $integration @(
        'require_approved_linux_opencode_binary',
        'require_isolated_managed_configuration',
        'require_exact_mcp_registration',
        'require_local_gsd_mcp_server',
        'require_explicit_mcp_enablement_approval',
        'require_explicit_read_permission_review',
        'require_explicit_external_directory_permission_review',
        'restrict_permissions_to_approved_gsd_paths',
        'verify_mcp_command_path',
        'verify_mcp_server_syntax',
        'verify_mcp_server_lifecycle',
        'verify_managed_config_precedence',
        'preserve_existing_tps_registration',
        'preserve_unrelated_configuration',
        'do_not_write_secrets_into_project'
    ) 'OpenCode integration'

    Assert-FalseProperties $integration @(
        'runtime_activation_enabled'
    ) 'OpenCode integration'

    Write-Output 'Managed versioned installation: REQUIRED'
    Write-Output 'Conflict and ownership verification: REQUIRED'
    Write-Output 'Exact local GSD MCP registration: REQUIRED'
    Write-Output 'Read/external-directory permissions: SEPARATE REVIEW'
    Write-Output 'Existing TPS registration: PRESERVE'
    Write-Output 'Managed config precedence: MUST BE VERIFIED'
    Write-Output 'MCP runtime activation: DISABLED'

    # --------------------------------------------------------
    # 6. Command generation and transactional migration.
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '[6/8] Validating command-generation and migration policy...'

    $generation = $r.command_generation_and_migration

    Assert-TrueProperties $generation @(
        'require_approved_generation_method',
        'audit_generated_commands_before_installation',
        'record_expected_command_inventory',
        'verify_generated_command_integrity',
        'validate_all_generated_paths',
        'reject_symlinked_command_files',
        'restrict_migration_to_managed_gsd_command_files',
        'preserve_unrelated_markdown_files',
        'preserve_existing_runtime_plugins',
        'require_file_level_backups',
        'require_atomic_file_replacement',
        'require_post_migration_verification',
        'require_rollback_on_failure',
        'historical_command_count_is_not_future_pin'
    ) 'command migration'

    Assert-FalseProperties $generation @(
        'modify_existing_runtime_commands_without_approval'
    ) 'command migration'

    $transaction = $r.transaction

    Assert-TrueProperties $transaction @(
        'private_owned_staging',
        'stage_complete_installation_before_promotion',
        'validate_staged_manifest',
        'validate_staged_hashes',
        'validate_staged_dependency_tree',
        'validate_staged_configuration',
        'validate_staged_command_paths',
        'preserve_existing_installation_for_rollback',
        'preserve_existing_config_for_rollback',
        'preserve_existing_commands_for_rollback',
        'rollback_on_promotion_failure',
        'report_rollback_failure',
        'never_delete_unrelated_files',
        'refuse_unapproved_partial_state_repair'
    ) 'transaction'

    Write-Output 'Approved generation process: REQUIRED'
    Write-Output 'Future command inventory: VERSION-DEPENDENT'
    Write-Output 'Historical 72-command count: NOT A FUTURE PIN'
    Write-Output 'Managed GSD files only: MIGRATION SCOPE'
    Write-Output 'Private transaction staging: REQUIRED'
    Write-Output 'Atomic replacement and rollback: REQUIRED'
    Write-Output 'Existing runtime command modification: NOT APPROVED'

    # --------------------------------------------------------
    # 7. Acceptance and testing requirements.
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '[7/8] Validating acceptance requirements...'

    Assert-TrueProperties $r.acceptance @(
        'static_validation_required',
        'source_and_dependency_audit_required',
        'disposable_distro_test_requires_explicit_approval',
        'fresh_install_test_required',
        'existing_installation_rerun_required',
        'partial_state_recovery_required',
        'conflicting_state_rejection_required',
        'forced_failure_rollback_required',
        'exact_mcp_configuration_test_required',
        'mcp_server_functionality_test_required',
        'generated_command_integrity_test_required',
        'cross_project_isolation_test_required',
        'existing_plugin_preservation_test_required',
        'managed_config_precedence_test_required',
        'negative_network_tests_required',
        'exit_code_propagation_required',
        'mocked_orchestrator_test_required',
        'git_clean_required',
        'production_regression_required'
    ) 'acceptance'

    Assert-FalseProperties $r.acceptance @(
        'accept_historical_pilot_as_production_proof'
    ) 'acceptance'

    Write-Output 'Fresh-install and rerun tests: REQUIRED'
    Write-Output 'Partial-state and conflict tests: REQUIRED'
    Write-Output 'Forced rollback test: REQUIRED'
    Write-Output 'MCP functionality and command integrity: REQUIRED'
    Write-Output 'Isolation and negative network tests: REQUIRED'
    Write-Output 'Historical pilot alone satisfies acceptance: NO'
    Write-Output 'Executable acceptance tests performed here: NONE'

    # --------------------------------------------------------
    # 8. Independent approvals and security restrictions.
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '[8/8] Validating approval and security gates...'

    Assert-FalseProperties $r.approval @(
        'source_download',
        'dependency_download',
        'generation_execution',
        'disposable_test_execution',
        'installation',
        'runtime_configuration_changes',
        'existing_runtime_command_migration',
        'mcp_server_execution',
        'runtime_provider_requests',
        'wsl_termination',
        'production_apply',
        'direct_script_installation',
        'implicit_orchestrator_installation'
    ) 'approval'

    Assert-TrueProperties $r.security @(
        'allow_offline_review'
    ) 'security'

    Assert-FalseProperties $r.security @(
        'allow_distribution_execution',
        'allow_downloads',
        'allow_installation',
        'allow_generation_execution',
        'allow_runtime_modification',
        'allow_pilot_modification',
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
    ) 'Invalid Phase 092 exit-code contract.'

    Write-Output 'Download and generation approvals: NOT GRANTED'
    Write-Output 'Installation and runtime-change approvals: NOT GRANTED'
    Write-Output 'Direct PowerShell installation: DISABLED'
    Write-Output 'Implicit orchestrator installation: DISABLED'
    Write-Output 'Production apply: DISABLED'

    # --------------------------------------------------------
    # Final offline review result.
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '========================================'
    Write-Output 'PHASE 092 OFFLINE REVIEW: PASS'
    Write-Output '========================================'
    Write-Output 'GSD modernization requirements are valid.'
    Write-Output ''
    Write-Output 'IMPORTANT:'
    Write-Output 'PHASE 050 RUNTIME GATE: NOT SATISFIED'
    Write-Output 'PHASE 090 MODERN OPENCODE INSTALLATION: NOT VERIFIED'
    Write-Output 'MODERN GSD VERSION: NOT RESOLVED'
    Write-Output 'DEPENDENCY AND GENERATED-TREE AUDITS: NOT COMPLETE'
    Write-Output 'INSTALLATION READINESS: NOT ESTABLISHED'
    Write-Output ''
    Write-Output 'WSL INVOCATION: NONE'
    Write-Output 'DOWNLOADS: NONE'
    Write-Output 'GENERATION EXECUTION: NONE'
    Write-Output 'PILOT MODIFICATIONS: NONE'
    Write-Output 'RUNTIME MODIFICATIONS: NONE'
    Write-Output 'PRODUCTION APPLY: DISABLED'

    exit 0
}
catch {
    [Console]::Error.WriteLine(
        "PHASE 092 OFFLINE REVIEW FAILED: $($_.Exception.Message)"
    )

    exit 1
}
