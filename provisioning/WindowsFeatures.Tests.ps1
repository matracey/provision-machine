BeforeAll {
    . (Join-Path $PSScriptRoot 'DscConfiguration.ps1')
    if (-not $env:PROVISION_TEST_DSC) { throw 'Set PROVISION_TEST_DSC to the pinned DSC executable.' }
    $document = Read-DscDocument -Path (Join-Path $PSScriptRoot '..\winget\modules\windows-features.dsc.yaml') -Executable $env:PROVISION_TEST_DSC
    $script:features = $document.resources | Where-Object type -EQ 'Microsoft.Windows/WindowsFeatureList'
    $script:wslDefault = ($document.resources | Where-Object name -EQ 'Set WSL default version to 2').properties
    $script:netfx = ($document.resources | Where-Object name -EQ 'Install .NET Framework 3.5').properties
    $script:testNetfx = [scriptblock]::Create($netfx.testScript)
    $script:setNetfx = [scriptblock]::Create($netfx.setScript)
}

Describe '.NET Framework 3.5 provisioning' {
    BeforeEach {
        $script:build = 28000
        $script:installed = $false
        Mock Get-ItemPropertyValue { "$script:build" }
        Mock Test-Path { $script:installed } -ParameterFilter { $LiteralPath -like 'HKLM:*' }
        Mock Get-ItemProperty { @{ Install = [int]$script:installed } } -ParameterFilter { $LiteralPath -like 'HKLM:*' }
        Mock Get-WindowsOptionalFeature { @{ State = 'Disabled' } }
        Mock Enable-WindowsOptionalFeature { @{ RestartNeeded = $false } }
        Mock Invoke-WebRequest {}
        Mock Get-AuthenticodeSignature {
            @{ Status = 'Valid'; SignerCertificate = @{ Subject = 'CN=Microsoft Corporation, O=Microsoft Corporation, C=US' } }
        }
        Mock Start-Process {
            $script:installed = $true
            @{ ExitCode = 0 }
        }
        Mock Write-Warning {}
        $script:originalTemp = $env:TEMP
        $env:TEMP = $TestDrive
    }

    AfterEach {
        $env:TEMP = $originalTemp
    }

    It 'keeps the other optional features and excludes NetFx3 from the native list' {
        @($features.properties.features.featureName) | Should -Be @(
            'Containers-DisposableClientVM', 'Microsoft-Windows-Subsystem-Linux',
            'VirtualMachinePlatform', 'Microsoft-Hyper-V-All', 'Client-ProjFS'
        )
    }

    It 'keeps both WSL2 prerequisites and defaults new distributions to WSL2' {
        @($features.properties.features.featureName) | Should -Contain 'Microsoft-Windows-Subsystem-Linux'
        @($features.properties.features.featureName) | Should -Contain 'VirtualMachinePlatform'
        $wslDefault.executable | Should -Be 'wsl.exe'
        $wslDefault.arguments | Should -Be @('--set-default-version', '2')
    }

    It 'uses the Windows feature on builds below 28000' {
        $script:build = 27999
        (& $testNetfx $netfx.input) | Should -BeFalse
        & $setNetfx $netfx.input
        Should -Invoke Enable-WindowsOptionalFeature -Times 1 -Exactly -ParameterFilter {
            $Online -and $FeatureName -eq 'NetFx3' -and $All -and $NoRestart
        }
        Should -Invoke Invoke-WebRequest -Times 0
    }

    It 'leaves an enabled Windows feature unchanged' {
        $script:build = 26100
        Mock Get-WindowsOptionalFeature { @{ State = 'Enabled' } }
        (& $testNetfx $netfx.input) | Should -BeTrue
        & $setNetfx $netfx.input
        Should -Invoke Enable-WindowsOptionalFeature -Times 0
    }

    It 'reports a required restart for the Windows feature' {
        $script:build = 26100
        Mock Enable-WindowsOptionalFeature { @{ RestartNeeded = $true } }
        & $setNetfx $netfx.input
        Should -Invoke Write-Warning -Times 1 -Exactly -ParameterFilter { $Message -like '*requires a restart*' }
    }

    It 'installs the standalone runtime on build 28000 and cleans up the download' {
        (& $testNetfx $netfx.input) | Should -BeFalse
        & $setNetfx $netfx.input
        (& $testNetfx $netfx.input) | Should -BeTrue
        Should -Invoke Invoke-WebRequest -Times 1 -Exactly -ParameterFilter {
            $Uri -eq 'https://go.microsoft.com/fwlink/?LinkID=2337635'
        }
        Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter {
            $Wait -and $PassThru -and ($ArgumentList -join ' ') -eq '/q /norestart'
        }
        Should -Invoke Get-WindowsOptionalFeature -Times 0
        @(Get-ChildItem $TestDrive -Filter 'provision-netfx35-*').Count | Should -Be 0
    }

    It 'leaves an installed standalone runtime unchanged' {
        $script:installed = $true
        (& $testNetfx $netfx.input) | Should -BeTrue
        & $setNetfx $netfx.input
        Should -Invoke Invoke-WebRequest -Times 0
        Should -Invoke Start-Process -Times 0
    }

    It 'does not treat an uninstalled registry entry as an installed runtime' {
        Mock Test-Path { $true } -ParameterFilter { $LiteralPath -like 'HKLM:*' }
        (& $testNetfx $netfx.input) | Should -BeFalse
        & $setNetfx $netfx.input
        Should -Invoke Start-Process -Times 1 -Exactly
    }

    It 'rejects untrusted installers' {
        Mock Get-AuthenticodeSignature { @{ Status = 'NotSigned' } }
        { & $setNetfx $netfx.input } | Should -Throw '*valid Microsoft signature*'
        Should -Invoke Start-Process -Times 0
        @(Get-ChildItem $TestDrive -Filter 'provision-netfx35-*').Count | Should -Be 0
    }

    It 'rejects valid signatures from other publishers' {
        Mock Get-AuthenticodeSignature {
            @{ Status = 'Valid'; SignerCertificate = @{ Subject = 'CN=Another Publisher, O=Example' } }
        }
        { & $setNetfx $netfx.input } | Should -Throw '*valid Microsoft signature*'
        Should -Invoke Start-Process -Times 0
    }

    It 'reports installer failures' {
        Mock Start-Process { @{ ExitCode = 1603 } }
        { & $setNetfx $netfx.input } | Should -Throw '*exit code 1603*'
        @(Get-ChildItem $TestDrive -Filter 'provision-netfx35-*').Count | Should -Be 0
    }

    It 'does not accept a successful exit without an installed runtime' {
        Mock Start-Process { @{ ExitCode = 0 } }
        { & $setNetfx $netfx.input } | Should -Throw '*without registering*'
    }

    It 'reports a required restart without restarting' {
        Mock Start-Process {
            $script:installed = $true
            @{ ExitCode = 3010 }
        }
        & $setNetfx $netfx.input
        Should -Invoke Write-Warning -Times 1 -Exactly -ParameterFilter { $Message -like '*requires a restart*' }
    }

    It 'does not run the version-specific installer on future Windows builds' {
        $script:build = 28100
        { & $setNetfx $netfx.input } | Should -Throw '*No matching*28100*'
        Should -Invoke Invoke-WebRequest -Times 0
        Should -Invoke Get-WindowsOptionalFeature -Times 0
    }

    It 'preserves an existing standalone runtime on future Windows builds' {
        $script:build = 28100
        $script:installed = $true
        (& $testNetfx $netfx.input) | Should -BeTrue
        & $setNetfx $netfx.input
        Should -Invoke Invoke-WebRequest -Times 0
        Should -Invoke Get-WindowsOptionalFeature -Times 0
    }

    It 'surfaces download errors and cleans up' {
        Mock Invoke-WebRequest { throw 'Download failed' }
        { & $setNetfx $netfx.input } | Should -Throw '*Download failed*'
        Should -Invoke Start-Process -Times 0
        @(Get-ChildItem $TestDrive -Filter 'provision-netfx35-*').Count | Should -Be 0
    }
}
