# Explicit, separately invoked read-only consumer of bound Phase 010 evidence.
# No automatic elevation. No installation, update, distro execution, or APPLY.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$SessionDirectory,
    [Parameter(Mandatory=$true)][string]$VerificationPath,
    [switch]$EvidenceOnly
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
try {
    . (Join-Path $PSScriptRoot '010-boundary.ps1')
    $admission = Assert-Aij010PreflightCompleteEvidence -SessionDirectory $SessionDirectory -VerificationPath $VerificationPath
    Write-Output ('PREFLIGHT_DEPENDENCY=' + $admission.DependencyResult)
    foreach ($warning in $admission.WarningReasons) { Write-Output ('WARNING=' + $warning) }
    Write-Output 'INSTALLATION_AUTHORIZED=False'
    if ($EvidenceOnly) { Write-Output 'PHASE_020_READ_ONLY_ADMISSION_OK'; exit 0 }
    $expected = @{
        '020-wsl-check.ps1' = '808ECC3DE90753FAAE384A388D857A64895CE8B25AD420A17B529EF4718A9695'
        '020-requirements.json' = '57C2B22874315E42A77171ED7F9E6C61D6B24DAD57C440681E96746662F8106E'
    }
    foreach ($name in $expected.Keys) {
        $path = Assert-Aij010OrdinaryBoundFile -Path (Join-Path $PSScriptRoot $name)
        if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $expected[$name]) {
            throw 'PHASE_020_REVIEWED_SOURCE_CHANGED'
        }
    }
    # The user explicitly invokes this entry point. Phase 010 approval itself
    # grants no authority to execute WSL; this separate invocation does.
    $exe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    & $exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot '020-wsl-check.ps1')
    exit $LASTEXITCODE
} catch {
    [Console]::Error.WriteLine('PHASE_020_ADMISSION_FAILED: ' + $_.Exception.Message)
    exit 1
}
