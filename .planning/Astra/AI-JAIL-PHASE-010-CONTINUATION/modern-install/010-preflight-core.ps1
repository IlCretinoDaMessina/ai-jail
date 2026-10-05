# ============================================================
# AI Jail - Phase 010 read-only preflight core
# Windows PowerShell 5.1 compatible.
#
# This file defines collectors and pure decision functions.
# Loading it performs no Windows, network or WSL probes.
#
# Deliverable A does not authorize a public live execution route.
# ============================================================

function New-Aij010Check {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Status,

        [Parameter(Mandatory = $true)]
        [string]$Decision,

        [Parameter(Mandatory = $true)]
        [string]$Method,

        [Parameter()]
        [AllowNull()]
        $Observation,

        [Parameter()]
        [string[]]$Reasons = @()
    )

    [pscustomobject][ordered]@{
        Status      = $Status
        Decision    = $Decision
        Method      = $Method
        Observation = $Observation
        Reasons     = @($Reasons)
    }
}

function ConvertTo-Aij010Operation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        throw 'Phase 010 operation must not be empty.'
    }

    switch ($Value.ToUpperInvariant()) {
        'REVIEW' {
            return 'REVIEW'
        }

        'COLLECTOFFLINE' {
            return 'COLLECT_OFFLINE'
        }

        'COLLECT_OFFLINE' {
            return 'COLLECT_OFFLINE'
        }

        'COLLECTONLINE' {
            return 'COLLECT_ONLINE'
        }

        'COLLECT_ONLINE' {
            return 'COLLECT_ONLINE'
        }

        default {
            throw "Unsupported Phase 010 operation: $Value."
        }
    }
}

function Get-Aij010RequiredProperty {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Object,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    $property = $Object.PSObject.Properties[$Name]

    if ($null -eq $property) {
        throw "Missing required Phase 010 property: $Label."
    }

    return $property.Value
}

function Assert-Aij010Boolean {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Object,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [bool]$Expected,

        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    $value = Get-Aij010RequiredProperty `
        -Object $Object `
        -Name $Name `
        -Label $Label

    if ($value -isnot [bool] -or $value -ne $Expected) {
        throw "Invalid Phase 010 boolean contract: $Label."
    }
}

function Assert-Aij010Sequence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Actual,

        [Parameter(Mandatory = $true)]
        [object[]]$Expected,

        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    if ($Actual.Count -ne $Expected.Count) {
        throw "Invalid Phase 010 sequence: $Label."
    }

    for ($i = 0; $i -lt $Expected.Count; $i++) {
        if ([string]$Actual[$i] -cne [string]$Expected[$i]) {
            throw "Invalid Phase 010 sequence: $Label."
        }
    }
}

function Assert-Aij010OrdinaryFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not [IO.File]::Exists($Path)) {
        throw "Required file missing: $([IO.Path]::GetFileName($Path))."
    }

    $attributes = [IO.File]::GetAttributes($Path)

    if (($attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Reparse-point source file rejected: $([IO.Path]::GetFileName($Path))."
    }
}

function Read-Aij010Requirements {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    Assert-Aij010OrdinaryFile -Path $Path

    $resolved = @(Resolve-Path -LiteralPath $Path -ErrorAction Stop)

    if ($resolved.Count -ne 1) {
        throw 'Phase 010 requirements path is ambiguous.'
    }

    $encoding = New-Object System.Text.UTF8Encoding($false, $true)
    [byte[]]$bytes = [IO.File]::ReadAllBytes($resolved[0].ProviderPath)
    $text = $encoding.GetString($bytes)

    if ($text.StartsWith(
        [string][char]0xFEFF,
        [StringComparison]::Ordinal
    )) {
        $text = $text.Substring(1)
    }

    if ($text.IndexOf([char]0xFEFF) -ge 0) {
        throw 'Unexpected Unicode BOM in Phase 010 requirements.'
    }

    $r = $text | ConvertFrom-Json -ErrorAction Stop

    if ($r -isnot [pscustomobject]) {
        throw 'Invalid Phase 010 requirements document.'
    }

    if (
        (Get-Aij010RequiredProperty $r 'schema' 'schema') -ne 1 -or
        (Get-Aij010RequiredProperty $r 'contract_version' 'contract_version') -ne 2 -or
        (Get-Aij010RequiredProperty $r 'phase' 'phase') -cne '010' -or
        (Get-Aij010RequiredProperty $r 'name' 'name') -cne 'Windows Preflight' -or
        (Get-Aij010RequiredProperty $r 'version_policy' 'version_policy') -cne 'security-baseline'
    ) {
        throw 'Invalid Phase 010 requirements identity.'
    }

    if ($null -ne $r.PSObject.Properties['mode']) {
        throw 'Phase 010 must remain a legacy read-only requirements document.'
    }

    $execution = Get-Aij010RequiredProperty $r 'execution' 'execution'

    Assert-Aij010Boolean $execution 'read_only' $true `
        'execution.read_only'
    Assert-Aij010Boolean $execution 'administrator_required' $true `
        'execution.administrator_required'
    Assert-Aij010Boolean $execution 'standalone_auto_elevation' $false `
        'execution.standalone_auto_elevation'
    Assert-Aij010Boolean $execution 'orchestrated_auto_elevation' $false `
        'execution.orchestrated_auto_elevation'
    Assert-Aij010Boolean $execution 'public_live_collection_authorized' $false `
        'execution.public_live_collection_authorized'
    Assert-Aij010Boolean $execution 'fail_closed' $true `
        'execution.fail_closed'

    $profiles = Get-Aij010RequiredProperty $r 'profiles' 'profiles'

    foreach ($name in @('review', 'collect_offline', 'collect_online')) {
        $profile = Get-Aij010RequiredProperty `
            $profiles $name "profiles.$name"

        if ($profile -isnot [pscustomobject]) {
            throw "Invalid Phase 010 profile: $name."
        }
    }

    Assert-Aij010Boolean $profiles.review `
        'live_windows_probes' $false `
        'profiles.review.live_windows_probes'
    Assert-Aij010Boolean $profiles.review `
        'administrator_probe' $false `
        'profiles.review.administrator_probe'
    Assert-Aij010Boolean $profiles.review `
        'network_probe' $false `
        'profiles.review.network_probe'
    Assert-Aij010Boolean $profiles.review `
        'public_entry_authorized' $true `
        'profiles.review.public_entry_authorized'

    Assert-Aij010Boolean $profiles.collect_offline `
        'live_windows_probes' $true `
        'profiles.collect_offline.live_windows_probes'
    Assert-Aij010Boolean $profiles.collect_offline `
        'administrator_probe' $true `
        'profiles.collect_offline.administrator_probe'
    Assert-Aij010Boolean $profiles.collect_offline `
        'network_probe' $false `
        'profiles.collect_offline.network_probe'
    Assert-Aij010Boolean $profiles.collect_offline `
        'public_entry_authorized' $false `
        'profiles.collect_offline.public_entry_authorized'

    Assert-Aij010Boolean $profiles.collect_online `
        'live_windows_probes' $true `
        'profiles.collect_online.live_windows_probes'
    Assert-Aij010Boolean $profiles.collect_online `
        'administrator_probe' $true `
        'profiles.collect_online.administrator_probe'
    Assert-Aij010Boolean $profiles.collect_online `
        'network_probe' $true `
        'profiles.collect_online.network_probe'
    Assert-Aij010Boolean $profiles.collect_online `
        'public_entry_authorized' $false `
        'profiles.collect_online.public_entry_authorized'

    Assert-Aij010Sequence `
        -Actual @($r.checks) `
        -Expected @(
            'administrator',
            'configuration',
            'windows_platform',
            'linux_user',
            'virtualization',
            'storage',
            'wsl_readiness',
            'reboot_observations',
            'internet'
        ) `
        -Label 'checks'

    $configuration = Get-Aij010RequiredProperty `
        $r 'configuration' 'configuration'

    if (
        $configuration.source -cne 'config.env' -or
        $configuration.disk_threshold_key -cne 'MIN_FREE_GB' -or
        $configuration.disk_target_key -cne 'TARGET_DRIVE' -or
        $configuration.linux_user_key -cne 'LINUX_USER' -or
        $configuration.wsl_minimum_version_key -cne 'MIN_WSL_VERSION'
    ) {
        throw 'Invalid Phase 010 configuration contract.'
    }

    $platform = Get-Aij010RequiredProperty $r 'platform' 'platform'

    if (
        $platform.policy_name -cne 'WSL2_UPSTREAM_TECHNICAL_PREREQUISITE' -or
        $platform.policy_kind -cne 'NOT_AI_JAIL_PRODUCT_SUPPORT_POLICY'
    ) {
        throw 'Invalid Phase 010 platform-policy classification.'
    }

    Assert-Aij010Sequence `
        -Actual @($platform.allowed_architectures) `
        -Expected @('X64', 'ARM64') `
        -Label 'platform.allowed_architectures'

    if (
        $platform.minimum_build_by_architecture.X64 -ne 18362 -or
        $platform.minimum_build_by_architecture.ARM64 -ne 19041 -or
        $platform.x64_minimum_ubr -ne 1049
    ) {
        throw 'Invalid WSL2 technical prerequisite contract.'
    }

    Assert-Aij010Sequence `
        -Actual @($platform.x64_builds_requiring_minimum_ubr) `
        -Expected @(18362, 18363) `
        -Label 'platform.x64_builds_requiring_minimum_ubr'

    $storage = Get-Aij010RequiredProperty $r 'storage' 'storage'

    Assert-Aij010Boolean $storage 'require_fixed_local_volume' $true `
        'storage.require_fixed_local_volume'
    Assert-Aij010Boolean $storage 'compare_available_free_space' $true `
        'storage.compare_available_free_space'
    Assert-Aij010Boolean $storage 'observe_total_free_space_only' $true `
        'storage.observe_total_free_space_only'
    Assert-Aij010Boolean $storage 'reject_reparse_target_ancestors' $true `
        'storage.reject_reparse_target_ancestors'

    if ($storage.existing_target_policy -cne 'MANUAL_ACTION_REQUIRED') {
        throw 'Invalid Phase 010 existing-target policy.'
    }

    $wsl = Get-Aij010RequiredProperty $r 'wsl_readiness' 'wsl_readiness'

    Assert-Aij010Boolean $wsl 'allow_wsl_execution' $false `
        'wsl_readiness.allow_wsl_execution'

    if (
        $wsl.package_name -cne
            'MicrosoftCorporationII.WindowsSubsystemForLinux' -or
        $wsl.executable_relative_path -cne 'System32\wsl.exe' -or
        $wsl.minimum_version_key -cne 'MIN_WSL_VERSION'
    ) {
        throw 'Invalid Phase 010 WSL-readiness contract.'
    }

    Assert-Aij010Sequence `
        -Actual @($wsl.optional_features) `
        -Expected @(
            'Microsoft-Windows-Subsystem-Linux',
            'VirtualMachinePlatform'
        ) `
        -Label 'wsl_readiness.optional_features'

    $reboot = Get-Aij010RequiredProperty `
        $r 'reboot_observations' 'reboot_observations'

    Assert-Aij010Sequence `
        -Actual @($reboot.indicators) `
        -Expected @(
            'CBS_REBOOT_PENDING',
            'WINDOWS_UPDATE_REBOOT_REQUIRED',
            'PENDING_FILE_RENAME_OPERATIONS'
        ) `
        -Label 'reboot_observations.indicators'

    if ($reboot.absence_meaning -cne 'NO_SELECTED_INDICATORS_ONLY') {
        throw 'Invalid Phase 010 reboot interpretation.'
    }

    $connectivity = Get-Aij010RequiredProperty `
        $r 'connectivity' 'connectivity'

    if ($connectivity.default -cne 'OFF') {
        throw 'Phase 010 connectivity must default to OFF.'
    }

    Assert-Aij010Boolean $connectivity `
        'required_for_runtime_pass' $true `
        'connectivity.required_for_runtime_pass'

    $probe = $connectivity.probe

    if (
        $probe.id -cne 'MICROSOFT_NCSI_HTTP_V1' -or
        $probe.uri -cne
            'http://www.msftconnecttest.com/connecttest.txt' -or
        $probe.method -cne 'GET' -or
        $probe.expected_status -ne 200 -or
        $probe.expected_body -cne 'Microsoft Connect Test' -or
        $probe.timeout_seconds -ne 10 -or
        $probe.max_response_bytes -ne 64 -or
        $probe.maximum_requests -ne 1 -or
        $probe.allow_redirects -ne $false -or
        $probe.proxy_mode -cne
            'SYSTEM_DEFAULT_NO_CREDENTIAL_INJECTION' -or
        $probe.purpose -cne
            'LIMITED_INTERNET_CONNECTIVITY_ONLY'
    ) {
        throw 'Invalid Phase 010 bounded-network policy.'
    }

    $record = Get-Aij010RequiredProperty `
        $r 'observation_record' 'observation_record'

    if (
        $record.schema -ne 1 -or
        $record.kind -cne 'AIJAIL_PHASE_010_OBSERVATION' -or
        $record.scope -cne 'REAL_WINDOWS_PREFLIGHT_010_UNBOUND'
    ) {
        throw 'Invalid Phase 010 observation-record contract.'
    }

    $security = Get-Aij010RequiredProperty $r 'security' 'security'

    foreach ($name in @(
        'allow_wsl_execution',
        'allow_downloads',
        'allow_system_modifications',
        'allow_docker_dependency',
        'allow_security_bypass',
        'production_apply_authorized'
    )) {
        Assert-Aij010Boolean $security $name $false "security.$name"
    }

    $installation = Get-Aij010RequiredProperty `
        $r 'installation' 'installation'

    Assert-Aij010Boolean $installation 'enabled' $false `
        'installation.enabled'
    Assert-Aij010Boolean $installation `
        'production_apply_authorized' $false `
        'installation.production_apply_authorized'

    if (
        $r.exit_codes.success -ne 0 -or
        $r.exit_codes.failure -ne 1
    ) {
        throw 'Invalid Phase 010 exit-code contract.'
    }

    return $r
}

