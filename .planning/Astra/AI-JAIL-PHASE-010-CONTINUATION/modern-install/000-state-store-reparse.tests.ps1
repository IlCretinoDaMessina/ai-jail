# Phase 000 - State-store reparse regression
# Windows PowerShell 5.1

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

. (Join-Path $PSScriptRoot '000-manifest.ps1')
. (Join-Path $PSScriptRoot '000-state.ps1')
. (Join-Path $PSScriptRoot '000-state-store.ps1')

$root = $null
$junctions = New-Object 'System.Collections.Generic.List[string]'

function New-TestJunction {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Target
    )

    $command = 'mklink /J "{0}" "{1}" >NUL 2>NUL' -f $Path, $Target

    & $env:ComSpec /D /C $command

    if ($LASTEXITCODE -ne 0 -or
        -not [IO.Directory]::Exists($Path)) {
        throw 'TEST_SETUP_FAILURE: Could not create junction fixture.'
    }

    $attributes = [IO.File]::GetAttributes($Path)

    if (($attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0) {
        throw 'TEST_SETUP_FAILURE: Junction fixture is not a reparse point.'
    }

    $junctions.Add($Path)
}

function Assert-Rejection {
    param(
        [string]$Label,
        [scriptblock]$Operation,
        [string]$Expected
    )

    $actual = $null

    try {
        $null = & $Operation
    }
    catch {
        $actual = $_.Exception.Message
    }

    if ($null -eq $actual) {
        throw "ASSERTION_FAILURE: ${Label}: accepted or not executed."
    }

    if ($actual -cne $Expected) {
        throw (
            "ASSERTION_FAILURE: ${Label}: expected [$Expected], " +
            "received [$actual]."
        )
    }

    Write-Output "PASS: $Label"
}

try {
    $root = Join-Path ([IO.Path]::GetTempPath()) (
        'AIJ-REPARSE-' + [guid]::NewGuid().ToString('N')
    )

    [void][IO.Directory]::CreateDirectory($root)

    $plan = New-AijPlanSnapshot -Root $PSScriptRoot
    $state = New-AijStateDraft -Snapshot $plan

    # Direct directory

    $direct = Join-Path $root 'direct'
    [void][IO.Directory]::CreateDirectory($direct)

    $written = Write-AijStateDraftFile `
        -StateDraft $state `
        -Directory $direct

    if (-not [IO.File]::Exists($written.Path)) {
        throw 'TEST_SETUP_FAILURE: Direct persistence failed.'
    }

    Write-Output 'PASS: DIRECT_DIRECTORY_BASELINE'

    # Final directory is a junction

    $realFinal = Join-Path $root 'real-final'
    $junctionFinal = Join-Path $root 'junction-final'

    [void][IO.Directory]::CreateDirectory($realFinal)

    New-TestJunction `
        -Path $junctionFinal `
        -Target $realFinal

    Assert-Rejection `
        -Label 'FINAL_DIRECTORY_JUNCTION_REJECTED' `
        -Operation {
            Write-AijStateDraftFile `
                -StateDraft $state `
                -Directory $junctionFinal
        } `
        -Expected 'State directory reparse point rejected.'

    # Ancestor directory is a junction

    $realAncestor = Join-Path $root 'real-ancestor'
    $realChild = Join-Path $realAncestor 'child'
    $junctionAncestor = Join-Path $root 'junction-ancestor'
    $aliasedChild = Join-Path $junctionAncestor 'child'

    [void][IO.Directory]::CreateDirectory($realAncestor)
    [void][IO.Directory]::CreateDirectory($realChild)

    New-TestJunction `
        -Path $junctionAncestor `
        -Target $realAncestor

    $actual = $null
    $accepted = $false

    try {
        $null = Write-AijStateDraftFile `
            -StateDraft $state `
            -Directory $aliasedChild

        $accepted = $true
    }
    catch {
        $actual = $_.Exception.Message
    }

    if ($accepted) {
        throw 'DEFECT_CONFIRMED: State directory beneath a junction ancestor was accepted.'
    }

    if ($actual -cne 'State path ancestor reparse point rejected.') {
        throw "UNEXPECTED_REJECTION: $actual"
    }

    Write-Output 'PASS: ANCESTOR_JUNCTION_REJECTED'
    Write-Output 'STATE_STORE_REPARSE_REGRESSION_OK'

    exit 0
}
catch {
    [Console]::Error.WriteLine($_.ToString())
    exit 1
}
finally {
    foreach ($junction in $junctions) {
        if ([IO.Directory]::Exists($junction)) {
            & $env:ComSpec /D /C (
                'rmdir "{0}" >NUL 2>NUL' -f $junction
            )
        }
    }

    if ($null -ne $root -and
        [IO.Directory]::Exists($root)) {
        [IO.Directory]::Delete($root, $true)
    }
}