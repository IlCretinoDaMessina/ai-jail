
# Phase 000 - Discovery and dependency contracts
# Windows PowerShell 5.1

function Get-AijDependencyRules {
    [CmdletBinding()]
    param()

    return @{
        '010' = @()
        '020' = @(
            '010|RUNTIME_PASS|BOOTSTRAP_POLICY'
        )
        '030' = @(
            '010|RUNTIME_PASS|BOOTSTRAP_POLICY'
            '020|RUNTIME_PASS|BOOTSTRAP_POLICY'
        )
        '040' = @(
            '030|RUNTIME_PASS|review.require_phase_030_verified'
        )
        '050' = @(
            '030|RUNTIME_PASS|dependencies.require_phase_030_verified'
            '040|APPLIED|dependencies.require_phase_040_configuration_applied'
        )
        '060' = @(
            '030|RUNTIME_PASS|dependencies.require_phase_030_verified'
            '040|APPLIED|dependencies.require_phase_040_configuration_applied'
            '050|RUNTIME_PASS|dependencies.require_phase_050_runtime_pass'
        )
        '070' = @(
            '030|RUNTIME_PASS|dependencies.require_phase_030_verified'
            '040|APPLIED|dependencies.require_phase_040_configuration_applied'
            '050|RUNTIME_PASS|dependencies.require_phase_050_runtime_pass'
            '060|RUNTIME_PASS|dependencies.require_phase_060_toolchain_verified'
        )
        '080' = @(
            '030|RUNTIME_PASS|dependencies.require_phase_030_verified'
            '040|APPLIED|dependencies.require_phase_040_configuration_applied'
            '050|RUNTIME_PASS|dependencies.require_phase_050_runtime_pass'
            '060|RUNTIME_PASS|dependencies.require_phase_060_toolchain_verified'
            '070|RUNTIME_PASS|dependencies.require_phase_070_sandbox_verified'
        )
        '090' = @(
            '030|RUNTIME_PASS|dependencies.require_phase_030_verified'
            '040|APPLIED|dependencies.require_phase_040_configuration_applied'
            '050|RUNTIME_PASS|dependencies.require_phase_050_runtime_pass'
            '060|RUNTIME_PASS|dependencies.require_phase_060_toolchain_verified'
            '070|RUNTIME_PASS|dependencies.require_phase_070_sandbox_verified'
            '080|APPLIED|dependencies.require_phase_080_approved_state'
        )
        '091' = @(
            '050|RUNTIME_PASS|dependencies.require_phase_050_runtime_pass'
            '070|RUNTIME_PASS|dependencies.require_phase_070_sandbox_verified'
            '080|APPLIED|dependencies.require_phase_080_approved_state'
            '090|RUNTIME_PASS|dependencies.require_phase_090_opencode_verified'
        )
        '092' = @(
            '050|RUNTIME_PASS|dependencies.require_phase_050_runtime_pass'
            '060|RUNTIME_PASS|dependencies.require_phase_060_toolchain_verified'
            '070|RUNTIME_PASS|dependencies.require_phase_070_sandbox_verified'
            '080|APPLIED|dependencies.require_phase_080_approved_state'
            '090|RUNTIME_PASS|dependencies.require_phase_090_opencode_verified'
        )
    }
}

function Get-AijRequiredDenialRules {
    [CmdletBinding()]
    param()

    return @{
        '050' = @(
            'dependencies.accept_offline_policy_review_as_runtime_proof'
            'installation_gate.offline_review_satisfies_gate'
        )
        '060' = @(
            'dependencies.accept_phase_050_offline_review_as_runtime_proof'
        )
        '070' = @(
            'dependencies.accept_offline_reviews_as_runtime_proof'
        )
        '080' = @(
            'dependencies.accept_offline_reviews_as_runtime_proof'
        )
        '090' = @(
            'dependencies.accept_offline_reviews_as_runtime_proof'
        )
        '091' = @(
            'dependencies.accept_offline_reviews_as_runtime_proof'
        )
        '092' = @(
            'dependencies.accept_offline_reviews_as_runtime_proof'
        )
    }
}

