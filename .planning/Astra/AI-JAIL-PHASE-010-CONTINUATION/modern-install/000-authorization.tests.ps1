# D2 focused acceptance, supplied for the operator to run. PS 5.1.
# All execution is the built-in file-writing mock. No phase BAT, WSL,
# installer, downloaded code or network client is invoked.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
$script:checks = 0
$script:tempRoot = $null

function Require {
    param([bool]$Condition,[string]$Name)
    if (-not $Condition) { throw ('ASSERTION_FAILED: ' + $Name) }
    $script:checks++
    Write-Output ('PASS: ' + $Name)
}

function Expect-Rejection {
    param([string]$Expected,[scriptblock]$Operation,[string]$Name)
    $actual = $null
    try { $null = & $Operation } catch { $actual = $_.Exception.Message }
    if ($actual -cne $Expected) {
        throw ('WRONG_REJECTION: ' + $Name + '; expected=' + $Expected + '; actual=' + $actual)
    }
    $script:checks++
    Write-Output ('PASS: ' + $Name)
}

function New-Fixture {
    param([int[]]$Codes=@(0))
    $workspace = New-AijMockWorkspace $script:tempRoot
    $plan = New-AijMockPlan -Workspace $workspace -ExitCodes $Codes
    $state = Initialize-AijMockState -Plan $plan -Workspace $workspace
    [pscustomobject]@{Workspace=$workspace; Plan=$plan; State=$state}
}

function Approve-Fixture {
    param($Fixture)
    $state = Read-AijStateFile -Directory (Join-Path $Fixture.Workspace 'state')
    New-AijMockApproval -Plan $Fixture.Plan -Workspace $Fixture.Workspace -ConfirmationText (Get-AijMockApprovalText $Fixture.Plan $state)
}

function Require-NoEffect {
    param($Fixture,[string]$Name)
    $files = @(Get-ChildItem -LiteralPath $Fixture.Workspace -Filter 'result-*.json' -File)
    Require ($files.Count -eq 0) $Name
    $state = Read-AijStateFile -Directory (Join-Path $Fixture.Workspace 'state')
    Require ($state.Sha256 -ceq $Fixture.State.Sha256) ($Name + '_STATE_UNCHANGED')
}

function Invoke-CmdFixture {
    param([string]$Body)
    $path = Join-Path $script:tempRoot ([guid]::NewGuid().ToString('N') + '.cmd')
    [IO.File]::WriteAllText($path,$Body,[Text.Encoding]::ASCII)
    $psi = New-Object Diagnostics.ProcessStartInfo
    $psi.FileName = Join-Path $env:SystemRoot 'System32\cmd.exe'
    $psi.Arguments = '/d /c ""' + $path + '""'
    $psi.UseShellExecute = $false; $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true
    $p = New-Object Diagnostics.Process
    $p.StartInfo = $psi
    try {
        $null = $p.Start()
        $outTask = $p.StandardOutput.ReadToEndAsync(); $errTask = $p.StandardError.ReadToEndAsync()
        if (-not $p.WaitForExit(60000)) { $p.Kill(); $p.WaitForExit(); throw 'CMD_FIXTURE_TIMEOUT' }
        [pscustomobject]@{ExitCode=$p.ExitCode; Stdout=$outTask.Result; Stderr=$errTask.Result}
    } finally { $p.Dispose() }
}

