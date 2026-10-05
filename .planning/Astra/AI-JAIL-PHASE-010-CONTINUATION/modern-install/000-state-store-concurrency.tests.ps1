# Phase 000 - State-store concurrency regression
# Windows PowerShell 5.1

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

$root = $PSScriptRoot
$temp = $null
$processA = $null
$processB = $null
$utf8 = New-Object Text.UTF8Encoding($false, $true)

. (Join-Path $root '000-manifest.ps1')
. (Join-Path $root '000-state.ps1')
. (Join-Path $root '000-state-store.ps1')

function New-TestAuthorizedState {
    param(
        [Parameter(Mandatory = $true)]
        $StateDraft,

        [Parameter(Mandatory = $true)]
        [string]$Phase
    )

    Assert-AijStateWrapper -StateDraft $StateDraft

    $record = Copy-AijStateRecord `
        -Record $StateDraft.Record

    $record.State = 'EXECUTION_AUTHORIZED'
    $record.ExecutionAuthorized = $true
    $record.Plan.ArtifactLockSha256 = ('B' * 64)

    $record.Target.IdentityVerified = $true
    $record.Target.StoragePathVerified = $true

    $record.Approval.Status = 'RECORDED'
    $record.Approval.SnapshotSha256 =
        $record.Plan.SnapshotSha256
    $record.Approval.ApprovedBy =
        'CONTROLLED_CONCURRENCY_TEST'
    $record.Approval.ApprovedAtUtc =
        '2000-01-01T00:00:00Z'

    $record.Resume.Status = 'NONE'
    $record.Resume.FromPhase = $null
    $record.Resume.RebootPending = $false
    $record.Resume.RebootPhase = $null

    return New-AijStateWrapperFromRecord `
        -Record $record
}

function Quote-ProcessArgument {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    if ($Value.Contains('"')) {
        throw 'TEST_SETUP_FAILURE: Unsupported quote in process argument.'
    }

    return '"' + $Value + '"'
}

function Start-Worker {
    param(
        [Parameter(Mandatory = $true)]
        [string]$WorkerPath,

        [Parameter(Mandatory = $true)]
        [string]$CandidatePath,

        [Parameter(Mandatory = $true)]
        [string]$ReadyPath,

        [Parameter(Mandatory = $true)]
        [string]$GatePath,

        [Parameter(Mandatory = $true)]
        [string]$ResultPath,

        [Parameter(Mandatory = $true)]
        [string]$StateDirectory,

        [Parameter(Mandatory = $true)]
        [string]$ExpectedPreviousSha256
    )

    $powerShellPath = Join-Path $PSHOME 'powershell.exe'

    $arguments = @(
        '-NoProfile',
        '-NonInteractive',
        '-ExecutionPolicy Bypass',
        '-File',
        (Quote-ProcessArgument -Value $WorkerPath),
        (Quote-ProcessArgument -Value $root),
        (Quote-ProcessArgument -Value $StateDirectory),
        (Quote-ProcessArgument -Value $CandidatePath),
        (Quote-ProcessArgument -Value $ExpectedPreviousSha256),
        (Quote-ProcessArgument -Value $ReadyPath),
        (Quote-ProcessArgument -Value $GatePath),
        (Quote-ProcessArgument -Value $ResultPath)
    ) -join ' '

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $powerShellPath
    $psi.Arguments = $arguments
    $psi.WorkingDirectory = $root
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi

    if (-not $process.Start()) {
        $process.Dispose()
        throw 'TEST_SETUP_FAILURE: Worker process did not start.'
    }

    return $process
}

function Wait-ForFiles {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Paths,

        [Parameter(Mandatory = $true)]
        [int]$TimeoutMilliseconds
    )

    $watch = [Diagnostics.Stopwatch]::StartNew()

    try {
        while ($watch.ElapsedMilliseconds -lt
            $TimeoutMilliseconds) {

            $allPresent = $true

            foreach ($path in $Paths) {
                if (-not [IO.File]::Exists($path)) {
                    $allPresent = $false
                    break
                }
            }

            if ($allPresent) {
                return
            }

            Start-Sleep -Milliseconds 25
        }
    }
    finally {
        $watch.Stop()
    }

    throw 'TEST_SETUP_FAILURE: Worker readiness timed out.'
}

