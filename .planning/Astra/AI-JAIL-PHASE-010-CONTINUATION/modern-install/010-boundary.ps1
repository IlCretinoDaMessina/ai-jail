# ============================================================
# AI Jail - Phase 010 bound real read-only execution boundary
# Windows PowerShell 5.1 compatible.
#
# Functions only. Loading this file performs no Windows, network,
# WSL, elevation or persistence operation.
# ============================================================

$script:Aij010BoundRoot = $PSScriptRoot
$script:Aij010BoundScope = 'REAL_WINDOWS_PREFLIGHT_010'
$script:Aij010ZeroSha256 = ('0' * 64)
$script:Aij010FreshnessSeconds = 300
$script:Aij010BoundSourceNames = @(
    '000-run-all.bat',
    '000-engine.ps1',
    '000-authorization.ps1',
    '000-state.ps1',
    '000-state-store.ps1',
    '000-manifest.ps1',
    '000-config.ps1',
    '010-preflight.ps1',
    '010-preflight-core.ps1',
    '010-preflight.bat',
    '010-requirements.json',
    '010-boundary.ps1'
)

function Get-Aij010BoundTextSha256 {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Text)

    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [Text.Encoding]::UTF8.GetBytes($Text)
        return [BitConverter]::ToString(
            $sha.ComputeHash($bytes)
        ).Replace('-', '')
    }
    finally {
        $sha.Dispose()
    }
}

function Assert-Aij010BoundLocalPath {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw 'B010_PATH_REQUIRED'
    }

    $full = [IO.Path]::GetFullPath($Path)
    if ($full -notmatch '^[A-Za-z]:\\' -or $full.Substring(3).Contains(':')) {
        throw 'B010_LOCAL_PATH_REQUIRED'
    }

    $part = [IO.Path]::GetPathRoot($full)
    foreach ($segment in $full.Substring($part.Length).Split([char]'\')) {
        if ($segment.Length -eq 0) { continue }
        if ($segment.EndsWith('.') -or $segment.EndsWith(' ')) {
            throw 'B010_PATH_ALIAS_REJECTED'
        }
        $part = Join-Path $part $segment
        if (Test-Path -LiteralPath $part) {
            $attributes = [IO.File]::GetAttributes($part)
            if (($attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw 'B010_REPARSE_REJECTED'
            }
        }
    }

    return $full
}

function Assert-Aij010OrdinaryBoundFile {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Path)

    $full = Assert-Aij010BoundLocalPath -Path $Path
    if (-not [IO.File]::Exists($full)) {
        throw 'B010_SOURCE_MISSING'
    }
    $attributes = [IO.File]::GetAttributes($full)
    if (($attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw 'B010_SOURCE_REPARSE_REJECTED'
    }
    return $full
}

function ConvertTo-Aij010BoundProfile {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][AllowEmptyString()][string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        throw 'B010_PROFILE_REQUIRED'
    }

    switch ($Value.ToUpperInvariant()) {
        'OFFLINE' { return 'OFFLINE_DIAGNOSTIC' }
        'OFFLINE_DIAGNOSTIC' { return 'OFFLINE_DIAGNOSTIC' }
        'ONLINE' { return 'ONLINE_RUNTIME_PASS' }
        'ONLINE_RUNTIME_PASS' { return 'ONLINE_RUNTIME_PASS' }
        default { throw 'B010_PROFILE_INVALID' }
    }
}

function Get-Aij010BoundSourceLock {
    [CmdletBinding()]
    param([string]$Root = $script:Aij010BoundRoot)

    $rootFull = Assert-Aij010BoundLocalPath -Path $Root
    if (-not [IO.Directory]::Exists($rootFull)) {
        throw 'B010_ROOT_MISSING'
    }

    $items = New-Object 'System.Collections.Generic.List[object]'
    foreach ($name in $script:Aij010BoundSourceNames) {
        $path = Assert-Aij010OrdinaryBoundFile -Path (Join-Path $rootFull $name)
        $items.Add([pscustomobject][ordered]@{
            Name = $name
            Sha256 = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
        })
    }
    return @($items.ToArray() | Sort-Object Name)
}

function Assert-Aij010BoundSourceLockCurrent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]$ExpectedSources,
        [string]$Root = $script:Aij010BoundRoot
    )

    $expected = @($ExpectedSources)
    $required = @($script:Aij010BoundSourceNames | Sort-Object)
    if ($expected.Count -ne $required.Count) {
        throw 'B010_SOURCE_LOCK_INVALID'
    }

    $seen = @{}
    foreach ($entry in $expected) {
        if ($null -eq $entry -or
            $entry.Name -isnot [string] -or
            $entry.Name -cnotmatch '^[A-Za-z0-9_][A-Za-z0-9_.-]*$' -or
            $entry.Name.Contains('..') -or
            $entry.Sha256 -isnot [string] -or
            $entry.Sha256 -cnotmatch '^[A-F0-9]{64}$' -or
            $seen.ContainsKey($entry.Name)) {
            throw 'B010_SOURCE_LOCK_INVALID'
        }
        $seen[$entry.Name] = $true
    }

    foreach ($name in $required) {
        if (-not $seen.ContainsKey($name)) {
            throw 'B010_SOURCE_LOCK_INVALID'
        }
    }

    $current = @(Get-Aij010BoundSourceLock -Root $Root)
    for ($i = 0; $i -lt $current.Count; $i++) {
        if ($current[$i].Name -cne $expected[$i].Name -or
            $current[$i].Sha256 -cne $expected[$i].Sha256) {
            throw 'B010_SOURCE_CHANGED'
        }
    }
}

function Read-Aij010BootstrapDocument {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Path)

    $full = Assert-Aij010OrdinaryBoundFile -Path $Path
    [byte[]]$bytes = [IO.File]::ReadAllBytes($full)
    if ($bytes.Length -ge 3 -and
        $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        throw 'B010_DOCUMENT_BOM_REJECTED'
    }

    $encoding = New-Object Text.UTF8Encoding($false, $true)
    try { $text = $encoding.GetString($bytes) }
    catch { throw 'B010_DOCUMENT_UTF8_INVALID' }

    $doc = ConvertFrom-Json -InputObject $text -ErrorAction Stop
    if ($null -eq $doc -or $null -eq $doc.Record -or
        $doc.Json -isnot [string] -or
        $doc.Sha256 -isnot [string] -or
        $doc.Sha256 -cnotmatch '^[A-F0-9]{64}$') {
        throw 'B010_DOCUMENT_INVALID'
    }

    $canonical = ConvertTo-Json -InputObject $doc.Record -Depth 40 -Compress
    if ($canonical -cne $doc.Json -or
        (Get-Aij010BoundTextSha256 -Text $doc.Json) -cne $doc.Sha256) {
        throw 'B010_DOCUMENT_CHANGED'
    }
    return $doc
}

function New-Aij010BoundDocument {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)]$Record)

    # Boundary-local canonical document constructor. This deliberately uses
    # the same JSON depth and SHA-256 contract as Phase 000's
    # New-AijD2Document, but does not depend on a dynamically imported
    # function remaining stable across the PLAN -> APPROVE call boundary.
    $json = ConvertTo-Json -InputObject $Record -Depth 40 -Compress
    $sha256 = Get-Aij010BoundTextSha256 -Text $json

    $document = [pscustomobject][ordered]@{
        Record = $Record
        Json = $json
        Sha256 = $sha256
    }

    if ($document.Sha256 -cnotmatch '^[A-F0-9]{64}$' -or
        $document.Json -isnot [string]) {
        throw 'B010_DOCUMENT_CONSTRUCTION_INVALID'
    }

    return $document
}

