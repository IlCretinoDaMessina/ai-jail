# Phase 000 - State validation regressions
# Windows PowerShell 5.1

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

. (Join-Path $PSScriptRoot '000-manifest.ps1')
. (Join-Path $PSScriptRoot '000-state.ps1')

$script:positive = 0
$script:negative = 0
$script:guards = 0

function Copy-AijManifest {
    param(
        [Parameter(Mandatory = $true)]
        $Snapshot
    )

    return ConvertFrom-Json `
        -InputObject $Snapshot.Json `
        -ErrorAction Stop
}

function New-AijConsistentSnapshot {
    param(
        [Parameter(Mandatory = $true)]
        $Manifest
    )

    $json = ConvertTo-Json `
        -InputObject $Manifest `
        -Depth 20 `
        -Compress

    return [pscustomobject]@{
        Manifest = $Manifest
        Json = $json
        Sha256 = Get-AijTextSha256 -Text $json
    }
}

function Assert-AijRejection {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,

        [Parameter(Mandatory = $true)]
        [scriptblock]$Operation,

        [Parameter(Mandatory = $true)]
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

    $script:negative++
    Write-Output "PASS: $Label"
}

function Assert-AijGuard {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,

        [Parameter(Mandatory = $true)]
        [scriptblock]$Probe,

        [Parameter(Mandatory = $true)]
        [string]$Expected
    )

    $actual = $null

    try {
        $null = & $Probe
    }
    catch {
        $actual = $_.Exception.Message
    }

    if ($actual -cne $Expected) {
        throw "TEST_GUARD_FAILURE: $Label."
    }

    $script:guards++
    Write-Output "PASS: GUARD_$Label"
}

try {
    $plan = New-AijPlanSnapshot -Root $PSScriptRoot
    $state = New-AijStateDraft -Snapshot $plan

    if ($state.Record.Kind -cne 'PHASE_000_STATE' -or
        $state.Record.State -cne 'PLAN_BLOCKED' -or
        $state.Record.ExecutionAuthorized -ne $false -or
        $state.Record.PhaseEvidence.Count -ne 11) {
        throw 'TEST_SETUP_FAILURE: Valid baseline state failed.'
    }

    $script:positive++
    Write-Output 'PASS: VALID_STATE_BASELINE'

    # Fingerprint corruption

    $badHash = [pscustomobject]@{
        Manifest = $plan.Manifest
        Json = $plan.Json
        Sha256 = ('0' * 64)
    }

    if ($badHash.Sha256 -ceq $plan.Sha256) {
        $badHash.Sha256 = ('1' * 64)
    }

    Assert-AijRejection `
        -Label 'CORRUPTED_PLAN_FINGERPRINT_REJECTED' `
        -Operation { New-AijStateDraft -Snapshot $badHash } `
        -Expected 'PLAN snapshot fingerprint mismatch.'

    # Manifest differs from hashed JSON

    $mismatch = [pscustomobject]@{
        Manifest = Copy-AijManifest -Snapshot $plan
        Json = $plan.Json
        Sha256 = $plan.Sha256
    }

    $mismatch.Manifest.ProposedTarget.Distro = 'DifferentDistro'

    Assert-AijRejection `
        -Label 'MANIFEST_JSON_MISMATCH_REJECTED' `
        -Operation { New-AijStateDraft -Snapshot $mismatch } `
        -Expected 'PLAN snapshot content mismatch.'

    # Unsafe authorization fields

    foreach ($case in @(
        @('PLAN_EXECUTION_AUTHORIZED_REJECTED', 'ExecutionAuthorized'),
        @('PLAN_APPROVAL_RECORDED_REJECTED', 'ApprovalRecorded'),
        @('PLAN_READY_FOR_APPROVAL_REJECTED', 'ReadyForApproval')
    )) {
        $manifest = Copy-AijManifest -Snapshot $plan
        $property = $case[1]
        $manifest.$property = $true
        $candidate = New-AijConsistentSnapshot -Manifest $manifest

        Assert-AijRejection `
            -Label $case[0] `
            -Operation { New-AijStateDraft -Snapshot $candidate } `
            -Expected 'PLAN snapshot is not in the required blocked state.'
    }

    # Artifact lock cannot appear in a blocked draft

    $manifest = Copy-AijManifest -Snapshot $plan
    $manifest.ArtifactLock = [pscustomobject]@{
        Sha256 = ('A' * 64)
    }

    $candidate = New-AijConsistentSnapshot -Manifest $manifest

    Assert-AijRejection `
        -Label 'UNEXPECTED_ARTIFACT_LOCK_REJECTED' `
        -Operation { New-AijStateDraft -Snapshot $candidate } `
        -Expected 'PLAN snapshot is not in the required blocked state.'

    # Selected actions cannot appear in a blocked draft

    $manifest = Copy-AijManifest -Snapshot $plan
    $manifest.SelectedActions = @('030')
    $candidate = New-AijConsistentSnapshot -Manifest $manifest

    Assert-AijRejection `
        -Label 'UNEXPECTED_SELECTED_ACTION_REJECTED' `
        -Operation { New-AijStateDraft -Snapshot $candidate } `
        -Expected 'PLAN snapshot is not in the required blocked state.'

    # Configuration identity

    $manifest = Copy-AijManifest -Snapshot $plan
    $manifest.ConfigurationSha256 = 'BAD'
    $candidate = New-AijConsistentSnapshot -Manifest $manifest

    Assert-AijRejection `
        -Label 'INVALID_CONFIG_IDENTITY_REJECTED' `
        -Operation { New-AijStateDraft -Snapshot $candidate } `
        -Expected 'Invalid configuration identity.'

    # Target must remain unverified at this stage

    $manifest = Copy-AijManifest -Snapshot $plan
    $manifest.ProposedTarget.IdentityVerified = $true
    $candidate = New-AijConsistentSnapshot -Manifest $manifest

    Assert-AijRejection `
        -Label 'PREVERIFIED_TARGET_REJECTED' `
        -Operation { New-AijStateDraft -Snapshot $candidate } `
        -Expected 'Unexpected target verification state.'

    # Duplicate source identity

    $manifest = Copy-AijManifest -Snapshot $plan

    $duplicateSource = [pscustomobject][ordered]@{
        Name = $manifest.SourceFiles[0].Name
        Sha256 = $manifest.SourceFiles[0].Sha256
    }

    $manifest.SourceFiles = @($manifest.SourceFiles) + @($duplicateSource)
    $candidate = New-AijConsistentSnapshot -Manifest $manifest

    Assert-AijRejection `
        -Label 'DUPLICATE_SOURCE_IDENTITY_REJECTED' `
        -Operation { New-AijStateDraft -Snapshot $candidate } `
        -Expected "Duplicate source-file identity: $($duplicateSource.Name)."

    # Invalid source hash

    $manifest = Copy-AijManifest -Snapshot $plan
    $manifest.SourceFiles[0].Sha256 = 'BAD'
    $candidate = New-AijConsistentSnapshot -Manifest $manifest

    Assert-AijRejection `
        -Label 'INVALID_SOURCE_IDENTITY_REJECTED' `
        -Operation { New-AijStateDraft -Snapshot $candidate } `
        -Expected 'Invalid source-file identity.'

    # Duplicate phase candidate

    $manifest = Copy-AijManifest -Snapshot $plan

    $phase = $manifest.PhaseCandidates[0]

    $duplicatePhase = [pscustomobject][ordered]@{
        Id = $phase.Id
        Name = $phase.Name
        DeclaredMode = $phase.DeclaredMode
        SecurityCritical = $phase.SecurityCritical
        EntryPointSha256 = $phase.EntryPointSha256
        RequirementsSha256 = $phase.RequirementsSha256
        Dependencies = @($phase.Dependencies)
        ExecutionAuthorized = $false
    }

    $manifest.PhaseCandidates = @($manifest.PhaseCandidates) + @($duplicatePhase)
    $candidate = New-AijConsistentSnapshot -Manifest $manifest

    Assert-AijRejection `
        -Label 'DUPLICATE_PHASE_CANDIDATE_REJECTED' `
        -Operation { New-AijStateDraft -Snapshot $candidate } `
        -Expected "Duplicate phase candidate: $($duplicatePhase.Id)."

    # Per-phase authorization

    $manifest = Copy-AijManifest -Snapshot $plan
    $phaseId = $manifest.PhaseCandidates[0].Id
    $manifest.PhaseCandidates[0].ExecutionAuthorized = $true
    $candidate = New-AijConsistentSnapshot -Manifest $manifest

    Assert-AijRejection `
        -Label 'PHASE_AUTHORIZATION_REJECTED' `
        -Operation { New-AijStateDraft -Snapshot $candidate } `
        -Expected "Unexpected phase authorization: $phaseId."

    # Invalid phase identity

    $manifest = Copy-AijManifest -Snapshot $plan
    $phaseId = $manifest.PhaseCandidates[0].Id
    $manifest.PhaseCandidates[0].EntryPointSha256 = 'BAD'
    $candidate = New-AijConsistentSnapshot -Manifest $manifest

    Assert-AijRejection `
        -Label 'INVALID_PHASE_IDENTITY_REJECTED' `
        -Operation { New-AijStateDraft -Snapshot $candidate } `
        -Expected "Invalid phase identity: $phaseId."

    # Empty source inventory

    $manifest = Copy-AijManifest -Snapshot $plan
    $manifest.SourceFiles = @()
    $candidate = New-AijConsistentSnapshot -Manifest $manifest

    Assert-AijRejection `
        -Label 'EMPTY_SOURCE_INVENTORY_REJECTED' `
        -Operation { New-AijStateDraft -Snapshot $candidate } `
        -Expected 'PLAN snapshot contains no source identities.'

    # Empty phase inventory

    $manifest = Copy-AijManifest -Snapshot $plan
    $manifest.PhaseCandidates = @()
    $candidate = New-AijConsistentSnapshot -Manifest $manifest

    Assert-AijRejection `
        -Label 'EMPTY_PHASE_INVENTORY_REJECTED' `
        -Operation { New-AijStateDraft -Snapshot $candidate } `
        -Expected 'PLAN snapshot contains no phase candidates.'

    # Assertion integrity

    Assert-AijGuard `
        -Label 'UNEXPECTED_ACCEPTANCE' `
        -Probe {
            Assert-AijRejection `
                -Label 'CONTROL_ACCEPT' `
                -Operation { 'accepted' } `
                -Expected 'EXPECTED'
        } `
        -Expected 'ASSERTION_FAILURE: CONTROL_ACCEPT: accepted or not executed.'

    Assert-AijGuard `
        -Label 'UNRELATED_EXCEPTION' `
        -Probe {
            Assert-AijRejection `
                -Label 'CONTROL_WRONG' `
                -Operation { throw 'UNRELATED_SENTINEL' } `
                -Expected 'EXPECTED'
        } `
        -Expected 'ASSERTION_FAILURE: CONTROL_WRONG: expected [EXPECTED], received [UNRELATED_SENTINEL].'

    Assert-AijGuard `
        -Label 'SKIPPED_OPERATION' `
        -Probe {
            Assert-AijRejection `
                -Label 'CONTROL_SKIP' `
                -Operation { } `
                -Expected 'EXPECTED'
        } `
        -Expected 'ASSERTION_FAILURE: CONTROL_SKIP: accepted or not executed.'

    if ($script:positive -ne 1 -or
        $script:negative -ne 16 -or
        $script:guards -ne 3) {
        throw (
            'TEST_COUNT_FAILURE: expected positive=1 negative=16 guard=3; ' +
            "actual positive=$script:positive negative=$script:negative guard=$script:guards."
        )
    }

    Write-Output 'STATE_REGRESSIONS_OK positive=1 negative=16 guard=3'
    exit 0
}
catch {
    [Console]::Error.WriteLine($_.ToString())
    exit 1
}