function Get-Aij010ConfigSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config
    )

    if ($Config.Count -ne 13) {
        throw 'Configuration validation returned an unexpected key count.'
    }

    [int64]$minimumFreeBytes = (
        [int64]$Config['MIN_FREE_GB'] * [int64]1GB
    )

    [pscustomobject][ordered]@{
        TARGET_DRIVE         = [string]$Config['TARGET_DRIVE']
        DISTRO               = [string]$Config['DISTRO']
        BASE_DISTRO          = [string]$Config['BASE_DISTRO']
        LINUX_USER           = [string]$Config['LINUX_USER']
        MIN_WSL_VERSION      = [string]$Config['MIN_WSL_VERSION']
        MIN_FREE_GB          = [string]$Config['MIN_FREE_GB']
        MIN_FREE_BYTES       = $minimumFreeBytes
        ALLOW_HOSTS_OPENCODE = [string]$Config['ALLOW_HOSTS_OPENCODE']
        ALLOW_HOSTS_COMFYUI  = [string]$Config['ALLOW_HOSTS_COMFYUI']
        ALLOW_HOSTS_INSTALL  = [string]$Config['ALLOW_HOSTS_INSTALL']
        INSTALL_COMFYUI      = ($Config['INSTALL_COMFYUI'] -ceq '1')
        INSTALL_OPENCODE     = ($Config['INSTALL_OPENCODE'] -ceq '1')
        INSTALL_VSCODE       = ($Config['INSTALL_VSCODE'] -ceq '1')
        ENABLE_NONO          = ($Config['ENABLE_NONO'] -ceq '1')
    }
}