function Import-Aij010BoundLibraries {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)]$ExpectedSources)

    # Validate the complete fixed source closure before loading any of the
    # reusable Phase 000 / Phase 010 libraries.
    Assert-Aij010BoundSourceLockCurrent -ExpectedSources $ExpectedSources

    # Dot-sourcing from inside this function loads definitions into this
    # function scope. Without promotion those definitions disappear when this
    # importer returns. Collect the exact function names declared by the
    # bound library files, load the libraries, then promote only those declared
    # functions into the containing script scope.
    #
    # Parsing discovers declarations only; it does not execute the source.
    $definitionFiles = @(
        '000-state.ps1',
        '000-state-store.ps1',
        '000-manifest.ps1',
        '000-authorization.ps1',
        '000-config.ps1',
        '010-preflight-core.ps1'
    )

    $declaredFunctions = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)

    foreach ($name in $definitionFiles) {
        $path = Assert-Aij010OrdinaryBoundFile -Path (
            Join-Path $script:Aij010BoundRoot $name
        )

        $tokens = $null
        $parseErrors = $null
        $ast = [Management.Automation.Language.Parser]::ParseFile(
            $path,
            [ref]$tokens,
            [ref]$parseErrors
        )

        if ($null -eq $ast -or @($parseErrors).Count -ne 0) {
            throw "B010_BOUND_LIBRARY_PARSE_FAILED:$name"
        }

        $definitions = @(
            $ast.FindAll(
                {
                    param($node)
                    $node -is [Management.Automation.Language.FunctionDefinitionAst]
                },
                $true
            )
        )

        foreach ($definition in $definitions) {
            if ([string]::IsNullOrWhiteSpace($definition.Name)) {
                throw "B010_BOUND_LIBRARY_FUNCTION_INVALID:$name"
            }

            $null = $declaredFunctions.Add([string]$definition.Name)
        }
    }

    # 000-authorization.ps1 loads its bound state/state-store/manifest
    # dependencies. Config and the Phase 010 core are loaded explicitly.
    . (Join-Path $script:Aij010BoundRoot '000-authorization.ps1')
    . (Join-Path $script:Aij010BoundRoot '000-config.ps1')
    . (Join-Path $script:Aij010BoundRoot '010-preflight-core.ps1')

    foreach ($functionName in @($declaredFunctions | Sort-Object)) {
        $command = Get-Command `
            -Name $functionName `
            -CommandType Function `
            -ErrorAction SilentlyContinue

        if ($null -eq $command) {
            throw "B010_BOUND_LIBRARY_FUNCTION_MISSING:$functionName"
        }

        # Function:\script: targets the script scope that contains this
        # boundary. When the boundary is dot-sourced by 000-engine.ps1 or by
        # the focused fixture, the promoted definitions therefore remain
        # available after this importer returns.
        Set-Item `
            -LiteralPath ("Function:\script:{0}" -f $functionName) `
            -Value $command.ScriptBlock `
            -Force
    }

    foreach ($functionName in @(
        'New-AijD2Document',
        'Save-AijD2Document',
        'Read-AijD2Document',
        'Write-AijD2NewFile',
        'Read-AijStrictUtf8StateText',
        'Read-AijConfig',
        'Read-Aij010Requirements',
        'Invoke-Aij010Preflight',
        'Get-Aij010Decision',
        'Get-Aij010PrivilegeCheck'
    )) {
        if (-not (
            Get-Command `
                -Name $functionName `
                -CommandType Function `
                -ErrorAction SilentlyContinue
        )) {
            throw "B010_REQUIRED_FUNCTION_MISSING:$functionName"
        }
    }

    # Revalidate after loading/promoting so a source change during the import
    # window fails closed before the caller performs any bound operation.
    Assert-Aij010BoundSourceLockCurrent -ExpectedSources $ExpectedSources
}

function Enter-Aij010SessionLock {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$SessionDirectory)

    $full = Assert-Aij010BoundLocalPath -Path $SessionDirectory
    $identity = $full.TrimEnd([char]'\').ToUpperInvariant()
    $mutexName = 'Global\AIJail.RealPreflight010.' + (Get-Aij010BoundTextSha256 -Text $identity)
    $mutex = New-Object Threading.Mutex($false, $mutexName)
    $held = $false
    try {
        try { $held = $mutex.WaitOne(30000) }
        catch [Threading.AbandonedMutexException] { $held = $true }
        if (-not $held) { throw 'B010_LOCK_TIMEOUT' }
        return $mutex
    }
    catch {
        $mutex.Dispose()
        throw
    }
}

function Exit-Aij010SessionLock {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)]$Mutex)
    try { $Mutex.ReleaseMutex() }
    finally { $Mutex.Dispose() }
}

function Assert-Aij010NewSessionPath {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$SessionDirectory)

    $full = Assert-Aij010BoundLocalPath -Path $SessionDirectory
    if (Test-Path -LiteralPath $full) {
        throw 'B010_SESSION_EXISTS'
    }
    $parent = [IO.Path]::GetDirectoryName($full)
    if ([string]::IsNullOrWhiteSpace($parent) -or
        -not [IO.Directory]::Exists($parent)) {
        throw 'B010_SESSION_PARENT_MISSING'
    }
    $null = Assert-Aij010BoundLocalPath -Path $parent
    return $full
}

function Get-Aij010SessionMarker {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$SessionDirectory)

    $full = Assert-Aij010BoundLocalPath -Path $SessionDirectory
    if (-not [IO.Directory]::Exists($full)) {
        throw 'B010_SESSION_MISSING'
    }
    $markerPath = Join-Path $full 'session.json'
    $marker = Read-AijD2Document -Path $markerPath
    $r = $marker.Record
    if ($r.Schema -ne 1 -or
        $r.Kind -cne 'REAL_WINDOWS_PREFLIGHT_010_SESSION' -or
        $r.Scope -cne $script:Aij010BoundScope -or
        $r.Id -isnot [string] -or
        $r.Id -cnotmatch '^[a-f0-9]{32}$' -or
        $r.PathSha256 -cne (Get-AijTextSha256 -Text $full.TrimEnd([char]'\').ToUpperInvariant())) {
        throw 'B010_SESSION_INVALID'
    }
    foreach ($child in @('approvals','evidence')) {
        $childPath = Join-Path $full $child
        $null = Assert-Aij010BoundLocalPath -Path $childPath
        if (-not [IO.Directory]::Exists($childPath)) {
            throw 'B010_SESSION_INVALID'
        }
    }
    return $marker
}

function Get-Aij010HostBinding {
    [CmdletBinding()]
    param()

    try {
        $systems = @(Get-CimInstance -ClassName Win32_ComputerSystemProduct -ErrorAction Stop)
        $os = @(Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop)
        if ($systems.Count -ne 1 -or $os.Count -ne 1) {
            throw 'AMBIGUOUS_HOST_DATA'
        }

        $parts = New-Object 'System.Collections.Generic.List[string]'
        $methods = New-Object 'System.Collections.Generic.List[string]'
        $uuid = [string]$systems[0].UUID
        if (-not [string]::IsNullOrWhiteSpace($uuid) -and
            $uuid -notmatch '^(0{8}-0{4}-0{4}-0{4}-0{12}|F{8}-F{4}-F{4}-F{4}-F{12})$') {
            $parts.Add('CSP_UUID=' + $uuid.ToUpperInvariant())
            $methods.Add('Win32_ComputerSystemProduct.UUID')
        }

        try {
            $mg = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Cryptography' -Name MachineGuid -ErrorAction Stop
            $machineGuid = [string]$mg.MachineGuid
            if (-not [string]::IsNullOrWhiteSpace($machineGuid)) {
                $parts.Add('MACHINE_GUID=' + $machineGuid.ToUpperInvariant())
                $methods.Add('HKLM:MachineGuid')
            }
        }
        catch {
            # UUID alone is acceptable. No raw identifier is persisted.
        }

        if ($parts.Count -lt 1) {
            throw 'HOST_IDENTITY_UNAVAILABLE'
        }

        $boot = $os[0].LastBootUpTime
        if ($boot -is [datetime]) {
            $bootText = $boot.ToUniversalTime().ToString('o')
        }
        else {
            try {
                $bootDate = [Management.ManagementDateTimeConverter]::ToDateTime([string]$boot)
                $bootText = $bootDate.ToUniversalTime().ToString('o')
            }
            catch {
                throw 'BOOT_SESSION_UNAVAILABLE'
            }
        }

        return [pscustomobject][ordered]@{
            ReferenceSha256 = Get-AijTextSha256 -Text (@($parts.ToArray() | Sort-Object) -join '|')
            Methods = @($methods.ToArray() | Sort-Object)
            BootSessionReference = $bootText
        }
    }
    catch {
        throw "B010_HOST_IDENTITY_UNAVAILABLE:$($_.Exception.Message)"
    }
}

function Get-Aij010VolumeBinding {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][hashtable]$Config)

    $drive = [string]$Config['TARGET_DRIVE']
    $root = $drive + '\'
    try {
        $driveInfo = New-Object IO.DriveInfo($root)
        if (-not $driveInfo.IsReady -or $driveInfo.DriveType -ne [IO.DriveType]::Fixed) {
            throw 'TARGET_VOLUME_NOT_READY_FIXED'
        }
        $logical = @(Get-CimInstance -ClassName Win32_LogicalDisk -Filter ("DeviceID='{0}'" -f $drive) -ErrorAction Stop)
        if ($logical.Count -ne 1) { throw 'TARGET_VOLUME_AMBIGUOUS' }
        $serial = [string]$logical[0].VolumeSerialNumber
        $provider = [string]$logical[0].ProviderName
        if ([string]::IsNullOrWhiteSpace($serial) -or
            -not [string]::IsNullOrWhiteSpace($provider) -or
            [int]$logical[0].DriveType -ne 3) {
            throw 'TARGET_VOLUME_IDENTITY_UNAVAILABLE'
        }
        $fileSystem = [string]$logical[0].FileSystem
        $canonical = 'DRIVE=' + $drive.ToUpperInvariant() + '|SERIAL=' + $serial.ToUpperInvariant() + '|FS=' + $fileSystem.ToUpperInvariant()
        return [pscustomobject][ordered]@{
            ReferenceSha256 = Get-AijTextSha256 -Text $canonical
            Drive = $drive
            FileSystem = $fileSystem
            Method = 'DriveInfo+Win32_LogicalDisk'
        }
    }
    catch {
        throw "B010_VOLUME_IDENTITY_UNAVAILABLE:$($_.Exception.Message)"
    }
}

function Get-Aij010CurrentUserReference {
    [CmdletBinding()]
    param()
    $name = [Security.Principal.WindowsIdentity]::GetCurrent().Name
    if ([string]::IsNullOrWhiteSpace($name)) { throw 'B010_USER_IDENTITY_UNAVAILABLE' }
    return Get-AijTextSha256 -Text $name.ToUpperInvariant()
}

function Get-Aij010NetworkPolicy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Profile,
        [Parameter(Mandatory=$true)]$Requirements
    )

    $normalized = ConvertTo-Aij010BoundProfile -Value $Profile
    if ($normalized -ceq 'OFFLINE_DIAGNOSTIC') {
        return [pscustomobject][ordered]@{
            Schema = 1
            Kind = 'REAL_WINDOWS_PREFLIGHT_010_NETWORK_POLICY'
            Enabled = $false
            ProbeId = $null
            Uri = $null
            Method = $null
            ExpectedStatus = $null
            ExpectedBody = $null
            TimeoutSeconds = 0
            MaxResponseBytes = 0
            RedirectsAllowed = $false
            ProxyMode = 'NONE'
            RequestsPerPass = 0
            Passes = 2
            MaximumRequestsTotal = 0
            Purpose = 'OFFLINE_DIAGNOSTIC'
        }
    }

    $p = $Requirements.connectivity.probe
    return [pscustomobject][ordered]@{
        Schema = 1
        Kind = 'REAL_WINDOWS_PREFLIGHT_010_NETWORK_POLICY'
        Enabled = $true
        ProbeId = [string]$p.id
        Uri = [string]$p.uri
        Method = [string]$p.method
        ExpectedStatus = [int]$p.expected_status
        ExpectedBody = [string]$p.expected_body
        TimeoutSeconds = [int]$p.timeout_seconds
        MaxResponseBytes = [int]$p.max_response_bytes
        RedirectsAllowed = [bool]$p.allow_redirects
        ProxyMode = [string]$p.proxy_mode
        RequestsPerPass = 1
        Passes = 2
        MaximumRequestsTotal = 2
        Purpose = [string]$p.purpose
    }
}

function Get-Aij010PermittedProbes {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Profile)

    $items = @(
        'ADMINISTRATOR_STATE',
        'WINDOWS_PLATFORM_CIM_REGISTRY_READ',
        'CPU_FIRMWARE_VIRTUALIZATION_CIM',
        'LOCAL_VOLUME_DRIVEINFO_CIM',
        'WSL_WINDOWS_SIDE_FEATURE_PACKAGE_FILE_READ',
        'SELECTED_REBOOT_REGISTRY_READ'
    )
    if ((ConvertTo-Aij010BoundProfile -Value $Profile) -ceq 'ONLINE_RUNTIME_PASS') {
        $items += 'MICROSOFT_NCSI_BOUNDED_HTTP_GET'
    }
    return @($items)
}

function Get-Aij010NoArtifactLock {
    [CmdletBinding()]
    param()
    return [pscustomobject][ordered]@{
        Schema = 1
        Kind = 'REAL_WINDOWS_PREFLIGHT_010_NO_ARTIFACT_LOCK'
        Artifacts = @()
        NetworkAcquisitionAllowed = $false
        DownloadedCodeExecutionAllowed = $false
        SoftwareAcquisitionAllowed = $false
    }
}

function New-Aij010BoundPlanRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$SessionId,
        [Parameter(Mandatory=$true)][string]$SessionMarkerSha256,
        [Parameter(Mandatory=$true)][string]$Profile,
        [Parameter(Mandatory=$true)][string]$RequirementsSha256,
        [Parameter(Mandatory=$true)][string]$ConfigurationSha256,
        [Parameter(Mandatory=$true)]$SourceFiles,
        [Parameter(Mandatory=$true)][string]$SourceLockSha256,
        [Parameter(Mandatory=$true)]$ArtifactLock,
        [Parameter(Mandatory=$true)][string]$ArtifactLockSha256,
        [Parameter(Mandatory=$true)]$HostBinding,
        [Parameter(Mandatory=$true)]$VolumeBinding,
        [Parameter(Mandatory=$true)]$NetworkPolicy,
        [Parameter(Mandatory=$true)][string]$NetworkPolicySha256,
        [Parameter(Mandatory=$true)][int]$RequirementsContractVersion
    )

    $normalized = ConvertTo-Aij010BoundProfile -Value $Profile
    return [pscustomobject][ordered]@{
        Schema = 1
        Kind = 'REAL_WINDOWS_PREFLIGHT_010_PLAN'
        Scope = $script:Aij010BoundScope
        Phase = '010'
        OperationKind = 'COLLECT_AND_VERIFY'
        Profile = $normalized
        SessionId = $SessionId
        SessionMarkerSha256 = $SessionMarkerSha256
        RequirementsContractVersion = $RequirementsContractVersion
        RequirementsSha256 = $RequirementsSha256
        ConfigurationSha256 = $ConfigurationSha256
        SourceFiles = @($SourceFiles)
        SourceLockSha256 = $SourceLockSha256
        ArtifactLock = $ArtifactLock
        ArtifactLockSha256 = $ArtifactLockSha256
        HostIdentitySha256 = $HostBinding.ReferenceSha256
        VolumeIdentitySha256 = $VolumeBinding.ReferenceSha256
        TargetDrive = $VolumeBinding.Drive
        BootSessionReference = $HostBinding.BootSessionReference
        PreviousStateSha256 = $script:Aij010ZeroSha256
        PreviousEvidenceSha256 = $script:Aij010ZeroSha256
        NetworkPolicy = $NetworkPolicy
        NetworkPolicySha256 = $NetworkPolicySha256
        PermittedProbes = @(Get-Aij010PermittedProbes -Profile $normalized)
        PrivilegePolicy = 'ADMINISTRATOR_REQUIRED_AT_EXECUTION'
        FreshnessPolicySeconds = $script:Aij010FreshnessSeconds
        ProductionApplyAuthorized = $false
        GeneralProductionVerifyAuthorized = $false
        CreatedAtUtc = [DateTime]::UtcNow.ToString('o')
    }
}

function Get-Aij010ConfirmationToken {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)]$Plan)
    if ($Plan.Sha256 -isnot [string] -or $Plan.Sha256 -cnotmatch '^[A-F0-9]{64}$') {
        throw 'B010_PLAN_INVALID'
    }
    return 'APPROVE-010-' + $Plan.Sha256
}

function Get-Aij010AuditTail {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$SessionDirectory)

    $path = Join-Path $SessionDirectory 'audit.jsonl'
    $null = Assert-Aij010BoundLocalPath -Path $path
    $previous = $script:Aij010ZeroSha256
    $sequence = 0
    $planSha = $null
    $approvalHashes = New-Object 'System.Collections.Generic.List[string]'
    $receiptSha = $null

    if ([IO.File]::Exists($path)) {
        $text = Read-AijStrictUtf8StateText -Path $path
        if (-not $text.EndsWith("`n")) { throw 'B010_AUDIT_TRUNCATED' }
        foreach ($line in $text.Split([char]10)) {
            if ($line.Length -eq 0) { continue }
            $entry = ConvertFrom-Json -InputObject $line -ErrorAction Stop
            Assert-AijD2Document -Document $entry
            $r = $entry.Record
            if ($r.Schema -ne 1 -or
                $r.Kind -cne 'REAL_WINDOWS_PREFLIGHT_010_AUDIT' -or
                $r.Scope -cne $script:Aij010BoundScope -or
                $r.Phase -cne '010' -or
                $r.Sequence -ne ($sequence + 1) -or
                $r.PreviousSha256 -cne $previous -or
                $r.Event -cnotin @(
                    'SESSION_PLANNED','APPROVAL_RECORDED','EXECUTION_STARTED',
                    'COLLECTION_PERSISTED','VERIFICATION_PERSISTED',
                    'RECEIPT_COMMITTED','EXECUTION_FAILED'
                )) {
                throw 'B010_AUDIT_CHAIN_INVALID'
            }
            $sequence++
            $previous = $entry.Sha256
            if ($r.Event -ceq 'SESSION_PLANNED') { $planSha = $r.PlanSha256 }
            if ($r.Event -ceq 'APPROVAL_RECORDED') { $approvalHashes.Add($r.ApprovalSha256) }
            if ($r.Event -ceq 'RECEIPT_COMMITTED') { $receiptSha = $r.EvidenceSha256 }
        }
    }
    elseif (Test-Path -LiteralPath $path) {
        throw 'B010_AUDIT_PATH_INVALID'
    }

    return [pscustomobject]@{
        Sequence = $sequence
        Sha256 = $previous
        PlanSha256 = $planSha
        ApprovalHashes = @($approvalHashes.ToArray())
        ReceiptSha256 = $receiptSha
    }
}

function Write-Aij010Audit {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$SessionDirectory,
        [Parameter(Mandatory=$true)]
        [ValidateSet('SESSION_PLANNED','APPROVAL_RECORDED','EXECUTION_STARTED','COLLECTION_PERSISTED','VERIFICATION_PERSISTED','RECEIPT_COMMITTED','EXECUTION_FAILED')]
        [string]$Event,
        [Parameter(Mandatory=$true)][ValidatePattern('^[A-F0-9]{64}$')][string]$PlanSha256,
        [ValidatePattern('^[A-F0-9]{64}$')][string]$ApprovalSha256 = ('0' * 64),
        [string]$OperationId = $null,
        [ValidatePattern('^[A-F0-9]{64}$')][string]$EvidenceSha256 = ('0' * 64),
        [string]$Outcome = $null
    )

    $tail = Get-Aij010AuditTail -SessionDirectory $SessionDirectory
    $record = [pscustomobject][ordered]@{
        Schema = 1
        Kind = 'REAL_WINDOWS_PREFLIGHT_010_AUDIT'
        Scope = $script:Aij010BoundScope
        Phase = '010'
        Sequence = $tail.Sequence + 1
        PreviousSha256 = $tail.Sha256
        Utc = [DateTime]::UtcNow.ToString('o')
        Event = $Event
        PlanSha256 = $PlanSha256
        ApprovalSha256 = $ApprovalSha256
        OperationId = $OperationId
        EvidenceSha256 = $EvidenceSha256
        Outcome = $Outcome
    }
    $entry = New-AijD2Document -Record $record
    $line = (ConvertTo-Json -InputObject $entry -Depth 45 -Compress) + "`n"
    $bytes = (New-Object Text.UTF8Encoding($false,$true)).GetBytes($line)
    $path = Join-Path $SessionDirectory 'audit.jsonl'
    $null = Assert-Aij010BoundLocalPath -Path $path
    $stream = [IO.File]::Open($path,[IO.FileMode]::Append,[IO.FileAccess]::Write,[IO.FileShare]::Read)
    try { $stream.Write($bytes,0,$bytes.Length); $stream.Flush($true) }
    finally { $stream.Dispose() }
    return $entry
}

