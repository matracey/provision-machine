BeforeAll {
    . (Join-Path $PSScriptRoot 'DscConfiguration.ps1')
    if (-not $env:PROVISION_TEST_DSC) { throw 'Set PROVISION_TEST_DSC to the pinned DSC executable.' }
    $document = Read-DscDocument -Path (Join-Path $PSScriptRoot '..\winget\modules\mise.dsc.yaml') -Executable $env:PROVISION_TEST_DSC
    $script:installDirectory = ($document.resources | Where-Object name -EQ 'Configure mise install directory').properties.valueData.String

    function Invoke-MiseFixture($Command, [int]$ExitCode = 0, [string]$InheritedDirectory = 'C:\stale', [switch]$Native) {
        $originalPath = $env:PATH
        $originalDirectory = $env:MISE_INSTALLS_DIR
        try {
            Set-Content -LiteralPath (Join-Path $TestDrive 'mise.cmd') -Value "@echo off`r`nif not `"%MISE_INSTALLS_DIR%`"==`"$installDirectory`" exit /b 99`r`necho %MISE_INSTALLS_DIR%`r`necho %*`r`nexit /b $ExitCode" -Encoding ascii
            $env:PATH = $TestDrive
            $env:MISE_INSTALLS_DIR = $InheritedDirectory
            $arguments = @($command.arguments)
            $executable = Join-Path "$env:SystemRoot\System32" $command.executable
            if ($Native) {
                $resourceExecutable = Join-Path (Split-Path $env:PROVISION_TEST_DSC) 'RunCommandOnSet.exe'
                $output = $Command | ConvertTo-Json -Compress | & $resourceExecutable set
            } else {
                $output = & $executable @arguments 2>&1
            }
            [pscustomobject]@{ Output = $output; ExitCode = $LASTEXITCODE }
        } finally {
            $env:PATH = $originalPath
            $env:MISE_INSTALLS_DIR = $originalDirectory
        }
    }
}

Describe 'Mise install environment in <Module>' -ForEach @(
    @{ Module = 'mise'; ResourceName = 'Run mise install'; ExpectedArguments = 'install' }
    @{ Module = 'mise-work'; ResourceName = 'Install Azurite'; ExpectedArguments = 'use --global npm:azurite@latest' }
) {
    BeforeAll {
        $path = Join-Path $PSScriptRoot "..\winget\modules\$Module.dsc.yaml"
        $document = Read-DscDocument -Path $path -Executable $env:PROVISION_TEST_DSC
        $command = ($document.resources | Where-Object name -EQ $ResourceName).properties
    }

    It 'uses the configured directory without PowerShell on PATH' {
        $result = Invoke-MiseFixture -Command $command
        $result.ExitCode | Should -Be 0
        $result.Output | Should -Be @($installDirectory, $ExpectedArguments)
    }

    It 'propagates a failed tool restore' {
        $result = Invoke-MiseFixture -Command $command -ExitCode 37
        $result.ExitCode | Should -Be 37
    }

    It 'also configures a fresh process without a directory variable' {
        $result = Invoke-MiseFixture -Command $command -InheritedDirectory ''
        $result.ExitCode | Should -Be 0
        $result.Output | Should -Be @($installDirectory, $ExpectedArguments)
    }

    It 'also passes the environment through the shipped native command resource' {
        $result = Invoke-MiseFixture -Command $command -Native
        $result.ExitCode | Should -Be 0
        ($result.Output | ConvertFrom-Json -AsHashtable).ContainsKey('exitCode') | Should -BeFalse
    }
}