function Resolve-Aij010PlatformCheck {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Observation,

        [Parameter(Mandatory = $true)]
        $Requirements
    )

    if ($Observation.QuerySucceeded -ne $true) {
        return New-Aij010Check `
            'UNKNOWN' `
            'UNKNOWN' `
            'STRUCTURED_WINDOWS_PLATFORM_DATA' `
            $Observation `
            @('Windows platform observation did not complete.')
    }

    [long]$build = 0

    if (
        $null -eq $Observation.BuildNumber -or
        -not [long]::TryParse(
            [string]$Observation.BuildNumber,
            [ref]$build
        )
    ) {
        return New-Aij010Check `
            'UNKNOWN' `
            'UNKNOWN' `
            'STRUCTURED_WINDOWS_PLATFORM_DATA' `
            $Observation `
            @('Windows build number is missing or non-numeric.')
    }

    $architectures = @($Observation.Architectures | Sort-Object -Unique)

    if ($architectures.Count -ne 1) {
        return New-Aij010Check `
            'UNKNOWN' `
            'UNKNOWN' `
            'STRUCTURED_WINDOWS_PLATFORM_DATA' `
            $Observation `
            @('Native architecture observations are missing or contradictory.')
    }

    $architecture = [string]$architectures[0]

    if (
        @($Requirements.platform.allowed_architectures) -cnotcontains
        $architecture
    ) {
        return New-Aij010Check `
            'FAIL' `
            'UPSTREAM_PREREQUISITE_UNSUPPORTED' `
            'STRUCTURED_WINDOWS_PLATFORM_DATA' `
            $Observation `
            @('Architecture is outside the documented WSL 2 technical prerequisite.')
    }

    [long]$minimumBuild = [long](
        $Requirements.platform.minimum_build_by_architecture.$architecture
    )

    if ($build -lt $minimumBuild) {
        return New-Aij010Check `
            'FAIL' `
            'UPSTREAM_PREREQUISITE_UNSUPPORTED' `
            'STRUCTURED_WINDOWS_PLATFORM_DATA' `
            $Observation `
            @('Windows build is below the documented WSL 2 technical prerequisite.')
    }

    if (
        $architecture -ceq 'X64' -and
        @($Requirements.platform.x64_builds_requiring_minimum_ubr) `
            -contains $build
    ) {
        [long]$ubr = 0

        if (
            $null -eq $Observation.Ubr -or
            -not [long]::TryParse(
                [string]$Observation.Ubr,
                [ref]$ubr
            )
        ) {
            return New-Aij010Check `
                'UNKNOWN' `
                'UNKNOWN' `
                'STRUCTURED_WINDOWS_PLATFORM_DATA' `
                $Observation `
                @('Windows update-build revision is required but unavailable.')
        }

        if ($ubr -lt [long]$Requirements.platform.x64_minimum_ubr) {
            return New-Aij010Check `
                'FAIL' `
                'UPSTREAM_PREREQUISITE_UNSUPPORTED' `
                'STRUCTURED_WINDOWS_PLATFORM_DATA' `
                $Observation `
                @('Windows update-build revision is below the documented WSL 2 technical prerequisite.')
        }
    }

    return New-Aij010Check `
        'PASS' `
        'MEETS_WSL2_TECHNICAL_PREREQUISITE' `
        'STRUCTURED_WINDOWS_PLATFORM_DATA' `
        $Observation `
        @(
            'This is an upstream WSL 2 technical-prerequisite result, not an AI Jail product-support-policy decision.'
        )
}

function Resolve-Aij010VirtualizationCheck {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Observation
    )

    if ($Observation.QuerySucceeded -ne $true) {
        return New-Aij010Check `
            'UNKNOWN' 'UNKNOWN' `
            'CIM_VIRTUALIZATION_OBSERVATION' `
            $Observation `
            @('Virtualization observations did not complete.')
    }

    if ($Observation.HypervisorPresent -isnot [bool]) {
        return New-Aij010Check `
            'UNKNOWN' 'UNKNOWN' `
            'CIM_VIRTUALIZATION_OBSERVATION' `
            $Observation `
            @('Running-hypervisor state is unavailable.')
    }

    $processors = @($Observation.Processors)

    if ($processors.Count -lt 1) {
        return New-Aij010Check `
            'UNKNOWN' 'UNKNOWN' `
            'CIM_VIRTUALIZATION_OBSERVATION' `
            $Observation `
            @('No processor virtualization observations were returned.')
    }

    if ($Observation.HypervisorPresent) {
        return New-Aij010Check `
            'PASS' 'SATISFIED' `
            'CIM_VIRTUALIZATION_OBSERVATION' `
            $Observation
    }

    foreach ($processor in $processors) {
        foreach ($name in @(
            'VirtualizationFirmwareEnabled',
            'SecondLevelAddressTranslationExtensions',
            'VMMonitorModeExtensions'
        )) {
            if ($processor.$name -isnot [bool]) {
                return New-Aij010Check `
                    'UNKNOWN' 'UNKNOWN' `
                    'CIM_VIRTUALIZATION_OBSERVATION' `
                    $Observation `
                    @("Processor virtualization property unavailable: $name.")
            }
        }
    }

    foreach ($processor in $processors) {
        if (
            -not $processor.SecondLevelAddressTranslationExtensions -or
            -not $processor.VMMonitorModeExtensions
        ) {
            return New-Aij010Check `
                'FAIL' `
                'UPSTREAM_PREREQUISITE_UNSUPPORTED' `
                'CIM_VIRTUALIZATION_OBSERVATION' `
                $Observation `
                @('Required processor virtualization capability is unavailable.')
        }
    }

    foreach ($processor in $processors) {
        if (-not $processor.VirtualizationFirmwareEnabled) {
            return New-Aij010Check `
                'FAIL' `
                'MANUAL_ACTION_NEEDED' `
                'CIM_VIRTUALIZATION_OBSERVATION' `
                $Observation `
                @(
                    'Processor capability is present but firmware virtualization is not enabled.'
                )
        }
    }

    return New-Aij010Check `
        'PASS' `
        'BOOTSTRAP_NEEDED' `
        'CIM_VIRTUALIZATION_OBSERVATION' `
        $Observation `
        @(
            'Virtualization prerequisites are available; absence of a running hypervisor alone is not rejection.'
        )
}

function Resolve-Aij010StorageCheck {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Observation
    )

    if ($Observation.QuerySucceeded -ne $true) {
        return New-Aij010Check `
            'UNKNOWN' 'UNKNOWN' `
            'LOCAL_VOLUME_OBSERVATION' `
            $Observation `
            @('Configured storage observation did not complete.')
    }

    if ($Observation.Ready -isnot [bool] -or -not $Observation.Ready) {
        return New-Aij010Check `
            'FAIL' 'UNAVAILABLE' `
            'LOCAL_VOLUME_OBSERVATION' `
            $Observation `
            @('Configured target drive is not ready.')
    }

    if ([string]$Observation.DriveType -cne 'Fixed') {
        return New-Aij010Check `
            'FAIL' 'UNSUPPORTED_STORAGE' `
            'LOCAL_VOLUME_OBSERVATION' `
            $Observation `
            @('Configured target must be a fixed local volume.')
    }

    if (
        -not [string]::IsNullOrWhiteSpace(
            [string]$Observation.ProviderName
        )
    ) {
        return New-Aij010Check `
            'FAIL' 'UNSUPPORTED_STORAGE' `
            'LOCAL_VOLUME_OBSERVATION' `
            $Observation `
            @('Configured target resolves through a provider path.')
    }

    if (
        [string]::IsNullOrWhiteSpace(
            [string]$Observation.VolumeSerialNumber
        )
    ) {
        return New-Aij010Check `
            'UNKNOWN' 'UNKNOWN' `
            'LOCAL_VOLUME_OBSERVATION' `
            $Observation `
            @('Configured local volume identity is unavailable.')
    }

    if (@($Observation.ReparsePaths).Count -gt 0) {
        return New-Aij010Check `
            'FAIL' 'UNSAFE_PATH_INDIRECTION' `
            'LOCAL_VOLUME_OBSERVATION' `
            $Observation `
            @('Configured target path contains a reparse point.')
    }

    if ($Observation.TargetExists -eq $true) {
        return New-Aij010Check `
            'FAIL' 'MANUAL_ACTION_NEEDED' `
            'LOCAL_VOLUME_OBSERVATION' `
            $Observation `
            @(
                'Configured installation target already exists; adoption or migration is separate scope.'
            )
    }

    [int64]$available = 0
    [int64]$required = 0

    if (
        $null -eq $Observation.AvailableFreeSpace -or
        -not [int64]::TryParse(
            [string]$Observation.AvailableFreeSpace,
            [ref]$available
        ) -or
        $null -eq $Observation.RequiredBytes -or
        -not [int64]::TryParse(
            [string]$Observation.RequiredBytes,
            [ref]$required
        )
    ) {
        return New-Aij010Check `
            'UNKNOWN' 'UNKNOWN' `
            'System.IO.DriveInfo.AvailableFreeSpace' `
            $Observation `
            @('Caller-available free-space observation is unavailable.')
    }

    if ($available -lt $required) {
        return New-Aij010Check `
            'FAIL' 'INSUFFICIENT_AVAILABLE_SPACE' `
            'System.IO.DriveInfo.AvailableFreeSpace' `
            $Observation `
            @(
                'Caller-available free space is below the configured threshold.'
            )
    }

    return New-Aij010Check `
        'PASS' 'READY' `
        'System.IO.DriveInfo.AvailableFreeSpace' `
        $Observation
}

