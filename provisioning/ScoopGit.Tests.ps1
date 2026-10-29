BeforeAll {
    . (Join-Path $PSScriptRoot 'DscConfiguration.ps1')
    if (-not $env:PROVISION_TEST_DSC) { throw 'Set PROVISION_TEST_DSC to the pinned DSC executable.' }

    function Invoke-ScoopGitFixture($Resource, [bool]$GitAvailable) {
        $calls = [System.Collections.Generic.List[string]]::new()
        function Get-Command {
            if ($GitAvailable) { [pscustomobject]@{ Name = 'git.exe' } }
        }
        function scoop($Action, $Package) {
            $calls.Add("$Action $Package")
            if ($Action -eq 'list' -and $Package -ne 'git') { "  $Package 1.0" }
        }
        $test = & ([scriptblock]::Create($Resource.testScript)) $Resource.input
        & ([scriptblock]::Create($Resource.setScript)) $Resource.input
        [pscustomobject]@{ InDesiredState = $test; Calls = $calls }
    }
}

Describe 'Scoop Git ownership in <Module>' -ForEach @(
    @{ Module = 'scoop-common' }
    @{ Module = 'scoop-work' }
) {
    BeforeAll {
        $path = Join-Path $PSScriptRoot "..\winget\modules\$Module.dsc.yaml"
        $document = Read-DscDocument -Path $path -Executable $env:PROVISION_TEST_DSC
        $script:prereqs = ($document.resources | Where-Object name -EQ 'Scoop Prereqs').properties
    }

    It 'keeps an existing Git and still provisions other prerequisites' {
        $result = Invoke-ScoopGitFixture $prereqs -GitAvailable $true
        $result.InDesiredState | Should -BeTrue
        $result.Calls | Should -Not -Contain 'list git'
        $result.Calls | Should -Not -Contain 'install git'
        $result.Calls | Should -Contain 'install 7zip'
    }

    It 'retains the Git bootstrap fallback when no Git is available' {
        $result = Invoke-ScoopGitFixture $prereqs -GitAvailable $false
        $result.InDesiredState | Should -BeFalse
        $result.Calls | Should -Contain 'list git'
        $result.Calls | Should -Contain 'install git'
    }
}
