BeforeAll {
    . (Join-Path $PSScriptRoot 'DscRuntime.ps1')
    function winget { throw 'WinGet must be mocked in these tests.' }
    function Repair-WinGetPackageManager { param($Version, [switch]$Force) throw 'Repair must be mocked.' }
}

Describe 'Pinned runtime preparation' {
    It 'does not download anything without explicit prerequisite installation' {
        Mock Invoke-WebRequest {}
        { Get-DscRuntime -CacheRoot (Join-Path $TestDrive 'missing') } | Should -Throw '*InstallPrereqs*'
        Should -Invoke Invoke-WebRequest -Times 0
    }
    It 'rejects a corrupt archive before promoting it into the runtime cache' {
        Mock Invoke-WebRequest { Set-Content -LiteralPath $OutFile -Value 'corrupt download' }
        $cache = Join-Path $TestDrive 'cache'
        { Get-DscRuntime -Install -CacheRoot $cache } | Should -Throw '*checksum mismatch*'
        @(Get-ChildItem -LiteralPath $cache).Count | Should -Be 0
    }
    It 'does not overwrite an incomplete existing cache' {
        $arch = if ([System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture -eq 'Arm64') { 'aarch64' } else { 'x86_64' }
        New-Item -ItemType Directory -Path (Join-Path $TestDrive "incomplete\3.3.0-$arch") -Force | Out-Null
        { Get-DscRuntime -Install -CacheRoot (Join-Path $TestDrive 'incomplete') } | Should -Throw '*Incomplete DSC cache*'
    }
}

Describe 'Elevated script launch' {
    It 'prefers gsudo and preserves switches, arrays, and quoted values' {
        Mock Get-Command { [pscustomobject]@{ Source = 'C:\fixture\gsudo.exe' } } -ParameterFilter {
            $Name -eq 'gsudo'
        }
        Mock Invoke-GsudoProcess { 23 }
        $result = Invoke-ElevatedScript -Path 'C:\fixture\Apply Configuration.ps1' -BoundParameters @{
            Work = [switch]::new($true)
            Test = [switch]::new($true)
            Remote = [switch]::new($false)
            Only = @('first.dsc.yaml', "second's module.dsc.yaml")
        }
        $result | Should -Be 23
        Should -Invoke Invoke-GsudoProcess -Times 1 -Exactly -ParameterFilter {
            $decoded = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($Arguments[3]))
            $Executable -eq 'C:\fixture\gsudo.exe' -and
            $Arguments[0] -eq 'pwsh' -and
            $Arguments[1] -eq '-NoProfile' -and $Arguments[2] -eq '-EncodedCommand' -and
            $decoded.StartsWith("& 'C:\fixture\Apply Configuration.ps1' ") -and
            $decoded -match '(?:^| )-Work(?: |$)' -and
            $decoded -match '(?:^| )-Test(?: |$)' -and
            $decoded -notmatch '(?:^| )-Remote(?: |$)' -and
            $decoded -match [regex]::Escape("-Only @('first.dsc.yaml', 'second''s module.dsc.yaml')")
        }
    }

    It 'falls back to RunAs when gsudo is unavailable' {
        Mock Get-Command {} -ParameterFilter { $Name -eq 'gsudo' }
        Mock Start-Process { [pscustomobject]@{ ExitCode = 0 } }
        Invoke-ElevatedScript -Path 'C:\fixture\Apply.ps1' -BoundParameters @{} | Should -Be 0
        Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter {
            $FilePath -like '*\pwsh.exe' -and $Verb -eq 'RunAs' -and $Wait -and $PassThru
        }
    }

    It 'reports a failed elevation request clearly' {
        Mock Get-Command {} -ParameterFilter { $Name -eq 'gsudo' }
        Mock Start-Process { throw 'The operation was canceled by the user.' }
        { Invoke-ElevatedScript -Path 'C:\fixture\Apply.ps1' -BoundParameters @{} } |
            Should -Throw '*requires administrator access*operation was canceled*'
    }
}

Describe 'Stable WinGet requirement' {
    It 'accepts a supported stable version' {
        Mock winget { $global:LASTEXITCODE = 0; 'v1.29.380' }
        { Assert-StableWinGet } | Should -Not -Throw
    }
    It 'rejects a newer preview rather than silently mixing channels' {
        Mock winget { $global:LASTEXITCODE = 0; 'v1.30.140-preview' }
        { Assert-StableWinGet } | Should -Throw '*Stable WinGet*'
    }
    It 'rejects an unsupported older stable version' {
        Mock winget { $global:LASTEXITCODE = 0; 'v1.10.0' }
        { Assert-StableWinGet } | Should -Throw '*Stable WinGet*'
    }
    It 'bootstraps the stable release only when installation was requested' {
        $script:repaired = $false
        Mock winget {
            $global:LASTEXITCODE = 0
            if ($script:repaired) { 'v1.29.380' } else { 'v1.30.140-preview' }
        }
        Mock Install-Module {}
        Mock Import-Module {}
        Mock Repair-WinGetPackageManager { $script:repaired = $true }
        Assert-StableWinGet -Install
        Should -Invoke Repair-WinGetPackageManager -Times 1 -ParameterFilter { $Version -eq '1.29.380' -and $Force }
        Should -Invoke Install-Module -Times 1 -ParameterFilter { $RequiredVersion -eq '1.29.380' }
    }
}

Describe 'Scoped resource discovery' {
    It 'replaces inherited discovery paths and restores the caller environment' {
        Mock Get-AppxPackage { [pscustomobject]@{ InstallLocation = 'C:\fixture\winget' } }
        $original = $env:DSC_RESOURCE_PATH
        $originalPath = $env:PATH
        $env:DSC_RESOURCE_PATH = 'C:\unrelated-preview'
        try {
            $previous = Enter-DscRuntime -Executable 'C:\fixture\dsc\dsc.exe' -ConfigurationRoot 'C:\fixture\winget'
            $env:DSC_RESOURCE_PATH | Should -Not -Match 'unrelated-preview'
            $env:DSC_RESOURCE_PATH | Should -Match ([regex]::Escape('C:\fixture\dsc'))
            Exit-DscRuntime -Previous $previous
            $env:DSC_RESOURCE_PATH | Should -Be 'C:\unrelated-preview'
            $env:PATH | Should -Be $originalPath
        } finally {
            $env:DSC_RESOURCE_PATH = $original
            $env:PATH = $originalPath
        }
    }
    It 'sets and restores the selected provisioning context' {
        Mock Get-AppxPackage { [pscustomobject]@{ InstallLocation = 'C:\fixture\winget' } }
        $original = $env:PROVISION_MACHINE_CONTEXT
        $env:PROVISION_MACHINE_CONTEXT = 'personal'
        try {
            $previous = Enter-DscRuntime -Executable 'C:\fixture\dsc\dsc.exe' `
                -ConfigurationRoot 'C:\fixture\winget' -Context work
            $env:PROVISION_MACHINE_CONTEXT | Should -Be work
            Exit-DscRuntime -Previous $previous
            $env:PROVISION_MACHINE_CONTEXT | Should -Be personal
        } finally {
            $env:PROVISION_MACHINE_CONTEXT = $original
        }
    }
}
