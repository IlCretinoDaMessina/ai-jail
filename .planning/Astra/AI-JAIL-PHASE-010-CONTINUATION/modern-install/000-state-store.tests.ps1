# Phase 000 - State-store regressions
# Windows PowerShell 5.1

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

. (Join-Path $PSScriptRoot '000-manifest.ps1')
. (Join-Path $PSScriptRoot '000-state.ps1')
. (Join-Path $PSScriptRoot '000-state-store.ps1')

$script:root = $null
$script:negative = 0
$script:guards = 0
$script:utf8 = New-Object System.Text.UTF8Encoding($false, $true)

function New-CaseDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $path = Join-Path $script:root $Name

    if ([IO.Directory]::Exists($path)) {
        throw "TEST_SETUP_FAILURE: Duplicate case directory: $Name."
    }

    [void][IO.Directory]::CreateDirectory($path)

    return $path
}

function Write-TextNoBom {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    [IO.File]::WriteAllText(
        $Path,
        $Text,
        $script:utf8
    )
}

function Read-Envelope {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return ConvertFrom-Json `
        -InputObject ([IO.File]::ReadAllText(
            $Path,
            $script:utf8
        )) `
        -ErrorAction Stop
}

function Write-Envelope {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        $Envelope
    )

    $text = ConvertTo-Json `
        -InputObject $Envelope `
        -Depth 20 `
        -Compress

    Write-TextNoBom -Path $Path -Text $text
}

function New-ValidStateFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Directory,

        [Parameter(Mandatory = $true)]
        $State
    )

    return Write-AijStateDraftFile `
        -StateDraft $State `
        -Directory $Directory
}

function Assert-Rejection {
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

function Assert-Guard {
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

function Assert-NoTemporaryResidue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Directory
    )

    $files = @(
        Get-ChildItem -LiteralPath $Directory -Force -File |
            Where-Object {
                $_.Name -like '.phase-000-state.*.tmp'
            }
    )

    if ($files.Count -ne 0) {
        throw 'ASSERTION_FAILURE: Temporary state residue detected.'
    }
}

try {
    $script:root = Join-Path ([IO.Path]::GetTempPath()) (
        'AIJ-STATE-REGRESS-' + [guid]::NewGuid().ToString('N')
    )

    [void][IO.Directory]::CreateDirectory($script:root)

    $plan = New-AijPlanSnapshot -Root $PSScriptRoot
    $state = New-AijStateDraft -Snapshot $plan

    # Positive control

    $folder = New-CaseDirectory -Name 'baseline'
    $write = New-ValidStateFile -Directory $folder -State $state

    $read = Read-AijStateDraftFile `
        -Path $write.Path `
        -ExpectedStateSha256 $state.Sha256

    if ($read.Sha256 -cne $state.Sha256 -or
        $read.Json -cne $state.Json -or
        $read.Record.State -cne 'PLAN_BLOCKED' -or
        $read.Record.ExecutionAuthorized -ne $false) {
        throw 'TEST_SETUP_FAILURE: Valid persisted state failed.'
    }

    Write-Output 'PASS: VALID_PERSISTED_STATE_BASELINE'

    # Invalid expected hash syntax

    Assert-Rejection `
        -Label 'INVALID_EXPECTED_HASH_REJECTED' `
        -Operation {
            Read-AijStateDraftFile `
                -Path $write.Path `
                -ExpectedStateSha256 'BAD'
        } `
        -Expected 'Invalid expected state fingerprint.'

    # Missing file

    $folder = New-CaseDirectory -Name 'missing'

    Assert-Rejection `
        -Label 'MISSING_STATE_FILE_REJECTED' `
        -Operation {
            Read-AijStateDraftFile `
                -Path (Join-Path $folder 'phase-000-state.json') `
                -ExpectedStateSha256 $state.Sha256
        } `
        -Expected 'State file missing.'

    # Empty file

    $folder = New-CaseDirectory -Name 'empty'
    $path = Join-Path $folder 'phase-000-state.json'
    [IO.File]::WriteAllBytes($path, [byte[]]@())

    Assert-Rejection `
        -Label 'EMPTY_STATE_FILE_REJECTED' `
        -Operation {
            Read-AijStateDraftFile `
                -Path $path `
                -ExpectedStateSha256 $state.Sha256
        } `
        -Expected 'State file is empty.'

    # UTF-8 BOM

    $folder = New-CaseDirectory -Name 'bom'
    $valid = New-ValidStateFile -Directory $folder -State $state
    $originalBytes = [IO.File]::ReadAllBytes($valid.Path)

    $bomBytes = [byte[]](
        @(
            [byte]0xEF,
            [byte]0xBB,
            [byte]0xBF
        ) + @($originalBytes)
    )

    [IO.File]::WriteAllBytes($valid.Path, $bomBytes)

    Assert-Rejection `
        -Label 'UTF8_BOM_REJECTED' `
        -Operation {
            Read-AijStateDraftFile `
                -Path $valid.Path `
                -ExpectedStateSha256 $state.Sha256
        } `
        -Expected 'State file UTF-8 BOM rejected.'

    # Malformed UTF-8

    $folder = New-CaseDirectory -Name 'utf8'
    $path = Join-Path $folder 'phase-000-state.json'

    [IO.File]::WriteAllBytes(
        $path,
        [byte[]]@(
            [byte]0xC3,
            [byte]0x28
        )
    )

    Assert-Rejection `
        -Label 'MALFORMED_UTF8_REJECTED' `
        -Operation {
            Read-AijStateDraftFile `
                -Path $path `
                -ExpectedStateSha256 $state.Sha256
        } `
        -Expected 'State file is not valid UTF-8.'

    # Malformed envelope JSON

    $folder = New-CaseDirectory -Name 'outer-json'
    $path = Join-Path $folder 'phase-000-state.json'

    Write-TextNoBom `
        -Path $path `
        -Text '{"Schema":'

    Assert-Rejection `
        -Label 'MALFORMED_ENVELOPE_JSON_REJECTED' `
        -Operation {
            Read-AijStateDraftFile `
                -Path $path `
                -ExpectedStateSha256 $state.Sha256
        } `
        -Expected 'State file JSON is invalid.'

    # Unexpected envelope field

    $folder = New-CaseDirectory -Name 'extra-field'
    $valid = New-ValidStateFile -Directory $folder -State $state
    $envelope = Read-Envelope -Path $valid.Path

    $envelope | Add-Member `
        -NotePropertyName 'Unexpected' `
        -NotePropertyValue $false

    Write-Envelope -Path $valid.Path -Envelope $envelope

    Assert-Rejection `
        -Label 'EXTRA_ENVELOPE_FIELD_REJECTED' `
        -Operation {
            Read-AijStateDraftFile `
                -Path $valid.Path `
                -ExpectedStateSha256 $state.Sha256
        } `
        -Expected 'Invalid state file envelope.'

    # Unsupported envelope schema

    $folder = New-CaseDirectory -Name 'schema'
    $valid = New-ValidStateFile -Directory $folder -State $state
    $envelope = Read-Envelope -Path $valid.Path
    $envelope.Schema = 2

    Write-Envelope -Path $valid.Path -Envelope $envelope

    Assert-Rejection `
        -Label 'UNSUPPORTED_ENVELOPE_SCHEMA_REJECTED' `
        -Operation {
            Read-AijStateDraftFile `
                -Path $valid.Path `
                -ExpectedStateSha256 $state.Sha256
        } `
        -Expected 'Invalid state file envelope.'

    # Wrong expected binding

    $folder = New-CaseDirectory -Name 'binding'
    $valid = New-ValidStateFile -Directory $folder -State $state
    $wrongHash = ('B' * 64)

    if ($wrongHash -ceq $state.Sha256) {
        $wrongHash = ('C' * 64)
    }

    Assert-Rejection `
        -Label 'WRONG_EXPECTED_BINDING_REJECTED' `
        -Operation {
            Read-AijStateDraftFile `
                -Path $valid.Path `
                -ExpectedStateSha256 $wrongHash
        } `
        -Expected 'State file hash binding mismatch.'

    # Stale state fingerprint

    $folder = New-CaseDirectory -Name 'stale-state-hash'
    $valid = New-ValidStateFile -Directory $folder -State $state
    $envelope = Read-Envelope -Path $valid.Path

    $inner = ConvertFrom-Json `
        -InputObject $envelope.StateJson `
        -ErrorAction Stop

    $inner.State = 'TAMPERED'

    $envelope.StateJson = ConvertTo-Json `
        -InputObject $inner `
        -Depth 20 `
        -Compress

    Write-Envelope -Path $valid.Path -Envelope $envelope

    Assert-Rejection `
        -Label 'STALE_STATE_FINGERPRINT_REJECTED' `
        -Operation {
            Read-AijStateDraftFile `
                -Path $valid.Path `
                -ExpectedStateSha256 $state.Sha256
        } `
        -Expected 'Persisted state fingerprint mismatch.'

    # Invalid inner JSON with valid hash

    $folder = New-CaseDirectory -Name 'inner-json'
    $valid = New-ValidStateFile -Directory $folder -State $state
    $envelope = Read-Envelope -Path $valid.Path

    $envelope.StateJson = '{'
    $envelope.StateSha256 = Get-AijTextSha256 `
        -Text $envelope.StateJson

    Write-Envelope -Path $valid.Path -Envelope $envelope

    Assert-Rejection `
        -Label 'MALFORMED_INNER_STATE_JSON_REJECTED' `
        -Operation {
            Read-AijStateDraftFile `
                -Path $valid.Path `
                -ExpectedStateSha256 $envelope.StateSha256
        } `
        -Expected 'Persisted state JSON is invalid.'

    # Noncanonical inner JSON

    $folder = New-CaseDirectory -Name 'noncanonical'
    $valid = New-ValidStateFile -Directory $folder -State $state
    $envelope = Read-Envelope -Path $valid.Path

    $inner = ConvertFrom-Json `
        -InputObject $envelope.StateJson `
        -ErrorAction Stop

    $envelope.StateJson = ConvertTo-Json `
        -InputObject $inner `
        -Depth 20

    $envelope.StateSha256 = Get-AijTextSha256 `
        -Text $envelope.StateJson

    Write-Envelope -Path $valid.Path -Envelope $envelope

    Assert-Rejection `
        -Label 'NONCANONICAL_STATE_JSON_REJECTED' `
        -Operation {
            Read-AijStateDraftFile `
                -Path $valid.Path `
                -ExpectedStateSha256 $envelope.StateSha256
        } `
        -Expected 'Persisted state content mismatch.'

    # Self-consistent unsafe state

    $folder = New-CaseDirectory -Name 'unsafe-state'
    $valid = New-ValidStateFile -Directory $folder -State $state
    $envelope = Read-Envelope -Path $valid.Path

    $inner = ConvertFrom-Json `
        -InputObject $envelope.StateJson `
        -ErrorAction Stop

    $phaseId = $inner.PhaseEvidence[0].Phase

    $inner.PhaseEvidence[0].State = 'RUNTIME_PASS'
    $inner.PhaseEvidence[0].Attempt = 1
    $inner.PhaseEvidence[0].ExitCode = 0
    $inner.PhaseEvidence[0].RuntimeVerified = $true
    $inner.PhaseEvidence[0].EvidenceSha256 = ('A' * 64)

    $envelope.StateJson = ConvertTo-Json `
        -InputObject $inner `
        -Depth 20 `
        -Compress

    $envelope.StateSha256 = Get-AijTextSha256 `
        -Text $envelope.StateJson

    Write-Envelope -Path $valid.Path -Envelope $envelope

    Assert-Rejection `
        -Label 'SELF_CONSISTENT_UNSAFE_STATE_REJECTED' `
        -Operation {
            Read-AijStateDraftFile `
                -Path $valid.Path `
                -ExpectedStateSha256 $envelope.StateSha256
        } `
        -Expected "Unsafe persisted phase evidence: $phaseId."

    # Existing destination

    $folder = New-CaseDirectory -Name 'overwrite'
    $null = New-ValidStateFile -Directory $folder -State $state

    Assert-Rejection `
        -Label 'PREEXISTING_DESTINATION_REJECTED' `
        -Operation {
            Write-AijStateDraftFile `
                -StateDraft $state `
                -Directory $folder
        } `
        -Expected 'State file already exists.'

    Assert-NoTemporaryResidue -Directory $folder
    Write-Output 'PASS: FAILED_WRITE_LEFT_NO_TEMPORARY_RESIDUE'

    # Assertion integrity

    Assert-Guard `
        -Label 'UNEXPECTED_ACCEPTANCE' `
        -Probe {
            Assert-Rejection `
                -Label 'CONTROL_ACCEPT' `
                -Operation { 'accepted' } `
                -Expected 'EXPECTED'
        } `
        -Expected 'ASSERTION_FAILURE: CONTROL_ACCEPT: accepted or not executed.'

    Assert-Guard `
        -Label 'UNRELATED_EXCEPTION' `
        -Probe {
            Assert-Rejection `
                -Label 'CONTROL_WRONG' `
                -Operation { throw 'UNRELATED_SENTINEL' } `
                -Expected 'EXPECTED'
        } `
        -Expected 'ASSERTION_FAILURE: CONTROL_WRONG: expected [EXPECTED], received [UNRELATED_SENTINEL].'

    Assert-Guard `
        -Label 'SKIPPED_OPERATION' `
        -Probe {
            Assert-Rejection `
                -Label 'CONTROL_SKIP' `
                -Operation { } `
                -Expected 'EXPECTED'
        } `
        -Expected 'ASSERTION_FAILURE: CONTROL_SKIP: accepted or not executed.'

    if ($script:negative -ne 14 -or
        $script:guards -ne 3) {
        throw (
            'TEST_COUNT_FAILURE: expected negative=14 guard=3; ' +
            "actual negative=$script:negative guard=$script:guards."
        )
    }

    Write-Output 'STATE_STORE_REGRESSIONS_OK positive=1 negative=14 guard=3'
    exit 0
}
catch {
    [Console]::Error.WriteLine($_.ToString())
    exit 1
}
finally {
    if ($null -ne $script:root -and
        [IO.Directory]::Exists($script:root)) {
        [IO.Directory]::Delete($script:root, $true)
    }
}