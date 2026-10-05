# Phase 000 - Production source-lock regression
# Windows PowerShell 5.1

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

. (Join-Path $PSScriptRoot '000-manifest.ps1')

try {
    $snapshot = New-AijPlanSnapshot -Root $PSScriptRoot

    if ($snapshot.Manifest.Kind -cne 'PHASE_000_PLAN_SNAPSHOT' -or
        $snapshot.Manifest.State -cne 'DRAFT_BLOCKED' -or
        $snapshot.Manifest.ExecutionAuthorized -ne $false) {
        throw 'TEST_SETUP_FAILURE: Baseline PLAN snapshot invalid.'
    }

    Write-Output 'PASS: VALID_PLAN_BASELINE'

    $names = @($snapshot.Manifest.SourceFiles.Name)

    $missing = @(
        @(
            '000-state.ps1',
            '000-state-store.ps1'
        ) | Where-Object {
            $names -cnotcontains $_
        }
    )

    if ($missing.Count -gt 0) {
        throw (
            'DEFECT_CONFIRMED: PLAN source lock omits production modules: ' +
            ($missing -join ', ') +
            '.'
        )
    }

    foreach ($name in @(
        '000-state.ps1',
        '000-state-store.ps1'
    )) {
        $record = @(
            $snapshot.Manifest.SourceFiles |
                Where-Object { $_.Name -ceq $name }
        )

        if ($record.Count -ne 1 -or
            $record[0].Sha256 -cnotmatch '^[A-F0-9]{64}$') {
            throw "SOURCE_LOCK_FAILURE: $name"
        }

        $actual = (
            Get-FileHash `
                -LiteralPath (Join-Path $PSScriptRoot $name) `
                -Algorithm SHA256
        ).Hash

        if ($record[0].Sha256 -cne $actual) {
            throw "SOURCE_HASH_MISMATCH: $name"
        }
    }

    if ($snapshot.Manifest.SourceFiles.Count -ne 33) {
        throw (
            'SOURCE_COUNT_FAILURE: expected 33, received ' +
            $snapshot.Manifest.SourceFiles.Count +
            '.'
        )
    }

    Write-Output 'PASS: STATE_MODULES_BOUND_TO_PLAN'
    Write-Output 'PASS: SOURCE_COUNT_33'
    Write-Output 'MANIFEST_SOURCE_LOCK_REGRESSION_OK'

    exit 0
}
catch {
    [Console]::Error.WriteLine($_.ToString())
    exit 1
}