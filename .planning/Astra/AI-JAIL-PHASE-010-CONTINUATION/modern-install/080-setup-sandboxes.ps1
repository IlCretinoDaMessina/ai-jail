
# ============================================================
# AI Jail - Phase 080 Sandbox Workspace and Launcher Setup
#
# MODE: OFFLINE_REVIEW_ONLY
#
# This companion has NO apply implementation.
# Direct -Mode '--apply' execution is rejected.
#
# No WSL execution, downloads, file creation, secret access,
# installation, distribution changes, or state writes.
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

function Assert-TrueProperties {
    param(
        [object]$Source,
        [string[]]$Names,
        [string]$Description
    )

    foreach ($name in $Names) {
        Assert-Requirement (
            $Source.$name -ceq $true
        ) "Required ${Description} protection disabled: $name"
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
            $Source.$name -ceq $false
        ) "Prohibited ${Description} permission enabled: $name"
    }
}

function Read-Configuration {
    param(
        [string]$Path,
        [string[]]$ExpectedKeys
    )

    $result = @{}
    $allowed = @{}

    foreach ($key in $ExpectedKeys) {
        $allowed[$key] = $true
    }

    foreach ($line in [IO.File]::ReadAllLines($Path)) {
        if ($line -ceq '' -or $line.StartsWith('#')) {
            continue
        }

        if ($line -cnotmatch '^([A-Z][A-Z0-9_]*)=(.*)$') {
            throw 'Malformed config.env line.'
        }

        $key = $Matches[1]
        $value = $Matches[2]

        Assert-Requirement (
            $allowed.ContainsKey($key)
        ) "Unknown configuration key: $key"

        Assert-Requirement (
            -not $result.ContainsKey($key)
        ) "Duplicate configuration key: $key"

        $result[$key] = $value
    }

    foreach ($key in $ExpectedKeys) {
        Assert-Requirement (
            $result.ContainsKey($key)
        ) "Missing configuration key: $key"
    }

    return $result
}

function Get-ValidatedHosts {
    param(
        [AllowEmptyString()][string]$Value,
        [string]$Key
    )

    if ($Value -ceq '') {
        return
    }

    $seen = @{}

    foreach ($hostName in $Value.Split(';')) {

        # At least two DNS labels; lowercase ASCII only.
        # No IP literals, ports, spaces, shell metacharacters,
        # empty labels or wildcard entries.

        $dnsPattern = (
            '^(?=.{1,253}$)' +
            '[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?' +
            '(?:\.[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?)+$'
        )

        Assert-Requirement (
            $hostName -cmatch $dnsPattern
        ) "Invalid DNS hostname in $Key."

        $labels = @($hostName.Split('.'))

        Assert-Requirement (
            $labels[-1] -cmatch '[a-z]'
        ) "Top-level DNS label must contain a letter in $Key."

        $parsedAddress = $null

        Assert-Requirement (
            -not [Net.IPAddress]::TryParse(
                $hostName,
                [ref]$parsedAddress
            )
        ) "IP literals are forbidden in $Key."

        # Reject legacy numeric/hexadecimal IP representations.

        $legacyIP = $true

        foreach ($label in $labels) {
            if ($label -cnotmatch '^(?:[0-9]+|0x[0-9a-f]+)$') {
                $legacyIP = $false
                break
            }
        }

        Assert-Requirement (
            -not $legacyIP
        ) "Legacy IP representation forbidden in $Key."

        Assert-Requirement (
            -not $seen.ContainsKey($hostName)
        ) "Duplicate hostname in $Key."

        $seen[$hostName] = $true

        Write-Output $hostName
    }
}

function Get-NetworkFlags {
    param([string[]]$Hosts)

    if ($Hosts.Count -eq 0) {
        return '--no-network'
    }

    return (
        ($Hosts | ForEach-Object { '--allow-host ' + $_ }) -join ' '
    )
}

