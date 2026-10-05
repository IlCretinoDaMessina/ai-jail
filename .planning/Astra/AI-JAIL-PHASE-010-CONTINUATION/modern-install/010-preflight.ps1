# =========================================================
# AI Jail - Phase 010 Windows Preflight
# Read-only. No WSL execution or system modifications.
# =========================================================

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

try {
    $root = $PSScriptRoot

    $requirementsPath = Join-Path $root '010-requirements.json'
    $configPath = Join-Path $root 'config.env'

    # -----------------------------------------------------
    # 1. Administrator privileges
    # -----------------------------------------------------

    Write-Output '[1/6] Administrator privileges...'

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()

    $principal = [Security.Principal.WindowsPrincipal]::new(
        $identity
    )

    $isAdmin = $principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )

    if (-not $isAdmin) {
        throw 'Administrator privileges are required.'
    }

    Write-Output 'PASS'

    # -----------------------------------------------------
    # 2. Requirements and configuration
    # -----------------------------------------------------

    Write-Output '[2/6] Requirements and configuration...'

    foreach ($path in @($requirementsPath, $configPath)) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Required file missing: $(Split-Path -Leaf $path)"
        }
    }

    $r = Get-Content -LiteralPath $requirementsPath -Raw |
        ConvertFrom-Json -ErrorAction Stop

    if ($r.schema -ne 1 -or $r.phase -cne '010') {
        throw 'Invalid Phase 010 requirements schema or identity.'
    }

    if ($r.version_policy -cne 'security-baseline') {
        throw 'Unexpected version policy.'
    }

    if (
        $r.execution.read_only -cne $true -or
        $r.execution.administrator_required -cne $true -or
        $r.execution.standalone_auto_elevation -cne $true -or
        $r.execution.orchestrated_auto_elevation -cne $false -or
        $r.execution.fail_fast -cne $true
    ) {
        throw 'Invalid Phase 010 execution requirements.'
    }

    $expectedChecks = @(
        'administrator',
        'configuration',
        'linux_user',
        'virtualization',
        'disk_space',
        'internet'
    )

    if (
        (@($r.checks) -join ',') -cne
        ($expectedChecks -join ',')
    ) {
        throw 'Unexpected preflight check sequence.'
    }

    if (
        $r.configuration.source -cne 'config.env' -or
        $r.configuration.disk_threshold_key -cne 'MIN_FREE_GB' -or
        $r.configuration.disk_target_key -cne 'TARGET_DRIVE' -or
        $r.configuration.linux_user_key -cne 'LINUX_USER'
    ) {
        throw 'Invalid configuration contract.'
    }

    foreach ($property in @(
        'allow_wsl_execution',
        'allow_downloads',
        'allow_system_modifications',
        'allow_docker_dependency',
        'allow_security_bypass'
    )) {
        if ($r.security.$property -cne $false) {
            throw "Prohibited Phase 010 permission: $property"
        }
    }

    if (
        $r.exit_codes.success -ne 0 -or
        $r.exit_codes.failure -ne 1
    ) {
        throw 'Invalid Phase 010 exit-code contract.'
    }

    # Parse config.env as data. Never execute its contents.

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

    foreach ($key in @(
        'TARGET_DRIVE',
        'LINUX_USER',
        'MIN_FREE_GB'
    )) {
        if (-not $config.ContainsKey($key)) {
            throw "Missing configuration key: $key"
        }
    }

    if ($config['TARGET_DRIVE'] -cnotmatch '^[A-Z]:$') {
        throw 'TARGET_DRIVE must be a Windows drive letter.'
    }

    $minimumText = $config['MIN_FREE_GB']

    if ($minimumText -cnotmatch '^(0|[1-9][0-9]*)$') {
        throw 'MIN_FREE_GB must be a whole number without leading zeros.'
    }

    $minimumGB = [long]0

    if (-not [long]::TryParse(
        $minimumText,
        [ref]$minimumGB
    )) {
        throw 'MIN_FREE_GB is outside the supported numeric range.'
    }

    Write-Output 'PASS'

    # -----------------------------------------------------
    # 3. Linux username
    # -----------------------------------------------------

    Write-Output '[3/6] Linux username...'

    if ([string]::IsNullOrWhiteSpace($config['LINUX_USER'])) {
        throw 'LINUX_USER must not be empty.'
    }

    Write-Output 'PASS'

    # -----------------------------------------------------
    # 4. Virtualization
    # -----------------------------------------------------

    Write-Output '[4/6] Windows virtualization...'

    $computer = Get-CimInstance -ClassName Win32_ComputerSystem

    if ($computer.HypervisorPresent -ne $true) {
        throw 'Hypervisor not detected. Check firmware virtualization.'
    }

    Write-Output 'PASS'

    # -----------------------------------------------------
    # 5. Free disk space
    # -----------------------------------------------------

    Write-Output '[5/6] Available disk space...'

    $drive = [IO.DriveInfo]::new($config['TARGET_DRIVE'])

    if (-not $drive.IsReady) {
        throw 'Target drive is not ready.'
    }

    $availableGB = [math]::Floor(
        $drive.TotalFreeSpace / 1GB
    )

    if ($availableGB -lt $minimumGB) {
        throw (
            "Insufficient disk space. Available: $availableGB GB; " +
            "required: $minimumGB GB."
        )
    }

    Write-Output "PASS ($availableGB GB available)"

    # -----------------------------------------------------
    # 6. Internet connectivity
    # -----------------------------------------------------

    Write-Output '[6/6] Internet connectivity...'

    # Test-only bypass. Never allowed merely because
    # AIJAIL_TEST_SKIP_INTERNET exists in production.

    $skipInternet = (
        $env:AIJAIL_CI -eq '1' -and
        $env:AIJAIL_TEST_SKIP_INTERNET -eq '1'
    )

    if ($skipInternet) {
        Write-Output 'SKIPPED (CI test mode)'
    }
    else {
        # Microsoft's NCSI endpoint intentionally uses HTTP.

        Invoke-WebRequest `
            -Uri 'http://www.msftconnecttest.com/connecttest.txt' `
            -UseBasicParsing `
            -TimeoutSec 10 `
            -ErrorAction Stop | Out-Null

        Write-Output 'PASS'
    }

    Write-Output ''
    Write-Output '========================================'
    Write-Output 'PHASE 010: PASS'
    Write-Output '========================================'
    Write-Output 'All required Windows preflight checks passed.'
    Write-Output 'No installation or system modifications performed.'

    exit 0
}
catch {
    [Console]::Error.WriteLine(
        "PHASE 010 FAILED: $($_.Exception.Message)"
    )

    exit 1
}