function Open-Aij010BoundContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$SessionDirectory,
        [switch]$SkipMutableBinding
    )

    $sessionFull = Assert-Aij010BoundLocalPath -Path $SessionDirectory
    if (-not [IO.Directory]::Exists($sessionFull)) { throw 'B010_SESSION_MISSING' }
    $bootstrapPlan = Read-Aij010BootstrapDocument -Path (Join-Path $sessionFull 'plan.json')
    if ($bootstrapPlan.Record.Kind -cne 'REAL_WINDOWS_PREFLIGHT_010_PLAN' -or
        $bootstrapPlan.Record.Scope -cne $script:Aij010BoundScope) {
        throw 'B010_PLAN_INVALID'
    }

    Assert-Aij010BoundSourceLockCurrent -ExpectedSources @($bootstrapPlan.Record.SourceFiles)
    Import-Aij010BoundLibraries -ExpectedSources @($bootstrapPlan.Record.SourceFiles)

    $plan = Read-AijD2Document -Path (Join-Path $sessionFull 'plan.json')
    if ($plan.Sha256 -cne $bootstrapPlan.Sha256) { throw 'B010_PLAN_CHANGED' }
    $marker = Get-Aij010SessionMarker -SessionDirectory $sessionFull
    $p = $plan.Record

    if ($p.Schema -ne 1 -or
        $p.Kind -cne 'REAL_WINDOWS_PREFLIGHT_010_PLAN' -or
        $p.Scope -cne $script:Aij010BoundScope -or
        $p.Phase -cne '010' -or
        $p.OperationKind -cne 'COLLECT_AND_VERIFY' -or
        $p.SessionId -cne $marker.Record.Id -or
        $p.SessionMarkerSha256 -cne $marker.Sha256 -or
        $p.ProductionApplyAuthorized -ne $false -or
        $p.GeneralProductionVerifyAuthorized -ne $false -or
        $p.PreviousStateSha256 -cne $script:Aij010ZeroSha256 -or
        $p.PreviousEvidenceSha256 -cne $script:Aij010ZeroSha256 -or
        $p.FreshnessPolicySeconds -ne $script:Aij010FreshnessSeconds) {
        throw 'B010_PLAN_INVALID'
    }

    $sourceDoc = New-AijD2Document -Record @($p.SourceFiles)
    if ($sourceDoc.Sha256 -cne $p.SourceLockSha256) { throw 'B010_SOURCE_LOCK_INVALID' }

    $artifactDoc = New-AijD2Document -Record $p.ArtifactLock
    if ($artifactDoc.Sha256 -cne $p.ArtifactLockSha256 -or
        $p.ArtifactLock.Kind -cne 'REAL_WINDOWS_PREFLIGHT_010_NO_ARTIFACT_LOCK' -or
        @($p.ArtifactLock.Artifacts).Count -ne 0 -or
        $p.ArtifactLock.NetworkAcquisitionAllowed -ne $false -or
        $p.ArtifactLock.DownloadedCodeExecutionAllowed -ne $false -or
        $p.ArtifactLock.SoftwareAcquisitionAllowed -ne $false) {
        throw 'B010_ARTIFACT_LOCK_INVALID'
    }

    $requirementsPath = Join-Path $script:Aij010BoundRoot '010-requirements.json'
    $configPath = Join-Path $script:Aij010BoundRoot 'config.env'
    if ((Get-FileHash -LiteralPath $requirementsPath -Algorithm SHA256).Hash -cne $p.RequirementsSha256) {
        throw 'B010_REQUIREMENTS_CHANGED'
    }
    if ((Get-FileHash -LiteralPath $configPath -Algorithm SHA256).Hash -cne $p.ConfigurationSha256) {
        throw 'B010_CONFIG_CHANGED'
    }

    $requirements = Read-Aij010Requirements -Path $requirementsPath
    $config = Read-AijConfig -Path $configPath
    if ($requirements.contract_version -ne $p.RequirementsContractVersion) {
        throw 'B010_REQUIREMENTS_CHANGED'
    }

    $network = Get-Aij010NetworkPolicy -Profile $p.Profile -Requirements $requirements
    if ((New-AijD2Document -Record $network).Sha256 -cne $p.NetworkPolicySha256 -or
        (New-AijD2Document -Record $p.NetworkPolicy).Sha256 -cne $p.NetworkPolicySha256) {
        throw 'B010_NETWORK_POLICY_CHANGED'
    }

    $expectedProbes = @(Get-Aij010PermittedProbes -Profile $p.Profile)
    if ((@($p.PermittedProbes) -join '|') -cne ($expectedProbes -join '|')) {
        throw 'B010_PROBE_SCOPE_CHANGED'
    }

    $preflightHostIdentity = $null
    $volume = $null
    if (-not $SkipMutableBinding.IsPresent) {
        $preflightHostIdentity = Get-Aij010HostBinding
        $volume = Get-Aij010VolumeBinding -Config $config
        if ($preflightHostIdentity.ReferenceSha256 -cne $p.HostIdentitySha256) { throw 'B010_HOST_CHANGED' }
        if ($volume.ReferenceSha256 -cne $p.VolumeIdentitySha256 -or $volume.Drive -cne $p.TargetDrive) {
            throw 'B010_VOLUME_CHANGED'
        }
        if ($preflightHostIdentity.BootSessionReference -cne $p.BootSessionReference) { throw 'B010_BOOT_SESSION_CHANGED' }
    }

    $tail = Get-Aij010AuditTail -SessionDirectory $sessionFull
    if ($tail.PlanSha256 -cne $plan.Sha256) { throw 'B010_PLAN_NOT_RECORDED' }

    return [pscustomobject]@{
        SessionDirectory = $sessionFull
        SessionMarker = $marker
        Plan = $plan
        Requirements = $requirements
        Config = $config
        HostBinding = $preflightHostIdentity
        VolumeBinding = $volume
        AuditTail = $tail
    }
}

