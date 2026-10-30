BeforeAll {
    . (Join-Path $PSScriptRoot 'DscRuntime.ps1')
    . (Join-Path $PSScriptRoot 'DscConfiguration.ps1')
    if (-not $env:PROVISION_TEST_DSC) { throw 'Set PROVISION_TEST_DSC to the pinned DSC executable.' }
    $script:edgeDocuments = @{}
    foreach ($name in @('edge', 'edge-shortcuts', 'edge-taskbar', 'edge-extensions')) {
        $edgeDocuments[$name] = Read-DscDocument -Path (Join-Path $PSScriptRoot "..\winget\modules\$name.dsc.yaml") -Executable $env:PROVISION_TEST_DSC
    }
}

Describe 'Edge declarative configuration' {
    It 'resolves a consistent association file path through the native expression engine' {
        $resources = $edgeDocuments['edge'].resources
        $file = $resources | Where-Object name -EQ 'Write Edge Dev default associations'
        $policy = $resources | Where-Object name -EQ 'Set Edge Dev default browser policy'
        $import = $resources | Where-Object name -EQ 'Set Edge Dev defaults for new Windows profiles'
        $configuration = @{
            '$schema' = $edgeDocuments['edge'].'$schema'
            resources = @(@{
                name = 'Resolved paths'; type = 'Microsoft.DSC.Debug/Echo'
                properties = @{ output = @{
                    file = $file.properties.DestinationPath
                    policy = $policy.properties.valueData.String
                    import = $import.properties.arguments[1]
                } }
            })
        }
        $previous = Enter-DscRuntime -Executable $env:PROVISION_TEST_DSC -ConfigurationRoot (Join-Path $PSScriptRoot '..\winget')
        try {
            $result = Invoke-DscConfiguration -Executable $env:PROVISION_TEST_DSC -Configuration $configuration `
                -Operation get -LogRoot (Join-Path $TestDrive 'echo-logs')
            $paths = $result.Result.results[0].result.actualState.output
            $paths.file | Should -Be (Join-Path $env:ProgramData 'provision-machine\DefaultAssociations.xml')
            $paths.policy | Should -Be $paths.file
            $paths.import | Should -Be "/Import-DefaultAppAssociations:$($paths.file)"
        } finally { Exit-DscRuntime -Previous $previous }
        $associations = ([xml]$file.properties.Contents).DefaultAssociations.Association
        @($associations.Identifier | Sort-Object) | Should -Be @('.htm', '.html', 'http', 'https')
        @($associations | Where-Object ProgId -NE 'MSEdgeDHTML').Count | Should -Be 0
    }

    It 'pins the profile shortcuts without replacing taskbar pins or defining a Start menu layout' {
        $file = $edgeDocuments['edge-taskbar'].resources | Where-Object type -EQ 'PSDesiredStateConfiguration/File'
        $xml = [xml]$file.properties.Contents
        $collection = $xml.SelectSingleNode("//*[local-name()='CustomTaskbarLayoutCollection']")
        $collection.HasAttribute('PinListPlacement') | Should -BeFalse
        $xml.SelectNodes("//*[local-name()='DefaultLayoutOverride' or local-name()='StartLayout']").Count | Should -Be 0
        $links = @($xml.SelectNodes("//*[local-name()='DesktopApp']") | ForEach-Object DesktopApplicationLinkPath)
        $expected = @($edgeDocuments['edge-shortcuts'].resources[0].properties.input.profiles | ForEach-Object { "%PUBLIC%\Desktop\$($_.name).lnk" })
        $links | Should -Be $expected
        $workLayout = [xml](Get-Content -LiteralPath (Join-Path $PSScriptRoot 'taskbarlayout.work.xml') -Raw)
        @($workLayout.SelectNodes("//*[local-name()='DesktopApp']") |
            Where-Object DesktopApplicationLinkPath -Like '*Microsoft Edge Dev -*' |
            ForEach-Object DesktopApplicationLinkPath) | Should -Be $expected
    }

    It 'uses individual optional-install entries without replacing unrelated Edge policy' {
        $entries = $edgeDocuments['edge-extensions'].resources[0].properties.registryEntries
        foreach ($group in $entries | Group-Object keyPath) {
            $group.Name | Should -Match '^HKCU\\Software\\Policies\\Microsoft\\Edge\\ExtensionSettings\\[a-p]{32}$'
            @($group.Group.valueName | Sort-Object) | Should -Be @('installation_mode', 'update_url')
            ($group.Group | Where-Object valueName -EQ installation_mode).valueData.String | Should -Be normal_installed
            ($group.Group | Where-Object valueName -EQ update_url).valueData.String | Should -BeIn @(
                'https://edge.microsoft.com/extensionwebstorebase/v1/crx',
                'https://clients2.google.com/service/update2/crx'
            )
        }
    }
}
