BeforeAll {
    . (Join-Path $PSScriptRoot 'DscRuntime.ps1')
    . (Join-Path $PSScriptRoot 'DscConfiguration.ps1')
    if (-not $env:PROVISION_TEST_DSC) { throw 'Set PROVISION_TEST_DSC to the pinned DSC executable.' }
    $script:document = Read-DscDocument -Path (Join-Path $PSScriptRoot '..\winget\modules\edge-shortcuts.dsc.yaml') -Executable $env:PROVISION_TEST_DSC
    $script:shortcuts = $document.resources[0].properties
    function New-EdgeFixture {
        $directory = Join-Path $env:ProgramFiles 'Microsoft\Edge Dev\Application'
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $directory 'msedge.exe') -Value 'Not executable; only used as a shortcut target.'
    }
}

Describe 'Edge shortcut provisioning' {
    BeforeEach {
        $script:originalEnvironment = @{}
        foreach ($name in @('ProgramFiles', 'ProgramFiles(x86)', 'LOCALAPPDATA')) {
            $originalEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
            [Environment]::SetEnvironmentVariable($name, (Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))), 'Process')
        }
        $script:shortcutInput = $shortcuts.input.Clone()
        $shortcutInput.desktopPath = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
    }
    AfterEach {
        foreach ($name in $originalEnvironment.Keys) {
            [Environment]::SetEnvironmentVariable($name, $originalEnvironment[$name], 'Process')
        }
    }
    It 'creates real shortcuts with distinct application IDs and repairs the profile arguments' {
        New-EdgeFixture
        & ([scriptblock]::Create($shortcuts.testScript)) $shortcutInput | Should -BeFalse
        & ([scriptblock]::Create($shortcuts.setScript)) $shortcutInput
        & ([scriptblock]::Create($shortcuts.testScript)) $shortcutInput | Should -BeTrue
        $wsh = New-Object -ComObject WScript.Shell
        $path = Join-Path $shortcutInput.desktopPath 'Microsoft Edge Dev - Personal.lnk'
        $link = $wsh.CreateShortcut($path)
        $link.Arguments = '--profile-directory="Default"'
        $link.Save()
        [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($link)
        & ([scriptblock]::Create($shortcuts.testScript)) $shortcutInput | Should -BeFalse
        & ([scriptblock]::Create($shortcuts.setScript)) $shortcutInput
        & ([scriptblock]::Create($shortcuts.testScript)) $shortcutInput | Should -BeTrue
    }
    It 'does not create broken shortcuts when Edge Dev is missing' {
        { & ([scriptblock]::Create($shortcuts.setScript)) $shortcutInput } |
            Should -Throw '*Install Microsoft Edge Dev*'
        Test-Path $shortcutInput.desktopPath | Should -BeFalse
    }
    It 'creates the shortcuts through the shipped Windows PowerShell resource' {
        New-EdgeFixture
        $resource = $document.resources[0] | ConvertTo-Json -Depth 100 | ConvertFrom-Json -AsHashtable
        $resource.properties.input.desktopPath = $shortcutInput.desktopPath
        $environmentSetup = @('ProgramFiles', 'ProgramFiles(x86)', 'LOCALAPPDATA') | ForEach-Object {
            $value = [Environment]::GetEnvironmentVariable($_, 'Process').Replace("'", "''")
            "[Environment]::SetEnvironmentVariable('$_', '$value', 'Process')"
        }
        foreach ($operation in @('testScript', 'setScript')) {
            $resource.properties[$operation] = $resource.properties[$operation].Replace(
                'param($inputData)', 'param($inputData)' + "`n" + ($environmentSetup -join "`n"))
        }
        $configuration = @{ '$schema' = $document.'$schema'; resources = @($resource) }
        $previous = Enter-DscRuntime -Executable $env:PROVISION_TEST_DSC -ConfigurationRoot (Join-Path $PSScriptRoot '..\winget')
        try {
            $logs = Join-Path $TestDrive 'shortcut-logs'
            (Invoke-DscConfiguration -Executable $env:PROVISION_TEST_DSC -Configuration $configuration -Operation set -LogRoot $logs).Status |
                Should -Be 'OK'
            (Invoke-DscConfiguration -Executable $env:PROVISION_TEST_DSC -Configuration $configuration -Operation test -LogRoot $logs).Status |
                Should -Be 'OK'
        } catch {
            throw "$($_.Exception.Message)`n$(Get-Content -LiteralPath (Join-Path $logs 'trace.log') -Raw)"
        } finally { Exit-DscRuntime -Previous $previous }
    }
}