function New-Aij010BoundPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$SessionDirectory,
        [Parameter(Mandatory=$true)][string]$Profile
    )

    $normalizedProfile = ConvertTo-Aij010BoundProfile -Value $Profile
    $sessionFull = Assert-Aij010NewSessionPath -SessionDirectory $SessionDirectory
    $mutex = Enter-Aij010SessionLock -SessionDirectory $sessionFull
    try {
        if (Test-Path -LiteralPath $sessionFull) { throw 'B010_SESSION_EXISTS' }

        $sources = @(Get-Aij010BoundSourceLock)
        Import-Aij010BoundLibraries -ExpectedSources $sources

        $requirementsPath = Join-Path $script:Aij010BoundRoot '010-requirements.json'
        $configPath = Join-Path $script:Aij010BoundRoot 'config.env'
        $requirements = Read-Aij010Requirements -Path $requirementsPath
        $config = Read-AijConfig -Path $configPath

        $preflightHostIdentity = Get-Aij010HostBinding
        $volume = Get-Aij010VolumeBinding -Config $config
        $network = Get-Aij010NetworkPolicy -Profile $normalizedProfile -Requirements $requirements
        $artifact = Get-Aij010NoArtifactLock

        [void][IO.Directory]::CreateDirectory($sessionFull)
        [void][IO.Directory]::CreateDirectory((Join-Path $sessionFull 'approvals'))
        [void][IO.Directory]::CreateDirectory((Join-Path $sessionFull 'evidence'))

        $sessionId = [guid]::NewGuid().ToString('N')
        $marker = New-AijD2Document -Record ([pscustomobject][ordered]@{
            Schema = 1
            Kind = 'REAL_WINDOWS_PREFLIGHT_010_SESSION'
            Scope = $script:Aij010BoundScope
            Phase = '010'
            Id = $sessionId
            PathSha256 = Get-AijTextSha256 -Text $sessionFull.TrimEnd([char]'\').ToUpperInvariant()
            CreatedAtUtc = [DateTime]::UtcNow.ToString('o')
        })
        Save-AijD2Document -Path (Join-Path $sessionFull 'session.json') -Document $marker

        $sourceLockSha = (New-AijD2Document -Record $sources).Sha256
        $artifactSha = (New-AijD2Document -Record $artifact).Sha256
        $networkSha = (New-AijD2Document -Record $network).Sha256
        $record = New-Aij010BoundPlanRecord `
            -SessionId $sessionId `
            -SessionMarkerSha256 $marker.Sha256 `
            -Profile $normalizedProfile `
            -RequirementsSha256 (Get-FileHash -LiteralPath $requirementsPath -Algorithm SHA256).Hash `
            -ConfigurationSha256 (Get-FileHash -LiteralPath $configPath -Algorithm SHA256).Hash `
            -SourceFiles $sources `
            -SourceLockSha256 $sourceLockSha `
            -ArtifactLock $artifact `
            -ArtifactLockSha256 $artifactSha `
            -HostBinding $preflightHostIdentity `
            -VolumeBinding $volume `
            -NetworkPolicy $network `
            -NetworkPolicySha256 $networkSha `
            -RequirementsContractVersion ([int]$requirements.contract_version)

        $plan = New-AijD2Document -Record $record
        Save-AijD2Document -Path (Join-Path $sessionFull 'plan.json') -Document $plan
        $null = Write-Aij010Audit -SessionDirectory $sessionFull -Event 'SESSION_PLANNED' -PlanSha256 $plan.Sha256

        return [pscustomobject]@{
            SessionDirectory = $sessionFull
            Plan = $plan
            ConfirmationToken = Get-Aij010ConfirmationToken -Plan $plan
            Profile = $normalizedProfile
            MaximumNetworkRequests = [int]$network.MaximumRequestsTotal
        }
    }
    finally {
        Exit-Aij010SessionLock -Mutex $mutex
    }
}

function Assert-Aij010NoPending {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$SessionDirectory)
    if (Test-Path -LiteralPath (Join-Path $SessionDirectory 'pending.json')) {
        throw 'B010_RECOVERY_REQUIRED'
    }
}

function Assert-Aij010ApprovalUnused {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$SessionDirectory,
        [Parameter(Mandatory=$true)][string]$ApprovalId
    )
    $path = Join-Path (Join-Path $SessionDirectory 'approvals') ($ApprovalId + '.used')
    $null = Assert-Aij010BoundLocalPath -Path $path
    if (Test-Path -LiteralPath $path) { throw 'B010_APPROVAL_CONSUMED' }
}

function Assert-Aij010ApprovalBinding {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]$Plan,
        [Parameter(Mandatory=$true)]$Approval,
        [Parameter(Mandatory=$true)][string]$CurrentUserReference
    )

    Assert-AijD2Document -Document $Plan
    Assert-AijD2Document -Document $Approval
    $p = $Plan.Record
    $a = $Approval.Record
    if ($a.Schema -ne 1 -or
        $a.Kind -cne 'REAL_WINDOWS_PREFLIGHT_010_APPROVAL' -or
        $a.Scope -cne $script:Aij010BoundScope -or
        $a.Phase -cne '010' -or
        $a.Id -isnot [string] -or $a.Id -cnotmatch '^[a-f0-9]{32}$' -or
        $a.OperationId -isnot [string] -or $a.OperationId -cnotmatch '^[a-f0-9]{32}$' -or
        $a.PlanSha256 -cne $Plan.Sha256 -or
        $a.OperationKind -cne $p.OperationKind -or
        $a.Profile -cne $p.Profile -or
        $a.ConfigurationSha256 -cne $p.ConfigurationSha256 -or
        $a.RequirementsSha256 -cne $p.RequirementsSha256 -or
        $a.SourceLockSha256 -cne $p.SourceLockSha256 -or
        $a.ArtifactLockSha256 -cne $p.ArtifactLockSha256 -or
        $a.HostIdentitySha256 -cne $p.HostIdentitySha256 -or
        $a.VolumeIdentitySha256 -cne $p.VolumeIdentitySha256 -or
        $a.BootSessionReference -cne $p.BootSessionReference -or
        $a.NetworkPolicySha256 -cne $p.NetworkPolicySha256 -or
        $a.PreviousStateSha256 -cne $p.PreviousStateSha256 -or
        $a.PreviousEvidenceSha256 -cne $p.PreviousEvidenceSha256 -or
        $a.ApprovedByReferenceSha256 -cne $CurrentUserReference -or
        $a.ProductionApplyAuthorized -ne $false -or
        $a.ApprovedAtUtc -isnot [string] -or $a.ApprovedAtUtc -notmatch '^\d{4}-\d{2}-\d{2}T') {
        throw 'B010_APPROVAL_BINDING_CHANGED'
    }
}

function New-Aij010BoundApproval {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$SessionDirectory,
        [Parameter(Mandatory=$true)][string]$ConfirmationToken
    )

    $mutex = Enter-Aij010SessionLock -SessionDirectory $SessionDirectory
    try {
        $context = Open-Aij010BoundContext -SessionDirectory $SessionDirectory
        Assert-Aij010NoPending -SessionDirectory $context.SessionDirectory

        $approvalDirectory = Join-Path $context.SessionDirectory 'approvals'
        if (@(Get-ChildItem -LiteralPath $approvalDirectory -Filter '*.json' -File -ErrorAction Stop).Count -gt 0) {
            throw 'B010_APPROVAL_ALREADY_EXISTS'
        }

        if ($ConfirmationToken -cne (Get-Aij010ConfirmationToken -Plan $context.Plan)) {
            throw 'B010_EXPLICIT_APPROVAL_REQUIRED'
        }

        $p = $context.Plan.Record
        $record = [pscustomobject][ordered]@{
            Schema = 1
            Kind = 'REAL_WINDOWS_PREFLIGHT_010_APPROVAL'
            Scope = $script:Aij010BoundScope
            Phase = '010'
            Id = [guid]::NewGuid().ToString('N')
            OperationId = [guid]::NewGuid().ToString('N')
            PlanSha256 = $context.Plan.Sha256
            OperationKind = $p.OperationKind
            Profile = $p.Profile
            ConfigurationSha256 = $p.ConfigurationSha256
            RequirementsSha256 = $p.RequirementsSha256
            SourceLockSha256 = $p.SourceLockSha256
            ArtifactLockSha256 = $p.ArtifactLockSha256
            HostIdentitySha256 = $p.HostIdentitySha256
            VolumeIdentitySha256 = $p.VolumeIdentitySha256
            BootSessionReference = $p.BootSessionReference
            NetworkPolicySha256 = $p.NetworkPolicySha256
            PreviousStateSha256 = $p.PreviousStateSha256
            PreviousEvidenceSha256 = $p.PreviousEvidenceSha256
            ApprovedByReferenceSha256 = Get-Aij010CurrentUserReference
            ApprovedAtUtc = [DateTime]::UtcNow.ToString('o')
            ProductionApplyAuthorized = $false
        }
        $approval = New-Aij010BoundDocument -Record $record
        Assert-AijD2Document -Document $approval
        $null = Write-Aij010Audit -SessionDirectory $context.SessionDirectory -Event 'APPROVAL_RECORDED' -PlanSha256 $context.Plan.Sha256 -ApprovalSha256 $approval.Sha256 -OperationId $record.OperationId
        $path = Join-Path $approvalDirectory ($record.Id + '.json')
        Save-AijD2Document -Path $path -Document $approval
        return [pscustomobject]@{ Path=$path; Approval=$approval }
    }
    finally {
        Exit-Aij010SessionLock -Mutex $mutex
    }
}

