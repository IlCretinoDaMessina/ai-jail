# =========================================================
# AI Jail - Phase 000 Requirements and Installation Review
# REVIEW ONLY - No installation or system modifications.
# =========================================================

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

try {
    $root = $PSScriptRoot

    $requirementsPath = Join-Path $root '000-requirements.json'
    $configPath       = Join-Path $root 'config.env'
    $commonPath       = Join-Path $root '_common.bat'

    Write-Output '[1/4] Checking installation structure...'

    foreach ($path in @(
        $requirementsPath,
        $configPath,
        $commonPath
    )) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Required file missing: $(Split-Path -Leaf $path)"
        }
    }

    Write-Output 'PASS'
    Write-Output ''

    # -----------------------------------------------------
    # Validate Phase 000 requirements.
    # -----------------------------------------------------

    Write-Output '[2/4] Validating Phase 000 requirements...'

    $r = Get-Content -LiteralPath $requirementsPath -Raw |
        ConvertFrom-Json -ErrorAction Stop

    if ($r.schema -ne 1) {
        throw 'Unsupported requirements schema.'
    }

    if ($r.phase -cne '000') {
        throw 'Requirements phase mismatch.'
    }

    if ($r.status -cne 'MODERNIZATION_CANDIDATE') {
        throw 'Unexpected modernization status.'
    }

    if ($r.execution.discover_phases -cne $true -or
        $r.execution.strict_ordering -cne $true -or
        $r.execution.stop_on_failure -cne $true -or
        $r.execution.idempotency_required -cne $true) {

        throw 'Required execution policy is missing or disabled.'
    }

    if ($r.exit_codes.success -ne 0 -or
        $r.exit_codes.failure -ne 1 -or
        $r.exit_codes.reboot_required -ne 3010 -or
        $r.exit_codes.unknown -cne 'FAIL_CLOSED') {

        throw 'Invalid exit-code contract.'
    }

    if ($r.requirements.per_phase_json_required -cne $true -or
        $r.requirements.validate_before_execution -cne $true -or
        $r.requirements.missing_requirements -cne 'FAIL_CLOSED' -or
        $r.requirements.unsupported_schema -cne 'FAIL_CLOSED') {

        throw 'Requirements validation policy mismatch.'
    }

    if ($r.approvals.explicit_installation_approval -cne $true -or
        $r.approvals.production_apply_authorized -cne $false -or
        $r.approvals.automatic_security_downgrades -cne $false) {

        throw 'Installation approval policy mismatch.'
    }

    if ($r.phase_skipping.default -cne 'DENY') {
        throw 'Phase skipping must default to DENY.'
    }

    Write-Output 'Requirements schema: PASS'
    Write-Output 'Exit-code contract: PASS'
    Write-Output 'Approval policy: PASS'
    Write-Output 'Production apply: DISABLED'
    Write-Output ''

    # -----------------------------------------------------
    # Parse config.env without executing its contents.
    # -----------------------------------------------------

    Write-Output '[3/4] Inspecting configuration...'

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

    $requiredKeys = @(
        'TARGET_DRIVE',
        'DISTRO',
        'BASE_DISTRO',
        'LINUX_USER',
        'MIN_WSL_VERSION',
        'MIN_FREE_GB',
        'ALLOW_HOSTS_OPENCODE',
        'ALLOW_HOSTS_COMFYUI',
        'ALLOW_HOSTS_INSTALL',
        'INSTALL_COMFYUI',
        'INSTALL_OPENCODE',
        'INSTALL_VSCODE',
        'ENABLE_NONO'
    )

    foreach ($key in $requiredKeys) {
        if (-not $config.ContainsKey($key)) {
            throw "Missing configuration key: $key"
        }

        if ([string]::IsNullOrWhiteSpace($config[$key])) {
            throw "Empty configuration value: $key"
        }
    }

    foreach ($key in @(
        'INSTALL_COMFYUI',
        'INSTALL_OPENCODE',
        'INSTALL_VSCODE',
        'ENABLE_NONO'
    )) {
        if ($config[$key] -cnotin @('0', '1')) {
            throw "Invalid feature flag: $key"
        }
    }

    Write-Output 'Configuration syntax: PASS'
    Write-Output 'Required keys: PASS'
    Write-Output 'Feature flags: PASS'
    Write-Output 'Configuration values are not printed.'
    Write-Output ''

    # -----------------------------------------------------
    # Discover phases without executing them.
    # -----------------------------------------------------

    Write-Output '[4/4] Reviewing installation phases...'

    $phases = @(
        Get-ChildItem -LiteralPath $root -Filter '*.bat' -File |
            Where-Object {
                $_.Name -cmatch '^([0-9]{3})-.+\.bat$' -and
                $_.Name -cnotmatch '^(000|999)-'
            } |
            Sort-Object Name
    )

    if ($phases.Count -eq 0) {
        Write-Output 'No installation phases added yet.'
    }

    $missing = @()

    foreach ($phase in $phases) {
        $number = $phase.Name.Substring(0, 3)
        $requirementsFile = Join-Path $root "$number-requirements.json"

        if (-not (Test-Path -LiteralPath $requirementsFile -PathType Leaf)) {
            Write-Output "$($phase.Name): REQUIREMENTS MISSING"
            $missing += $phase.Name
            continue
        }

        $phaseRequirements =
            Get-Content -LiteralPath $requirementsFile -Raw |
            ConvertFrom-Json -ErrorAction Stop

        if ($phaseRequirements.schema -ne 1 -or
            $phaseRequirements.phase -cne $number) {
            throw "Invalid requirements: $number-requirements.json"
        }

        Write-Output "$($phase.Name): REQUIREMENTS PRESENT"
    }

    if ($missing.Count -gt 0) {
        throw "$($missing.Count) installation phase(s) lack valid requirements."
    }

    Write-Output ''
    Write-Output '========================================'
    Write-Output 'PHASE 000 REVIEW: PASS'
    Write-Output '========================================'
    Write-Output "Installation phases discovered: $($phases.Count)"
    Write-Output 'Requirements validation: PASS'
    Write-Output ''
    Write-Output 'INSTALLATION: DISABLED'
    Write-Output 'PRODUCTION APPLY: DISABLED'
    Write-Output 'WSL INVOCATION: NONE'
    Write-Output 'DOWNLOADS: NONE'
    Write-Output 'SYSTEM MODIFICATIONS: NONE'

    exit 0
}
catch {
    [Console]::Error.WriteLine(
        "PHASE 000 REVIEW FAILED: $($_.Exception.Message)"
    )

    exit 1
}