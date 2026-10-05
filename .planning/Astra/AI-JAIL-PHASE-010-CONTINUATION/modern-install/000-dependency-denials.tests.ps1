
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

. (Join-Path $PSScriptRoot '000-dependencies.ps1')

$temp = Join-Path ([IO.Path]::GetTempPath()) (
    'AIJ-DEP-DENIAL-' + [guid]::NewGuid().ToString('N')
)

if ([IO.Directory]::Exists($temp)) {
    throw 'TEST_SETUP_FAILURE: Fixture already exists.'
}

[void][IO.Directory]::CreateDirectory($temp)

try {
    $files = @(
        Get-ChildItem -LiteralPath $PSScriptRoot -File |
            Where-Object {
                $_.Name -cmatch '^[0-9]{3}-.+\.bat$' -or
                $_.Name -cmatch '^[0-9]{3}-requirements\.json$'
            }
    )

    foreach ($file in $files) {
        [IO.File]::Copy(
            $file.FullName,
            (Join-Path $temp $file.Name)
        )
    }

    $baseline = @(Get-AijPhaseInventory -Root $temp)

    if ($baseline.Count -ne 11) {
        throw 'TEST_SETUP_FAILURE: Known-valid inventory failed.'
    }

    Write-Output 'PASS: VALID_BASELINE'

    $path = Join-Path $temp '050-requirements.json'

    $doc = Get-Content -LiteralPath $path -Raw |
        ConvertFrom-Json -ErrorAction Stop

    if ($doc.dependencies.accept_offline_policy_review_as_runtime_proof -cne $false) {
        throw 'TEST_SETUP_FAILURE: Original denial policy is not false.'
    }

    $doc.dependencies.accept_offline_policy_review_as_runtime_proof = $true

    [IO.File]::WriteAllText(
        $path,
        (ConvertTo-Json -InputObject $doc -Depth 60),
        (New-Object System.Text.UTF8Encoding($false))
    )

    $expected = 'Unsafe dependency policy: 050-requirements.json.dependencies.accept_offline_policy_review_as_runtime_proof.'

    $actual = $null

    try {
        $null = Get-AijPhaseInventory -Root $temp
    }
    catch {
        $actual = $_.Exception.Message
    }

    if ($null -eq $actual) {
        throw 'DEFECT_CONFIRMED: Unsafe offline-review bypass declaration was accepted.'
    }

    if ($actual -cne $expected) {
        throw "UNEXPECTED_REJECTION: $actual"
    }

    Write-Output 'PASS: OFFLINE_REVIEW_CANNOT_SATISFY_RUNTIME_PROOF'
}
finally {
    if ([IO.Directory]::Exists($temp)) {
        foreach ($file in @(Get-ChildItem -LiteralPath $temp -Force -File)) {
            [IO.File]::Delete($file.FullName)
        }

        [IO.Directory]::Delete($temp)
    }
}