function Get-Aij010NetworkRequestCount {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)]$PreflightRecord)

    $connectivity = $PreflightRecord.Checks.Connectivity
    if ($connectivity.Status -ceq 'NOT_RUN') { return 0 }
    if ($null -eq $connectivity.Observation -or
        $null -eq $connectivity.Observation.PSObject.Properties['RequestCount']) {
        throw 'B010_NETWORK_REQUEST_COUNT_UNKNOWN'
    }
    [int]$count = $connectivity.Observation.RequestCount
    if ($count -lt 0 -or $count -gt 1) { throw 'B010_NETWORK_REQUEST_COUNT_INVALID' }
    return $count
}

function Assert-Aij010DecisionIntegrity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]$PreflightRecord,
        [Parameter(Mandatory=$true)][string]$Operation
    )

    if ($PreflightRecord.Scope -cne 'REAL_WINDOWS_PREFLIGHT_010_UNBOUND' -or
        $PreflightRecord.Phase -cne '010' -or
        $PreflightRecord.Decision.RuntimePass -ne $false) {
        throw 'B010_PREFLIGHT_RECORD_INVALID'
    }
    $recomputed = Get-Aij010Decision -Operation $Operation -Checks $PreflightRecord.Checks
    foreach ($name in @('Outcome','ExitCode','RequiredCheckCompletion','ObservationCompletion','RuntimePassCandidate','RuntimePass','DependencyResult')) {
        if ($PreflightRecord.Decision.$name -cne $recomputed.$name) {
            throw 'B010_DECISION_RECOMPUTE_MISMATCH'
        }
    }
    return $recomputed
}

function New-Aij010CollectionDocument {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]$Context,
        [Parameter(Mandatory=$true)]$Approval,
        [Parameter(Mandatory=$true)]$PreflightRecord
    )

    $operation = if ($Context.Plan.Record.Profile -ceq 'ONLINE_RUNTIME_PASS') { 'COLLECT_ONLINE' } else { 'COLLECT_OFFLINE' }
    $recomputed = Assert-Aij010DecisionIntegrity -PreflightRecord $PreflightRecord -Operation $operation
    $requests = Get-Aij010NetworkRequestCount -PreflightRecord $PreflightRecord
    $record = [pscustomobject][ordered]@{
        Schema = 1
        Kind = 'REAL_WINDOWS_PREFLIGHT_010_COLLECTION'
        Scope = $script:Aij010BoundScope
        Phase = '010'
        EvidenceOrigin = 'LIVE_BOUND_EXECUTION'
        OperationId = $Approval.Record.OperationId
        PlanSha256 = $Context.Plan.Sha256
        ApprovalSha256 = $Approval.Sha256
        RequirementsSha256 = $Context.Plan.Record.RequirementsSha256
        ConfigurationSha256 = $Context.Plan.Record.ConfigurationSha256
        SourceLockSha256 = $Context.Plan.Record.SourceLockSha256
        HostIdentitySha256 = $Context.Plan.Record.HostIdentitySha256
        VolumeIdentitySha256 = $Context.Plan.Record.VolumeIdentitySha256
        BootSessionReference = $Context.Plan.Record.BootSessionReference
        PreviousStateSha256 = $Context.Plan.Record.PreviousStateSha256
        PreviousEvidenceSha256 = $Context.Plan.Record.PreviousEvidenceSha256
        Profile = $Context.Plan.Record.Profile
        NetworkPolicySha256 = $Context.Plan.Record.NetworkPolicySha256
        NetworkRequestsObserved = $requests
        CollectedAtUtc = [DateTime]::UtcNow.ToString('o')
        PreflightRecord = $PreflightRecord
        RecomputedDecision = $recomputed
        RuntimePassEmitted = $false
    }
    return New-AijD2Document -Record $record
}

function Get-Aij010ReasonSummary {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)]$PreflightRecord)

    $bootstrap = New-Object 'System.Collections.Generic.List[string]'
    $manual = New-Object 'System.Collections.Generic.List[string]'
    $unknown = New-Object 'System.Collections.Generic.List[string]'
    foreach ($property in $PreflightRecord.Checks.PSObject.Properties) {
        $check = $property.Value
        if ($null -eq $check) { continue }
        if ($check.Decision -in @('BOOTSTRAP_NEEDED','ABSENT_BOOTSTRAP_NEEDED','KNOWN_TOO_OLD','PRESENT_VERSION_UNKNOWN')) {
            foreach ($reason in @($check.Reasons)) { if (-not [string]::IsNullOrWhiteSpace([string]$reason)) { $bootstrap.Add([string]$reason) } }
        }
        if ($check.Decision -ceq 'MANUAL_ACTION_NEEDED') {
            foreach ($reason in @($check.Reasons)) { if (-not [string]::IsNullOrWhiteSpace([string]$reason)) { $manual.Add([string]$reason) } }
        }
        if ($check.Status -ceq 'UNKNOWN') {
            foreach ($reason in @($check.Reasons)) { if (-not [string]::IsNullOrWhiteSpace([string]$reason)) { $unknown.Add([string]$reason) } }
        }
    }
    return [pscustomobject]@{
        BootstrapReasons = @($bootstrap.ToArray() | Sort-Object -Unique)
        ManualActionReasons = @($manual.ToArray() | Sort-Object -Unique)
        UnknownReasons = @($unknown.ToArray() | Sort-Object -Unique)
    }
}

function New-Aij010VerificationDocument {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]$Context,
        [Parameter(Mandatory=$true)]$Approval,
        [Parameter(Mandatory=$true)]$Collection,
        [Parameter(Mandatory=$true)]$FreshPreflightRecord,
        [Parameter(Mandatory=$true)]$FreshHostBinding,
        [Parameter(Mandatory=$true)]$FreshVolumeBinding
    )

    $operation = if ($Context.Plan.Record.Profile -ceq 'ONLINE_RUNTIME_PASS') { 'COLLECT_ONLINE' } else { 'COLLECT_OFFLINE' }
    $freshDecision = Assert-Aij010DecisionIntegrity -PreflightRecord $FreshPreflightRecord -Operation $operation
    $reasonSummary = Get-Aij010ReasonSummary -PreflightRecord $FreshPreflightRecord
    $freshRequests = Get-Aij010NetworkRequestCount -PreflightRecord $FreshPreflightRecord
    $collectionRequests = [int]$Collection.Record.NetworkRequestsObserved
    $totalRequests = $collectionRequests + $freshRequests
    if ($totalRequests -gt [int]$Context.Plan.Record.NetworkPolicy.MaximumRequestsTotal) {
        throw 'B010_NETWORK_REQUEST_BOUND_EXCEEDED'
    }

    $sameBinding = (
        $FreshHostBinding.ReferenceSha256 -ceq $Context.Plan.Record.HostIdentitySha256 -and
        $FreshHostBinding.BootSessionReference -ceq $Context.Plan.Record.BootSessionReference -and
        $FreshVolumeBinding.ReferenceSha256 -ceq $Context.Plan.Record.VolumeIdentitySha256
    )

    $runtimePass = (
        $Context.Plan.Record.Profile -ceq 'ONLINE_RUNTIME_PASS' -and
        $Collection.Record.RecomputedDecision.RuntimePassCandidate -eq $true -and
        $Collection.Record.RecomputedDecision.RequiredCheckCompletion -eq $true -and
        $freshDecision.RuntimePassCandidate -eq $true -and
        $freshDecision.RequiredCheckCompletion -eq $true -and
        $sameBinding -and
        $totalRequests -eq 2
    )

    $preflightComplete = (
        $Context.Plan.Record.Profile -ceq 'ONLINE_RUNTIME_PASS' -and
        $Collection.Record.RecomputedDecision.ObservationCompletion -eq $true -and
        $freshDecision.ObservationCompletion -eq $true -and $sameBinding -and $totalRequests -eq 2
    )
    $localDiagnosticPass = (
        $Context.Plan.Record.Profile -ceq 'OFFLINE_DIAGNOSTIC' -and
        $Collection.Record.RecomputedDecision.ExitCode -eq 0 -and
        $freshDecision.ExitCode -eq 0 -and
        $sameBinding -and
        $totalRequests -eq 0
    )

    $decision = if ($runtimePass) { 'PASS' } elseif ($preflightComplete) { 'COMPLETE_WITH_WARNINGS' } elseif ($localDiagnosticPass) { 'LOCAL_DIAGNOSTIC_PASS' } else { 'FAIL' }
    $dependency = if ($runtimePass) { '010 RUNTIME_PASS' } elseif ($preflightComplete) { '010 PREFLIGHT_COMPLETE' } else { 'NOT_EMITTED' }

    $record = [pscustomobject][ordered]@{
        Schema = 1
        Kind = 'REAL_WINDOWS_PREFLIGHT_010_VERIFICATION'
        Scope = $script:Aij010BoundScope
        Phase = '010'
        EvidenceOrigin = 'LIVE_BOUND_EXECUTION'
        OperationId = $Approval.Record.OperationId
        PlanSha256 = $Context.Plan.Sha256
        ApprovalSha256 = $Approval.Sha256
        CollectionResultSha256 = $Collection.Sha256
        RequirementsSha256 = $Context.Plan.Record.RequirementsSha256
        ConfigurationSha256 = $Context.Plan.Record.ConfigurationSha256
        SourceLockSha256 = $Context.Plan.Record.SourceLockSha256
        HostIdentitySha256 = $Context.Plan.Record.HostIdentitySha256
        VolumeIdentitySha256 = $Context.Plan.Record.VolumeIdentitySha256
        BootSessionReference = $Context.Plan.Record.BootSessionReference
        Profile = $Context.Plan.Record.Profile
        NetworkPolicySha256 = $Context.Plan.Record.NetworkPolicySha256
        NetworkRequestsObservedTotal = $totalRequests
        FreshnessPolicySeconds = $Context.Plan.Record.FreshnessPolicySeconds
        VerifiedAtUtc = [DateTime]::UtcNow.ToString('o')
        FreshPreflightRecord = $FreshPreflightRecord
        FreshRecomputedDecision = $freshDecision
        VerificationDecision = $decision
        EligibleForBootstrap = $freshDecision.EligibleForBootstrap
        BootstrapNeeded = $freshDecision.BootstrapNeeded
        BootstrapReasons = @($reasonSummary.BootstrapReasons)
        ManualActionReasons = @($reasonSummary.ManualActionReasons)
        UnknownReasons = @($reasonSummary.UnknownReasons)
        DependencyResult = $dependency
        DependencyScope = $(if ($runtimePass -or $preflightComplete) { $script:Aij010BoundScope } else { 'NOT_EMITTED' })
        CanSatisfy010PreflightComplete = [bool]$preflightComplete
        InstallationAuthorized = $false
        WarningReasons = @($(foreach ($record in @($Collection.Record.PreflightRecord,$FreshPreflightRecord)) {
            foreach ($check in $record.Checks.PSObject.Properties) {
                if ($check.Value.Status -ceq 'WARN') { $check.Value.Reasons }
            }
        }) | Sort-Object -Unique)
        CanSatisfy010RuntimePass = [bool]$runtimePass
        RuntimePassMeaning = 'Bound real Windows preflight only; no WSL runtime, distro, sandbox, installation or provider proof.'
    }
    return New-AijD2Document -Record $record
}

