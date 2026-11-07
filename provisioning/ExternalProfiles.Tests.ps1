BeforeAll {
    . (Join-Path $PSScriptRoot 'DscConfiguration.ps1')
    if (-not $env:PROVISION_TEST_DSC) { throw 'Set PROVISION_TEST_DSC to the pinned DSC executable.' }
    $document = Read-DscDocument -Path (Join-Path $PSScriptRoot '..\winget\modules\external-profiles.dsc.yaml') `
        -Executable $env:PROVISION_TEST_DSC
}

Describe 'External profile integrations' {
    It 'uses dotagents as its source of truth' {
        ($document.resources | Where-Object name -EQ 'Install dotagents').properties.input.repository |
            Should -Be 'https://github.com/matracey/dotagents.git'
    }

    It 'passes the selected context to the dotagents installer' {
        $resource = $document.resources | Where-Object name -EQ 'Install dotagents'
        $resource.properties.testScript | Should -Match 'ExternalRepository\.ps1'
        $resource.properties.setScript | Should -Match 'Sync-GitCheckout'
        $resource.properties.setScript | Should -Match 'PROVISION_MACHINE_CONTEXT'
        $resource.properties.setScript | Should -Match 'install\.py.*--profile \$context'
    }

    It 'deploys the Git configuration gist with profile passthrough' {
        $resource = $document.resources | Where-Object name -EQ 'Install Git configuration'
        $resource.properties.input.gistId | Should -Be '8ab9c43a7cc61c7597cdb1582ede6ea5'
        $resource.properties.testScript | Should -Match 'ExternalRepository\.ps1'
        $resource.properties.setScript | Should -Match 'Sync-GitCheckout'
        $resource.properties.setScript | Should -Match '\$context -eq ''personal'''
        $resource.properties.setScript | Should -Match '--no-work'
        $resource.properties.setScript | Should -Match 'deploy\.py'
    }
}
