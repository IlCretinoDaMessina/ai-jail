
# Phase 000 - Dependency denial matrix
# Windows PowerShell 5.1

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

. (Join-Path $PSScriptRoot '000-dependencies.ps1')

$utf8 = New-Object System.Text.UTF8Encoding($false, $true)
$owned = New-Object 'System.Collections.Generic.List[string]'
$passed = 0

$cases = @(
    @('050', 'dependencies', 'accept_offline_policy_review_as_runtime_proof'),
    @('050', 'installation_gate', 'offline_review_satisfies_gate'),
    @('060', 'dependencies', 'accept_phase_050_offline_review_as_runtime_proof'),
    @('070', 'dependencies', 'accept_offline_reviews_as_runtime_proof'),
    @('080', 'dependencies', 'accept_offline_reviews_as_runtime_proof'),
    @('090', 'dependencies', 'accept_offline_reviews_as_runtime_proof'),
    @('091', 'dependencies', 'accept_offline_reviews_as_runtime_proof'),
    @('092', 'dependencies', 'accept_offline_reviews_as_runtime_proof')
)

function New-DenialFixture {
    $folder = Join-Path ([IO.Path]::GetTempPath()) (
        'AIJ-DENIAL-' + [guid]::NewGuid().ToString('N')
    )

    if ([IO.Directory]::Exists($folder)) {
        throw 'TEST_SETUP_FAILURE: Fixture directory already exists.'
    }

    [void][IO.Directory]::CreateDirectory($folder)
    $owned.Add($folder)

    Get-ChildItem -LiteralPath $PSScriptRoot -File |
        Where-Object {
            $_.Name -cmatch '^[0-9]{3}-.+\.bat$' -or
            $_.Name -cmatch '^[0-9]{3}-requirements\.json$'
        } |
        ForEach-Object {
            [IO.File]::Copy(
                $_.FullName,
                (Join-Path $folder $_.Name)
            )
        }

    $inventory = @(Get-AijPhaseInventory -Root $folder)

    if ($inventory.Count -ne 11) {
        throw 'TEST_SETUP_FAILURE: Invalid positive control.'
    }

    return $folder
}

function Assert-SpecificRejection {
    param(
        [string]$Folder,
        [string]$Expected,
        [string]$Label
    )

    $actual = $null

    try {
        $null = Get-AijPhaseInventory -Root $Folder
    }
    catch {
        $actual = $_.Exception.Message
    }

    if ($null -eq $actual) {
        throw "ASSERTION_FAILURE: $Label was accepted."
    }

    if ($actual -cne $Expected) {
        throw "ASSERTION_FAILURE: $Label expected [$Expected], received [$actual]."
    }

    Write-Output "PASS: $Label"
}

try {
    foreach ($case in $cases) {
        $id = $case[0]
        $section = $case[1]
        $field = $case[2]

        $folder = New-DenialFixture
        $path = Join-Path $folder "$id-requirements.json"

        $doc = [IO.File]::ReadAllText($path, $utf8) |
            ConvertFrom-Json -ErrorAction Stop

        $property = $doc.$section.PSObject.Properties[$field]

        if ($null -eq $property -or
            $property.Value -isnot [bool] -or
            $property.Value -ne $false) {
            throw "TEST_SETUP_FAILURE: Invalid original denial: $id.$section.$field."
        }

        $property.Value = $true

        [IO.File]::WriteAllText(
            $path,
            (ConvertTo-Json -InputObject $doc -Depth 60),
            $utf8
        )

        $expected = "Unsafe dependency policy: $id-requirements.json.$section.$field."
        $label = "DENIAL_${id}_${field}"

        Assert-SpecificRejection `
            -Folder $folder `
            -Expected $expected `
            -Label $label

        $passed++
    }

    # Missing mandatory denial declaration

    $folder = New-DenialFixture
    $path = Join-Path $folder '050-requirements.json'

    $doc = [IO.File]::ReadAllText($path, $utf8) |
        ConvertFrom-Json -ErrorAction Stop

    $doc.installation_gate.PSObject.Properties.Remove(
        'offline_review_satisfies_gate'
    )

    [IO.File]::WriteAllText(
        $path,
        (ConvertTo-Json -InputObject $doc -Depth 60),
        $utf8
    )

    Assert-SpecificRejection `
        -Folder $folder `
        -Expected 'Unsafe dependency policy: 050-requirements.json.installation_gate.offline_review_satisfies_gate.' `
        -Label 'MISSING_MANDATORY_DENIAL'

    $passed++

    if ($passed -ne 9) {
        throw "TEST_COUNT_FAILURE: Expected 9 checks, received $passed."
    }

    Write-Output "DEPENDENCY_DENIAL_MATRIX_OK count=$passed"
}
finally {
    foreach ($folder in $owned) {
        if ([IO.Directory]::Exists($folder)) {
            [IO.Directory]::Delete($folder, $true)
        }
    }
}