try {
    # Fixture state

    $snapshot = New-AijPlanSnapshot -Root $root
    $draft = New-AijStateDraft -Snapshot $snapshot

    $authorized = New-TestAuthorizedState `
        -StateDraft $draft `
        -Phase '010'

    $failure = Apply-AijPhaseResultTransition `
        -StateDraft $authorized `
        -Phase '010' `
        -ExitCode 1 `
        -EvidenceSha256 ('C' * 64)

    $reboot = Apply-AijPhaseResultTransition `
        -StateDraft $authorized `
        -Phase '010' `
        -ExitCode 3010 `
        -EvidenceSha256 ('D' * 64)

    Assert-AijPersistableState -StateDraft $failure
    Assert-AijPersistableState -StateDraft $reboot

    if ($failure.Sha256 -ceq $reboot.Sha256) {
        throw 'TEST_SETUP_FAILURE: Candidate states are identical.'
    }

    $temp = Join-Path ([IO.Path]::GetTempPath()) (
        'AIJ-STATE-CONCURRENCY-' +
        [guid]::NewGuid().ToString('N')
    )

    [void][IO.Directory]::CreateDirectory($temp)

    $stateDirectory = Join-Path $temp 'state'
    [void][IO.Directory]::CreateDirectory($stateDirectory)

    $initial = Write-AijStateDraftFile `
        -StateDraft $draft `
        -Directory $stateDirectory

    if (-not [IO.File]::Exists($initial.Path)) {
        throw 'TEST_SETUP_FAILURE: Initial state was not persisted.'
    }

    # Candidate files

    $candidateAPath = Join-Path $temp 'candidate-a.json'
    $candidateBPath = Join-Path $temp 'candidate-b.json'

    [IO.File]::WriteAllText(
        $candidateAPath,
        $failure.Json,
        $utf8
    )

    [IO.File]::WriteAllText(
        $candidateBPath,
        $reboot.Json,
        $utf8
    )

    # Worker

    $workerPath = Join-Path $temp 'worker.ps1'

    $workerText = @'
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

$root = $args[0]
$stateDirectory = $args[1]
$candidatePath = $args[2]
$expectedPreviousSha256 = $args[3]
$readyPath = $args[4]
$gatePath = $args[5]
$resultPath = $args[6]

$utf8 = New-Object Text.UTF8Encoding($false, $true)

. (Join-Path $root '000-state.ps1')
. (Join-Path $root '000-state-store.ps1')

try {
    $json = [IO.File]::ReadAllText(
        $candidatePath,
        $utf8
    )

    $record = ConvertFrom-Json `
        -InputObject $json `
        -ErrorAction Stop

    $state = [pscustomobject]@{
        Record = $record
        Json = $json
        Sha256 = Get-AijTextSha256 -Text $json
    }

    Assert-AijPersistableState -StateDraft $state

    [IO.File]::WriteAllText(
        $readyPath,
        'READY',
        $utf8
    )

    $watch = [Diagnostics.Stopwatch]::StartNew()

    try {
        while (-not [IO.File]::Exists($gatePath)) {
            if ($watch.ElapsedMilliseconds -ge 30000) {
                throw 'WORKER_GATE_TIMEOUT'
            }

            Start-Sleep -Milliseconds 10
        }
    }
    finally {
        $watch.Stop()
    }

    try {
        $path = Write-AijStateFile `
            -StateDraft $state `
            -StateDirectory $stateDirectory `
            -ExpectedPreviousSha256 $expectedPreviousSha256

        [IO.File]::WriteAllText(
            $resultPath,
            ('SUCCESS|' + $path),
            $utf8
        )
    }
    catch {
        [IO.File]::WriteAllText(
            $resultPath,
            ('ERROR|' + $_.Exception.Message),
            $utf8
        )
    }

    exit 0
}
catch {
    try {
        [IO.File]::WriteAllText(
            $resultPath,
            ('WORKER_FAILURE|' + $_.Exception.Message),
            $utf8
        )
    }
    catch {
    }

    exit 1
}
'@

    [IO.File]::WriteAllText(
        $workerPath,
        $workerText,
        $utf8
    )

    $readyA = Join-Path $temp 'a.ready'
    $readyB = Join-Path $temp 'b.ready'
    $resultA = Join-Path $temp 'a.result'
    $resultB = Join-Path $temp 'b.result'
    $gate = Join-Path $temp 'start.gate'

    # Competing writers

    $processA = Start-Worker `
        -WorkerPath $workerPath `
        -CandidatePath $candidateAPath `
        -ReadyPath $readyA `
        -GatePath $gate `
        -ResultPath $resultA `
        -StateDirectory $stateDirectory `
        -ExpectedPreviousSha256 $draft.Sha256

    $processB = Start-Worker `
        -WorkerPath $workerPath `
        -CandidatePath $candidateBPath `
        -ReadyPath $readyB `
        -GatePath $gate `
        -ResultPath $resultB `
        -StateDirectory $stateDirectory `
        -ExpectedPreviousSha256 $draft.Sha256

    Wait-ForFiles `
        -Paths @($readyA, $readyB) `
        -TimeoutMilliseconds 30000

    [IO.File]::WriteAllText(
        $gate,
        'GO',
        $utf8
    )

    if (-not $processA.WaitForExit(60000)) {
        $processA.Kill()
        $processA.WaitForExit()
        throw 'TEST_SETUP_FAILURE: Writer A timed out.'
    }

    if (-not $processB.WaitForExit(60000)) {
        $processB.Kill()
        $processB.WaitForExit()
        throw 'TEST_SETUP_FAILURE: Writer B timed out.'
    }

    $stderrA = $processA.StandardError.ReadToEnd().Trim()
    $stderrB = $processB.StandardError.ReadToEnd().Trim()

    if ($processA.ExitCode -ne 0) {
        throw (
            'TEST_SETUP_FAILURE: Writer A process failed: ' +
            $stderrA
        )
    }

    if ($processB.ExitCode -ne 0) {
        throw (
            'TEST_SETUP_FAILURE: Writer B process failed: ' +
            $stderrB
        )
    }

    Wait-ForFiles `
        -Paths @($resultA, $resultB) `
        -TimeoutMilliseconds 5000

    $a = [IO.File]::ReadAllText($resultA, $utf8)
    $b = [IO.File]::ReadAllText($resultB, $utf8)

    $results = @($a, $b)

    $successes = @(
        $results |
            Where-Object {
                $_.StartsWith(
                    'SUCCESS|',
                    [StringComparison]::Ordinal
                )
            }
    )

    $stale = @(
        $results |
            Where-Object {
                $_ -ceq (
                    'ERROR|' +
                    'Previous state fingerprint mismatch.'
                )
            }
    )

    if ($successes.Count -ne 1) {
        throw (
            'ASSERTION_FAILURE: Expected exactly one ' +
            'successful competing writer. Results: ' +
            ($results -join ' || ')
        )
    }

    if ($stale.Count -ne 1) {
        throw (
            'ASSERTION_FAILURE: Losing writer did not ' +
            'observe the serialized stale-SHA rejection. ' +
            'Results: ' +
            ($results -join ' || ')
        )
    }

    Write-Output 'PASS: EXACTLY_ONE_COMPETING_WRITER_COMMITTED'
    Write-Output 'PASS: LOSING_WRITER_REJECTED_AS_STALE'

    # Final state

    $final = Read-AijStateFile `
        -StateDirectory $stateDirectory

    if ($final.Sha256 -cne $failure.Sha256 -and
        $final.Sha256 -cne $reboot.Sha256) {
        throw 'ASSERTION_FAILURE: Final state is neither candidate.'
    }

    if ($final.Sha256 -ceq $draft.Sha256) {
        throw 'ASSERTION_FAILURE: Initial state remained unchanged.'
    }

    Write-Output 'PASS: FINAL_STATE_IS_ONE_COMPLETE_CANDIDATE'

    # No partial residue

    $temporaryResidue = @(
        Get-ChildItem `
            -LiteralPath $stateDirectory `
            -Force |
        Where-Object {
            $_.Name -like '.phase-000-state.*.tmp'
        }
    )

    if ($temporaryResidue.Count -ne 0) {
        throw 'ASSERTION_FAILURE: Temporary state residue remains.'
    }

    $stateFiles = @(
        Get-ChildItem `
            -LiteralPath $stateDirectory `
            -File |
        Where-Object {
            $_.Name -ceq 'phase-000-state.json'
        }
    )

    if ($stateFiles.Count -ne 1) {
        throw 'ASSERTION_FAILURE: State-file count is invalid.'
    }

    Write-Output 'PASS: NO_PARTIAL_WRITE_RESIDUE'
    Write-Output 'STATE_STORE_CONCURRENCY_REGRESSION_OK'

    exit 0
}
catch {
    [Console]::Error.WriteLine($_.ToString())
    exit 1
}
finally {
    foreach ($process in @($processA, $processB)) {
        if ($null -ne $process) {
            try {
                if (-not $process.HasExited) {
                    $process.Kill()
                    $process.WaitForExit()
                }
            }
            catch {
            }

            $process.Dispose()
        }
    }

    if ($null -ne $temp -and
        [IO.Directory]::Exists($temp)) {

        try {
            [IO.Directory]::Delete(
                $temp,
                $true
            )
        }
        catch {
            [Console]::Error.WriteLine(
                'TEST_CLEANUP_FAILURE: ' +
                $_.Exception.Message
            )
        }
    }
}