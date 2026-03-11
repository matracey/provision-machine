BeforeAll {
    . (Join-Path $PSScriptRoot 'DscConfiguration.ps1')
    if (-not $env:PROVISION_TEST_DSC) { throw 'Set PROVISION_TEST_DSC to the pinned DSC executable.' }
    $script:executable = $env:PROVISION_TEST_DSC
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
