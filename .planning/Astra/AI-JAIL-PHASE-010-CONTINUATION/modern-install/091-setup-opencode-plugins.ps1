
# ============================================================
# AI Jail - Phase 091 OpenCode TPS Meter Plugin
#
# MODE: OFFLINE_REVIEW_ONLY
#
# No WSL execution, downloads, plugin installation, provider
# requests, pilot access, cache access or filesystem changes.
#
# An offline PASS validates the declared installation contract.
# It does NOT establish installation or runtime readiness.
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
        ) "Missing ${Description} setting: $name"

        Assert-Requirement (
            $property.Value -is [bool] -and
            $property.Value -eq $Expected
        ) "Invalid ${Description} setting: $name"
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

        if ($entry.Length -eq 0 -or $entry.StartsWith('#')) {
            continue
        }

        Assert-Requirement (
            $entry -cmatch '^([A-Z][A-Z0-9_]*)=(.*)$'
        ) 'Malformed config.env entry.'

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
    # 0. Direct PowerShell execution must fail closed.
    # --------------------------------------------------------

    if ($Mode -cne '--review') {
        throw (
            "Unsupported mode: $Mode. " +
            'Plugin installation, pilot execution and apply are disabled.'
        )
    }

    Assert-Requirement (
        $args.Count -eq 0
    ) 'Unexpected additional arguments.'

    $requirementsPath = Join-Path `
        $PSScriptRoot '091-requirements.json'

    $configPath = Join-Path `
        $PSScriptRoot 'config.env'

    Write-Output '[1/7] Validating review mode and local requirements...'

    foreach ($path in @($requirementsPath, $configPath)) {
        Assert-Requirement (
            Test-Path -LiteralPath $path -PathType Leaf
        ) "Required file missing: $(Split-Path -Leaf $path)"
    }

    $r = Get-Content -LiteralPath $requirementsPath -Raw |
        ConvertFrom-Json -ErrorAction Stop

    Assert-Requirement (
        $r.schema -eq 1 -and
        $r.phase -ceq '091' -and
        $r.name -ceq 'OpenCode TPS Meter Plugin' -and
        $r.status -ceq 'MODERNIZATION_CANDIDATE' -and
        $r.mode -ceq 'OFFLINE_REVIEW_ONLY'
    ) 'Invalid Phase 091 requirements identity or mode.'

    Write-Output 'Requirements identity: PASS'
    Write-Output 'Execution mode: OFFLINE_REVIEW_ONLY'

    # --------------------------------------------------------
    # 2. Scope and local configuration.
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '[2/7] Validating plugin scope and configuration...'

    Assert-Requirement (
        $r.scope.plugin -ceq 'opencode-tps-meter' -and
        $r.scope.official_repository -ceq
            'https://github.com/ChiR24/opencode-tps-meter'
    ) 'Unexpected plugin identity or official repository.'

    Assert-TrueProperties $r.scope @(
        'preserve_existing_pilot',
        'preserve_existing_opencode_installation',
        'other_plugins_require_separate_review'
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
    ) 'Configuration differs from the approved modernization scope.'

    Write-Output 'Plugin: opencode-tps-meter'
    Write-Output 'Official repository declaration: PASS'
    Write-Output 'Target distribution and Linux user: PASS'
    Write-Output 'OpenCode enabled; VS Code and nono disabled.'
    Write-Output 'Existing pilot preservation: REQUIRED'

    # --------------------------------------------------------
    # 3. Runtime dependencies.
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '[3/7] Validating runtime dependency policy...'

    Assert-TrueProperties $r.dependencies @(
        'require_phase_050_runtime_pass',
        'require_phase_070_sandbox_verified',
        'require_phase_080_approved_state',
        'require_phase_090_opencode_verified',
        'block_installation_without_runtime_proof'
    ) 'dependency'

    Assert-FalseProperties $r.dependencies @(
        'accept_offline_reviews_as_runtime_proof'
    ) 'dependency'

    Write-Output 'Mandatory runtime dependencies: DECLARED'
    Write-Output 'Phase 050 runtime isolation: NOT ESTABLISHED'
    Write-Output 'Phase 070 runtime verification: NOT ESTABLISHED'
    Write-Output 'Phase 080 approved installation state: NOT ESTABLISHED'
    Write-Output 'Phase 090 OpenCode installation: NOT ESTABLISHED'
    Write-Output 'Offline reviews authorize plugin installation: NO'

    # --------------------------------------------------------
    # 4. Historical experimental baseline.
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '[4/7] Validating historical TPS Meter baseline...'

    $historical = $r.historical_baseline

    Assert-Requirement (
        $historical.opencode_version -ceq '1.18.34' -and
        $historical.plugin_version -ceq '0.4.0' -and
        $historical.installation_method -ceq
            'opencode plug opencode-tps-meter@0.4.0 --global'
    ) 'Historical experimental installation evidence mismatch.'

    Assert-TrueProperties $historical @(
        'experimentally_verified'
    ) 'historical baseline'

    Assert-FalseProperties $historical @(
        'authorizes_pilot_reuse',
        'authorizes_production_installation'
    ) 'historical baseline'

    Write-Output 'Historical OpenCode: 1.18.34'
    Write-Output 'Historical TPS Meter: 0.4.0'
    Write-Output 'Official historical command: DECLARED'
    Write-Output 'Historical evidence grants production approval: NO'
    Write-Output 'Existing pilot access: NONE'

    # --------------------------------------------------------
    # 5. Future version-resolution and installation contract.
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '[5/7] Validating version and installation contract...'

    $versionPolicy = $r.version_policy

    Assert-Requirement (
        $versionPolicy.target -ceq
            'LATEST_APPROVED_COMPATIBLE_STABLE' -and
        $versionPolicy.state_directory -ceq '.state'
    ) 'Invalid TPS Meter version-resolution policy.'

    Assert-TrueProperties $versionPolicy @(
        'resolve_before_installation',
        'review_opencode_plugin_compatibility',
        'reject_prereleases_by_default',
        'use_exact_resolved_version',
        'record_package_source',
        'record_resolved_version',
        'record_installed_version',
        'record_package_integrity',
        'record_approval_reference'
    ) 'version policy'

    Assert-FalseProperties $versionPolicy @(
        'automatic_security_downgrades',
        'automatic_replacement'
    ) 'version policy'

    $installation = $r.installation

    Assert-Requirement (
        $installation.method -ceq
            'OFFICIAL_OPENCODE_PLUG_COMMAND' -and
        $installation.command_pattern -ceq
            'opencode plug opencode-tps-meter@{APPROVED_VERSION} --global'
    ) 'Unexpected plugin installation method.'

    Assert-TrueProperties $installation @(
        'use_approved_linux_opencode_binary',
        'use_isolated_xdg_config_home',
        'require_explicit_approval',
        'require_approved_installation_hosts',
        'require_artifact_integrity',
        'require_pre_install_conflict_review',
        'refuse_incomplete_existing_installation',
        'refuse_conflicting_existing_version',
        'no_manual_package_metadata_creation',
        'no_manual_package_cache_population'
    ) 'installation'

    Assert-FalseProperties $installation @(
        'enabled',
        'reuse_phase092_pilot',
        'production_apply_authorized'
    ) 'installation'

    Write-Output 'Target: LATEST APPROVED COMPATIBLE STABLE'
    Write-Output 'Official OpenCode plugin command: REQUIRED'
    Write-Output 'Exact approved package version: REQUIRED'
    Write-Output 'Isolated XDG_CONFIG_HOME: REQUIRED'
    Write-Output 'Manual package metadata/cache construction: PROHIBITED'
    Write-Output 'Conflicting or incomplete installation: FAIL CLOSED'
    Write-Output 'Modern TPS Meter version resolved: NO'
    Write-Output 'Plugin download and installation: DISABLED'

    # --------------------------------------------------------
    # 6. Installation verification and sandbox cache policy.
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '[6/7] Validating verification and cache-isolation policy...'

    $verification = $r.verification

    Assert-FalseProperties $verification @(
        'enabled',
        'broad_host_cache_access'
    ) 'verification'

    Assert-TrueProperties $verification @(
        'require_exact_package_name',
        'require_exact_package_version',
        'require_exact_server_registration',
        'require_exact_tui_registration',
        'validate_json_structure_not_serialized_substrings',
        'verify_package_metadata_from_actual_installed_location',
        'distinguish_absent_complete_and_conflicting_states',
        'require_plugin_runtime_functionality_test',
        'require_sandbox_cache_visibility_review',
        'narrow_read_only_cache_mapping'
    ) 'verification'

    # These settings are requirements for a future verifier.
    # This review does not claim to inspect actual Linux JSON,
    # node_modules or installed plugin metadata.

    $proposedStates = @(
        'ABSENT',
        'COMPLETE',
        'INCOMPLETE_OR_CONFLICTING'
    )

    Assert-Requirement (
        $proposedStates.Count -eq 3
    ) 'Incomplete plugin-state classification.'

    Write-Output 'Exact package name/version verification: REQUIRED'
    Write-Output 'Structured server registration verification: REQUIRED'
    Write-Output 'Structured TUI registration verification: REQUIRED'
    Write-Output 'Absent/complete/conflicting state handling: DECLARED'
    Write-Output 'Narrow read-only plugin cache mapping: REQUIRED'
    Write-Output 'Broad host cache exposure: PROHIBITED'
    Write-Output 'Actual installed plugin metadata: NOT INSPECTED'
    Write-Output 'Actual runtime functionality: NOT TESTED'

    # --------------------------------------------------------
    # 7. Independent approval and security restrictions.
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '[7/7] Validating approval and security gates...'

    Assert-FalseProperties $r.approval @(
        'download_and_install',
        'runtime_plugin_execution',
        'plugin_cache_mapping',
        'runtime_configuration_changes',
        'existing_plugin_replacement',
        'production_apply',
        'implicit_orchestrator_installation',
        'direct_script_installation'
    ) 'approval'

    Assert-TrueProperties $r.security @(
        'allow_offline_review'
    ) 'security'

    Assert-FalseProperties $r.security @(
        'allow_distribution_execution',
        'allow_downloads',
        'allow_plugin_installation',
        'allow_plugin_execution',
        'allow_host_cache_modification',
        'allow_pilot_modification',
        'allow_distribution_termination',
        'allow_wsl_shutdown',
        'allow_isolation_gate_bypass'
    ) 'security'

    Assert-Requirement (
        $r.exit_codes.success -eq 0 -and
        $r.exit_codes.failure -eq 1 -and
        $r.exit_codes.reboot_required -eq 3010 -and
        $r.exit_codes.unknown -ceq 'FAIL_CLOSED'
    ) 'Invalid Phase 091 exit-code contract.'

    Write-Output 'Separate download/install approval: REQUIRED'
    Write-Output 'Separate runtime plugin approval: REQUIRED'
    Write-Output 'Separate cache-mapping approval: REQUIRED'
    Write-Output 'Existing installation replacement: NOT APPROVED'
    Write-Output 'Direct PowerShell installation: DISABLED'
    Write-Output 'Implicit orchestrator installation: DISABLED'
    Write-Output 'Production apply: DISABLED'

    # --------------------------------------------------------
    # Final review result.
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '========================================'
    Write-Output 'PHASE 091 OFFLINE REVIEW: PASS'
    Write-Output '========================================'
    Write-Output 'TPS Meter modernization requirements are valid.'
    Write-Output ''
    Write-Output 'IMPORTANT:'
    Write-Output 'PHASE 050 RUNTIME GATE: NOT SATISFIED'
    Write-Output 'PHASE 090 MODERN OPENCODE INSTALLATION: NOT VERIFIED'
    Write-Output 'MODERN TPS METER VERSION: NOT RESOLVED'
    Write-Output 'PLUGIN CACHE MAPPING: NOT APPROVED'
    Write-Output 'INSTALLATION READINESS: NOT ESTABLISHED'
    Write-Output ''
    Write-Output 'WSL INVOCATION: NONE'
    Write-Output 'DOWNLOADS: NONE'
    Write-Output 'PLUGIN EXECUTION: NONE'
    Write-Output 'PILOT MODIFICATIONS: NONE'
    Write-Output 'PRODUCTION MODIFICATIONS: NONE'
    Write-Output 'PRODUCTION APPLY: DISABLED'

    exit 0
}
catch {
    [Console]::Error.WriteLine(
        "PHASE 091 OFFLINE REVIEW FAILED: $($_.Exception.Message)"
    )

    exit 1
}
