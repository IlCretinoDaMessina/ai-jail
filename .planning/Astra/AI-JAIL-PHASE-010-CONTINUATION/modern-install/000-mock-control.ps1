# Optional manual entry point for the D2 mock-only authorization boundary.
# Production /review, /plan, /apply, /verify remain in 000-engine.ps1.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][ValidateSet('Create','Approve','Execute','Resume')][string]$Mode,
    [string]$ParentDirectory,
    [string]$Workspace,
    [string]$ApprovalPath,
    [int[]]$ExitCodes=@(0)
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
try {
    . (Join-Path $PSScriptRoot '000-authorization.ps1')
    if ($Mode -ceq 'Create') {
        if ([string]::IsNullOrWhiteSpace($ParentDirectory)) { throw 'D2_PARENT_REQUIRED' }
        $Workspace = New-AijMockWorkspace -ParentDirectory $ParentDirectory
        $plan = New-AijMockPlan -Workspace $Workspace -ExitCodes $ExitCodes
        Save-AijD2Document (Join-Path $Workspace 'plan.json') $plan
        $state = Initialize-AijMockState -Plan $plan -Workspace $Workspace
        Write-Output ('MOCK_WORKSPACE=' + $Workspace)
        Write-Output ('MOCK_PLAN_SHA256=' + $plan.Sha256)
        Write-Output ('STATE_SHA256=' + $state.Sha256)
        Write-Output 'Created blocked mock state. No approval or phase execution occurred.'
        exit 0
    }
    if ([string]::IsNullOrWhiteSpace($Workspace)) { throw 'D2_WORKSPACE_REQUIRED' }
    $plan = Read-AijD2Document (Join-Path $Workspace 'plan.json')
    Assert-AijMockPlan -Plan $plan -Workspace $Workspace
    if ($Mode -ceq 'Approve') {
        $state = Read-AijStateFile -Directory (Join-Path $Workspace 'state')
        Assert-AijMockStateBinding -Plan $plan -State $state
        Write-Output 'MOCK ONLY: writes one result file inside the displayed temporary workspace.'
        Write-Output ('Target: ' + $plan.Record.Target.Path)
        Write-Output ('Phase: ' + $plan.Record.Phase)
        Write-Output ('Bound result sequence: ' + ($plan.Record.ExitCodes -join ', '))
        Write-Output ('Same-phase resume: ' + ($state.Record.State -ceq 'REBOOT_PENDING'))
        Write-Output ('PLAN: ' + $plan.Sha256)
        Write-Output ('Config: ' + $plan.Record.ConfigurationSha256)
        Write-Output ('Sources: ' + $plan.Record.SourceLockSha256)
        Write-Output ('Artifacts (none downloaded): ' + $plan.Record.ArtifactLockSha256)
        Write-Output ('Target identity: ' + $plan.Record.TargetSha256)
        Write-Output ('State: ' + $state.Sha256)
        $required = Get-AijMockApprovalText -Plan $plan -State $state
        Write-Output ('Type exactly: ' + $required)
        $answer = Read-Host 'Approval'
        $receipt = New-AijMockApproval -Plan $plan -Workspace $Workspace -ConfirmationText $answer
        Write-Output ('APPROVAL_PATH=' + $receipt.Path)
        exit 0
    }
    if ([string]::IsNullOrWhiteSpace($ApprovalPath)) { throw 'D2_APPROVAL_REQUIRED' }
    $result = Invoke-AijApprovedMockPhase -Plan $plan -Workspace $Workspace -ApprovalPath $ApprovalPath -Resume:($Mode -ceq 'Resume')
    Write-Output ('STATE=' + $result.State.Record.State)
    Write-Output 'RUNTIME_VERIFIED=False'
    exit $result.ExitCode
} catch {
    # Stable codes only. Unknown .NET/parser errors may contain configuration
    # values, source text or paths; retain those only in the test harness.
    $message = $_.Exception.Message
    if ($message -cnotmatch '^D2_[A-Z0-9_]+$') { $message = 'D2_OPERATION_FAILED' }
    [Console]::Error.WriteLine($message)
    exit 1
}
