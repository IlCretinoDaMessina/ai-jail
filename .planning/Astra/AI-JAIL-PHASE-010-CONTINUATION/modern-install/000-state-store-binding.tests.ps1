# Phase 000 - State-store binding regression
# Windows PowerShell 5.1

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

. (Join-Path $PSScriptRoot '000-manifest.ps1')
. (Join-Path $PSScriptRoot '000-state.ps1')
. (Join-Path $PSScriptRoot '000-state-store.ps1')

$temp = $null

try {
    $plan = New-AijPlanSnapshot -Root $PSScriptRoot
    $state = New-AijStateDraft -Snapshot $plan

    $temp = Join-Path ([IO.Path]::GetTempPath()) (
        'AIJ-STATE-BIND-' + [guid]::NewGuid().ToString('N')
    )

    [void][IO.Directory]::CreateDirectory($temp)

    # Positive control

    $control = Join-Path $temp 'control'
    [void][IO.Directory]::CreateDirectory($control)

    $written = Write-AijStateDraftFile `
        -StateDraft $state `
        -Directory $control

    if (-not [IO.File]::Exists($written.Path)) {
        throw 'TEST_SETUP_FAILURE: Valid state was not persisted.'
    }

    Write-Output 'PASS: VALID_STATE_PERSISTENCE_BASELINE'

    # Self-consistent but unsafe phase evidence

    $record = ConvertFrom-Json `
        -InputObject $state.Json `
        -ErrorAction Stop

    $record.PhaseEvidence[0].State = 'RUNTIME_PASS'
    $record.PhaseEvidence[0].Attempt = 1
    $record.PhaseEvidence[0].ExitCode = 0
    $record.PhaseEvidence[0].RuntimeVerified = $true
    $record.PhaseEvidence[0].EvidenceSha256 = ('A' * 64)

    $json = ConvertTo-Json `
        -InputObject $record `
        -Depth 20 `
        -Compress

    $unsafe = [pscustomobject]@{
        Record = $record
        Json = $json
        Sha256 = Get-AijTextSha256 -Text $json
    }

    $unsafeFolder = Join-Path $temp 'unsafe'
    [void][IO.Directory]::CreateDirectory($unsafeFolder)

    $actual = $null

    try {
        $null = Write-AijStateDraftFile `
            -StateDraft $unsafe `
            -Directory $unsafeFolder
    }
    catch {
        $actual = $_.Exception.Message
    }

    if ($null -eq $actual) {
        throw 'DEFECT_CONFIRMED: Self-consistent runtime evidence was accepted in PLAN_BLOCKED state.'
    }

    if ($actual -cne 'Unsafe persisted phase evidence: 010.') {
        throw "UNEXPECTED_REJECTION: $actual"
    }

    Write-Output 'PASS: UNSAFE_PHASE_EVIDENCE_REJECTED'
    Write-Output 'STATE_STORE_BINDING_REGRESSION_OK'

    exit 0
}
catch {
    [Console]::Error.WriteLine($_.ToString())
    exit 1
}
finally {
    if ($null -ne $temp -and [IO.Directory]::Exists($temp)) {
        [IO.Directory]::Delete($temp, $true)
    }
}