function Resolve-Aij010WslReadinessCheck {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Observation,

        [Parameter(Mandatory = $true)]
        [hashtable]$Config
    )

    if ($Observation.QuerySucceeded -ne $true) {
        return New-Aij010Check `
            'UNKNOWN' 'UNKNOWN' `
            'WINDOWS_SIDE_WSL_OBSERVATION' `
            $Observation `
            @('Windows-side WSL readiness observation did not complete.')
    }

    foreach ($feature in @($Observation.Features)) {
        if ([string]$feature.State -ceq 'UNKNOWN') {
            return New-Aij010Check `
                'UNKNOWN' 'UNKNOWN' `
                'WINDOWS_SIDE_WSL_OBSERVATION' `
                $Observation `
                @('At least one required optional-feature state is unknown.')
        }
    }

    $packageVersions = @($Observation.PackageVersions)

    if (
        $packageVersions.Count -eq 0 -and
        $Observation.WslFilePresent -ne $true
    ) {
        return New-Aij010Check `
            'PASS' 'ABSENT_BOOTSTRAP_NEEDED' `
            'WINDOWS_SIDE_WSL_OBSERVATION' `
            $Observation `
            @('WSL is absent; absence is compatible with later bootstrap.')
    }

    if (
        $packageVersions.Count -eq 0 -and
        $Observation.WslFilePresent -eq $true
    ) {
        return New-Aij010Check `
            'PASS' 'PRESENT_VERSION_UNKNOWN' `
            'WINDOWS_SIDE_WSL_OBSERVATION' `
            $Observation `
            @(
                'Windows-side WSL presence was observed but a package version was unavailable.'
            )
    }

    $bestVersion = $null

    foreach ($versionText in $packageVersions) {
        try {
            $null = ConvertTo-AijVersionParts -Value ([string]$versionText)
        }
        catch {
            return New-Aij010Check `
                'UNKNOWN' 'UNKNOWN' `
                'WINDOWS_SIDE_WSL_OBSERVATION' `
                $Observation `
                @('Observed WSL package version could not be parsed.')
        }

        if ($null -eq $bestVersion) {
            $bestVersion = [string]$versionText
            continue
        }

        if (
            (Compare-AijVersion `
                -Actual ([string]$versionText) `
                -Minimum $bestVersion) -gt 0
        ) {
            $bestVersion = [string]$versionText
        }
    }

    if ($Observation.WslFilePresent -ne $true) {
        return New-Aij010Check `
            'UNKNOWN' 'UNKNOWN' `
            'WINDOWS_SIDE_WSL_OBSERVATION' `
            $Observation `
            @(
                'WSL package presence and executable-file observations are contradictory.'
            )
    }

    if (
        (Compare-AijVersion `
            -Actual $bestVersion `
            -Minimum ([string]$Config['MIN_WSL_VERSION'])) -lt 0
    ) {
        return New-Aij010Check `
            'PASS' 'KNOWN_TOO_OLD' `
            'WINDOWS_SIDE_WSL_OBSERVATION' `
            $Observation `
            @(
                'Observed WSL package version is below MIN_WSL_VERSION and needs later bootstrap/update.'
            )
    }

    $allEnabled = $true

    foreach ($feature in @($Observation.Features)) {
        if ([string]$feature.State -cne 'ENABLED') {
            $allEnabled = $false
        }
    }

    if (-not $allEnabled) {
        return New-Aij010Check `
            'PASS' 'BOOTSTRAP_NEEDED' `
            'WINDOWS_SIDE_WSL_OBSERVATION' `
            $Observation `
            @(
                'WSL package is present but required Windows features are not all enabled.'
            )
    }

    return New-Aij010Check `
        'PASS' 'PRESENT_CURRENT' `
        'WINDOWS_SIDE_WSL_OBSERVATION' `
        $Observation `
        @(
            'Windows-side observations meet the configured minimum; runtime WSL capability remains Phase 020 scope.'
        )
}

function Resolve-Aij010RebootCheck {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)]$Observation)
    $valid = $true
    try {
        if ($Observation.QuerySucceeded -ne $true) { $valid = $false }
        foreach ($name in @('CBS_REBOOT_PENDING','WINDOWS_UPDATE_REBOOT_REQUIRED','PENDING_FILE_RENAME_OPERATIONS')) {
            $items = @($Observation.Indicators | Where-Object { $_.Name -ceq $name })
            if ($items.Count -ne 1 -or $items[0].Present -isnot [bool]) { $valid = $false }
        }
    } catch { $valid = $false }
    if (-not $valid) {
        return New-Aij010Check 'UNKNOWN' 'UNKNOWN' 'READ_ONLY_REBOOT_INDICATORS' $Observation @('Selected reboot indicators could not all be observed.')
    }
    $present = @($Observation.Indicators | Where-Object { $_.Present -eq $true })
    if (@($present | Where-Object { $_.Name -cne 'PENDING_FILE_RENAME_OPERATIONS' }).Count -gt 0) {
        return New-Aij010Check 'FAIL' 'MANUAL_ACTION_NEEDED' 'READ_ONLY_REBOOT_INDICATORS' $Observation @('At least one hard selected reboot indicator is present.')
    }
    if ($present.Count -gt 0) {
        try {
            $e = $present[0].Evidence
            if ($e.EntryCount -isnot [int] -or $e.EntryCount -le 0 -or
                $e.NonEmptyEntryCount -isnot [int] -or $e.NonEmptyEntryCount -lt 0 -or
                $e.NonEmptyEntryCount -gt $e.EntryCount -or
                $e.EntriesSha256 -cnotmatch '^[A-F0-9]{64}$' -or
                $e.RawValuesPersisted -ne $false -or $e.RedactionPolicy -cne 'SHA256_AGGREGATE_ONLY') { throw 'Invalid redacted observation.' }
        } catch {
            return New-Aij010Check 'UNKNOWN' 'UNKNOWN' 'READ_ONLY_REBOOT_INDICATORS' $Observation @('Pending-file evidence is incomplete.')
        }
        return New-Aij010Check 'WARN' 'PENDING_FILE_RENAME_OPERATIONS_PRESENT' 'READ_ONLY_REBOOT_INDICATORS' $Observation @('Pending file operations remain unresolved. Read-only completion does not authorize installation or establish that these operations are harmless.')
    }
    return New-Aij010Check 'PASS' 'NO_SELECTED_INDICATORS' 'READ_ONLY_REBOOT_INDICATORS' $Observation @('No selected indicator was present; this is not universal proof that no reboot is pending.')
}

function Get-Aij010PendingEvidence {
    [CmdletBinding()]
    param([object[]]$Values = @())
    $items = @($Values | ForEach-Object { [string]$_ })
    $json = ConvertTo-Json -InputObject $items -Compress
    $sha = [Security.Cryptography.SHA256]::Create()
    try { $digest = [BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($json))).Replace('-','') }
    finally { $sha.Dispose() }
    return [pscustomobject][ordered]@{
        EntryCount = $items.Count
        NonEmptyEntryCount = @($items | Where-Object { -not [string]::IsNullOrEmpty($_) }).Count
        EntriesSha256 = $digest
        RawValuesPersisted = $false
        RedactionPolicy = 'SHA256_AGGREGATE_ONLY'
    }
}

function Test-Aij010ReadOnlyReboot {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)]$Check)
    if ($Check.Status -ceq 'PASS') { return $true }
    if ($Check.Status -cne 'WARN' -or $Check.Decision -cne 'PENDING_FILE_RENAME_OPERATIONS_PRESENT') { return $false }
    $resolved = Resolve-Aij010RebootCheck -Observation $Check.Observation
    return ($resolved.Status -ceq 'WARN' -and $resolved.Decision -ceq $Check.Decision)
}

