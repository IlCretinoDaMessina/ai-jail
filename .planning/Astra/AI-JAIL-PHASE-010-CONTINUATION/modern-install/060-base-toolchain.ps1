# ============================================================
# AI Jail - Phase 060 Base Linux Toolchain
#
# MODE: OFFLINE_REVIEW_ONLY
#
# This script validates the toolchain requirements and policy.
#
# It does NOT:
#   - Invoke WSL or execute Linux commands
#   - Invoke Phase 050
#   - Treat offline review as runtime isolation proof
#   - Download or install packages
#   - Change the existing distribution
#   - Write installation state or authorize production apply
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
        ) "Unexpected entry in ${Description}: position $($i + 1)."
    }
}

try {
    $root = $PSScriptRoot

    $requirementsPath = Join-Path $root '060-requirements.json'
    $configPath = Join-Path $root 'config.env'

    $phase030Path = Join-Path $root '030-requirements.json'
    $phase040Path = Join-Path $root '040-requirements.json'
    $phase050Path = Join-Path $root '050-requirements.json'

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
    # 2. Requirements identity and execution restrictions
    # --------------------------------------------------------

    Write-Output '[2/6] Validating Phase 060 requirements...'

    foreach ($path in @(
        $requirementsPath,
        $configPath,
        $phase030Path,
        $phase040Path,
        $phase050Path
    )) {
        Assert-Requirement (
            Test-Path -LiteralPath $path -PathType Leaf
        ) "Required file missing: $(Split-Path -Leaf $path)"
    }

    $r = Get-Content -LiteralPath $requirementsPath -Raw |
        ConvertFrom-Json -ErrorAction Stop

    Assert-Requirement (
        $r.schema -eq 1 -and
        $r.phase -ceq '060' -and
        $r.status -ceq 'MODERNIZATION_CANDIDATE' -and
        $r.mode -ceq 'OFFLINE_REVIEW_ONLY'
    ) 'Invalid Phase 060 identity or execution mode.'

    Assert-Requirement (
        $r.configuration.source -ceq 'config.env'
    ) 'Unexpected configuration source.'

    Assert-ExactList `
        -Actual @($r.configuration.required_keys) `
        -Expected @('DISTRO', 'LINUX_USER') `
        -Description 'required configuration keys'

    foreach ($property in @(
        'administrator_required',
        'validate_requirements',
        'validate_tool_inventory',
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
    # 3. Configuration and prior-phase dependencies
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
        'require_fresh_isolation_verification',
        'block_execution_without_runtime_proof'
    )) {
        Assert-Requirement (
            $r.dependencies.$property -ceq $true
        ) "Mandatory dependency protection disabled: $property"
    }

    Assert-Requirement (
        $r.dependencies.accept_phase_050_offline_review_as_runtime_proof -ceq
            $false
    ) 'Phase 050 offline review must not count as runtime proof.'

    # Read dependency declarations as data only.
    # Their existence does not establish successful execution.

    $phase030 = Get-Content -LiteralPath $phase030Path -Raw |
        ConvertFrom-Json -ErrorAction Stop

    $phase040 = Get-Content -LiteralPath $phase040Path -Raw |
        ConvertFrom-Json -ErrorAction Stop

    $phase050 = Get-Content -LiteralPath $phase050Path -Raw |
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

    Write-Output "Target distribution: $distro"
    Write-Output "Expected Linux user: $linuxUser"
    Write-Output 'Dependency declarations: VALID'
    Write-Output 'Phase 050 runtime isolation proof: NOT ESTABLISHED'
    Write-Output 'Linux execution: BLOCKED'

    # --------------------------------------------------------
    # 4. Required toolchain inventory
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '[4/6] Validating base toolchain inventory...'

    $expectedCommands = @(
        'bwrap',
        'git',
        'curl',
        'jq',
        'rustup',
        'node',
        'npm',
        'python3',
        'pip3',
        'pkg-config',
        'gcc'
    )

    Assert-ExactList `
        -Actual @($r.toolchain.required_commands) `
        -Expected $expectedCommands `
        -Description 'required Linux commands'

    $expectedAdditionalChecks = @(
        'rust_active_toolchain',
        'unprivileged_user_namespaces'
    )

    Assert-ExactList `
        -Actual @($r.toolchain.additional_checks) `
        -Expected $expectedAdditionalChecks `
        -Description 'additional toolchain checks'

    Assert-Requirement (
        $r.toolchain.gpu_checks.mandatory -ceq $false -and
        $r.toolchain.gpu_checks.missing_component_result -ceq 'WARNING'
    ) 'GPU checks must remain informational.'

    Assert-ExactList `
        -Actual @($r.toolchain.gpu_checks.checks) `
        -Expected @(
            '/usr/lib/wsl/lib',
            'nvidia-smi',
            '/dev/dxg'
        ) `
        -Description 'GPU check inventory'

    foreach ($command in $expectedCommands) {
        Write-Output "REQUIRED: $command"
    }

    Write-Output 'Rust active toolchain: REQUIRED'
    Write-Output 'Unprivileged user namespaces: REQUIRED'
    Write-Output 'GPU components: WARNING ONLY'
    Write-Output 'Actual Linux tools inspected: 0'

    # --------------------------------------------------------
    # 5. Version-resolution and installation policy
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '[5/6] Validating version and installation policy...'

    $v = $r.version_policy

    Assert-Requirement (
        $v.default -ceq 'LATEST_APPROVED_STABLE' -and
        $v.state_directory -ceq '.state'
    ) 'Unexpected version-resolution policy.'

    foreach ($property in @(
        'resolve_before_installation',
        'compatibility_review_required',
        'security_baseline_required',
        'record_resolved_versions',
        'record_installed_versions',
        'record_artifact_integrity',
        'record_installation_source'
    )) {
        Assert-Requirement (
            $v.$property -ceq $true
        ) "Mandatory version-policy protection disabled: $property"
    }

    Assert-Requirement (
        $v.automatic_security_downgrades -ceq $false
    ) 'Automatic security downgrades must remain prohibited.'

    $runtime = $r.runtime_verification

    Assert-Requirement (
        $runtime.enabled -ceq $false -and
        $runtime.explicit_approval_required -ceq $true -and
        $runtime.require_positive_command_execution -ceq $true -and
        $runtime.treat_missing_tools_as_failure -ceq $true -and
        $runtime.treat_ambiguous_results_as_failure -ceq $true -and
        $runtime.allow_unapproved_installation -ceq $false
    ) 'Invalid runtime-verification policy.'

    $installation = $r.installation

    Assert-Requirement (
        $installation.enabled -ceq $false -and
        $installation.explicit_approval_required -ceq $true -and
        $installation.fresh_machine_supported_target -ceq $true -and
        $installation.approved_sources_only -ceq $true -and
        $installation.require_resolved_installation_plan -ceq $true -and
        $installation.require_artifact_integrity_verification -ceq $true -and
        $installation.record_final_state -ceq $true -and
        $installation.reuse_temporary_pilot_artifacts -ceq $false -and
        $installation.automatic_downgrades -ceq $false -and
        $installation.production_apply_authorized -ceq $false
    ) 'Invalid installation safeguards.'

    Write-Output 'Approved stable version policy: VALID'
    Write-Output 'Compatibility review requirement: VALID'
    Write-Output 'Security downgrade protection: VALID'
    Write-Output 'Version and artifact recording policy: VALID'
    Write-Output 'Runtime verification: DISABLED'
    Write-Output 'Package installation: DISABLED'

    # --------------------------------------------------------
    # 6. Security and exit-code contract
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '[6/6] Validating security restrictions...'

    Assert-Requirement (
        $r.security.allow_offline_review -ceq $true
    ) 'Offline review is not authorized.'

    foreach ($property in @(
        'allow_distribution_execution',
        'allow_package_installation',
        'allow_downloads',
        'allow_distribution_modification',
        'allow_distribution_termination',
        'allow_wsl_shutdown',
        'allow_isolation_gate_bypass'
    )) {
        Assert-Requirement (
            $r.security.$property -ceq $false
        ) "Prohibited Phase 060 permission enabled: $property"
    }

    Assert-Requirement (
        $r.exit_codes.success -eq 0 -and
        $r.exit_codes.failure -eq 1 -and
        $r.exit_codes.reboot_required -eq 3010 -and
        $r.exit_codes.unknown -ceq 'FAIL_CLOSED'
    ) 'Invalid Phase 060 exit-code contract.'

    Write-Output 'Security restrictions: PASS'
    Write-Output 'Isolation-gate bypass: PROHIBITED'
    Write-Output 'Production apply: DISABLED'

    # --------------------------------------------------------
    # Final result
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '========================================'
    Write-Output 'PHASE 060 OFFLINE REVIEW: PASS'
    Write-Output '========================================'
    Write-Output 'Base toolchain requirements and policy are valid.'
    Write-Output ''
    Write-Output 'IMPORTANT:'
    Write-Output 'PHASE 050 RUNTIME GATE: NOT SATISFIED'
    Write-Output 'INSTALLED TOOLCHAIN: NOT VERIFIED'
    Write-Output 'VERSIONS RESOLVED: NONE'
    Write-Output 'INSTALLATION READINESS: NOT ESTABLISHED'
    Write-Output ''
    Write-Output 'WSL INVOCATION: NONE'
    Write-Output 'DOWNLOADS: NONE'
    Write-Output 'PACKAGE INSTALLATION: NONE'
    Write-Output 'DISTRIBUTION MODIFICATIONS: NONE'
    Write-Output 'PRODUCTION APPLY: DISABLED'

    exit 0
}
catch {
    [Console]::Error.WriteLine(
        "PHASE 060 OFFLINE REVIEW FAILED: $($_.Exception.Message)"
    )

    exit 1
}