function Assert-Aij010RuntimePassDocuments {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]$Plan,
        [Parameter(Mandatory=$true)]$Collection,
        [Parameter(Mandatory=$true)]$Verification
    )

    foreach ($doc in @($Plan,$Collection,$Verification)) { Assert-AijD2Document -Document $doc }
    $p = $Plan.Record; $c = $Collection.Record; $v = $Verification.Record
    if ($p.Scope -cne $script:Aij010BoundScope -or
        $c.Kind -cne 'REAL_WINDOWS_PREFLIGHT_010_COLLECTION' -or
        $v.Kind -cne 'REAL_WINDOWS_PREFLIGHT_010_VERIFICATION' -or
        $c.Scope -cne $script:Aij010BoundScope -or $v.Scope -cne $script:Aij010BoundScope -or
        $c.EvidenceOrigin -cne 'LIVE_BOUND_EXECUTION' -or $v.EvidenceOrigin -cne 'LIVE_BOUND_EXECUTION' -or
        $p.Profile -cne 'ONLINE_RUNTIME_PASS' -or $c.Profile -cne $p.Profile -or $v.Profile -cne $p.Profile -or
        $c.PlanSha256 -cne $Plan.Sha256 -or $v.PlanSha256 -cne $Plan.Sha256 -or
        $v.CollectionResultSha256 -cne $Collection.Sha256 -or
        $c.OperationId -cne $v.OperationId -or
        $c.HostIdentitySha256 -cne $p.HostIdentitySha256 -or $v.HostIdentitySha256 -cne $p.HostIdentitySha256 -or
        $c.VolumeIdentitySha256 -cne $p.VolumeIdentitySha256 -or $v.VolumeIdentitySha256 -cne $p.VolumeIdentitySha256 -or
        $c.BootSessionReference -cne $p.BootSessionReference -or $v.BootSessionReference -cne $p.BootSessionReference -or
        $c.RecomputedDecision.RuntimePassCandidate -ne $true -or
        $c.RecomputedDecision.RequiredCheckCompletion -ne $true -or
        $v.FreshRecomputedDecision.RuntimePassCandidate -ne $true -or
        $v.FreshRecomputedDecision.RequiredCheckCompletion -ne $true -or
        $v.VerificationDecision -cne 'PASS' -or
        $v.DependencyResult -cne '010 RUNTIME_PASS' -or
        $v.DependencyScope -cne $script:Aij010BoundScope -or
        $v.CanSatisfy010RuntimePass -ne $true -or
        $v.NetworkRequestsObservedTotal -ne 2) {
        throw 'B010_RUNTIME_EVIDENCE_INVALID'
    }

    $collectedAt = [DateTime]::Parse($c.CollectedAtUtc).ToUniversalTime()
    $verifiedAt = [DateTime]::Parse($v.VerifiedAtUtc).ToUniversalTime()
    if ($verifiedAt -lt $collectedAt -or
        ($verifiedAt - $collectedAt).TotalSeconds -gt [int]$p.FreshnessPolicySeconds) {
        throw 'B010_RUNTIME_EVIDENCE_STALE'
    }
}

function Test-Aij010RuntimePassDocument {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)]$Document)
    try {
        Assert-AijD2Document -Document $Document
        return (
            $Document.Record.Kind -ceq 'REAL_WINDOWS_PREFLIGHT_010_VERIFICATION' -and
            $Document.Record.Scope -ceq $script:Aij010BoundScope -and
            $Document.Record.EvidenceOrigin -ceq 'LIVE_BOUND_EXECUTION' -and
            $Document.Record.DependencyResult -ceq '010 RUNTIME_PASS' -and
            $Document.Record.CanSatisfy010RuntimePass -eq $true
        )
    }
    catch { return $false }
}

function New-Aij010ReceiptDocument {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]$Context,
        [Parameter(Mandatory=$true)]$Approval,
        [Parameter(Mandatory=$true)]$Collection,
        $Verification,
        [Parameter(Mandatory=$true)][string]$Status,
        [Parameter(Mandatory=$true)][string]$DependencyResult
    )

    $verificationSha = if ($null -eq $Verification) { $script:Aij010ZeroSha256 } else { $Verification.Sha256 }
    return New-AijD2Document -Record ([pscustomobject][ordered]@{
        Schema = 1
        Kind = 'REAL_WINDOWS_PREFLIGHT_010_RECEIPT'
        Scope = $script:Aij010BoundScope
        Phase = '010'
        OperationId = $Approval.Record.OperationId
        PlanSha256 = $Context.Plan.Sha256
        ApprovalSha256 = $Approval.Sha256
        CollectionResultSha256 = $Collection.Sha256
        VerificationResultSha256 = $verificationSha
        Status = $Status
        DependencyResult = $DependencyResult
        ProductionApplyAuthorized = $false
        CompletedAtUtc = [DateTime]::UtcNow.ToString('o')
    })
}