function Resolve-Aij010ConnectivityCheck {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Observation,

        [Parameter(Mandatory = $true)]
        $Requirements
    )

    $policy = $Requirements.connectivity.probe

    if ($Observation.Attempted -ne $true) {
        return New-Aij010Check `
            'NOT_RUN' 'NOT_RUN' `
            'BOUNDED_NETWORK_PROBE' `
            $Observation `
            @('Required connectivity probe did not run.')
    }

    if ($Observation.RequestCount -ne 1) {
        return New-Aij010Check `
            'FAIL' 'NETWORK_POLICY_VIOLATION' `
            'BOUNDED_NETWORK_PROBE' `
            $Observation `
            @('Connectivity probe request count violated the bound.')
    }

    if (
        [string]$Observation.Uri -cne [string]$policy.uri -or
        [string]$Observation.Method -cne [string]$policy.method
    ) {
        return New-Aij010Check `
            'FAIL' 'NETWORK_POLICY_VIOLATION' `
            'BOUNDED_NETWORK_PROBE' `
            $Observation `
            @('Connectivity probe destination or method violated policy.')
    }

    if ($Observation.Redirected -eq $true) {
        return New-Aij010Check `
            'FAIL' 'UNEXPECTED_RESPONSE' `
            'BOUNDED_NETWORK_PROBE' `
            $Observation `
            @('Connectivity probe redirect was rejected.')
    }

    if ($Observation.TimedOut -eq $true) {
        return New-Aij010Check `
            'FAIL' 'CONNECTIVITY_FAILED' `
            'BOUNDED_NETWORK_PROBE' `
            $Observation `
            @('Connectivity probe timed out.')
    }

    if (
        -not [string]::IsNullOrWhiteSpace(
            [string]$Observation.ErrorType
        )
    ) {
        return New-Aij010Check `
            'FAIL' 'CONNECTIVITY_FAILED' `
            'BOUNDED_NETWORK_PROBE' `
            $Observation `
            @('Connectivity probe reported a transport failure.')
    }

    if (
        $Observation.BytesRead -gt
        [int]$policy.max_response_bytes
    ) {
        return New-Aij010Check `
            'FAIL' 'NETWORK_POLICY_VIOLATION' `
            'BOUNDED_NETWORK_PROBE' `
            $Observation `
            @('Connectivity response exceeded the approved byte bound.')
    }

    if (
        $Observation.StatusCode -ne
            [int]$policy.expected_status -or
        [string]$Observation.Body -cne
            [string]$policy.expected_body
    ) {
        return New-Aij010Check `
            'FAIL' 'UNEXPECTED_RESPONSE' `
            'BOUNDED_NETWORK_PROBE' `
            $Observation `
            @(
                'Connectivity response did not match the approved status and exact body.'
            )
    }

    return New-Aij010Check `
        'PASS' 'LIMITED_CONNECTIVITY_CONFIRMED' `
        'BOUNDED_NETWORK_PROBE' `
        $Observation `
        @(
            'This proves only the bounded NCSI observation, not TLS readiness, download provenance or sandbox policy.'
        )
}

function Get-Aij010PrivilegeCheck {
    [CmdletBinding()]
    param()

    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object `
            Security.Principal.WindowsPrincipal($identity)

        $elevated = $principal.IsInRole(
            [Security.Principal.WindowsBuiltInRole]::Administrator
        )

        if ($elevated) {
            return New-Aij010Check `
                'PASS' 'ELEVATED' `
                'WindowsPrincipal.IsInRole' `
                ([pscustomobject]@{ Elevated = $true })
        }

        return New-Aij010Check `
            'FAIL' 'ADMINISTRATOR_REQUIRED' `
            'WindowsPrincipal.IsInRole' `
            ([pscustomobject]@{ Elevated = $false }) `
            @('Complete real collection requires administrator privileges.')
    }
    catch {
        return New-Aij010Check `
            'UNKNOWN' 'UNKNOWN' `
            'WindowsPrincipal.IsInRole' `
            ([pscustomobject]@{
                ErrorType = $_.Exception.GetType().FullName
            }) `
            @('Administrator state could not be determined.')
    }
}

function Get-Aij010PlatformObservation {
    [CmdletBinding()]
    param()

    try {
        $os = @(
            Get-CimInstance `
                -ClassName Win32_OperatingSystem `
                -ErrorAction Stop
        )

        $processors = @(
            Get-CimInstance `
                -ClassName Win32_Processor `
                -ErrorAction Stop
        )

        if ($os.Count -ne 1 -or $processors.Count -lt 1) {
            return [pscustomobject][ordered]@{
                QuerySucceeded = $false
                ErrorType      = 'MISSING_OR_AMBIGUOUS_PLATFORM_DATA'
                BuildNumber    = $null
                Ubr            = $null
                Version        = $null
                ProductType    = $null
                Architectures  = @()
            }
        }

        $architectures = New-Object `
            'System.Collections.Generic.List[string]'

        foreach ($processor in $processors) {
            switch ([int]$processor.Architecture) {
                9 {
                    $architectures.Add('X64')
                }

                12 {
                    $architectures.Add('ARM64')
                }

                default {
                    $architectures.Add(
                        "UNSUPPORTED_$([int]$processor.Architecture)"
                    )
                }
            }
        }

        $ubr = $null

        try {
            $currentVersion = Get-ItemProperty `
                -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' `
                -ErrorAction Stop

            $ubrProperty = $currentVersion.PSObject.Properties['UBR']

            if ($null -ne $ubrProperty) {
                $ubr = $ubrProperty.Value
            }
        }
        catch {
            $ubr = $null
        }

        return [pscustomobject][ordered]@{
            QuerySucceeded = $true
            ErrorType      = $null
            BuildNumber    = $os[0].BuildNumber
            Ubr            = $ubr
            Version        = $os[0].Version
            ProductType    = $os[0].ProductType
            Caption        = $os[0].Caption
            Architectures  = @($architectures.ToArray())
        }
    }
    catch {
        return [pscustomobject][ordered]@{
            QuerySucceeded = $false
            ErrorType      = $_.Exception.GetType().FullName
            BuildNumber    = $null
            Ubr            = $null
            Version        = $null
            ProductType    = $null
            Architectures  = @()
        }
    }
}

function Get-Aij010VirtualizationObservation {
    [CmdletBinding()]
    param()

    try {
        $computerSystems = @(
            Get-CimInstance `
                -ClassName Win32_ComputerSystem `
                -ErrorAction Stop
        )

        $processors = @(
            Get-CimInstance `
                -ClassName Win32_Processor `
                -ErrorAction Stop
        )

        if ($computerSystems.Count -ne 1 -or $processors.Count -lt 1) {
            return [pscustomobject][ordered]@{
                QuerySucceeded    = $false
                ErrorType         = 'MISSING_OR_AMBIGUOUS_VIRTUALIZATION_DATA'
                HypervisorPresent = $null
                Processors        = @()
            }
        }

        $records = New-Object `
            'System.Collections.Generic.List[object]'

        foreach ($processor in $processors) {
            $records.Add([pscustomobject][ordered]@{
                VirtualizationFirmwareEnabled =
                    $processor.VirtualizationFirmwareEnabled
                SecondLevelAddressTranslationExtensions =
                    $processor.SecondLevelAddressTranslationExtensions
                VMMonitorModeExtensions =
                    $processor.VMMonitorModeExtensions
            })
        }

        return [pscustomobject][ordered]@{
            QuerySucceeded    = $true
            ErrorType         = $null
            HypervisorPresent = $computerSystems[0].HypervisorPresent
            Processors        = @($records.ToArray())
        }
    }
    catch {
        return [pscustomobject][ordered]@{
            QuerySucceeded    = $false
            ErrorType         = $_.Exception.GetType().FullName
            HypervisorPresent = $null
            Processors        = @()
        }
    }
}

function Get-Aij010StorageObservation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config
    )

    $drive = [string]$Config['TARGET_DRIVE']
    $root = $drive + '\'
    [int64]$requiredBytes = (
        [int64]$Config['MIN_FREE_GB'] * [int64]1GB
    )

    try {
        $driveInfo = New-Object System.IO.DriveInfo($root)

        $logicalDisks = @(
            Get-CimInstance `
                -ClassName Win32_LogicalDisk `
                -Filter ("DeviceID='{0}'" -f $drive) `
                -ErrorAction Stop
        )

        if ($logicalDisks.Count -ne 1) {
            return [pscustomobject][ordered]@{
                QuerySucceeded    = $false
                ErrorType         = 'MISSING_OR_AMBIGUOUS_VOLUME'
                Drive             = $drive
                RequiredBytes     = $requiredBytes
                ReparsePaths      = @()
            }
        }

        $distroRoot = Join-Path $root ([string]$Config['DISTRO'])
        $target = Join-Path $distroRoot 'wsl'

        $reparse = New-Object `
            'System.Collections.Generic.List[string]'

        foreach ($candidate in @($root, $distroRoot, $target)) {
            if (Test-Path -LiteralPath $candidate) {
                $attributes = [IO.File]::GetAttributes($candidate)

                if (
                    ($attributes -band [IO.FileAttributes]::ReparsePoint) `
                    -ne 0
                ) {
                    $reparse.Add($candidate)
                }
            }
        }

        return [pscustomobject][ordered]@{
            QuerySucceeded    = $true
            ErrorType         = $null
            Drive             = $drive
            Ready             = $driveInfo.IsReady
            DriveType         = $driveInfo.DriveType.ToString()
            ProviderName      = $logicalDisks[0].ProviderName
            FileSystem        = $logicalDisks[0].FileSystem
            VolumeSerialNumber = $logicalDisks[0].VolumeSerialNumber
            TargetPath        = $target
            TargetExists      = (Test-Path -LiteralPath $target)
            ReparsePaths      = @($reparse.ToArray())
            AvailableFreeSpace = $driveInfo.AvailableFreeSpace
            TotalFreeSpace    = $driveInfo.TotalFreeSpace
            RequiredBytes     = $requiredBytes
        }
    }
    catch {
        return [pscustomobject][ordered]@{
            QuerySucceeded = $false
            ErrorType      = $_.Exception.GetType().FullName
            Drive          = $drive
            RequiredBytes  = $requiredBytes
            ReparsePaths   = @()
        }
    }
}

