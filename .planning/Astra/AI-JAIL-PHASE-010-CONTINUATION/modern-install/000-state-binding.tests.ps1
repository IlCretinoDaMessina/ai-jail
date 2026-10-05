# Phase 000 - State binding regression
# Windows PowerShell 5.1

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

. (Join-Path $PSScriptRoot '000-manifest.ps1')
. (Join-Path $PSScriptRoot '000-state.ps1')

try {
    $plan = New-AijPlanSnapshot -Root $PSScriptRoot

    $baseline = New-AijStateDraft -Snapshot $plan

    if ($baseline.Record.Plan.SnapshotSha256 -cne $plan.Sha256 -or
        $baseline.Record.ExecutionAuthorized -ne $false) {
        throw 'TEST_SETUP_FAILURE: Baseline state invalid.'
    }

    Write-Output 'PASS: VALID_BASELINE'

    # The JSON and fingerprint remain unchanged while Manifest is altered.

    $originalJson = $plan.Json
    $originalSha = $plan.Sha256
    $originalDistro = $plan.Manifest.ProposedTarget.Distro

    $plan.Manifest.ProposedTarget.Distro = 'TamperedDistro'

    if ($plan.Json -cne $originalJson -or
        $plan.Sha256 -cne $originalSha) {
        throw 'TEST_SETUP_FAILURE: Wrapper identity unexpectedly changed.'
    }

    if ($plan.Manifest.ProposedTarget.Distro -ceq $originalDistro) {
        throw 'TEST_SETUP_FAILURE: Manifest tamper did not occur.'
    }

    $actual = $null

    try {
        $null = New-AijStateDraft -Snapshot $plan
    }
    catch {
        $actual = $_.Exception.Message
    }

    if ($null -eq $actual) {
        throw 'DEFECT_CONFIRMED: Mutated Manifest was accepted although PLAN JSON and fingerprint describe different content.'
    }

    if ($actual -cne 'PLAN snapshot content mismatch.') {
        throw "UNEXPECTED_REJECTION: $actual"
    }

    Write-Output 'PASS: MANIFEST_JSON_MISMATCH_REJECTED'
    Write-Output 'STATE_BINDING_REGRESSION_OK'

    exit 0
}
catch {
    [Console]::Error.WriteLine($_.ToString())
    exit 1
}