function Get-ScriptBytes {
    param([string]$Text)

    $normalized = $Text.Replace("`r`n", "`n")

    Assert-Requirement (
        -not $normalized.Contains("`r") -and
        -not $normalized.Contains([char]0) -and
        -not $normalized.Contains([char]0xFEFF)
    ) 'Generated wrapper contains forbidden bytes or characters.'

    if (-not $normalized.EndsWith("`n")) {
        $normalized += "`n"
    }

    $utf8 = New-Object Text.UTF8Encoding($false)

    return ,$utf8.GetBytes($normalized)
}

function Get-Sha256Hex {
    param([byte[]]$Bytes)

    $algorithm = [Security.Cryptography.SHA256]::Create()

    try {
        $hash = $algorithm.ComputeHash($Bytes)
    }
    finally {
        $algorithm.Dispose()
    }

    return (-join @(
        $hash | ForEach-Object { $_.ToString('x2') }
    ))
}

try {

    # --------------------------------------------------------
    # 0. Enforce review-only execution before any other work.
    # --------------------------------------------------------

    if ($Mode -cne '--review') {
        throw (
            "Unsupported mode: $Mode. " +
            'Phase 080 apply and runtime execution are disabled.'
        )
    }

    Assert-Requirement (
        $args.Count -eq 0
    ) 'Unexpected additional arguments.'

    $root = $PSScriptRoot

    $requirementsPath = Join-Path $root '080-requirements.json'
    $configPath = Join-Path $root 'config.env'

    Write-Output '[1/6] Validating Phase 080 review mode and files...'

    foreach ($path in @($requirementsPath, $configPath)) {
        Assert-Requirement (
            Test-Path -LiteralPath $path -PathType Leaf
        ) "Required file missing: $(Split-Path -Leaf $path)"
    }

    $r = Get-Content -LiteralPath $requirementsPath -Raw |
        ConvertFrom-Json -ErrorAction Stop

    Assert-Requirement (
        $r.schema -eq 1 -and
        $r.phase -ceq '080' -and
        $r.status -ceq 'MODERNIZATION_CANDIDATE' -and
        $r.mode -ceq 'OFFLINE_REVIEW_ONLY'
    ) 'Invalid Phase 080 requirements identity or mode.'

    Assert-Requirement (
        $r.review.enabled -ceq $true -and
        $r.review.offline_only -ceq $true -and
        $r.review.invoke_wsl -ceq $false -and
        $r.review.modify_files -ceq $false
    ) 'Invalid offline review restrictions.'

    Assert-TrueProperties $r.review @(
        'validate_configuration',
        'validate_allowlists',
        'generate_proposed_wrappers_in_memory',
        'validate_generated_wrapper_invariants',
        'validate_apply_payload_structure',
        'print_proposed_operations'
    ) 'review'

    Write-Output 'Requirements identity: PASS'
    Write-Output 'Execution mode: OFFLINE_REVIEW_ONLY'

    # --------------------------------------------------------
    # 2. Exact configuration schema and approved target
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '[2/6] Validating configuration and network allowlists...'

    Assert-Requirement (
        $r.configuration.source -ceq 'config.env' -and
        $r.configuration.target_distro -ceq 'ai-jail' -and
        $r.configuration.target_user -ceq 'aijail'
    ) 'Unexpected Phase 080 target or configuration source.'

    Assert-TrueProperties $r.configuration @(
        'require_exact_documented_schema',
        'reject_unknown_keys',
        'reject_missing_keys',
        'reject_duplicate_keys',
        'reject_malformed_values'
    ) 'configuration'

    $expectedKeys = @(
        'TARGET_DRIVE',
        'DISTRO',
        'BASE_DISTRO',
        'LINUX_USER',
        'MIN_WSL_VERSION',
        'ALLOW_HOSTS_OPENCODE',
        'ALLOW_HOSTS_COMFYUI',
        'ALLOW_HOSTS_INSTALL',
        'MIN_FREE_GB',
        'INSTALL_COMFYUI',
        'INSTALL_OPENCODE',
        'INSTALL_VSCODE',
        'ENABLE_NONO'
    )

    $config = Read-Configuration $configPath $expectedKeys

    Assert-Requirement (
        $config['TARGET_DRIVE'] -cmatch '^[A-Z]:$'
    ) 'Invalid TARGET_DRIVE.'

    Assert-Requirement (
        $config['DISTRO'] -ceq 'ai-jail'
    ) 'Unexpected target distribution.'

    Assert-Requirement (
        $config['LINUX_USER'] -ceq 'aijail'
    ) 'Unexpected Linux user.'

    Assert-Requirement (
        $config['BASE_DISTRO'] -cmatch
            '^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$'
    ) 'Invalid BASE_DISTRO.'

    $minimumVersion = $config['MIN_WSL_VERSION']

    Assert-Requirement (
        $minimumVersion -cmatch
            '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$'
    ) 'Invalid MIN_WSL_VERSION format.'

    try {
        [void][version]::Parse("$minimumVersion.0")
    }
    catch {
        throw 'Invalid MIN_WSL_VERSION numeric values.'
    }

    Assert-Requirement (
        $config['MIN_FREE_GB'] -cmatch '^[1-9][0-9]*$'
    ) 'Invalid MIN_FREE_GB.'

    $freeGB = 0

    Assert-Requirement (
        [int]::TryParse(
            $config['MIN_FREE_GB'],
            [ref]$freeGB
        )
    ) 'MIN_FREE_GB exceeds the supported numeric range.'

    foreach ($key in @(
        'INSTALL_COMFYUI',
        'INSTALL_OPENCODE',
        'INSTALL_VSCODE',
        'ENABLE_NONO'
    )) {
        Assert-Requirement (
            $config[$key] -cmatch '^[01]$'
        ) "Invalid feature flag: $key"
    }

    $allowlistPolicy = $r.allowlists

    Assert-TrueProperties $allowlistPolicy @(
        'require_lowercase_ascii_dns',
        'require_alphabetic_top_level_label',
        'reject_duplicates',
        'reject_wildcards',
        'reject_ports',
        'reject_metacharacters',
        'reject_canonical_ip_literals',
        'reject_legacy_ip_literals'
    ) 'allowlist'

    Assert-Requirement (
        $allowlistPolicy.minimum_labels -eq 2 -and
        $allowlistPolicy.missing_list -ceq 'FAIL' -and
        $allowlistPolicy.empty_list -ceq '--no-network'
    ) 'Invalid allowlist policy.'

    $openHosts = @(
        Get-ValidatedHosts `
            $config['ALLOW_HOSTS_OPENCODE'] `
            'ALLOW_HOSTS_OPENCODE'
    )

    $comfyHosts = @(
        Get-ValidatedHosts `
            $config['ALLOW_HOSTS_COMFYUI'] `
            'ALLOW_HOSTS_COMFYUI'
    )

    $installHosts = @(
        Get-ValidatedHosts `
            $config['ALLOW_HOSTS_INSTALL'] `
            'ALLOW_HOSTS_INSTALL'
    )

    Write-Output 'Exact configuration schema: PASS'
    Write-Output 'Allowlists: PASS'
    Write-Output "OpenCode entries: $($openHosts.Count)"
    Write-Output "ComfyUI entries:  $($comfyHosts.Count)"
    Write-Output "Install entries:  $($installHosts.Count)"
    Write-Output 'Secrets and environment-file contents were not read.'

    # --------------------------------------------------------
    # 3. Validate dependency declarations.
    # These declarations are NOT proof of runtime completion.
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '[3/6] Validating runtime dependency policy...'

    Assert-TrueProperties $r.dependencies @(
        'require_phase_030_verified',
        'require_phase_040_configuration_applied',
        'require_phase_050_runtime_pass',
        'require_phase_060_toolchain_verified',
        'require_phase_070_sandbox_verified'
    ) 'dependency'

    Assert-FalseProperties $r.dependencies @(
        'accept_offline_reviews_as_runtime_proof',
        'allow_implicit_apply_from_orchestrator'
    ) 'dependency'

    Write-Output 'Mandatory runtime dependencies: DECLARED'
    Write-Output 'Phase 050 runtime proof: NOT ESTABLISHED'
    Write-Output 'Phase 070 sandbox verification: NOT ESTABLISHED'
    Write-Output 'Offline reviews authorize application: NO'

    # --------------------------------------------------------
    # 4. Validate launcher declarations and generate proposals.
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '[4/6] Validating and generating proposed launchers...'

    $launcherPolicy = $r.launchers

    Assert-ExactList `
        -Actual @($launcherPolicy.names) `
        -Expected @(
            'jail-shell',
            'jail-opencode',
            'jail-comfyui'
        ) `
        -Description 'launcher names'

    Assert-ExactList `
        -Actual @($launcherPolicy.required_flags) `
        -Expected @(
            '--clean',
            '--no-save-config',
            '--private-home',
            '--hide-dotdir .secrets',
            '--rw-map',
            '--terminal-passthrough',
            '--exec'
        ) `
        -Description 'required launcher flags'

    Assert-Requirement (
        $launcherPolicy.parser -ceq 'TESTED_OPTION_C' -and
        $launcherPolicy.shell_network_policy -ceq '--no-network' -and
        $launcherPolicy.opencode_network_source -ceq
            'ALLOW_HOSTS_OPENCODE' -and
        $launcherPolicy.comfyui_network_source -ceq
            'ALLOW_HOSTS_COMFYUI' -and
        $launcherPolicy.opencode_env_file -ceq
            '/home/aijail/.secrets/opencode.env' -and
        $launcherPolicy.comfyui_env_file -ceq
            '/home/aijail/.secrets/comfyui.env' -and
        $launcherPolicy.encoding -ceq 'UTF-8_NO_BOM' -and
        $launcherPolicy.line_endings -ceq 'LF' -and
        $launcherPolicy.mode -ceq '0700' -and
        $launcherPolicy.owner -ceq 'aijail'
    ) 'Invalid launcher-generation contract.'

    # Preserve the original reviewed Option C parser.
    # This template remains in memory throughout the review.

    $template = @'
#!/bin/bash
set -e
usage() { echo "Usage: NAME [-c COMMAND [ARG...]] | [-- COMMAND [ARG...]]" >&2; exit 64; }
cd /home/aijail/projects/PROJECT
case "$#:$1" in
  0:) set -- bash ;;
  *:-c) [ "$#" -ge 2 ] || usage; set -- bash "$@" ;;
  *:--) shift; [ "$#" -ge 1 ] || usage ;;
  *) usage ;;