function Get-Aij010OptionalFeatureObservation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    try {
        $items = @(
            Get-CimInstance `
                -ClassName Win32_OptionalFeature `
                -Filter ("Name='{0}'" -f $Name) `
                -ErrorAction Stop
        )

        if ($items.Count -eq 0) {
            return [pscustomobject][ordered]@{
                Name  = $Name
                State = 'ABSENT'
            }
        }

        if ($items.Count -ne 1) {
            return [pscustomobject][ordered]@{
                Name  = $Name
                State = 'UNKNOWN'
            }
        }

        switch ([int]$items[0].InstallState) {
            1 {
                $state = 'ENABLED'
            }

            2 {
                $state = 'DISABLED'
            }

            3 {
                $state = 'ABSENT'
            }

            default {
                $state = 'UNKNOWN'
            }
        }

        return [pscustomobject][ordered]@{
            Name  = $Name
            State = $state
        }
    }
    catch {
        return [pscustomobject][ordered]@{
            Name      = $Name
            State     = 'UNKNOWN'
            ErrorType = $_.Exception.GetType().FullName
        }
    }
}

function Get-Aij010WslObservation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Requirements
    )

    try {
        $features = New-Object `
            'System.Collections.Generic.List[object]'

        foreach ($name in @(
            $Requirements.wsl_readiness.optional_features
        )) {
            $features.Add(
                (Get-Aij010OptionalFeatureObservation `
                    -Name ([string]$name))
            )
        }

        $packageCommand = Get-Command `
            -Name Get-AppxPackage `
            -CommandType Cmdlet `
            -ErrorAction SilentlyContinue

        if ($null -eq $packageCommand) {
            return [pscustomobject][ordered]@{
                QuerySucceeded = $false
                ErrorType      = 'GET_APPX_PACKAGE_UNAVAILABLE'
                Features       = @($features.ToArray())
                PackageVersions = @()
                WslFilePresent = $false
                WslExecuted    = $false
            }
        }

        $packages = @(
            Get-AppxPackage `
                -AllUsers `
                -Name ([string]$Requirements.wsl_readiness.package_name) `
                -ErrorAction Stop
        )

        $versions = New-Object `
            'System.Collections.Generic.List[string]'

        foreach ($package in $packages) {
            if ($null -ne $package.Version) {
                $versions.Add([string]$package.Version)
            }
        }

        $systemRoot = [string]$env:SystemRoot

        if ([string]::IsNullOrWhiteSpace($systemRoot)) {
            throw 'SystemRoot is unavailable.'
        }

        $wslPath = Join-Path `
            $systemRoot `
            ([string]$Requirements.wsl_readiness.executable_relative_path)

        return [pscustomobject][ordered]@{
            QuerySucceeded = $true
            ErrorType      = $null
            Features       = @($features.ToArray())
            PackageVersions = @($versions.ToArray())
            WslFilePresent = [IO.File]::Exists($wslPath)
            WslExecuted    = $false
        }
    }
    catch {
        return [pscustomobject][ordered]@{
            QuerySucceeded = $false
            ErrorType      = $_.Exception.GetType().FullName
            Features       = @()
            PackageVersions = @()
            WslFilePresent = $false
            WslExecuted    = $false
        }
    }
}

function Get-Aij010RebootObservation {
    [CmdletBinding()]
    param()

    try {
        $indicators = New-Object `
            'System.Collections.Generic.List[object]'

        $indicators.Add([pscustomobject]@{
            Name = 'CBS_REBOOT_PENDING'
            Present = [bool](
                Test-Path `
                    -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'
            )
        })

        $indicators.Add([pscustomobject]@{
            Name = 'WINDOWS_UPDATE_REBOOT_REQUIRED'
            Present = [bool](
                Test-Path `
                    -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
            )
        })

        $sessionManager = Get-ItemProperty `
            -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' `
            -ErrorAction Stop

        $pending = $sessionManager.PSObject.Properties[
            'PendingFileRenameOperations'
        ]

        $pendingValues = @()
        if ($null -ne $pending -and $null -ne $pending.Value) { $pendingValues = @($pending.Value) }
        $pendingPresent = ($pendingValues.Count -gt 0)
        $pendingEvidence = Get-Aij010PendingEvidence -Values $pendingValues

        $indicators.Add([pscustomobject]@{
            Name = 'PENDING_FILE_RENAME_OPERATIONS'
            Present = [bool]$pendingPresent
            Evidence = $pendingEvidence
        })

        return [pscustomobject][ordered]@{
            QuerySucceeded = $true
            ErrorType      = $null
            Indicators     = @($indicators.ToArray())
            AbsenceMeaning = 'NO_SELECTED_INDICATORS_ONLY'
        }
    }
    catch {
        return [pscustomobject][ordered]@{
            QuerySucceeded = $false
            ErrorType      = $_.Exception.GetType().FullName
            Indicators     = @()
            AbsenceMeaning = 'NO_SELECTED_INDICATORS_ONLY'
        }
    }
}

function Invoke-Aij010NetworkObservation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Requirements
    )

    $policy = $Requirements.connectivity.probe
    $response = $null
    $stream = $null

    try {
        $request = [Net.HttpWebRequest][Net.WebRequest]::Create(
            [string]$policy.uri
        )

        $request.Method = [string]$policy.method
        $request.AllowAutoRedirect = $false
        $request.Timeout = [int]$policy.timeout_seconds * 1000
        $request.ReadWriteTimeout = [int]$policy.timeout_seconds * 1000
        $request.KeepAlive = $false
        $request.UserAgent = 'AI-Jail-Phase-010-Probe/1'
        $request.Accept = 'text/plain'
        $request.UseDefaultCredentials = $false
        $request.Credentials = $null

        $response = [Net.HttpWebResponse]$request.GetResponse()

        [int]$maxBytes = [int]$policy.max_response_bytes
        $stream = $response.GetResponseStream()
        $buffer = New-Object byte[] ($maxBytes + 1)
        $total = 0

        while ($total -lt $buffer.Length) {
            $read = $stream.Read(
                $buffer,
                $total,
                $buffer.Length - $total
            )

            if ($read -le 0) {
                break
            }

            $total += $read
        }

        $bodyLength = [Math]::Min($total, $maxBytes)
        $bodyBytes = New-Object byte[] $bodyLength

        if ($bodyLength -gt 0) {
            [Array]::Copy(
                $buffer,
                0,
                $bodyBytes,
                0,
                $bodyLength
            )
        }

        $utf8 = New-Object System.Text.UTF8Encoding($false, $true)
        $body = $utf8.GetString($bodyBytes)

        return [pscustomobject][ordered]@{
            Attempted    = $true
            RequestCount = 1
            Uri          = [string]$policy.uri
            Method       = [string]$policy.method
            StatusCode   = [int]$response.StatusCode
            Body         = $body
            BytesRead    = $total
            Redirected   = $false
            TimedOut     = $false
            ErrorType    = $null
        }
    }
    catch {
        $timedOut = (
            $_.Exception -is [Net.WebException] -and
            $_.Exception.Status -eq [Net.WebExceptionStatus]::Timeout
        )

        return [pscustomobject][ordered]@{
            Attempted    = $true
            RequestCount = 1
            Uri          = [string]$policy.uri
            Method       = [string]$policy.method
            StatusCode   = $null
            Body         = $null
            BytesRead    = 0
            Redirected   = $false
            TimedOut     = [bool]$timedOut
            ErrorType    = $_.Exception.GetType().FullName
        }
    }
    finally {
        if ($null -ne $stream) {
            $stream.Dispose()
        }

        if ($null -ne $response) {
            $response.Dispose()
        }
    }
}

function Get-Aij010DefaultAdapters {
    [CmdletBinding()]
    param()

    @{
        Administrator = {
            param($Config, $Requirements)

            Get-Aij010PrivilegeCheck
        }

        WindowsPlatform = {
            param($Config, $Requirements)

            $observation = Get-Aij010PlatformObservation

            Resolve-Aij010PlatformCheck `
                -Observation $observation `
                -Requirements $Requirements
        }

        Virtualization = {
            param($Config, $Requirements)

            $observation = Get-Aij010VirtualizationObservation

            Resolve-Aij010VirtualizationCheck `
                -Observation $observation
        }

        Storage = {
            param($Config, $Requirements)

            $observation = Get-Aij010StorageObservation `
                -Config $Config

            Resolve-Aij010StorageCheck `
                -Observation $observation
        }

        WslReadiness = {
            param($Config, $Requirements)

            $observation = Get-Aij010WslObservation `
                -Requirements $Requirements

            Resolve-Aij010WslReadinessCheck `
                -Observation $observation `
                -Config $Config
        }

        RebootObservations = {
            param($Config, $Requirements)

            $observation = Get-Aij010RebootObservation

            Resolve-Aij010RebootCheck `
                -Observation $observation
        }

        Connectivity = {
            param($Config, $Requirements)

            $observation = Invoke-Aij010NetworkObservation `
                -Requirements $Requirements

            Resolve-Aij010ConnectivityCheck `
                -Observation $observation `
                -Requirements $Requirements
        }
    }
}

function Get-Aij010Decision {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Operation,

        [Parameter(Mandatory = $true)]
        $Checks
    )

    $normalized = ConvertTo-Aij010Operation -Value $Operation

    if ($normalized -ceq 'REVIEW') {
        return [pscustomobject][ordered]@{
            Outcome                 = 'REVIEW_PASS'
            ExitCode                = 0
            LocalEligibility        = $null
            EligibleForBootstrap    = $null
            BootstrapNeeded         = $null
            ObservationCompletion   = $false
            RequiredCheckCompletion = $false
            RuntimePassCandidate    = $false
            RuntimePass             = $false
            DependencyResult        = 'NOT_EMITTED'
        }
    }

    $localNames = @(
        'Administrator',
        'WindowsPlatform',
        'Virtualization',
        'Storage',
        'WslReadiness',
        'RebootObservations'
    )

    $localPass = $true

    foreach ($name in $localNames) {
        $property = $Checks.PSObject.Properties[$name]

        if (
            $null -eq $property -or
            $property.Value.Status -cne 'PASS'
        ) {
            $localPass = $false
        }
    }

    $bootstrapNeeded = (
        $Checks.Virtualization.Decision -ceq 'BOOTSTRAP_NEEDED' -or
        $Checks.WslReadiness.Decision -in @(
            'ABSENT_BOOTSTRAP_NEEDED',
            'KNOWN_TOO_OLD',
            'BOOTSTRAP_NEEDED',
            'PRESENT_VERSION_UNKNOWN'
        )
    )

    if ($normalized -ceq 'COLLECT_OFFLINE') {
        return [pscustomobject][ordered]@{
            Outcome = $(
                if ($localPass) {
                    'LOCAL_DIAGNOSTIC_PASS'
                }
                else {
                    'LOCAL_DIAGNOSTIC_FAIL'
                }
            )
            ExitCode = $(if ($localPass) { 0 } else { 1 })
            LocalEligibility        = [bool]$localPass
            EligibleForBootstrap    = $null
            BootstrapNeeded         = [bool]$bootstrapNeeded
            ObservationCompletion   = $false
            RequiredCheckCompletion = $false
            RuntimePassCandidate    = $false
            RuntimePass             = $false
            DependencyResult        = 'NOT_EMITTED'
        }
    }

    $connectivityPass = (
        $Checks.Connectivity.Status -ceq 'PASS'
    )

    $observationComplete = $connectivityPass
    foreach ($name in $localNames) {
        $property = $Checks.PSObject.Properties[$name]
        if ($null -eq $property) { $observationComplete = $false; continue }
        if ($name -ceq 'RebootObservations') {
            if (-not (Test-Aij010ReadOnlyReboot -Check $property.Value)) { $observationComplete = $false }
        } elseif ($property.Value.Status -cne 'PASS') { $observationComplete = $false }
    }
    $complete = ($localPass -and $connectivityPass)

    [pscustomobject][ordered]@{
        Outcome = $(
            if ($complete) {
                'COLLECTION_CANDIDATE_PASS'
            }
            else {
                'COLLECTION_CANDIDATE_FAIL'
            }
        )
        ExitCode = $(if ($complete) { 0 } else { 1 })
        LocalEligibility        = [bool]$localPass
        EligibleForBootstrap    = [bool]$complete
        BootstrapNeeded         = [bool]$bootstrapNeeded
        ObservationCompletion   = [bool]$observationComplete
        RequiredCheckCompletion = [bool]$complete
        RuntimePassCandidate    = [bool]$complete
        RuntimePass             = $false
        DependencyResult        = 'NOT_EMITTED'
    }
}

function Invoke-Aij010Preflight {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Operation,

        [Parameter(Mandatory = $true)]
        [hashtable]$Config,

        [Parameter(Mandatory = $true)]
        $Requirements,

        [Parameter()]
        [hashtable]$Adapters
    )

    $normalized = ConvertTo-Aij010Operation -Value $Operation
    $configSummary = Get-Aij010ConfigSummary -Config $Config

    $requirementsCheck = New-Aij010Check `
        'PASS' 'VALIDATED' `
        'Phase010RequirementsV2' `
        ([pscustomobject]@{
            ContractVersion = $Requirements.contract_version
        })

    $configCheck = New-Aij010Check `
        'PASS' 'VALIDATED_BY_AUTHORITATIVE_CONFIG_PARSER' `
        'Read-AijConfig' `
        ([pscustomobject]@{
            ConfigKeyCount = $Config.Count
        })

    $linuxCheck = New-Aij010Check `
        'PASS' 'VALIDATED_BY_AUTHORITATIVE_CONFIG_PARSER' `
        'Read-AijConfig' `
        ([pscustomobject]@{
            LinuxUser = [string]$Config['LINUX_USER']
        })

    if ($normalized -ceq 'REVIEW') {
        $notRunReason =
            'REVIEW performs no live Windows observation.'

        $checks = [pscustomobject][ordered]@{
            Requirements = $requirementsCheck
            Configuration = $configCheck
            LinuxUser = $linuxCheck
            Administrator = New-Aij010Check `
                'NOT_RUN' 'NOT_RUN' 'NONE' $null @($notRunReason)
            WindowsPlatform = New-Aij010Check `
                'NOT_RUN' 'NOT_RUN' 'NONE' $null @($notRunReason)
            Virtualization = New-Aij010Check `
                'NOT_RUN' 'NOT_RUN' 'NONE' $null @($notRunReason)
            Storage = New-Aij010Check `
                'NOT_RUN' 'NOT_RUN' 'NONE' $null @($notRunReason)
            WslReadiness = New-Aij010Check `
                'NOT_RUN' 'NOT_RUN' 'NONE' $null @($notRunReason)
            RebootObservations = New-Aij010Check `
                'NOT_RUN' 'NOT_RUN' 'NONE' $null @($notRunReason)
            Connectivity = New-Aij010Check `
                'NOT_RUN' 'NOT_RUN' 'NONE' $null `
                @('Network is disabled for REVIEW.')
        }

        $decision = Get-Aij010Decision `
            -Operation $normalized `
            -Checks $checks

        return [pscustomobject][ordered]@{
            Schema          = $Requirements.observation_record.schema
            Kind            = $Requirements.observation_record.kind
            ContractVersion = $Requirements.contract_version
            Scope           = $Requirements.observation_record.scope
            Phase           = '010'
            Operation       = $normalized
            GeneratedUtc    = [datetime]::UtcNow.ToString('o')
            Configuration   = $configSummary
            Checks          = $checks
            Decision        = $decision
            Limitations     = @(
                'UNBOUND_OBSERVATION_ONLY',
                'NO_DURABLE_RUNTIME_EVIDENCE',
                'NO_RUNTIME_PASS',
                'NO_WSL_EXECUTION',
                'NO_SYSTEM_MODIFICATION',
                'NO_ARTIFACT_ACQUISITION',
                'NO_NETWORK_REQUEST'
            )
        }
    }

    if ($null -eq $Adapters) {
        $Adapters = Get-Aij010DefaultAdapters
    }

    foreach ($requiredAdapter in @(
        'Administrator',
        'WindowsPlatform',
        'Virtualization',
        'Storage',
        'WslReadiness',
        'RebootObservations',
        'Connectivity'
    )) {
        if (-not $Adapters.ContainsKey($requiredAdapter)) {
            throw "Missing Phase 010 adapter: $requiredAdapter."
        }
    }

    $administrator = & $Adapters['Administrator'] `
        $Config $Requirements

    if ($administrator.Status -cne 'PASS') {
        $reason =
            'Live collection stopped because administrator state did not pass.'

        $checks = [pscustomobject][ordered]@{
            Requirements = $requirementsCheck
            Configuration = $configCheck
            LinuxUser = $linuxCheck
            Administrator = $administrator
            WindowsPlatform = New-Aij010Check `
                'NOT_RUN' 'NOT_RUN' 'NONE' $null @($reason)
            Virtualization = New-Aij010Check `
                'NOT_RUN' 'NOT_RUN' 'NONE' $null @($reason)
            Storage = New-Aij010Check `
                'NOT_RUN' 'NOT_RUN' 'NONE' $null @($reason)
            WslReadiness = New-Aij010Check `
                'NOT_RUN' 'NOT_RUN' 'NONE' $null @($reason)
            RebootObservations = New-Aij010Check `
                'NOT_RUN' 'NOT_RUN' 'NONE' $null @($reason)
            Connectivity = New-Aij010Check `
                'NOT_RUN' 'NOT_RUN' 'NONE' $null @($reason)
        }

        $decision = Get-Aij010Decision `
            -Operation $normalized `
            -Checks $checks

        return [pscustomobject][ordered]@{
            Schema          = $Requirements.observation_record.schema
            Kind            = $Requirements.observation_record.kind
            ContractVersion = $Requirements.contract_version
            Scope           = $Requirements.observation_record.scope
            Phase           = '010'
            Operation       = $normalized
            GeneratedUtc    = [datetime]::UtcNow.ToString('o')
            Configuration   = $configSummary
            Checks          = $checks
            Decision        = $decision
            Limitations     = @(
                'UNBOUND_OBSERVATION_ONLY',
                'NO_DURABLE_RUNTIME_EVIDENCE',
                'NO_RUNTIME_PASS'
            )
        }
    }

    $platform = & $Adapters['WindowsPlatform'] `
        $Config $Requirements

    $virtualization = & $Adapters['Virtualization'] `
        $Config $Requirements

    $storage = & $Adapters['Storage'] `
        $Config $Requirements

    $wsl = & $Adapters['WslReadiness'] `
        $Config $Requirements

    $reboot = & $Adapters['RebootObservations'] `
        $Config $Requirements

    $localPass = (
        $platform.Status -ceq 'PASS' -and
        $virtualization.Status -ceq 'PASS' -and
        $storage.Status -ceq 'PASS' -and
        $wsl.Status -ceq 'PASS' -and
        (Test-Aij010ReadOnlyReboot -Check $reboot)
    )

    if (
        $normalized -ceq 'COLLECT_ONLINE' -and
        $localPass
    ) {
        $connectivity = & $Adapters['Connectivity'] `
            $Config $Requirements
    }
    else {
        $networkReason = $(
            if ($normalized -ceq 'COLLECT_OFFLINE') {
                'Network is disabled for COLLECT_OFFLINE.'
            }
            else {
                'Connectivity did not run because a required local observation did not pass.'
            }
        )

        $connectivity = New-Aij010Check `
            'NOT_RUN' 'NOT_RUN' 'NONE' $null @($networkReason)
    }

    $checks = [pscustomobject][ordered]@{
        Requirements       = $requirementsCheck
        Configuration      = $configCheck
        LinuxUser          = $linuxCheck
        Administrator      = $administrator
        WindowsPlatform    = $platform
        Virtualization     = $virtualization
        Storage            = $storage
        WslReadiness       = $wsl
        RebootObservations = $reboot
        Connectivity       = $connectivity
    }

    $decision = Get-Aij010Decision `
        -Operation $normalized `
        -Checks $checks

    $limitations = @(
        'UNBOUND_OBSERVATION_ONLY',
        'NO_DURABLE_RUNTIME_EVIDENCE',
        'NO_RUNTIME_PASS',
        'NO_WSL_EXECUTION',
        'NO_SYSTEM_MODIFICATION',
        'NO_ARTIFACT_ACQUISITION'
    )

    if ($normalized -ceq 'COLLECT_OFFLINE') {
        $limitations += 'NO_NETWORK_REQUEST'
    }
    else {
        $limitations += 'NCSI_CONNECTIVITY_ONLY'
        $limitations += 'NO_TLS_OR_DOWNLOAD_PROVENANCE_PROOF'
    }

    [pscustomobject][ordered]@{
        Schema          = $Requirements.observation_record.schema
        Kind            = $Requirements.observation_record.kind
        ContractVersion = $Requirements.contract_version
        Scope           = $Requirements.observation_record.scope
        Phase           = '010'
        Operation       = $normalized
        GeneratedUtc    = [datetime]::UtcNow.ToString('o')
        Configuration   = $configSummary
        Checks          = $checks
        Decision        = $decision
        Limitations     = @($limitations)
    }
}

function Format-Aij010PreflightText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Record
    )

    Write-Output '========================================'
    Write-Output 'AI JAIL - PHASE 010 READ-ONLY PREFLIGHT'
    Write-Output '========================================'
    Write-Output "Operation: $($Record.Operation)"
    Write-Output "Scope: $($Record.Scope)"
    Write-Output "Contract version: $($Record.ContractVersion)"
    Write-Output ''

    foreach ($name in @(
        'Requirements',
        'Configuration',
        'LinuxUser',
        'Administrator',
        'WindowsPlatform',
        'Virtualization',
        'Storage',
        'WslReadiness',
        'RebootObservations',
        'Connectivity'
    )) {
        $check = $Record.Checks.PSObject.Properties[$name].Value

        Write-Output (
            '{0}: {1} / {2}' -f
            $name,
            $check.Status,
            $check.Decision
        )

        foreach ($reason in @($check.Reasons)) {
            Write-Output "  $reason"
        }
    }

    Write-Output ''
    Write-Output "Outcome: $($Record.Decision.Outcome)"
    Write-Output (
        "Required checks complete: $($Record.Decision.RequiredCheckCompletion)"
    )
    Write-Output (
        "Runtime-pass candidate: $($Record.Decision.RuntimePassCandidate)"
    )
    Write-Output '010 RUNTIME_PASS: NOT_EMITTED'
    Write-Output 'Production APPLY: BLOCKED'
    Write-Output ''

    if ($Record.Decision.ExitCode -eq 0) {
        switch ($Record.Operation) {
            'REVIEW' {
                Write-Output 'PHASE_010_REVIEW_OK'
            }

            'COLLECT_OFFLINE' {
                Write-Output 'PHASE_010_LOCAL_DIAGNOSTIC_OK'
            }

            'COLLECT_ONLINE' {
                Write-Output 'PHASE_010_COLLECTION_CANDIDATE_OK'
            }
        }
    }
    else {
        Write-Output 'PHASE_010_OPERATION_FAILED'
    }
}