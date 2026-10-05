# Phase 000 - Mode entry point
# Windows PowerShell 5.1

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

try {
    $tokens = @($args)

    $modeMap = @{
        '/review'  = 'REVIEW'
        '--review' = 'REVIEW'
        '/plan'    = 'PLAN'
        '--plan'   = 'PLAN'
        '/apply'   = 'APPLY'
        '--apply'  = 'APPLY'
        '/verify'  = 'VERIFY'
        '--verify' = 'VERIFY'
    }

    $mode = 'REVIEW'
    $explicitMode = $false
    $resumeFrom = $null
    $skips = New-Object 'System.Collections.Generic.List[string]'

    $mockInvocation = $false
    $mockWorkspace = $null
    $mockApprovalPath = $null

    # Mock entry

    if ($tokens.Count -gt 0) {
        $firstOption = (
            [string]$tokens[0]
        ).ToLowerInvariant()

        if ($firstOption -in @(
            '/mock-execute',
            '--mock-execute',
            '/mock-resume',
            '--mock-resume'
        )) {
            if ($tokens.Count -ne 3) {
                throw 'Mock execution requires workspace and approval path.'
            }

            $mockWorkspace = [string]$tokens[1]
            $mockApprovalPath = [string]$tokens[2]

            if ([string]::IsNullOrWhiteSpace($mockWorkspace) -or
                [string]::IsNullOrWhiteSpace($mockApprovalPath)) {

                throw 'Mock execution requires workspace and approval path.'
            }

            if ($firstOption -in @(
                '/mock-resume',
                '--mock-resume'
            )) {
                $mode = 'MOCK_RESUME'
            }
            else {
                $mode = 'MOCK_EXECUTE'
            }

            $explicitMode = $true
            $mockInvocation = $true
        }
    }

    # Arguments

    if (-not $mockInvocation) {
        for ($i = 0; $i -lt $tokens.Count; $i++) {
            $token = [string]$tokens[$i]
            $option = $token.ToLowerInvariant()

            if ($modeMap.ContainsKey($option)) {
                if ($explicitMode) {
                    throw 'Conflicting or repeated execution mode.'
                }

                $mode = $modeMap[$option]
                $explicitMode = $true
                continue
            }

            if ($option -eq '/from' -or
                $option -eq '--from') {

                if ($null -ne $resumeFrom) {
                    throw 'Duplicate resume option.'
                }

                if (($i + 1) -ge $tokens.Count) {
                    throw 'Missing value for /from.'
                }

                $i++
                $value = [string]$tokens[$i]

                if ($value -cnotmatch '^[0-9]{3}$' -or
                    $value -in @('000', '999')) {

                    throw 'Invalid /from phase identifier.'
                }

                $resumeFrom = $value
                continue
            }

            if ($option -eq '/skip' -or
                $option -eq '--skip') {

                if (($i + 1) -ge $tokens.Count) {
                    throw 'Missing value for /skip.'
                }

                $i++
                $value = [string]$tokens[$i]

                if ($value -cnotmatch '^[0-9]{3}$' -or
                    $value -in @('000', '999')) {

                    throw 'Invalid /skip phase identifier.'
                }

                if ($skips.Contains($value)) {
                    throw 'Duplicate skipped phase.'
                }

                $skips.Add($value)
                continue
            }

            throw "Unsupported argument: $token"
        }
    }

    # Resume and skip

    if ($null -ne $resumeFrom -or
        $skips.Count -gt 0) {

        throw 'Resume and skip are blocked until dependency validation is implemented.'
    }

    if ($mode -cnotin @(
        'REVIEW',
        'PLAN',
        'MOCK_EXECUTE',
        'MOCK_RESUME'
    )) {
        throw "Mode $mode is not implemented; no operation executed."
    }

    # Inventory

    $dependencyPath =
        Join-Path $PSScriptRoot '000-dependencies.ps1'

    if (-not (
        Test-Path `
            -LiteralPath $dependencyPath `
            -PathType Leaf
    )) {
        throw 'Required file missing: 000-dependencies.ps1'
    }

    $attributes =
        [IO.File]::GetAttributes($dependencyPath)

    if (($attributes -band
        [IO.FileAttributes]::ReparsePoint) -ne 0) {

        throw 'Dependency library reparse point rejected.'
    }

    . $dependencyPath

    $inventory = @(
        Get-AijPhaseInventory -Root $PSScriptRoot
    )

    foreach ($phase in $inventory) {
        if ($phase.AutomaticExecutionAuthorized -ne $false) {
            throw "Unexpected execution authorization: $($phase.Id)."
        }
    }

    Write-Output 'PHASE INVENTORY: VALIDATED'
    Write-Output "Inventory count: $($inventory.Count)"

    # Reviewer

    $reviewerPath =
        Join-Path $PSScriptRoot '000-review.ps1'

    if (-not (
        Test-Path `
            -LiteralPath $reviewerPath `
            -PathType Leaf
    )) {
        throw 'Required file missing: 000-review.ps1'
    }

    $powerShellPath =
        Join-Path $PSHOME 'powershell.exe'

    if (-not (
        Test-Path `
            -LiteralPath $powerShellPath `
            -PathType Leaf
    )) {
        throw 'Windows PowerShell executable unavailable.'
    }

    & $powerShellPath `
        -NoProfile `
        -NonInteractive `
        -ExecutionPolicy Bypass `
        -File $reviewerPath

    $reviewExitCode = $LASTEXITCODE

    if ($reviewExitCode -eq 1) {
        throw 'Offline reviewer failed.'
    }

    if ($reviewExitCode -ne 0) {
        throw "Unexpected REVIEW exit code: $reviewExitCode."
    }

    if ($mode -ceq 'REVIEW') {
        Write-Output 'RESULT: REVIEW_PASS'
        exit 0
    }

    # Mock orchestration

    if ($mode -in @(
        'MOCK_EXECUTE',
        'MOCK_RESUME'
    )) {
        $orchestrationPath =
            Join-Path $PSScriptRoot '000-orchestration.ps1'

        if (-not (
            Test-Path `
                -LiteralPath $orchestrationPath `
                -PathType Leaf
        )) {
            throw 'Required file missing: 000-orchestration.ps1'
        }

        $attributes =
            [IO.File]::GetAttributes($orchestrationPath)

        if (($attributes -band
            [IO.FileAttributes]::ReparsePoint) -ne 0) {

            throw 'Orchestration library reparse point rejected.'
        }

        . $orchestrationPath

        if (-not (
            Get-Command Invoke-AijD3NextPhase `
                -CommandType Function `
                -ErrorAction SilentlyContinue
        )) {
            throw 'Required orchestration function missing.'
        }

        if ($mode -ceq 'MOCK_RESUME') {
            $result =
                Invoke-AijD3NextPhase `
                    -Workspace $mockWorkspace `
                    -ApprovalPath $mockApprovalPath `
                    -Resume
        }
        else {
            $result =
                Invoke-AijD3NextPhase `
                    -Workspace $mockWorkspace `
                    -ApprovalPath $mockApprovalPath
        }

        if ($null -eq $result -or
            $result.Phase -isnot [string] -or
            $result.Phase -cnotmatch '^[0-9]{3}$' -or
            $result.Phase -in @('000', '999') -or
            ($result.ExitCode -isnot [int] -and
                $result.ExitCode -isnot [long]) -or
            $result.ExitCode -notin @(0, 1, 3010)) {

            throw 'Invalid mock orchestration result.'
        }

        Write-Output "MOCK PHASE: $($result.Phase)"
        Write-Output "RESULT: MOCK_PHASE_EXIT_$($result.ExitCode)"

        exit ([int]$result.ExitCode)
    }

    # PLAN snapshot

    $manifestPath =
        Join-Path $PSScriptRoot '000-manifest.ps1'

    if (-not (
        Test-Path `
            -LiteralPath $manifestPath `
            -PathType Leaf
    )) {
        throw 'Required file missing: 000-manifest.ps1'
    }

    $attributes =
        [IO.File]::GetAttributes($manifestPath)

    if (($attributes -band
        [IO.FileAttributes]::ReparsePoint) -ne 0) {

        throw 'Manifest library reparse point rejected.'
    }

    . $manifestPath

    $snapshot =
        New-AijPlanSnapshot -Root $PSScriptRoot

    if ($null -eq $snapshot -or
        $null -eq $snapshot.Manifest) {

        throw 'PLAN snapshot generation failed.'
    }

    $manifest = $snapshot.Manifest

    if ($manifest.Kind -cne 'PHASE_000_PLAN_SNAPSHOT' -or
        $manifest.State -cne 'DRAFT_BLOCKED' -or
        $manifest.ExecutionAuthorized -ne $false -or
        $manifest.ApprovalRecorded -ne $false -or
        $manifest.ReadyForApproval -ne $false -or
        $null -ne $manifest.ArtifactLock -or
        @($manifest.SelectedActions).Count -ne 0) {

        throw 'Unexpected PLAN authorization state.'
    }

    foreach ($line in @(
        Format-AijPlanSnapshot -Snapshot $snapshot
    )) {
        Write-Output $line
    }

    Write-Output 'PLAN_JSON_BEGIN'
    Write-Output $snapshot.Json
    Write-Output 'PLAN_JSON_END'

    # State draft

    $statePath =
        Join-Path $PSScriptRoot '000-state.ps1'

    if (-not (
        Test-Path `
            -LiteralPath $statePath `
            -PathType Leaf
    )) {
        throw 'Required file missing: 000-state.ps1'
    }

    $attributes =
        [IO.File]::GetAttributes($statePath)

    if (($attributes -band
        [IO.FileAttributes]::ReparsePoint) -ne 0) {

        throw 'State library reparse point rejected.'
    }

    . $statePath

    $stateDraft =
        New-AijStateDraft -Snapshot $snapshot

    if ($null -eq $stateDraft -or
        $null -eq $stateDraft.Record -or
        $stateDraft.Record.Kind -cne 'PHASE_000_STATE' -or
        $stateDraft.Record.State -cne 'PLAN_BLOCKED' -or
        $stateDraft.Record.ExecutionAuthorized -ne $false -or
        $stateDraft.Record.Approval.Status -cne
            'NOT_RECORDED' -or
        $stateDraft.Record.Resume.Status -cne 'NONE' -or
        $stateDraft.Record.Plan.SnapshotSha256 -cne
            $snapshot.Sha256) {

        throw 'Unexpected state-draft authorization state.'
    }

    foreach ($line in @(
        Format-AijStateDraft -StateDraft $stateDraft
    )) {
        Write-Output $line
    }

    Write-Output 'STATE_JSON_BEGIN'
    Write-Output $stateDraft.Json
    Write-Output 'STATE_JSON_END'

    Write-Output 'RESULT: PLAN_DRAFT_BLOCKED'
    exit 1
}
catch {
    [Console]::Error.WriteLine(
        "PHASE 000 ENGINE FAILED: $($_.Exception.Message)"
    )

    exit 1
}