function Assert-AijOrdinaryFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not [System.IO.File]::Exists($Path)) {
        throw "Required file missing: $([IO.Path]::GetFileName($Path))."
    }

    $attributes = [System.IO.File]::GetAttributes($Path)

    if (($attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Reparse-point file rejected: $([IO.Path]::GetFileName($Path))."
    }
}

function Assert-AijIntegerField {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Value,

        [Parameter(Mandatory = $true)]
        [int]$Expected,

        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    if (($Value -isnot [int] -and $Value -isnot [long]) -or
        $Value -ne $Expected) {
        throw "Invalid integer contract: $Label."
    }
}

function Get-AijPhaseInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Root
    )

    $resolved = Resolve-Path -LiteralPath $Root -ErrorAction Stop

    if (@($resolved).Count -ne 1) {
        throw 'Installer root is ambiguous.'
    }

    $rootPath = $resolved.ProviderPath

    if (-not [IO.Directory]::Exists($rootPath)) {
        throw 'Installer root is not a directory.'
    }

    $rootAttributes = [IO.File]::GetAttributes($rootPath)

    if (($rootAttributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw 'Installer root reparse point rejected.'
    }

    $rules = Get-AijDependencyRules
    $requiredDenials = Get-AijRequiredDenialRules

    $critical = @(
        '010', '020', '030', '040', '050', '070', '080'
    )

    $scripts = @(
        Get-ChildItem -LiteralPath $rootPath -Filter '*.bat' -File |
            Where-Object {
                $_.Name -cmatch '^([0-9]{3})-.+\.bat$' -and
                $_.Name -cnotmatch '^(000|999)-'
            } |
            Sort-Object @{
                Expression = { [int]$_.Name.Substring(0, 3) }
            }
    )

    $seen = @{}
    $items = New-Object 'System.Collections.Generic.List[object]'

    foreach ($script in $scripts) {
        $id = $script.Name.Substring(0, 3)

        if (-not $rules.ContainsKey($id)) {
            throw "Unknown installation phase: $id."
        }

        if ($seen.ContainsKey($id)) {
            throw "Duplicate installation phase ID: $id."
        }

        $seen[$id] = $true

        Assert-AijOrdinaryFile -Path $script.FullName

        $requirementsName = "$id-requirements.json"
        $requirementsPath = Join-Path $rootPath $requirementsName

        Assert-AijOrdinaryFile -Path $requirementsPath

        try {
            $doc = Get-Content -LiteralPath $requirementsPath -Raw |
                ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            throw "Invalid requirements JSON: $requirementsName."
        }

        if ($null -eq $doc -or $doc -isnot [pscustomobject]) {
            throw "Invalid requirements structure: $requirementsName."
        }

        $schemaProperty = $doc.PSObject.Properties['schema']
        $phaseProperty = $doc.PSObject.Properties['phase']
        $nameProperty = $doc.PSObject.Properties['name']

        if ($null -eq $schemaProperty) {
            throw "Missing requirements schema: $requirementsName."
        }

        Assert-AijIntegerField `
            -Value $schemaProperty.Value `
            -Expected 1 `
            -Label "$requirementsName.schema"

        if ($null -eq $phaseProperty -or
            $phaseProperty.Value -isnot [string] -or
            $phaseProperty.Value -cne $id) {
            throw "Requirements phase mismatch: $requirementsName."
        }

        if ($null -eq $nameProperty -or
            $nameProperty.Value -isnot [string] -or
            [string]::IsNullOrWhiteSpace($nameProperty.Value)) {
            throw "Invalid phase name: $requirementsName."
        }

        # Supported policy mode

        $modeProperty = $doc.PSObject.Properties['mode']

        if ($id -in @('010', '020')) {
            if ($null -ne $modeProperty) {
                throw "Unexpected legacy phase mode: $requirementsName."
            }

            $executionProperty = $doc.PSObject.Properties['execution']

            if ($null -eq $executionProperty -or
                $executionProperty.Value -isnot [pscustomobject]) {
                throw "Invalid read-only execution contract: $requirementsName."
            }

            $readOnly = $executionProperty.Value.PSObject.Properties['read_only']

            if ($null -eq $readOnly -or
                $readOnly.Value -isnot [bool] -or
                $readOnly.Value -ne $true) {
                throw "Invalid read-only execution contract: $requirementsName."
            }

            $declaredMode = 'LEGACY_READ_ONLY_QUERY'
        }
        else {
            if ($null -eq $modeProperty -or
                $modeProperty.Value -isnot [string] -or
                $modeProperty.Value -cnotin @(
                    'REVIEW_ONLY',
                    'OFFLINE_REVIEW_ONLY'
                )) {
                throw "Unsupported phase mode: $requirementsName."
            }

            $declaredMode = $modeProperty.Value
        }

        # Installation policy

        $installationProperty = $doc.PSObject.Properties['installation']

        if ($null -ne $installationProperty) {
            $installation = $installationProperty.Value

            if ($installation -isnot [pscustomobject]) {
                throw "Invalid installation policy: $requirementsName."
            }

            foreach ($key in @(
                'enabled',
                'production_apply_authorized'
            )) {
                $property = $installation.PSObject.Properties[$key]

                if ($null -ne $property) {
                    if ($property.Value -isnot [bool] -or
                        $property.Value -ne $false) {
                        throw "Installation policy not disabled: $requirementsName.$key."
                    }
                }
            }
        }

        $securityProperty = $doc.PSObject.Properties['security']

        if ($null -eq $securityProperty -or
            $securityProperty.Value -isnot [pscustomobject]) {
            throw "Invalid security policy: $requirementsName."
        }

        $security = $securityProperty.Value

        foreach ($property in $security.PSObject.Properties) {
            if ($property.Name -clike 'allow_*' -or
                $property.Name -ceq 'production_apply_authorized') {

                if ($property.Value -isnot [bool]) {
                    throw "Invalid security flag: $requirementsName.$($property.Name)."
                }
            }
        }

        $productionFlag = $security.PSObject.Properties[
            'production_apply_authorized'
        ]

        if ($null -ne $productionFlag -and $productionFlag.Value -ne $false) {
            throw "Production APPLY policy not disabled: $requirementsName."
        }

        # Exit-code contract

        $exitProperty = $doc.PSObject.Properties['exit_codes']

        if ($null -eq $exitProperty -or
            $exitProperty.Value -isnot [pscustomobject]) {
            throw "Missing exit-code contract: $requirementsName."
        }

        $exitContract = $exitProperty.Value

        foreach ($entry in @(
            @('success', 0),
            @('failure', 1)
        )) {
            $property = $exitContract.PSObject.Properties[$entry[0]]

            if ($null -eq $property) {
                throw "Missing exit-code field: $requirementsName.$($entry[0])."
            }

            Assert-AijIntegerField `
                -Value $property.Value `
                -Expected $entry[1] `
                -Label "$requirementsName.$($entry[0])"
        }

        $reboot = $exitContract.PSObject.Properties['reboot_required']

        if ($null -ne $reboot) {
            Assert-AijIntegerField `
                -Value $reboot.Value `
                -Expected 3010 `
                -Label "$requirementsName.reboot_required"
        }

        $unknown = $exitContract.PSObject.Properties['unknown']

        if ($null -ne $unknown -and $unknown.Value -cne 'FAIL_CLOSED') {
            throw "Invalid unknown-exit policy: $requirementsName."
        }

        # Dependency declarations

        $dependencyProperty = $doc.PSObject.Properties['dependencies']
        $dependencyDocument = $null

        if ($null -ne $dependencyProperty) {
            if ($dependencyProperty.Value -isnot [pscustomobject]) {
                throw "Invalid dependency document: $requirementsName."
            }

            $dependencyDocument = $dependencyProperty.Value

            foreach ($property in $dependencyDocument.PSObject.Properties) {
                if ($property.Value -isnot [bool]) {
                    throw "Invalid dependency flag: $requirementsName.$($property.Name)."
                }
            }
        }

        $expectedDeclarations = New-Object 'System.Collections.Generic.List[string]'
        $dependencies = New-Object 'System.Collections.Generic.List[object]'

        foreach ($rule in $rules[$id]) {
            $parts = $rule.Split('|')

            $priorId = $parts[0]
            $requiredState = $parts[1]
            $source = $parts[2]

            if ([int]$priorId -ge [int]$id) {
                throw "Invalid dependency ordering: $id -> $priorId."
            }

            if ($source -ne 'BOOTSTRAP_POLICY') {
                $expectedDeclarations.Add($source)

                $sourceParts = $source.Split('.')
                $sectionName = $sourceParts[0]
                $fieldName = $sourceParts[1]

                $section = $doc.PSObject.Properties[$sectionName]

                if ($null -eq $section -or
                    $section.Value -isnot [pscustomobject]) {
                    throw "Missing dependency declaration: $requirementsName.$source."
                }

                $field = $section.Value.PSObject.Properties[$fieldName]

                if ($null -eq $field -or
                    $field.Value -isnot [bool] -or
                    $field.Value -ne $true) {
                    throw "Dependency declaration not enabled: $requirementsName.$source."
                }
            }

            $dependencies.Add([pscustomobject]@{
                Phase = $priorId
                RequiredState = $requiredState
                Source = $source
            })
        }

        if ($null -ne $dependencyDocument) {
            foreach ($property in $dependencyDocument.PSObject.Properties) {
                if ($property.Name -cmatch '^require_phase_[0-9]{3}_') {
                    $declaration = "dependencies.$($property.Name)"

                    if (-not $expectedDeclarations.Contains($declaration)) {
                        throw "Unrecognised prerequisite: $requirementsName.$declaration."
                    }
                }
            }
        }

        # Mandatory offline-review denial policies

        if ($requiredDenials.ContainsKey($id)) {
            foreach ($declaration in $requiredDenials[$id]) {
                $parts = $declaration.Split('.')
                $sectionName = $parts[0]
                $fieldName = $parts[1]

                $section = $doc.PSObject.Properties[$sectionName]

                if ($null -eq $section -or
                    $section.Value -isnot [pscustomobject]) {
                    throw "Unsafe dependency policy: $requirementsName.$declaration."
                }

                $field = $section.Value.PSObject.Properties[$fieldName]

                if ($null -eq $field -or
                    $field.Value -isnot [bool] -or
                    $field.Value -ne $false) {
                    throw "Unsafe dependency policy: $requirementsName.$declaration."
                }
            }
        }

        # Source identity

        $items.Add([pscustomobject]@{
            Id = $id
            Name = $nameProperty.Value
            EntryPoint = $script.FullName
            Requirements = $requirementsPath
            EntryPointSha256 = (Get-FileHash -LiteralPath $script.FullName -Algorithm SHA256).Hash
            RequirementsSha256 = (Get-FileHash -LiteralPath $requirementsPath -Algorithm SHA256).Hash
            DeclaredMode = $declaredMode
            SecurityCritical = ($critical -contains $id)
            Dependencies = @($dependencies.ToArray())
            AutomaticExecutionAuthorized = $false
        })
    }

    # Prerequisite presence

    foreach ($item in $items) {
        foreach ($dependency in $item.Dependencies) {
            if (-not $seen.ContainsKey($dependency.Phase)) {
                throw "Missing prerequisite phase: $($item.Id) requires $($dependency.Phase)."
            }
        }
    }

    return $items.ToArray()
}
