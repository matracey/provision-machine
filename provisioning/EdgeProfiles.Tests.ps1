BeforeAll {
    . (Join-Path $PSScriptRoot 'DscConfiguration.ps1')
    if (-not $env:PROVISION_TEST_DSC) { throw 'Set PROVISION_TEST_DSC to the pinned DSC executable.' }
    $document = Read-DscDocument -Path (Join-Path $PSScriptRoot '..\winget\modules\edge-profiles.dsc.yaml') -Executable $env:PROVISION_TEST_DSC
    $script:profiles = $document.resources[0].properties
    function New-EdgeFixture([string]$Channel) {
        $directory = Join-Path $env:ProgramFiles "Microsoft\$Channel\Application"
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $directory 'msedge.exe') -Value 'Not executable; browser launches are mocked.'
    }
    function Register-ProfileFixture([string]$Channel, [string]$Profile) {
        $root = Join-Path $env:LOCALAPPDATA "Microsoft\$Channel\User Data"
        New-Item -ItemType Directory -Path (Join-Path $root $Profile) -Force | Out-Null
        $statePath = Join-Path $root 'Local State'
        $state = if (Test-Path $statePath) { Get-Content $statePath -Raw | ConvertFrom-Json -AsHashtable }
            else { @{ profile = @{ info_cache = @{} }; untouched = 'preserve' } }
        $state.profile.info_cache[$Profile] = @{ name = $Profile }
        $state | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $statePath
        Set-Content -LiteralPath (Join-Path $root "$Profile\Preferences") -Value '{"untouched":true}'
    }
}

Describe 'Edge profile provisioning' {
    BeforeEach {
        $script:originalEnvironment = @{}
        foreach ($name in @('ProgramFiles', 'ProgramFiles(x86)', 'LOCALAPPDATA')) {
            $originalEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
            [Environment]::SetEnvironmentVariable($name, (Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))), 'Process')
        }
        Mock Start-Sleep {}
    }
    AfterEach {
        foreach ($name in $originalEnvironment.Keys) {
            [Environment]::SetEnvironmentVariable($name, $originalEnvironment[$name], 'Process')
        }
    }
    It 'creates missing profiles only in installed channels and preserves existing profiles' {
        New-EdgeFixture 'Edge'
        New-EdgeFixture 'Edge Dev'
        Register-ProfileFixture 'Edge Dev' 'Default'
        $existing = Join-Path $env:LOCALAPPDATA 'Microsoft\Edge Dev\User Data\Default\Preferences'
        $before = Get-FileHash $existing
        Mock Start-Process {
            $channel = Split-Path (Split-Path (Split-Path $FilePath)) -Leaf
            $profile = $ArgumentList[0] -replace '^--profile-directory="(.+)"$', '$1'
            Register-ProfileFixture $channel $profile
        }
        & ([scriptblock]::Create($profiles.testScript)) $profiles.input | Should -BeFalse
        & ([scriptblock]::Create($profiles.setScript)) $profiles.input
        & ([scriptblock]::Create($profiles.testScript)) $profiles.input | Should -BeTrue
        & ([scriptblock]::Create($profiles.setScript)) $profiles.input
        Should -Invoke Start-Process -Times 3 -Exactly
        (Get-FileHash $existing).Hash | Should -Be $before.Hash
        Test-Path (Join-Path $env:LOCALAPPDATA 'Microsoft\Edge Beta') | Should -BeFalse
    }
    It 'fails explicitly when Edge does not initialize a requested profile' {
        New-EdgeFixture 'Edge Dev'
        Mock Start-Process {}
        $script:clock = [datetime]'2026-01-01'
        Mock Get-Date { $script:clock = $script:clock.AddMinutes(1); $script:clock }
        { & ([scriptblock]::Create($profiles.setScript)) $profiles.input } |
            Should -Throw "*did not create profile*"
    }
}
