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

    It 'installs the current extension set only into the Default profile' {
        $resource = $edgeDocuments['edge-extensions'].resources[0]
        $resource.type | Should -Be 'Microsoft.DSC.Transitional/WindowsPowerShellScript'
        $resource.properties.input.workProfile | Should -Be Default
        $resource.properties.input.ContainsKey('personalProfile') | Should -BeFalse
        foreach ($extension in $resource.properties.input.extensions) {
            $extension.id | Should -Match '^[a-p]{32}$'
            $extension.updateUrl | Should -BeIn @(
                'https://edge.microsoft.com/extensionwebstorebase/v1/crx',
                'https://clients2.google.com/service/update2/crx'
            )
        }
        $resource.properties.setScript | Should -Match '--profile-directory='
        $resource.properties.setScript | Should -Not -Match 'Profile 1|disable-extensions'
    }

    It 'does not provision obsolete analytics extensions' {
        $removedIds = @(
            'ikbablmmjldhamhcldjjigniffkkjgpo'
            'hbddacgmlbobbhnakjimlkkhgogfndeb'
            'eideoafecdnkjfiomaaplogicinmmlee'
            'canpneabbfipaelecfibpmmjbdkiaolf'
            'nmcihgehpmokipeigjpeckphhdejjpbf'
        )
        $inputData = $edgeDocuments['edge-extensions'].resources[0].properties.input
        @($inputData.obsoleteExtensionIds | Sort-Object) | Should -Be @($removedIds | Sort-Object)
        $remaining = $inputData.extensions.id
        foreach ($id in $removedIds) {
            $remaining | Should -Not -Contain $id
        }
    }
}