esac
exec /home/aijail/.cargo/bin/ai-jail --clean --no-save-config --private-home --hide-dotdir .secrets --rw-map /home/aijail/projects/PROJECT NETWORK --terminal-passthrough --exec -- "$@"
'@

    $specs = @(
        [pscustomobject]@{
            Name = 'jail-shell'
            Project = 'scratch'
            Network = '--no-network'
            Secret = ''
        },
        [pscustomobject]@{
            Name = 'jail-opencode'
            Project = 'opencode-work'
            Network = Get-NetworkFlags $openHosts
            Secret = ' --env-from-file /home/aijail/.secrets/opencode.env'
        },
        [pscustomobject]@{
            Name = 'jail-comfyui'
            Project = 'comfyui'
            Network = Get-NetworkFlags $comfyHosts
            Secret = ' --env-from-file /home/aijail/.secrets/comfyui.env'
        }
    )

    $scripts = @{}
    $hashes = @{}

    foreach ($spec in $specs) {
        $script = $template.Replace(
            'NAME', $spec.Name
        ).Replace(
            'PROJECT', $spec.Project
        ).Replace(
            'NETWORK', ($spec.Network + $spec.Secret)
        )

        $script += "`n"

        $bytes = Get-ScriptBytes $script

        Assert-Requirement (
            $bytes.Length -gt 0 -and
            $bytes[0] -eq 35 -and
            $bytes[1] -eq 33
        ) "Invalid wrapper header: $($spec.Name)"

        $requiredCommand = (
            'cd /home/aijail/projects/' + $spec.Project
        )

        Assert-Requirement (
            $script.Contains($requiredCommand)
        ) "Incorrect launcher project: $($spec.Name)"

        Assert-Requirement (
            $script.Contains(
                '--rw-map /home/aijail/projects/' + $spec.Project
            )
        ) "Incorrect launcher rw-map: $($spec.Name)"

        Assert-Requirement (
            $script.Contains($spec.Network)
        ) "Incorrect launcher network policy: $($spec.Name)"

        Assert-Requirement (
            $script.Contains('--clean --no-save-config') -and
            $script.Contains('--private-home --hide-dotdir .secrets') -and
            $script.Contains('--terminal-passthrough --exec -- "$@"')
        ) "Mandatory launcher flags missing: $($spec.Name)"

        Assert-Requirement (
            -not $script.Contains('PROJECT') -and
            -not $script.Contains('NETWORK')
        ) "Unresolved launcher placeholder: $($spec.Name)"

        $scripts[$spec.Name] = $script
        $hashes[$spec.Name] = Get-Sha256Hex $bytes

        Assert-Requirement (
            $hashes[$spec.Name] -cmatch '^[0-9a-f]{64}$'
        ) "Invalid proposed wrapper hash: $($spec.Name)"
    }

    Write-Output 'Option C launcher parser: VALIDATED'
    Write-Output 'Launcher network mapping: VALIDATED'
    Write-Output 'Proposed wrapper encoding: UTF-8, LF, no BOM'
    Write-Output 'Proposed wrapper count: 3'
    Write-Output 'All proposed wrappers generated in memory.'

    # --------------------------------------------------------
    # 5. Managed state, payload and transaction requirements.
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '[5/6] Validating proposed state and transaction...'

    $managed = $r.managed_state

    Assert-ExactList `
        -Actual @($managed.projects) `
        -Expected @(
            'scratch',
            'opencode-work',
            'comfyui'
        ) `
        -Description 'managed project directories'

    Assert-TrueProperties $managed @(
        'create_missing_git_repositories',
        'create_initial_empty_commits_when_required',
        'preserve_existing_repositories',
        'preserve_existing_project_data',
        'reject_managed_path_symlinks',
        'validate_existing_ownership',
        'preserve_existing_secret_bytes',
        'never_log_secrets'
    ) 'managed-state'

    Assert-Requirement (
        $managed.secret_directory_mode -ceq '0700' -and
        $managed.secret_file_mode -ceq '0600'
    ) 'Invalid secrets permission policy.'

    $payload = $r.payload_integrity

    Assert-Requirement (
        $payload.transport -ceq 'BASE64_UTF8_LF'
    ) 'Invalid proposed payload transport.'

    Assert-TrueProperties $payload @(
        'verify_sha256_inside_linux',
        'validate_shell_syntax_before_execution'
    ) 'payload'

    Assert-FalseProperties $payload @(
        'allow_powershell_text_pipeline_for_payload_transport'
    ) 'payload'

    $transaction = $r.transaction

    Assert-TrueProperties $transaction @(
        'private_owned_staging',
        'stage_all_three_wrappers_before_promotion',
        'validate_staged_hashes',
        'validate_staged_syntax',
        'preserve_existing_wrappers_for_rollback',
        'rollback_on_promotion_failure',
        'report_rollback_failure',
        'never_delete_unrelated_files'
    ) 'transaction'

    # This validates the declared apply-payload STRUCTURE.
    # It does not generate or execute an installation payload.
    # An executable payload requires a later independent review.

    $plannedOperations = @(
        'Validate runtime dependency completion and isolation',
        'Validate existing path types, ownership and permissions',
        'Verify AI Jail version and required command-line flags',
        'Stage the three proposed wrappers privately',
        'Verify staged UTF-8/LF bytes, hashes and shell syntax',
        'Create missing project repositories without resetting data',
        'Create missing secret placeholders without reading old bytes',
        'Back up existing managed wrappers',
        'Promote all wrappers with rollback on failure',
        'Verify promoted wrappers and final managed state'
    )

    Assert-Requirement (
        $plannedOperations.Count -eq 10 -and
        $hashes.Count -eq 3 -and
        $scripts.Count -eq 3
    ) 'Incomplete proposed installation structure.'

    Write-Output 'Managed paths and secrets policy: VALID'
    Write-Output 'Payload-integrity requirements: VALID'
    Write-Output 'Transaction and rollback requirements: VALID'
    Write-Output 'Proposed operation structure: VALID'
    Write-Output 'Executable apply payload: NOT GENERATED'

    # --------------------------------------------------------
    # 6. Acceptance tests, security and approval restrictions.
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '[6/6] Validating acceptance and approval gates...'

    Assert-TrueProperties $r.acceptance @(
        'static_validation_required',
        'invalid_config_matrix_required',
        'fresh_install_disposable_distro_only',
        'disposable_test_requires_explicit_approval',
        'existing_state_rerun_required',
        'partial_state_recovery_required',
        'forced_failure_rollback_required',
        'post_install_isolation_required',
        'cross_project_access_tests_required',
        'secret_isolation_required',
        'exit_propagation_required',
        'git_clean_required',
        'no_unexpected_ai_jail_files',
        'direct_dns_and_tcp_are_negative_tests',
        'require_connect_denial_for_unapproved_destinations'
    ) 'acceptance'

    Assert-Requirement (
        $r.acceptance.filtered_network_client -ceq
            'PROXY_AWARE_HTTPS_CONNECT'
    ) 'Invalid filtered-network acceptance policy.'

    Assert-Requirement (
        $r.installation.enabled -ceq $false -and
        $r.installation.explicit_approval_required -ceq $true -and
        $r.installation.runtime_dependencies_must_pass -ceq $true -and
        $r.installation.approved_installation_plan_required -ceq $true -and
        $r.installation.production_apply_authorized -ceq $false
    ) 'Invalid installation approval policy.'

    Assert-Requirement (
        $r.security.allow_offline_review -ceq $true
    ) 'Offline review is not authorized.'

    Assert-FalseProperties $r.security @(
        'allow_distribution_execution',
        'allow_distribution_modification',
        'allow_direct_powershell_apply',
        'allow_implicit_orchestrator_apply',
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
    ) 'Invalid Phase 080 exit-code contract.'

    Write-Output 'Acceptance requirements: VALID'
    Write-Output 'Network CONNECT test requirements: VALID'
    Write-Output 'Direct PowerShell apply: DISABLED'
    Write-Output 'Implicit orchestrator apply: DISABLED'
    Write-Output 'Production apply: DISABLED'

    # --------------------------------------------------------
    # Review output.
    # --------------------------------------------------------

    Write-Output ''
    Write-Output '========================================'
    Write-Output 'PROPOSED LAUNCHERS'
    Write-Output '========================================'

    foreach ($spec in $specs) {
        Write-Output ''
        Write-Output "--- $($spec.Name) ---"
        Write-Output $scripts[$spec.Name]
        Write-Output "Proposed SHA-256: $($hashes[$spec.Name])"
    }

    Write-Output ''
    Write-Output '========================================'
    Write-Output 'PROPOSED OPERATIONS - NOT EXECUTED'
    Write-Output '========================================'

    foreach ($operation in $plannedOperations) {
        Write-Output "- $operation"
    }

    Write-Output ''
    Write-Output '========================================'
    Write-Output 'PHASE 080 OFFLINE REVIEW: PASS'
    Write-Output '========================================'
    Write-Output 'Requirements and proposed launcher contents are valid.'
    Write-Output ''
    Write-Output 'IMPORTANT:'
    Write-Output 'PHASE 050 RUNTIME GATE: NOT SATISFIED'
    Write-Output 'PHASE 070 SANDBOX VERIFICATION: NOT ESTABLISHED'
    Write-Output 'EXECUTABLE APPLY PAYLOAD: NOT GENERATED'
    Write-Output 'INSTALLATION READINESS: NOT ESTABLISHED'
    Write-Output ''
    Write-Output 'WSL INVOCATION: NONE'
    Write-Output 'DOWNLOADS: NONE'
    Write-Output 'FILES MODIFIED: NONE'
    Write-Output 'PRODUCTION APPLY: DISABLED'

    exit 0
}
catch {
    [Console]::Error.WriteLine(
        "PHASE 080 OFFLINE REVIEW FAILED: $($_.Exception.Message)"
    )

    exit 1
}
