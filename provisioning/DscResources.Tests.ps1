BeforeAll {
    . (Join-Path $PSScriptRoot 'DscRuntime.ps1')
    . (Join-Path $PSScriptRoot 'DscConfiguration.ps1')
    if (-not $env:PROVISION_TEST_DSC) { throw 'Set PROVISION_TEST_DSC to the pinned DSC executable.' }
    $script:executable = $env:PROVISION_TEST_DSC
    $script:root = Join-Path $PSScriptRoot '..\winget'
    $script:previous = Enter-DscRuntime -Executable $executable -ConfigurationRoot $root
    $script:configurationSchema = (& $executable schema --type configuration --output-format json) -join "`n"
    if ($LASTEXITCODE -ne 0) { throw 'Cannot load the configuration schema.' }
    $script:documents = @{}
    Get-ChildItem -LiteralPath $root -Recurse -File |
        Where-Object { $_.Extension -in @('.yaml', '.winget') -and $_.Name -notlike '*.new.winget' } |
        ForEach-Object { $documents[$_.FullName] = Read-DscDocument -Path $_.FullName -Executable $executable }
}

AfterAll {
    if ($previous) { Exit-DscRuntime -Previous $previous }
}

Describe 'DSC document contracts' {
    It 'validates configuration documents and unique resource names' {
        foreach ($path in $documents.Keys) {
            $document = $documents[$path]
            $document | ConvertTo-Json -Depth 100 |
                Test-Json -Schema $configurationSchema -ErrorAction Stop | Should -BeTrue -Because $path
            @($document.resources.name | Group-Object | Where-Object Count -GT 1).Count |
                Should -Be 0 -Because "resource names must be unique in $path"
            foreach ($resource in $document.resources | Where-Object type -EQ 'Microsoft.DSC/Include') {
                Test-Path -LiteralPath (Join-Path (Split-Path $path) $resource.properties.configurationFile) |
                    Should -BeTrue -Because "Includes must resolve in $path"
            }
        }
    }

    It 'validates native registry and DISM properties against the shipped resource schemas' {
        foreach ($type in @('Microsoft.Windows/Registry', 'Microsoft.Windows/RegistryList',
            'Microsoft.Windows/WindowsFeatureList', 'Microsoft.Windows/FeatureOnDemandList')) {
            $schema = (& $executable resource schema --resource $type --output-format json) -join "`n"
            if ($LASTEXITCODE -ne 0) { throw "Cannot load schema for $type." }
            foreach ($document in $documents.Values) {
                foreach ($resource in $document.resources | Where-Object type -EQ $type) {
                    $resource.properties | ConvertTo-Json -Depth 100 |
                        Test-Json -Schema $schema -ErrorAction Stop | Should -BeTrue -Because $resource.name
                }
            }
        }
    }

    It 'parses inline scripts and requires the input parameter expected by the native script resource' {
        foreach ($document in $documents.Values) {
            foreach ($resource in $document.resources | Where-Object type -In @(
                'Microsoft.DSC.Transitional/PowerShellScript', 'Microsoft.DSC.Transitional/WindowsPowerShellScript')) {
                foreach ($operation in @('getScript', 'testScript', 'setScript')) {
                    $source = $resource.properties[$operation]
                    if (-not $source) { continue }
                    $tokens = $errors = $null
                    $ast = [System.Management.Automation.Language.Parser]::ParseInput($source, [ref]$tokens, [ref]$errors)
                    @($errors).Count | Should -Be 0 -Because "$($resource.name) $operation must parse"
                    if ($resource.properties.ContainsKey('input')) {
                        @($ast.ParamBlock.Parameters).Count | Should -Be 1 -Because "$($resource.name) $operation receives input"
                    }
                }
            }
        }
    }

    It 'executes an inert Include with the same runtime and result contract as the launcher' {
        $fixture = Join-Path $TestDrive 'echo.dsc.yaml'
        Set-Content -LiteralPath $fixture -Value @'
$schema: https://aka.ms/dsc/schemas/v3/bundled/config/document.json
resources:
  - name: Fixture
    type: Microsoft.DSC.Debug/Echo
    properties:
      output: fixture
'@
        $configuration = @{
            '$schema' = 'https://aka.ms/dsc/schemas/v3/bundled/config/document.json'
            resources = @(@{ name = 'Include'; type = 'Microsoft.DSC/Include'; properties = @{ configurationFile = $fixture } })
        }
        $result = Invoke-DscConfiguration -Executable $executable -Configuration $configuration `
            -Operation test -LogRoot (Join-Path $TestDrive 'logs')
        $result.Status | Should -Be OK
        $result.ExitCode | Should -Be 0
    }

    It 'checks mise config deployment without PowerShell 7 on PATH' {
        $document = $documents[[IO.Path]::GetFullPath((Join-Path $root 'modules\mise.dsc.yaml'))]
        $deployment = $document.resources | Where-Object name -EQ 'Deploy mise config'
        $configuration = @{ '$schema' = $document.'$schema'; resources = @($deployment) }
        $originalPath = $env:PATH
        $originalProfile = $env:USERPROFILE
        try {
            $env:PATH = "$(Split-Path $executable);$env:SystemRoot\System32;$env:SystemRoot\System32\WindowsPowerShell\v1.0"
            $env:USERPROFILE = $TestDrive
            $logRoot = Join-Path $TestDrive 'mise-logs'
            (Invoke-DscConfiguration -Executable $executable -Configuration $configuration -Operation test -LogRoot $logRoot).Status |
                Should -Be 'DRIFT'
            $configDirectory = Join-Path $TestDrive '.config\mise'
            New-Item -ItemType Directory -Path $configDirectory -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $configDirectory 'config.toml') -Value '[tools]'
            (Invoke-DscConfiguration -Executable $executable -Configuration $configuration -Operation test -LogRoot $logRoot).Status |
                Should -Be 'OK'
        } finally {
            $env:PATH = $originalPath
            $env:USERPROFILE = $originalProfile
        }
    }
}
