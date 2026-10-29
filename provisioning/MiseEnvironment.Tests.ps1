BeforeAll {
    . (Join-Path $PSScriptRoot 'DscConfiguration.ps1')
    if (-not $env:PROVISION_TEST_DSC) { throw 'Set PROVISION_TEST_DSC to the pinned DSC executable.' }
    $document = Read-DscDocument -Path (Join-Path $PSScriptRoot '..\winget\modules\mise.dsc.yaml') -Executable $env:PROVISION_TEST_DSC
    $script:command = ($document.resources | Where-Object name -EQ 'Run mise install').properties
    $script:installDirectory = ($document.resources | Where-Object name -EQ 'Configure mise install directory').properties.valueData.String

    function Invoke-MiseFixture([int]$ExitCode = 0, [string]$InheritedDirectory = 'C:\stale') {
        $originalPath = $env:PATH
        $originalDirectory = $env:MISE_INSTALLS_DIR
        try {
            Set-Content -LiteralPath (Join-Path $TestDrive 'mise.cmd') -Value "@echo off`r`necho %MISE_INSTALLS_DIR%`r`necho %*`r`nexit /b $ExitCode" -Encoding ascii
            $env:PATH = $TestDrive
            $env:MISE_INSTALLS_DIR = $InheritedDirectory
            $arguments = @($command.arguments)
            $executable = Join-Path "$env:SystemRoot\System32" $command.executable
            $output = & $executable @arguments 2>&1
            [pscustomobject]@{ Output = $output; ExitCode = $LASTEXITCODE }
        } finally {
            $env:PATH = $originalPath
            $env:MISE_INSTALLS_DIR = $originalDirectory
        }
    }
}

Describe 'Mise install environment' {
    It 'uses the configured directory without PowerShell on PATH' {
        $result = Invoke-MiseFixture
        $result.ExitCode | Should -Be 0
        $result.Output | Should -Be @($installDirectory, 'install')
    }

    It 'propagates a failed tool restore' {
        $result = Invoke-MiseFixture -ExitCode 37
        $result.ExitCode | Should -Be 37
    }

    It 'also configures a fresh process without a directory variable' {
        $result = Invoke-MiseFixture -InheritedDirectory ''
        $result.ExitCode | Should -Be 0
        $result.Output | Should -Be @($installDirectory, 'install')
    }
}
