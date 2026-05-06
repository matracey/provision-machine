BeforeAll {
    . (Join-Path $PSScriptRoot 'DscConfiguration.ps1')
    if (-not $env:PROVISION_TEST_DSC) { throw 'Set PROVISION_TEST_DSC to the pinned DSC executable.' }
    $script:executable = $env:PROVISION_TEST_DSC
}

Describe 'DSC configuration selection' {
    BeforeAll {
        $script:manifest = Join-Path $TestDrive 'work.winget'
        New-Item -ItemType Directory -Path (Join-Path $TestDrive 'modules') | Out-Null
        $resources = foreach ($name in @('first', 'second')) {
            Set-Content -LiteralPath (Join-Path $TestDrive "modules\$name.dsc.yaml") -Value 'resources: []'
            @{ name = $name; type = 'Microsoft.DSC/Include'; properties = @{ configurationFile = "./modules/$name.dsc.yaml" } }
        }
        @{ resources = @($resources) } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $manifest
    }
    It 'filters Includes and resolves paths before passing configuration on stdin' {
        $document = Get-DscConfiguration -Path $manifest -Executable $executable -Only second.dsc.yaml
        $document.resources.Count | Should -Be 1
        $document.resources[0].properties.configurationFile | Should -Be (Join-Path $TestDrive 'modules\second.dsc.yaml')
    }
    It 'also parses YAML through the bundled converter' {
        $path = Join-Path $TestDrive 'example.dsc.yaml'
        Set-Content -LiteralPath $path -Value "resources:`n  - name: Example`n    type: Microsoft.DSC.Debug/Echo"
        $document = Read-DscDocument -Path $path -Executable $executable
        $document.resources[0].name | Should -Be Example
    }
    It 'rejects unknown modules instead of silently running the full configuration' {
        { Get-DscConfiguration -Path $manifest -Executable $executable -Only typo.dsc.yaml } | Should -Throw '*Unknown included module*'
    }
    It 'rejects an empty selection' {
        { Get-DscConfiguration -Path $manifest -Executable $executable -Skip first.dsc.yaml, second.dsc.yaml } | Should -Throw '*No DSC resources*'
    }
}

Describe 'DSC result interpretation' {
    It 'finds drift inside nested Include results' {
        Test-DscDrift @(@{ result = @(@{ result = @{ inDesiredState = $false } }) }) | Should -BeTrue
    }
    It 'does not interpret resource payload fields as DSC status' {
        Test-DscDrift @(@{ result = @{
            inDesiredState = $true
            actualState = @{ output = @{ inDesiredState = $false } }
        } }) | Should -BeFalse
    }
    BeforeEach {
        $script:stub = Join-Path $TestDrive 'dsc-stub.ps1'
        $script:logs = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
    }
    It 'reports drift from JSON even when the process exits successfully' {
        Set-Content $stub @'
$null = @($input)
$global:LASTEXITCODE = 0
'{"hadErrors":false,"results":[{"result":{"inDesiredState":false}}]}'
'@
        $result = Invoke-DscConfiguration -Executable $stub -Configuration @{ resources = @() } -Operation test -LogRoot $logs
        $result.Status | Should -Be 'DRIFT'
        $result.ExitCode | Should -Be 2
        Test-Path $result.ResultPath | Should -BeTrue
    }
    It 'does not classify a failed process as drift' {
        Set-Content $stub '$null = @($input); $global:LASTEXITCODE = 2'
        { Invoke-DscConfiguration -Executable $stub -Configuration @{} -Operation test -LogRoot $logs } | Should -Throw '*exit code 2*'
    }
    It 'rejects error results even with a zero process exit code' {
        Set-Content $stub '$null = @($input); $global:LASTEXITCODE = 0; ''{"hadErrors":true,"results":[]}'''
        { Invoke-DscConfiguration -Executable $stub -Configuration @{} -Operation test -LogRoot $logs } | Should -Throw '*resource errors*'
    }
    It 'rejects success-shaped invalid output' {
        Set-Content $stub '$null = @($input); $global:LASTEXITCODE = 0; ''{}'''
        { Invoke-DscConfiguration -Executable $stub -Configuration @{} -Operation get -LogRoot $logs } | Should -Throw '*invalid configuration result*'
    }
}

Describe 'Structured Gist delivery' {
    It 'reconstructs the paths used by native Includes' {
        Mock Invoke-RestMethod { [pscustomobject]@{ files = [pscustomobject]@{
            'winget__work.winget' = @{ raw_url = 'https://example.test/work' }
            'winget__modules__example.dsc.yaml' = @{ raw_url = 'https://example.test/module' }
        } } }
        Mock Invoke-WebRequest { Set-Content -LiteralPath $OutFile -Value 'resources: []' }
        Save-DscBundle -Directory (Join-Path $TestDrive 'bundle') -GistId fixture
        Test-Path (Join-Path $TestDrive 'bundle\winget\work.winget') | Should -BeTrue
        Test-Path (Join-Path $TestDrive 'bundle\winget\modules\example.dsc.yaml') | Should -BeTrue
    }
    It 'rejects paths escaping the download directory' {
        Mock Invoke-RestMethod { [pscustomobject]@{ files = [pscustomobject]@{
            'winget__..__..__escape.ps1' = @{ raw_url = 'https://example.test/escape' }
        } } }
        Mock Invoke-WebRequest {}
        { Save-DscBundle -Directory (Join-Path $TestDrive 'unsafe') -GistId fixture } | Should -Throw '*Invalid path*'
        Should -Invoke Invoke-WebRequest -Times 0
    }
}