function Invoke-Aij010BoundExecution {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$SessionDirectory,
        [Parameter(Mandatory=$true)][string]$ApprovalPath
    )

    $mutex = Enter-Aij010SessionLock -SessionDirectory $SessionDirectory
    $approvalConsumed = $false
    $context = $null
    $approval = $null
    try {
        $context = Open-Aij010BoundContext -SessionDirectory $SessionDirectory -SkipMutableBinding
        Assert-Aij010NoPending -SessionDirectory $context.SessionDirectory

        $approvalFull = Assert-Aij010BoundLocalPath -Path $ApprovalPath
        $approvalDirectory = [IO.Path]::GetFullPath((Join-Path $context.SessionDirectory 'approvals'))
        if ([IO.Path]::GetDirectoryName($approvalFull) -ine $approvalDirectory) {
            throw 'B010_APPROVAL_PATH_INVALID'
        }
        $approval = Read-AijD2Document -Path $approvalFull
        if ([IO.Path]::GetFileName($approvalFull) -cne ($approval.Record.Id + '.json')) {
            throw 'B010_APPROVAL_PATH_INVALID'
        }
        Assert-Aij010ApprovalBinding -Plan $context.Plan -Approval $approval -CurrentUserReference (Get-Aij010CurrentUserReference)
        if ($context.AuditTail.ApprovalHashes -cnotcontains $approval.Sha256) {
            throw 'B010_APPROVAL_NOT_RECORDED'
        }
        Assert-Aij010ApprovalUnused -SessionDirectory $context.SessionDirectory -ApprovalId $approval.Record.Id

        # Only after a structurally valid, recorded, unused approval is present do
        # we refresh mutable host/volume/boot bindings. Invalid approvals therefore
        # cannot trigger the real Phase 010 observation path.
        $initialHost = Get-Aij010HostBinding
        $initialVolume = Get-Aij010VolumeBinding -Config $context.Config
        if ($initialHost.ReferenceSha256 -cne $context.Plan.Record.HostIdentitySha256) { throw 'B010_HOST_CHANGED' }
        if ($initialHost.BootSessionReference -cne $context.Plan.Record.BootSessionReference) { throw 'B010_BOOT_SESSION_CHANGED' }
        if ($initialVolume.ReferenceSha256 -cne $context.Plan.Record.VolumeIdentitySha256) { throw 'B010_VOLUME_CHANGED' }

        $privilege = Get-Aij010PrivilegeCheck
        if ($privilege.Status -cne 'PASS') { throw 'B010_ADMINISTRATOR_REQUIRED' }

        $null = Write-Aij010Audit -SessionDirectory $context.SessionDirectory -Event 'EXECUTION_STARTED' -PlanSha256 $context.Plan.Sha256 -ApprovalSha256 $approval.Sha256 -OperationId $approval.Record.OperationId
        $pending = New-AijD2Document -Record ([pscustomobject][ordered]@{
            Schema=1; Kind='REAL_WINDOWS_PREFLIGHT_010_PENDING'; Scope=$script:Aij010BoundScope; Phase='010'
            OperationId=$approval.Record.OperationId; PlanSha256=$context.Plan.Sha256; ApprovalSha256=$approval.Sha256
            StartedAtUtc=[DateTime]::UtcNow.ToString('o')
        })
        Save-AijD2Document -Path (Join-Path $context.SessionDirectory 'pending.json') -Document $pending
        $usedPath = Join-Path (Join-Path $context.SessionDirectory 'approvals') ($approval.Record.Id + '.used')
        Write-AijD2NewFile -Path $usedPath -Text $approval.Sha256
        $approvalConsumed = $true

        Assert-Aij010BoundSourceLockCurrent -ExpectedSources @($context.Plan.Record.SourceFiles)
        $operation = if ($context.Plan.Record.Profile -ceq 'ONLINE_RUNTIME_PASS') { 'COLLECT_ONLINE' } else { 'COLLECT_OFFLINE' }
        $collectionRaw = Invoke-Aij010Preflight -Operation $operation -Config $context.Config -Requirements $context.Requirements
        if ($collectionRaw.Decision.ExitCode -notin @(0,1)) { throw 'B010_UNEXPECTED_PHASE_EXIT' }
        $collection = New-Aij010CollectionDocument -Context $context -Approval $approval -PreflightRecord $collectionRaw
        $collectionPath = Join-Path (Join-Path $context.SessionDirectory 'evidence') ('collection-' + $approval.Record.OperationId + '.json')
        Save-AijD2Document -Path $collectionPath -Document $collection
        $null = Write-Aij010Audit -SessionDirectory $context.SessionDirectory -Event 'COLLECTION_PERSISTED' -PlanSha256 $context.Plan.Sha256 -ApprovalSha256 $approval.Sha256 -OperationId $approval.Record.OperationId -EvidenceSha256 $collection.Sha256 -Outcome $collection.Record.RecomputedDecision.Outcome

        if ($collection.Record.RecomputedDecision.ExitCode -ne 0 -and $collection.Record.RecomputedDecision.ObservationCompletion -ne $true) {
            $receipt = New-Aij010ReceiptDocument -Context $context -Approval $approval -Collection $collection -Verification $null -Status 'COLLECTION_FAILED' -DependencyResult 'NOT_EMITTED'
            $receiptPath = Join-Path (Join-Path $context.SessionDirectory 'evidence') ('receipt-' + $approval.Record.OperationId + '.json')
            Save-AijD2Document -Path $receiptPath -Document $receipt
            $null = Write-Aij010Audit -SessionDirectory $context.SessionDirectory -Event 'RECEIPT_COMMITTED' -PlanSha256 $context.Plan.Sha256 -ApprovalSha256 $approval.Sha256 -OperationId $approval.Record.OperationId -EvidenceSha256 $receipt.Sha256 -Outcome 'COLLECTION_FAILED'
            [IO.File]::Delete((Join-Path $context.SessionDirectory 'pending.json'))
            return [pscustomobject]@{ExitCode=1; CollectionPath=$collectionPath; VerificationPath=$null; ReceiptPath=$receiptPath; DependencyResult='NOT_EMITTED'}
        }

        Assert-Aij010BoundSourceLockCurrent -ExpectedSources @($context.Plan.Record.SourceFiles)
        if ((Get-FileHash -LiteralPath (Join-Path $script:Aij010BoundRoot 'config.env') -Algorithm SHA256).Hash -cne $context.Plan.Record.ConfigurationSha256) { throw 'B010_CONFIG_CHANGED' }
        if ((Get-FileHash -LiteralPath (Join-Path $script:Aij010BoundRoot '010-requirements.json') -Algorithm SHA256).Hash -cne $context.Plan.Record.RequirementsSha256) { throw 'B010_REQUIREMENTS_CHANGED' }
        $freshHost = Get-Aij010HostBinding
        $freshVolume = Get-Aij010VolumeBinding -Config $context.Config
        if ($freshHost.ReferenceSha256 -cne $context.Plan.Record.HostIdentitySha256) { throw 'B010_HOST_CHANGED' }
        if ($freshHost.BootSessionReference -cne $context.Plan.Record.BootSessionReference) { throw 'B010_BOOT_SESSION_CHANGED' }
        if ($freshVolume.ReferenceSha256 -cne $context.Plan.Record.VolumeIdentitySha256) { throw 'B010_VOLUME_CHANGED' }

        $verificationRaw = Invoke-Aij010Preflight -Operation $operation -Config $context.Config -Requirements $context.Requirements
        if ($verificationRaw.Decision.ExitCode -notin @(0,1)) { throw 'B010_UNEXPECTED_PHASE_EXIT' }
        $verification = New-Aij010VerificationDocument -Context $context -Approval $approval -Collection $collection -FreshPreflightRecord $verificationRaw -FreshHostBinding $freshHost -FreshVolumeBinding $freshVolume
        $verificationPath = Join-Path (Join-Path $context.SessionDirectory 'evidence') ('verification-' + $approval.Record.OperationId + '.json')
        Save-AijD2Document -Path $verificationPath -Document $verification
        $null = Write-Aij010Audit -SessionDirectory $context.SessionDirectory -Event 'VERIFICATION_PERSISTED' -PlanSha256 $context.Plan.Sha256 -ApprovalSha256 $approval.Sha256 -OperationId $approval.Record.OperationId -EvidenceSha256 $verification.Sha256 -Outcome $verification.Record.VerificationDecision

        if ($verification.Record.CanSatisfy010RuntimePass) {
            Assert-Aij010RuntimePassDocuments -Plan $context.Plan -Collection $collection -Verification $verification
            $status = 'VERIFIED_RUNTIME_PASS'
            $dependency = '010 RUNTIME_PASS'
            $exitCode = 0
        }
        elseif ($verification.Record.CanSatisfy010PreflightComplete) {
            Assert-Aij010CompletionDocuments -Plan $context.Plan -Collection $collection -Verification $verification
            $status = 'VERIFIED_PREFLIGHT_COMPLETE_WITH_WARNINGS'
            $dependency = '010 PREFLIGHT_COMPLETE'
            $exitCode = 0
        }
        elseif ($verification.Record.VerificationDecision -ceq 'LOCAL_DIAGNOSTIC_PASS') {
            $status = 'LOCAL_DIAGNOSTIC_COMPLETE'
            $dependency = 'NOT_EMITTED'
            $exitCode = 0
        }
        else {
            $status = 'VERIFICATION_FAILED'
            $dependency = 'NOT_EMITTED'
            $exitCode = 1
        }

        $receipt = New-Aij010ReceiptDocument -Context $context -Approval $approval -Collection $collection -Verification $verification -Status $status -DependencyResult $dependency
        $receiptPath = Join-Path (Join-Path $context.SessionDirectory 'evidence') ('receipt-' + $approval.Record.OperationId + '.json')
        Save-AijD2Document -Path $receiptPath -Document $receipt
        $null = Write-Aij010Audit -SessionDirectory $context.SessionDirectory -Event 'RECEIPT_COMMITTED' -PlanSha256 $context.Plan.Sha256 -ApprovalSha256 $approval.Sha256 -OperationId $approval.Record.OperationId -EvidenceSha256 $receipt.Sha256 -Outcome $status
        [IO.File]::Delete((Join-Path $context.SessionDirectory 'pending.json'))

        return [pscustomobject]@{
            ExitCode = $exitCode
            CollectionPath = $collectionPath
            VerificationPath = $verificationPath
            ReceiptPath = $receiptPath
            DependencyResult = $dependency
        }
    }
    catch {
        if ($approvalConsumed -and $null -ne $context -and $null -ne $approval) {
            try {
                $null = Write-Aij010Audit -SessionDirectory $context.SessionDirectory -Event 'EXECUTION_FAILED' -PlanSha256 $context.Plan.Sha256 -ApprovalSha256 $approval.Sha256 -OperationId $approval.Record.OperationId -Outcome $_.Exception.Message
            }
            catch {
                # Preserve the primary exception and leave pending.json as the recovery blocker.
            }
        }
        throw
    }
    finally {
        Exit-Aij010SessionLock -Mutex $mutex
    }
}

function Assert-Aij010RuntimePassEvidence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$SessionDirectory,
        [Parameter(Mandatory=$true)][string]$VerificationPath
    )

    $mutex = Enter-Aij010SessionLock -SessionDirectory $SessionDirectory
    try {
        $context = Open-Aij010BoundContext -SessionDirectory $SessionDirectory
        Assert-Aij010NoPending -SessionDirectory $context.SessionDirectory
        $verificationFull = Assert-Aij010BoundLocalPath -Path $VerificationPath
        $evidenceDir = [IO.Path]::GetFullPath((Join-Path $context.SessionDirectory 'evidence'))
        if ([IO.Path]::GetDirectoryName($verificationFull) -ine $evidenceDir) { throw 'B010_EVIDENCE_PATH_INVALID' }
        $verification = Read-AijD2Document -Path $verificationFull
        if (-not (Test-Aij010RuntimePassDocument -Document $verification)) { throw 'B010_RUNTIME_EVIDENCE_INVALID' }
        $collectionPath = Join-Path $evidenceDir ('collection-' + $verification.Record.OperationId + '.json')
        $collection = Read-AijD2Document -Path $collectionPath
        Assert-Aij010RuntimePassDocuments -Plan $context.Plan -Collection $collection -Verification $verification

        $now = [DateTime]::UtcNow
        $verifiedAt = [DateTime]::Parse($verification.Record.VerifiedAtUtc).ToUniversalTime()
        if (($now - $verifiedAt).TotalSeconds -gt [int]$context.Plan.Record.FreshnessPolicySeconds) {
            throw 'B010_RUNTIME_EVIDENCE_EXPIRED'
        }

        $receiptPath = Join-Path $evidenceDir ('receipt-' + $verification.Record.OperationId + '.json')
        $receipt = Read-AijD2Document -Path $receiptPath
        if ($receipt.Record.Kind -cne 'REAL_WINDOWS_PREFLIGHT_010_RECEIPT' -or
            $receipt.Record.Scope -cne $script:Aij010BoundScope -or
            $receipt.Record.VerificationResultSha256 -cne $verification.Sha256 -or
            $receipt.Record.CollectionResultSha256 -cne $collection.Sha256 -or
            $receipt.Record.Status -cne 'VERIFIED_RUNTIME_PASS' -or
            $receipt.Record.DependencyResult -cne '010 RUNTIME_PASS') {
            throw 'B010_RECEIPT_INVALID'
        }
        return $true
    }
    finally {
        Exit-Aij010SessionLock -Mutex $mutex
    }
}