try {
    $script:tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('aij-d2-tests-' + [guid]::NewGuid().ToString('N'))
    $null = [IO.Directory]::CreateDirectory($script:tempRoot)
    $fixtureRoot = Join-Path $script:tempRoot 'modern-install'
    $null = [IO.Directory]::CreateDirectory($fixtureRoot)
    # Flat source copy. Existing phase handlers are copied for fingerprinting,
    # never invoked. Fixtures never alter the operator's repository files.
    foreach ($file in @(Get-ChildItem -LiteralPath $PSScriptRoot -File)) {
        if ($file.Extension -in @('.ps1','.bat','.json','.env')) {
            Copy-Item -LiteralPath $file.FullName -Destination (Join-Path $fixtureRoot $file.Name)
        }
    }
    . (Join-Path $fixtureRoot '000-authorization.ps1')
    Write-Output ('TEST_EVIDENCE_DIRECTORY=' + $script:tempRoot)

    # Ensure a broken negative-test helper cannot claim acceptance.
    $caught = $false
    try { Expect-Rejection 'EXPECTED' { } 'guard' } catch { $caught = $_.Exception.Message.StartsWith('WRONG_REJECTION:') }
    Require $caught 'GUARD_UNEXPECTED_ACCEPTANCE'
    $caught = $false
    try { Expect-Rejection 'EXPECTED' { throw 'UNRELATED' } 'guard' } catch { $caught = $_.Exception.Message.StartsWith('WRONG_REJECTION:') }
    Require $caught 'GUARD_UNRELATED_EXCEPTION'

    $f = New-Fixture
    Expect-Rejection 'D2_EXPLICIT_APPROVAL_REQUIRED' {
        New-AijMockApproval -Plan $f.Plan -Workspace $f.Workspace -ConfirmationText 'yes'
    } 'NO_IMPLICIT_APPROVAL'
    Require-NoEffect $f 'NO_APPROVAL_NO_EFFECT'
    Expect-Rejection 'D2_DOCUMENT_MISSING' {
        Invoke-AijApprovedMockPhase -Plan $f.Plan -Workspace $f.Workspace -ApprovalPath (Join-Path $f.Workspace 'approvals\missing.json')
    } 'MISSING_APPROVAL_BLOCKED'
    Require-NoEffect $f 'MISSING_APPROVAL_NO_EFFECT'

    $f = New-Fixture; $approval = Approve-Fixture $f
    $tampered = Copy-AijStateRecord $approval.Approval.Record
    $tampered.SourceLockSha256 = 'F' * 64
    $tamperedDoc = New-AijD2Document $tampered
    [IO.File]::WriteAllText($approval.Path,(ConvertTo-Json -InputObject $tamperedDoc -Depth 45 -Compress),(New-Object Text.UTF8Encoding($false)))
    Expect-Rejection 'D2_APPROVAL_NOT_RECORDED' {
        Invoke-AijApprovedMockPhase -Plan $f.Plan -Workspace $f.Workspace -ApprovalPath $approval.Path
    } 'EDITED_APPROVAL_NOT_VALIDATED_BY_ITS_OWN_HASH'
    Require-NoEffect $f 'TAMPERED_APPROVAL_NO_EFFECT'

    $f = New-Fixture
    $approval = Approve-Fixture $f
    $changed = Copy-AijStateRecord $f.Plan.Record
    $changed.ExitCodes = @(1)
    $changedPlan = New-AijD2Document $changed
    Expect-Rejection 'D2_STATE_BINDING_CHANGED' {
        Invoke-AijApprovedMockPhase -Plan $changedPlan -Workspace $f.Workspace -ApprovalPath $approval.Path
    } 'DIFFERENT_VALID_PLAN_BLOCKED'
    Require-NoEffect $f 'CHANGED_PLAN_NO_EFFECT'

    foreach ($case in @(
        @{Name='PRODUCTION'; Code='D2_PRODUCTION_BLOCKED'; Edit={param($r) $r.ProductionExecutionAuthorized=$true}},
        @{Name='DEPENDENCY'; Code='D2_DEPENDENCY_PROOF_REQUIRED'; Edit={param($r) $r.Phase='020'}},
        @{Name='MISSING_ARTIFACT_LOCK'; Code='D2_ARTIFACT_LOCK_REQUIRED'; Edit={param($r) $r.ArtifactLock=$null}},
        @{Name='CHANGED_ARTIFACT_LOCK'; Code='D2_ARTIFACT_LOCK_CHANGED'; Edit={param($r) $r.ArtifactLock.ExecutorVersion=2}}
    )) {
        $f = New-Fixture; $approval = Approve-Fixture $f
        $record = Copy-AijStateRecord $f.Plan.Record
        & $case.Edit $record
        $bad = New-AijD2Document $record
        Expect-Rejection $case.Code {
            Invoke-AijApprovedMockPhase -Plan $bad -Workspace $f.Workspace -ApprovalPath $approval.Path
        } ($case.Name + '_BLOCKED')
        Require-NoEffect $f ($case.Name + '_NO_EFFECT')
    }

    $f = New-Fixture; $approval = Approve-Fixture $f
    $configPath = Join-Path $fixtureRoot 'config.env'
    $original = [IO.File]::ReadAllBytes($configPath)
    try {
        [IO.File]::AppendAllText($configPath,"`r`n# changed fixture config`r`n",(New-Object Text.UTF8Encoding($false)))
        Expect-Rejection 'D2_CONFIG_CHANGED' {
            Invoke-AijApprovedMockPhase -Plan $f.Plan -Workspace $f.Workspace -ApprovalPath $approval.Path
        } 'CONFIG_CHANGE_BLOCKED'
        Require-NoEffect $f 'CONFIG_CHANGE_NO_EFFECT'
    } finally { [IO.File]::WriteAllBytes($configPath,$original) }

    $f = New-Fixture; $approval = Approve-Fixture $f
    $sourcePath = Join-Path $fixtureRoot '000-dependencies.ps1'
    $original = [IO.File]::ReadAllBytes($sourcePath)
    $sentinel = Join-Path $script:tempRoot 'changed-source-ran.txt'
    try {
        # If the stale dependency module were sourced before checking hashes,
        # this would create evidence of the regression in the fixture only.
        $injection = "`r`n[IO.File]::WriteAllText('" + $sentinel.Replace("'","''") + "','ran')`r`n"
        [IO.File]::AppendAllText($sourcePath,$injection,(New-Object Text.UTF8Encoding($false)))
        Expect-Rejection 'D2_SOURCE_CHANGED' {
            Invoke-AijApprovedMockPhase -Plan $f.Plan -Workspace $f.Workspace -ApprovalPath $approval.Path
        } 'SOURCE_CHANGE_BLOCKED'
        Require (-not [IO.File]::Exists($sentinel)) 'CHANGED_SOURCE_NOT_LOADED'
        Require-NoEffect $f 'SOURCE_CHANGE_NO_EFFECT'
    } finally { [IO.File]::WriteAllBytes($sourcePath,$original) }

    $f = New-Fixture; $approval = Approve-Fixture $f
    $markerPath = Join-Path $f.Workspace 'workspace.json'
    $bytes = [IO.File]::ReadAllBytes($markerPath)
    try {
        $marker = Read-AijD2Document $markerPath
        $marker.Record | Add-Member -NotePropertyName Changed -NotePropertyValue $true
        $marker = New-AijD2Document $marker.Record
        [IO.File]::WriteAllText($markerPath,(ConvertTo-Json -InputObject $marker -Depth 45 -Compress),(New-Object Text.UTF8Encoding($false)))
        Expect-Rejection 'D2_TARGET_CHANGED' {
            Invoke-AijApprovedMockPhase -Plan $f.Plan -Workspace $f.Workspace -ApprovalPath $approval.Path
        } 'TARGET_CHANGE_BLOCKED'
        Require-NoEffect $f 'TARGET_CHANGE_NO_EFFECT'
    } finally { [IO.File]::WriteAllBytes($markerPath,$bytes) }

    $f = New-Fixture; $approval = Approve-Fixture $f
    $pending = Join-Path $f.Workspace 'pending.json'
    Save-AijD2Document $pending $approval.Approval
    Expect-Rejection 'D2_RECOVERY_REQUIRED' {
        Invoke-AijApprovedMockPhase -Plan $f.Plan -Workspace $f.Workspace -ApprovalPath $approval.Path
    } 'UNCERTAIN_PREVIOUS_ATTEMPT_BLOCKED'
    Require-NoEffect $f 'UNCERTAIN_ATTEMPT_NO_EFFECT'

    $f = New-Fixture; $approval = Approve-Fixture $f
    $used = Join-Path $f.Workspace ('approvals\' + $approval.Approval.Record.Id + '.used')
    Write-AijD2NewFile $used $approval.Approval.Sha256
    Expect-Rejection 'D2_APPROVAL_CONSUMED' {
        Invoke-AijApprovedMockPhase -Plan $f.Plan -Workspace $f.Workspace -ApprovalPath $approval.Path
    } 'ONE_USE_APPROVAL_BLOCKED'
    Require-NoEffect $f 'CONSUMED_APPROVAL_NO_EFFECT'

    $f = New-Fixture; $approval = Approve-Fixture $f
    # Persist a different but structurally valid blocked state using the
    # existing store. The approval/log must still bind to the old exact state.
    $changedStateRecord = Copy-AijStateRecord $f.State.Record
    $changedStateRecord | Add-Member -NotePropertyName FixtureNote -NotePropertyValue 'changed'
    $changedState = New-AijStateWrapperFromRecord $changedStateRecord
    $null = Write-AijStateFile -StateDraft $changedState -Directory (Join-Path $f.Workspace 'state') -ExpectedPreviousSha256 $f.State.Sha256
    Expect-Rejection 'D2_STATE_AUDIT_MISMATCH' {
        Invoke-AijApprovedMockPhase -Plan $f.Plan -Workspace $f.Workspace -ApprovalPath $approval.Path
    } 'STALE_STATE_APPROVAL_BLOCKED'
    Require (@(Get-ChildItem -LiteralPath $f.Workspace -Filter 'result-*.json' -File).Count -eq 0) 'STALE_STATE_NO_EFFECT'

    $f = New-Fixture; $approval = Approve-Fixture $f
    $audit = Join-Path $f.Workspace 'audit.jsonl'
    [IO.File]::AppendAllText($audit,'truncated',(New-Object Text.UTF8Encoding($false)))
    Expect-Rejection 'D2_AUDIT_TRUNCATED' {
        Invoke-AijApprovedMockPhase -Plan $f.Plan -Workspace $f.Workspace -ApprovalPath $approval.Path
    } 'DAMAGED_AUDIT_BLOCKED'
    Require-NoEffect $f 'DAMAGED_AUDIT_NO_EFFECT'

    $f = New-Fixture; $approval = Approve-Fixture $f
    $audit = Join-Path $f.Workspace 'audit.jsonl'
    $handle = [IO.File]::Open($audit,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
    $denied = $false
    try {
        try { $null = Invoke-AijApprovedMockPhase -Plan $f.Plan -Workspace $f.Workspace -ApprovalPath $approval.Path }
        catch {
            $ex = $_.Exception
            while ($null -ne $ex.InnerException) { $ex = $ex.InnerException }
            $denied = ($ex -is [IO.IOException] -and (($ex.HResult -band 65535) -eq 32))
        }
    } finally { $handle.Dispose() }
    Require $denied 'UNAVAILABLE_AUDIT_SHARING_VIOLATION'
    Require-NoEffect $f 'UNAVAILABLE_AUDIT_NO_EFFECT'

    foreach ($code in @(0,1,77)) {
        $f = New-Fixture -Codes @($code); $approval = Approve-Fixture $f
        $prefix = [IO.File]::ReadAllText((Join-Path $f.Workspace 'audit.jsonl'))
        $result = Invoke-AijApprovedMockPhase -Plan $f.Plan -Workspace $f.Workspace -ApprovalPath $approval.Path
        $expected = switch ($code) { 0 {'PROGRESS_BLOCKED'} 1 {'EXECUTION_FAILED'} default {'FAILED_CLOSED'} }
        $expectedExit = if ($code -eq 0) {0} else {1}
        Require ($result.ExitCode -eq $expectedExit -and $result.State.Record.State -ceq $expected) ('RESULT_' + $code)
        $saved = Read-AijStateFile -Directory (Join-Path $f.Workspace 'state')
        Require ($saved.Sha256 -ceq $result.State.Sha256 -and -not $saved.Record.ExecutionAuthorized) ('DURABLE_RESULT_' + $code)
        Require (@($saved.Record.PhaseEvidence | Where-Object {$_.RuntimeVerified}).Count -eq 0) ('NO_INFERRED_VERIFY_' + $code)
        $after = [IO.File]::ReadAllText((Join-Path $f.Workspace 'audit.jsonl'))
        Require ($after.StartsWith($prefix,[StringComparison]::Ordinal)) ('AUDIT_APPEND_' + $code)
        Require ((Get-AijD2AuditTail $f.Workspace).CommittedStateSha256 -ceq $saved.Sha256) ('AUDIT_STATE_BINDING_' + $code)
        Expect-Rejection 'D2_STATE_NOT_EXECUTABLE' {
            Invoke-AijApprovedMockPhase -Plan $f.Plan -Workspace $f.Workspace -ApprovalPath $approval.Path
        } ('COMPLETED_ATTEMPT_CANNOT_REPEAT_' + $code)
        Require (@(Get-ChildItem -LiteralPath $f.Workspace -Filter 'result-*.json' -File).Count -eq 1) ('EXACTLY_ONE_EFFECT_' + $code)
    }

    $f = New-Fixture -Codes @(3010,0); $approval = Approve-Fixture $f
    $first = Invoke-AijApprovedMockPhase -Plan $f.Plan -Workspace $f.Workspace -ApprovalPath $approval.Path
    Require ($first.ExitCode -eq 3010 -and $first.State.Record.State -ceq 'REBOOT_PENDING') '3010_PRESERVED'
    Expect-Rejection 'D2_APPROVAL_STATE_CHANGED' {
        Invoke-AijApprovedMockPhase -Plan $f.Plan -Workspace $f.Workspace -ApprovalPath $approval.Path -Resume
    } 'OLD_APPROVAL_CANNOT_RESUME'
    $secondApproval = Approve-Fixture $f
    Expect-Rejection 'D2_RESUME_APPROVAL_REQUIRED' {
        Invoke-AijApprovedMockPhase -Plan $f.Plan -Workspace $f.Workspace -ApprovalPath $secondApproval.Path
    } 'RESUME_MUST_BE_EXPLICIT'
    $second = Invoke-AijApprovedMockPhase -Plan $f.Plan -Workspace $f.Workspace -ApprovalPath $secondApproval.Path -Resume
    $phase = @($second.State.Record.PhaseEvidence | Where-Object {$_.Phase -ceq '010'})[0]
    Require ($second.ExitCode -eq 0 -and $phase.Attempt -eq 2 -and -not $phase.RuntimeVerified) 'FRESH_APPROVAL_SAME_PHASE_RESUME'

    # Audit schema proves redaction by construction: only fixed metadata,
    # hashes, timestamps, phase and exit code can enter the log.
    $auditFields = @('Schema','Kind','Sequence','PreviousSha256','Utc','Event','Phase','PlanSha256','StateSha256','ApprovalSha256','ExitCode')
    foreach ($line in [IO.File]::ReadAllLines((Join-Path $f.Workspace 'audit.jsonl'))) {
        $entry = ConvertFrom-Json -InputObject $line
        $actualFields = @($entry.Record.PSObject.Properties.Name)
        if (@(Compare-Object $auditFields $actualFields).Count -ne 0) { throw 'AUDIT_FIELD_LEAK' }
    }
    Require $true 'AUDIT_FIXED_REDACTED_SCHEMA'

    # Shared BAT must call the strict parser and export only its known keys.
    $common = Join-Path $fixtureRoot '_common.bat'
    $validConfig = [IO.File]::ReadAllText($configPath)
    $emptyConfig = Join-Path $script:tempRoot 'empty.env'
    $emptyText = [regex]::Replace($validConfig,'(?m)^ALLOW_HOSTS_INSTALL=[^\r\n]*','ALLOW_HOSTS_INSTALL=')
    [IO.File]::WriteAllText($emptyConfig,$emptyText,(New-Object Text.UTF8Encoding($false)))
    $body = @"
@echo off
setlocal EnableDelayedExpansion
set "ALLOW_HOSTS_INSTALL=stale"
call "$common" :load "$emptyConfig"
if errorlevel 1 exit /b 31
if defined ALLOW_HOSTS_INSTALL exit /b 32
if not defined DISTRO exit /b 33
echo STRICT_LOAD_OK
exit /b 0
"@
    $cmd = Invoke-CmdFixture $body
    Require ($cmd.ExitCode -eq 0 -and $cmd.Stdout.Contains('STRICT_LOAD_OK')) 'COMMON_VALID_AND_EMPTY_ALLOWLIST'
    foreach ($badLine in @('UNKNOWN_KEY=1','TARGET_DRIVE=E:','PATH=changed','AIJAIL_APPROVED=1','DISTRO=x&echo SHOULD_NOT_RUN')) {
        $badConfig = Join-Path $script:tempRoot 'bad.env'
        [IO.File]::WriteAllText($badConfig,($validConfig + "`r`n" + $badLine),(New-Object Text.UTF8Encoding($false)))
        $body = @"
@echo off
setlocal DisableDelayedExpansion
set "DISTRO=stale"
set "AIJAIL_APPROVED=sentinel"
set "PATH=AIJAIL_PATH_SENTINEL"
call "$common" :load "$badConfig"
if not errorlevel 1 exit /b 41
if defined DISTRO exit /b 42
if not "%AIJAIL_APPROVED%"=="sentinel" exit /b 43
if not "%PATH%"=="AIJAIL_PATH_SENTINEL" exit /b 44
echo STRICT_REJECTION_OK
exit /b 0
"@
        $cmd = Invoke-CmdFixture $body
        Require ($cmd.ExitCode -eq 0 -and $cmd.Stdout.Contains('STRICT_REJECTION_OK') -and -not $cmd.Stdout.Contains('SHOULD_NOT_RUN')) ('COMMON_REJECTS_' + $badLine.Split('=')[0])
    }
    $body = @"
@echo off
call "$common" :run_phase echo LEGACY_EXECUTED
if not errorlevel 1 exit /b 51
echo LEGACY_BLOCKED
exit /b 0
"@
    $cmd = Invoke-CmdFixture $body
    Require ($cmd.ExitCode -eq 0 -and $cmd.Stdout.Contains('LEGACY_BLOCKED') -and -not $cmd.Stdout.Contains('LEGACY_EXECUTED')) 'LEGACY_EXECUTION_BYPASS_BLOCKED'
    Write-Output ('DELIVERABLE_2_FOCUSED_OK assertions=' + $script:checks)
    # Keep the bounded temporary evidence directory for operator inspection.
    exit 0
} catch {
    [Console]::Error.WriteLine('DELIVERABLE_2_FOCUSED_FAILED: ' + $_.Exception.Message)
    [Console]::Error.WriteLine($_.ScriptStackTrace)
    if ($null -ne $script:tempRoot) { [Console]::Error.WriteLine('Evidence retained: ' + $script:tempRoot) }
    exit 1
}
