# Offline tests. Real PLAN/approval/collection/verification/persistence/consumer
# functions run only in a new temporary fixture. External observations are mocked.
# No WSL, network, elevation, installation-target writes or production APPLY.
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
$script:Assertions = 0
function Assert-T([bool]$Condition,[string]$Name) {
    if (-not $Condition) { throw ('ASSERTION_FAILED: ' + $Name) }
    $script:Assertions++; Write-Output ('PASS: ' + $Name)
}
function Reject([scriptblock]$Action,[string]$Message,[string]$Name) {
    $actual = $null
    try { $null = & $Action } catch { $actual = $_.Exception.Message }
    Assert-T ($actual -ceq $Message) ($Name + '; expected=' + $Message + '; actual=' + $actual)
}
function Pass-Check {
    New-Aij010Check 'PASS' 'TEST_OBSERVATION' 'FIXTURE_ONLY' ([pscustomobject]@{}) @()
}
function Reboot-Observation {
    [pscustomobject]@{
        QuerySucceeded = ($script:RebootMode -cne 'UNKNOWN'); ErrorType = $null
        Indicators = @(
            [pscustomobject]@{Name='CBS_REBOOT_PENDING'; Present=($script:RebootMode -cin @('CBS','CBS_WARN'))},
            [pscustomobject]@{Name='WINDOWS_UPDATE_REBOOT_REQUIRED'; Present=($script:RebootMode -cin @('WU','WU_WARN'))},
            [pscustomobject]@{Name='PENDING_FILE_RENAME_OPERATIONS'; Present=($script:RebootMode -cin @('WARN','CBS_WARN','WU_WARN')); Evidence=(Get-Aij010PendingEvidence -Values @('C:\Users\FixturePrivate\pending.tmp',''))}
        )
    }
}
function Install-ObservationMocks {
    Set-Item Function:\script:Get-Aij010HostBinding -Value {
        [pscustomobject]@{ReferenceSha256=$script:FixtureHost;BootSessionReference=$script:FixtureBoot;Methods=@('FIXTURE_ONLY')}
    }
    Set-Item Function:\script:Get-Aij010VolumeBinding -Value {
        param($Config)
        [pscustomobject]@{ReferenceSha256=$script:FixtureVolume;Drive=$Config['TARGET_DRIVE'];FileSystem='NTFS';Method='FIXTURE_ONLY'}
    }
    Set-Item Function:\script:Get-Aij010CurrentUserReference -Value { return ('9'*64) }
    Set-Item Function:\script:Get-Aij010PrivilegeCheck -Value { Pass-Check }
    Set-Item Function:\script:Get-Aij010DefaultAdapters -Value {
        @{
            Administrator={Pass-Check};WindowsPlatform={Pass-Check};Virtualization={Pass-Check}
            Storage={if ($script:StorageFails) { New-Aij010Check 'FAIL' 'MANUAL_ACTION_NEEDED' 'FIXTURE' $null @('fixture') } else {Pass-Check}}
            WslReadiness={Pass-Check}
            RebootObservations={Resolve-Aij010RebootCheck -Observation (Reboot-Observation)}
            Connectivity={
                $script:NetworkCalls++
                New-Aij010Check 'PASS' 'EXPECTED_RESPONSE' 'FIXTURE_ONLY' ([pscustomobject]@{RequestCount=1}) @()
            }
        }
    }
}
function Read-Doc([string]$Path) { Read-AijD2Document -Path $Path }
function Rewrite-Doc([string]$Path,$Record) {
    $doc = New-AijD2Document -Record $Record
    [IO.File]::WriteAllText($Path,(ConvertTo-Json -InputObject $doc -Depth 45 -Compress),(New-Object Text.UTF8Encoding($false)))
}
function Alter-File([string]$Path,[scriptblock]$Mutation,[scriptblock]$Action,[string]$Message,[string]$Name) {
    $before = [IO.File]::ReadAllBytes($Path)
    try { & $Mutation; Reject $Action $Message $Name }
    finally { [IO.File]::WriteAllBytes($Path,$before) }
}
try {
    # A private, non-production copy keeps all source/config mutation fixtures isolated.
    $script:FixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ('AIJ-WARNING-' + [guid]::NewGuid().ToString('N'))
    $null = [IO.Directory]::CreateDirectory($script:FixtureRoot)
    foreach ($name in @('000-run-all.bat','000-engine.ps1','000-authorization.ps1','000-state.ps1','000-state-store.ps1','000-manifest.ps1','000-config.ps1','010-preflight.ps1','010-preflight-core.ps1','010-preflight.bat','010-requirements.json','010-boundary.ps1','config.env')) {
        [IO.File]::Copy((Join-Path $PSScriptRoot $name),(Join-Path $script:FixtureRoot $name))
    }
    function Get-CimInstance { throw 'PROHIBITED_LIVE_CIM' }
    function Get-ItemProperty { throw 'PROHIBITED_LIVE_REGISTRY' }
    function Invoke-WebRequest { throw 'PROHIBITED_LIVE_NETWORK' }
    function Start-Process { throw 'PROHIBITED_PROCESS' }
    function wsl.exe { throw 'PROHIBITED_WSL' }
    . (Join-Path $script:FixtureRoot '010-boundary.ps1')
    $script:RealImporter = ${function:Import-Aij010BoundLibraries}
    # Keep actual source validation/imports; reinstall only external observation mocks.
    function Import-Aij010BoundLibraries {
        param($ExpectedSources)
        & $script:RealImporter -ExpectedSources $ExpectedSources
        Install-ObservationMocks
    }
    $script:FixtureHost='A'*64; $script:FixtureVolume='B'*64; $script:FixtureBoot='FIXTURE_BOOT'
    $script:RebootMode='WARN'; $script:NetworkCalls=0; $script:StorageFails=$false
    $session=Join-Path $script:FixtureRoot 'warning-session'
    $plan=New-Aij010BoundPlan -SessionDirectory $session -Profile online
    $approval=New-Aij010BoundApproval -SessionDirectory $session -ConfirmationToken $plan.ConfirmationToken
    $result=Invoke-Aij010BoundExecution -SessionDirectory $session -ApprovalPath $approval.Path
    Assert-T ($result.ExitCode -eq 0 -and $result.DependencyResult -ceq '010 PREFLIGHT_COMPLETE') 'real warning execution completes'
    Assert-T ($script:NetworkCalls -eq 2) 'exactly two mocked network observations'
    $consume={Assert-Aij010PreflightCompleteEvidence -SessionDirectory $session -VerificationPath $result.VerificationPath}
    $admission=& $consume
    Assert-T ($admission.PreflightComplete -and -not $admission.RuntimePass -and -not $admission.InstallationAuthorized) 'real consumer admits read-only work only'
    Assert-T ($admission.WarningReasons.Count -gt 0) 'consumer preserves warning'
    Reject {Assert-Aij010RuntimePassEvidence -SessionDirectory $session -VerificationPath $result.VerificationPath} 'B010_RUNTIME_EVIDENCE_INVALID' 'warning never becomes runtime pass'
    $json=[IO.File]::ReadAllText($result.CollectionPath)+[IO.File]::ReadAllText($result.VerificationPath)
    Assert-T (-not $json.Contains('FixturePrivate')) 'durable evidence contains no raw pending path'
    Reject {Invoke-Aij010BoundExecution -SessionDirectory $session -ApprovalPath $approval.Path} 'B010_APPROVAL_CONSUMED' 'approval cannot be replayed'

    $configPath=Join-Path $script:FixtureRoot 'config.env'
    Alter-File $configPath { [IO.File]::AppendAllText($configPath,"`r`n# fixture change") } $consume 'B010_CONFIG_CHANGED' 'changed configuration rejected'
    $sourcePath=Join-Path $script:FixtureRoot '010-preflight-core.ps1'
    Alter-File $sourcePath { [IO.File]::AppendAllText($sourcePath,"`r`n# fixture change") } $consume 'B010_SOURCE_CHANGED' 'changed source rejected'
    $script:FixtureHost='C'*64
    Reject $consume 'B010_HOST_CHANGED' 'changed host rejected'
    $script:FixtureHost='A'*64; $script:FixtureVolume='D'*64
    Reject $consume 'B010_VOLUME_CHANGED' 'changed target volume rejected'
    $script:FixtureVolume='B'*64; $script:FixtureBoot='OTHER_BOOT'
    Reject $consume 'B010_BOOT_SESSION_CHANGED' 'changed boot rejected'
    $script:FixtureBoot='FIXTURE_BOOT'
    Alter-File $result.VerificationPath {
        $doc=Read-Doc $result.VerificationPath; $doc.Record.PlanSha256='F'*64
        [IO.File]::WriteAllText($result.VerificationPath,(ConvertTo-Json -InputObject $doc -Depth 45 -Compress))
    } $consume 'D2_DOCUMENT_CHANGED' 'tampered document rejected without rehash'
    Alter-File $result.VerificationPath {
        $doc=Read-Doc $result.VerificationPath; $doc.Record.PlanSha256='F'*64
        Rewrite-Doc $result.VerificationPath $doc.Record
    } $consume 'B010_COMPLETION_BINDING_INVALID' 'rehash cannot hide wrong PLAN'
    Alter-File $result.VerificationPath {
        $doc=Read-Doc $result.VerificationPath; $doc.Record.ConfigurationSha256='F'*64
        Rewrite-Doc $result.VerificationPath $doc.Record
    } $consume 'B010_COMPLETION_BINDING_INVALID' 'rehash cannot hide wrong configuration binding'
    Alter-File $result.VerificationPath {
        $doc=Read-Doc $result.VerificationPath; $doc.Record.NetworkRequestsObservedTotal=1
        Rewrite-Doc $result.VerificationPath $doc.Record
    } $consume 'B010_COMPLETION_NETWORK_INVALID' 'incomplete network verification rejected'
    Alter-File $result.VerificationPath {
        $doc=Read-Doc $result.VerificationPath; $doc.Record.FreshRecomputedDecision.ObservationCompletion=$false
        Rewrite-Doc $result.VerificationPath $doc.Record
    } $consume 'B010_COMPLETION_DECISION_INVALID' 'changed decision rejected'
    Alter-File $result.VerificationPath {
        $doc=Read-Doc $result.VerificationPath
        $pending=@($doc.Record.FreshPreflightRecord.Checks.RebootObservations.Observation.Indicators | Where-Object { $_.Name -ceq 'PENDING_FILE_RENAME_OPERATIONS' })
        $pending[0].Evidence.EntriesSha256='E'*64
        Rewrite-Doc $result.VerificationPath $doc.Record
    } $consume 'B010_COMPLETION_WARNING_CHANGED' 'changed pending operations require fresh collection'
    Alter-File $result.VerificationPath {
        $doc=Read-Doc $result.VerificationPath; $doc.Record.VerifiedAtUtc=[DateTime]::UtcNow.AddMinutes(10).ToString('o')
        Rewrite-Doc $result.VerificationPath $doc.Record
    } $consume 'B010_COMPLETION_EXPIRED' 'future timestamp rejected'
    $oldCollection=[IO.File]::ReadAllBytes($result.CollectionPath)
    $oldVerification=[IO.File]::ReadAllBytes($result.VerificationPath)
    try {
        $c=Read-Doc $result.CollectionPath; $c.Record.CollectedAtUtc=[DateTime]::UtcNow.AddMinutes(-11).ToString('o')
        Rewrite-Doc $result.CollectionPath $c.Record
        $v=Read-Doc $result.VerificationPath; $v.Record.CollectionResultSha256=(Read-Doc $result.CollectionPath).Sha256
        $v.Record.VerifiedAtUtc=[DateTime]::UtcNow.AddMinutes(-10).ToString('o')
        Rewrite-Doc $result.VerificationPath $v.Record
        Reject $consume 'B010_COMPLETION_EXPIRED' 'expired otherwise consistent evidence rejected'
    } finally {
        [IO.File]::WriteAllBytes($result.CollectionPath,$oldCollection)
        [IO.File]::WriteAllBytes($result.VerificationPath,$oldVerification)
    }
    Alter-File $result.ReceiptPath {
        $doc=Read-Doc $result.ReceiptPath; $doc.Record.ApprovalSha256='F'*64
        Rewrite-Doc $result.ReceiptPath $doc.Record
    } $consume 'B010_COMPLETION_RECEIPT_INVALID' 'mismatched receipt rejected'
    Alter-File $result.ReceiptPath { [IO.File]::Delete($result.ReceiptPath) } $consume 'D2_DOCUMENT_MISSING' 'missing receipt rejected'
    $auditPath=Join-Path $session 'audit.jsonl'
    Alter-File $auditPath {
        $lines=@([IO.File]::ReadAllLines($auditPath)); [IO.File]::WriteAllText($auditPath,(($lines[0..($lines.Count-2)] -join "`n")+"`n"))
    } $consume 'B010_COMPLETION_RECEIPT_INVALID' 'uncommitted receipt rejected'
    $usedPath=Join-Path (Join-Path $session 'approvals') ($approval.Approval.Record.Id+'.used')
    Alter-File $usedPath { [IO.File]::WriteAllText($usedPath,('F'*64)) } $consume 'B010_COMPLETION_APPROVAL_INVALID' 'wrong consumed approval rejected'
    $pendingPath=Join-Path $session 'pending.json'
    try {
        [IO.File]::WriteAllText($pendingPath,'{}')
        Reject $consume 'B010_RECOVERY_REQUIRED' 'incomplete execution cannot be consumed'
    } finally { [IO.File]::Delete($pendingPath) }
    $null=& $consume
    Assert-T $true 'valid evidence still accepted after negative cases'

    # Actual preflight coordinator, actual reboot resolver, mocked observation adapters.
    $config=Read-AijConfig -Path $configPath
    $requirements=Read-Aij010Requirements -Path (Join-Path $script:FixtureRoot '010-requirements.json')
    foreach ($mode in @('CBS','WU','CBS_WARN','WU_WARN','UNKNOWN')) {
        $script:RebootMode=$mode; $script:NetworkCalls=0
        $raw=Invoke-Aij010Preflight -Operation COLLECT_ONLINE -Config $config -Requirements $requirements
        Assert-T (-not $raw.Decision.ObservationCompletion -and $script:NetworkCalls -eq 0) ('blocks '+$mode)
    }
    $script:RebootMode='WARN'; $script:StorageFails=$true; $script:NetworkCalls=0
    $raw=Invoke-Aij010Preflight -Operation COLLECT_ONLINE -Config $config -Requirements $requirements
    Assert-T (-not $raw.Decision.ObservationCompletion -and $script:NetworkCalls -eq 0) 'other failure is not waived'
    $script:StorageFails=$false
    $raw=Invoke-Aij010Preflight -Operation COLLECT_OFFLINE -Config $config -Requirements $requirements
    Assert-T (-not $raw.Decision.ObservationCompletion -and $script:NetworkCalls -eq 0) 'offline warning cannot complete online evidence'
    $incomplete=Reboot-Observation; $incomplete.Indicators=@($incomplete.Indicators[2])
    Assert-T ((Resolve-Aij010RebootCheck -Observation $incomplete).Status -ceq 'UNKNOWN') 'missing indicators fail closed'
    # The clean bound route still emits its existing result and is accepted by both readers.
    $script:RebootMode='NONE'; $script:NetworkCalls=0
    $cleanSession=Join-Path $script:FixtureRoot 'clean-session'
    $cleanPlan=New-Aij010BoundPlan -SessionDirectory $cleanSession -Profile online
    $cleanApproval=New-Aij010BoundApproval -SessionDirectory $cleanSession -ConfirmationToken $cleanPlan.ConfirmationToken
    $cleanResult=Invoke-Aij010BoundExecution -SessionDirectory $cleanSession -ApprovalPath $cleanApproval.Path
    Assert-T ($cleanResult.DependencyResult -ceq '010 RUNTIME_PASS' -and $script:NetworkCalls -eq 2) 'clean real bound flow preserved'
    $null=Assert-Aij010RuntimePassEvidence -SessionDirectory $cleanSession -VerificationPath $cleanResult.VerificationPath
    $cleanAdmission=Assert-Aij010PreflightCompleteEvidence -SessionDirectory $cleanSession -VerificationPath $cleanResult.VerificationPath
    Assert-T ($cleanAdmission.RuntimePass -and $cleanAdmission.PreflightComplete) 'clean evidence satisfies both meanings'
    Write-Output ('Assertions: '+$script:Assertions)
    Write-Output ('FIXTURE_DIRECTORY='+$script:FixtureRoot)
    Write-Output 'PHASE_010_WARNING_COMPLETION_FIXTURES_OK'
    exit 0
} catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    [Console]::Error.WriteLine($_.ScriptStackTrace)
    exit 1
}