# Completion is admission to a separately invoked read-only Phase 020 check.
# It is never an authorization to install, update, start a distro, or APPLY.
function Assert-Aij010CompletionDocuments {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)]$Plan,
          [Parameter(Mandatory=$true)]$Collection,
          [Parameter(Mandatory=$true)]$Verification)
    foreach ($doc in @($Plan,$Collection,$Verification)) { Assert-AijD2Document -Document $doc }
    $p = $Plan.Record; $c = $Collection.Record; $v = $Verification.Record
    if ($p.Kind -cne 'REAL_WINDOWS_PREFLIGHT_010_PLAN' -or $p.Scope -cne $script:Aij010BoundScope -or
        $p.Phase -cne '010' -or $p.Profile -cne 'ONLINE_RUNTIME_PASS' -or
        $p.ProductionApplyAuthorized -ne $false -or $p.GeneralProductionVerifyAuthorized -ne $false -or
        $c.Kind -cne 'REAL_WINDOWS_PREFLIGHT_010_COLLECTION' -or
        $v.Kind -cne 'REAL_WINDOWS_PREFLIGHT_010_VERIFICATION' -or
        $v.CollectionResultSha256 -cne $Collection.Sha256 -or
        $c.OperationId -cnotmatch '^[a-f0-9]{32}$' -or $c.OperationId -cne $v.OperationId -or
        $c.ApprovalSha256 -cnotmatch '^[A-F0-9]{64}$' -or $c.ApprovalSha256 -cne $v.ApprovalSha256 -or
        $c.RuntimePassEmitted -ne $false -or $v.InstallationAuthorized -ne $false) {
        throw 'B010_COMPLETION_BINDING_INVALID'
    }
    foreach ($record in @($c,$v)) {
        if ($record.Schema -ne 1 -or $record.Phase -cne '010' -or
            $record.Scope -cne $script:Aij010BoundScope -or
            $record.EvidenceOrigin -cne 'LIVE_BOUND_EXECUTION' -or $record.PlanSha256 -cne $Plan.Sha256) {
            throw 'B010_COMPLETION_BINDING_INVALID'
        }
        foreach ($field in @('RequirementsSha256','ConfigurationSha256','SourceLockSha256',
            'HostIdentitySha256','VolumeIdentitySha256','BootSessionReference','Profile','NetworkPolicySha256')) {
            if ($record.$field -cne $p.$field) { throw 'B010_COMPLETION_BINDING_INVALID' }
        }
    }
    if ($c.PreviousStateSha256 -cne $p.PreviousStateSha256 -or $c.PreviousEvidenceSha256 -cne $p.PreviousEvidenceSha256 -or
        $v.FreshnessPolicySeconds -ne $p.FreshnessPolicySeconds) { throw 'B010_COMPLETION_BINDING_INVALID' }

    $cd = Assert-Aij010DecisionIntegrity -PreflightRecord $c.PreflightRecord -Operation 'COLLECT_ONLINE'
    $vd = Assert-Aij010DecisionIntegrity -PreflightRecord $v.FreshPreflightRecord -Operation 'COLLECT_ONLINE'
    if ((New-AijD2Document -Record $cd).Json -cne (New-AijD2Document -Record $c.RecomputedDecision).Json -or
        (New-AijD2Document -Record $vd).Json -cne (New-AijD2Document -Record $v.FreshRecomputedDecision).Json) {
        throw 'B010_COMPLETION_DECISION_INVALID'
    }
    if ($cd.ObservationCompletion -ne $true -or $vd.ObservationCompletion -ne $true -or
        $v.CanSatisfy010PreflightComplete -ne $true -or $v.DependencyScope -cne $script:Aij010BoundScope) {
        throw 'B010_COMPLETION_NOT_SATISFIED'
    }
    foreach ($raw in @($c.PreflightRecord,$v.FreshPreflightRecord)) {
        if ($raw.Operation -cne 'COLLECT_ONLINE' -or (Get-Aij010NetworkRequestCount -PreflightRecord $raw) -ne 1) {
            throw 'B010_COMPLETION_NETWORK_INVALID'
        }
    }
    if ($c.NetworkRequestsObserved -ne 1 -or $v.NetworkRequestsObservedTotal -ne 2 -or
        $p.NetworkPolicy.MaximumRequestsTotal -ne 2) { throw 'B010_COMPLETION_NETWORK_INVALID' }
    $clean = ($cd.RuntimePassCandidate -eq $true -and $vd.RuntimePassCandidate -eq $true)
    if ($clean) {
        Assert-Aij010RuntimePassDocuments -Plan $Plan -Collection $Collection -Verification $Verification
    } else {
        if ($v.CanSatisfy010RuntimePass -ne $false -or $v.DependencyResult -cne '010 PREFLIGHT_COMPLETE' -or
            $v.VerificationDecision -cne 'COMPLETE_WITH_WARNINGS') { throw 'B010_COMPLETION_RESULT_INVALID' }
        # Unresolved conditions must remain the same between collection and verification.
        $first = $c.PreflightRecord.Checks.RebootObservations
        $second = $v.FreshPreflightRecord.Checks.RebootObservations
        if ($first.Status -cne 'WARN' -or $second.Status -cne 'WARN' -or
            (New-AijD2Document -Record $first.Observation).Json -cne (New-AijD2Document -Record $second.Observation).Json) {
            throw 'B010_COMPLETION_WARNING_CHANGED'
        }
    }
    $expectedWarnings = @($(foreach ($raw in @($c.PreflightRecord,$v.FreshPreflightRecord)) {
        foreach ($check in $raw.Checks.PSObject.Properties) {
            if ($check.Value.Status -ceq 'WARN') { $check.Value.Reasons }
        }
    }) | Sort-Object -Unique)
    $actualWarningSet = [pscustomobject]@{Warnings=@($v.WarningReasons)}
    $expectedWarningSet = [pscustomobject]@{Warnings=@($expectedWarnings)}
    if ((New-AijD2Document -Record $actualWarningSet).Json -cne (New-AijD2Document -Record $expectedWarningSet).Json) {
        throw 'B010_COMPLETION_WARNINGS_INVALID'
    }
    $collected = [DateTime]::Parse($c.CollectedAtUtc).ToUniversalTime()
    $verified = [DateTime]::Parse($v.VerifiedAtUtc).ToUniversalTime()
    $now = [DateTime]::UtcNow
    if ($collected -gt $now -or $verified -gt $now -or $verified -lt $collected -or
        ($verified-$collected).TotalSeconds -gt [int]$p.FreshnessPolicySeconds -or
        ($now-$verified).TotalSeconds -gt [int]$p.FreshnessPolicySeconds) {
        throw 'B010_COMPLETION_EXPIRED'
    }
}

function Assert-Aij010PreflightCompleteEvidence {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$SessionDirectory,
          [Parameter(Mandatory=$true)][string]$VerificationPath)
    $mutex = Enter-Aij010SessionLock -SessionDirectory $SessionDirectory
    try {
        # Rechecks source, config, requirements, host, target volume, boot, session and PLAN.
        $context = Open-Aij010BoundContext -SessionDirectory $SessionDirectory
        Assert-Aij010NoPending -SessionDirectory $context.SessionDirectory
        $verificationFull = Assert-Aij010OrdinaryBoundFile -Path $VerificationPath
        $evidenceDir = [IO.Path]::GetFullPath((Join-Path $context.SessionDirectory 'evidence'))
        if ([IO.Path]::GetDirectoryName($verificationFull) -ine $evidenceDir) { throw 'B010_EVIDENCE_PATH_INVALID' }
        $verification = Read-AijD2Document -Path $verificationFull
        $operationId = $verification.Record.OperationId
        if ($operationId -cnotmatch '^[a-f0-9]{32}$' -or
            [IO.Path]::GetFileName($verificationFull) -cne ('verification-' + $operationId + '.json')) {
            throw 'B010_EVIDENCE_PATH_INVALID'
        }
        $collection = Read-AijD2Document -Path (Join-Path $evidenceDir ('collection-' + $operationId + '.json'))
        Assert-Aij010CompletionDocuments -Plan $context.Plan -Collection $collection -Verification $verification
        $receipt = Read-AijD2Document -Path (Join-Path $evidenceDir ('receipt-' + $operationId + '.json'))
        $status = if ($verification.Record.CanSatisfy010RuntimePass) { 'VERIFIED_RUNTIME_PASS' } else { 'VERIFIED_PREFLIGHT_COMPLETE_WITH_WARNINGS' }
        $r = $receipt.Record
        if ($r.Schema -ne 1 -or $r.Kind -cne 'REAL_WINDOWS_PREFLIGHT_010_RECEIPT' -or
            $r.Scope -cne $script:Aij010BoundScope -or $r.Phase -cne '010' -or
            $r.OperationId -cne $operationId -or $r.PlanSha256 -cne $context.Plan.Sha256 -or
            $r.ApprovalSha256 -cne $verification.Record.ApprovalSha256 -or
            $r.CollectionResultSha256 -cne $collection.Sha256 -or $r.VerificationResultSha256 -cne $verification.Sha256 -or
            $r.Status -cne $status -or $r.DependencyResult -cne $verification.Record.DependencyResult -or
            $r.ProductionApplyAuthorized -ne $false -or $context.AuditTail.ReceiptSha256 -cne $receipt.Sha256) {
            throw 'B010_COMPLETION_RECEIPT_INVALID'
        }
        $completed = [DateTime]::Parse($r.CompletedAtUtc).ToUniversalTime()
        if ($completed -lt [DateTime]::Parse($verification.Record.VerifiedAtUtc).ToUniversalTime() -or $completed -gt [DateTime]::UtcNow) {
            throw 'B010_COMPLETION_RECEIPT_INVALID'
        }
        $approvalDocs = @(Get-ChildItem -LiteralPath (Join-Path $context.SessionDirectory 'approvals') -Filter '*.json' -File)
        if ($approvalDocs.Count -ne 1) { throw 'B010_COMPLETION_APPROVAL_INVALID' }
        $approval = Read-AijD2Document -Path $approvalDocs[0].FullName
        Assert-Aij010ApprovalBinding -Plan $context.Plan -Approval $approval -CurrentUserReference (Get-Aij010CurrentUserReference)
        if ($approval.Sha256 -cne $r.ApprovalSha256 -or $approval.Record.OperationId -cne $operationId -or
            $context.AuditTail.ApprovalHashes -cnotcontains $approval.Sha256 -or
            $approvalDocs[0].Name -cne ($approval.Record.Id + '.json')) { throw 'B010_COMPLETION_APPROVAL_INVALID' }
        $used = Read-AijStrictUtf8StateText -Path (Assert-Aij010OrdinaryBoundFile -Path (Join-Path $approvalDocs[0].DirectoryName ($approval.Record.Id + '.used')))
        if ($used -cne $approval.Sha256) { throw 'B010_COMPLETION_APPROVAL_INVALID' }
        # GetAuditTail already validated the whole hash chain. Bind its four execution events.
        $audit = Read-AijStrictUtf8StateText -Path (Join-Path $context.SessionDirectory 'audit.jsonl')
        $events = @($audit.Split([char]10) | Where-Object { $_.Length -gt 0 } | ForEach-Object { (ConvertFrom-Json -InputObject $_).Record } | Where-Object { $_.OperationId -ceq $operationId })
        $executionEvents = @($events | Where-Object { $_.Event -cne 'APPROVAL_RECORDED' })
        if (($executionEvents.Event -join '|') -cne 'EXECUTION_STARTED|COLLECTION_PERSISTED|VERIFICATION_PERSISTED|RECEIPT_COMMITTED') {
            throw 'B010_COMPLETION_AUDIT_INVALID'
        }
        foreach ($entry in $events) {
            if ($entry.PlanSha256 -cne $context.Plan.Sha256 -or $entry.ApprovalSha256 -cne $approval.Sha256) { throw 'B010_COMPLETION_AUDIT_INVALID' }
        }
        if ($executionEvents[1].EvidenceSha256 -cne $collection.Sha256 -or
            $executionEvents[2].EvidenceSha256 -cne $verification.Sha256 -or
            $executionEvents[3].EvidenceSha256 -cne $receipt.Sha256) { throw 'B010_COMPLETION_AUDIT_INVALID' }
        return [pscustomobject]@{
            Phase = '010'; PreflightComplete = $true
            RuntimePass = [bool]$verification.Record.CanSatisfy010RuntimePass
            DependencyResult = $verification.Record.DependencyResult
            WarningReasons = @($verification.Record.WarningReasons)
            VerificationSha256 = $verification.Sha256
            AllowedNextOperation = 'PHASE_020_READ_ONLY_WSL_VERSION_CHECK'
            InstallationAuthorized = $false
        }
    } finally { Exit-Aij010SessionLock -Mutex $mutex }
}
