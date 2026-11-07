BeforeAll {
    . (Join-Path $PSScriptRoot '..\winget\scripts\ExternalRepository.ps1')
}

Describe 'External repository helpers' {
    It 'discovers files by pattern without a manifest' {
        Set-Content -LiteralPath (Join-Path $TestDrive 'profile.ps1') -Value profile
        Set-Content -LiteralPath (Join-Path $TestDrive 'Helpers.psm1') -Value module
        Set-Content -LiteralPath (Join-Path $TestDrive 'README.md') -Value readme

        @(Get-MatchingFiles -Root $TestDrive -Patterns '*.ps1', '*.psm1').Name |
            Should -Be @('Helpers.psm1', 'profile.ps1')
    }

    It 'copies and verifies every matching file' {
        $source = Join-Path $TestDrive 'source'
        $first = Join-Path $TestDrive 'first'
        $second = Join-Path $TestDrive 'second'
        New-Item -ItemType Directory -Path $source | Out-Null
        Set-Content -LiteralPath (Join-Path $source 'profile.ps1') -Value profile
        Set-Content -LiteralPath (Join-Path $source 'Helpers.psm1') -Value module

        Sync-FileMirror -SourceRoot $source -DestinationRoots $first, $second -Patterns '*.ps1', '*.psm1'

        Test-FileMirror -SourceRoot $source -DestinationRoots $first, $second -Patterns '*.ps1', '*.psm1' |
            Should -BeTrue
    }
}
