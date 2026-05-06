#Requires -Version 7.4
# Diagnose selected Includes using the same runtime and result contract as the launcher.
[CmdletBinding()]
param(
    [ValidateSet('work', 'personal')][string]$Context = 'work',
    [ValidateSet('test', 'get', 'set')][string]$Mode = 'test',
    [string]$LogRoot = (Join-Path $env:TEMP "dsc-diag-$(Get-Date -Format 'yyyyMMdd-HHmmssfff')"),
    [string[]]$Only,
    [string[]]$Skip = @('uac.dsc.yaml'),
    [switch]$Preview
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'DscRuntime.ps1')
. (Join-Path $PSScriptRoot 'DscConfiguration.ps1')
Assert-StableWinGet
$executable = Get-DscRuntime
$manifest = Join-Path $PSScriptRoot "..\winget\$Context.winget"
$configuration = Get-DscConfiguration -Path $manifest -Executable $executable -Only $Only -Skip $Skip
$previous = Enter-DscRuntime -Executable $executable -ConfigurationRoot (Split-Path (Resolve-Path $manifest).Path)
try {
    $result = Invoke-DscConfiguration -Executable $executable -Configuration $configuration `
        -Operation $Mode -LogRoot $LogRoot -Preview:$Preview
    $result | Select-Object Status, ResultPath, TracePath | Format-List
    exit $result.ExitCode
} finally {
    Exit-DscRuntime -Previous $previous
}
