#Requires -Version 7.4
<#
.SYNOPSIS
    Apply Personal or Work configuration with portable DSC 3.3.
.PARAMETER InstallPrereqs
    Install stable WinGet, the checksum-pinned DSC runtime and exact compatibility-module versions.
.PARAMETER DryRun
    Read current state with DSC get. Use Preview to request set --what-if.
.PARAMETER Test
    Report drift. Exit 2 means drift; exit 1 means failure.
.PARAMETER Preview
    Request set --what-if. Not every resource supports this operation.
.PARAMETER Remote
    Download the configuration bundle from the repository's Gist.
.PARAMETER Skip
    Included module filenames to omit. UAC remains opt-in.
.PARAMETER Only
    Restrict execution to the named included module files.
.PARAMETER Monolithic
    Compatibility switch. All runs now use native DSC Includes.
#>
[CmdletBinding(DefaultParameterSetName = 'Interactive')]
param(
    [Parameter(ParameterSetName = 'Personal')][switch]$Personal,
    [Parameter(ParameterSetName = 'Work')][switch]$Work,
    [Parameter(ParameterSetName = 'Prereqs')][switch]$InstallPrereqs,
    [switch]$DryRun,
    [switch]$Test,
    [switch]$Preview,
    [switch]$Remote,
    [switch]$Monolithic,
    [string[]]$Skip = @('uac.dsc.yaml'),
    [string[]]$Only,
    [Parameter(DontShow)][switch]$ElevatedPhase
)

$ErrorActionPreference = 'Stop'
if (@(@($DryRun, $Test, $Preview) | Where-Object { $_ }).Count -gt 1) {
    throw 'Choose only one of -DryRun, -Test, or -Preview.'
}
. (Join-Path $PSScriptRoot 'DscRuntime.ps1')
. (Join-Path $PSScriptRoot 'DscConfiguration.ps1')

$isAdministrator = Test-IsAdministrator
if ($InstallPrereqs -and -not $isAdministrator) {
    Write-Host 'Administrator access is required to install prerequisites. Requesting elevation...' -ForegroundColor Yellow
    exit (Invoke-ElevatedScript -Path $PSCommandPath -BoundParameters $PSBoundParameters)
}
if ($ElevatedPhase -and -not $isAdministrator) {
    throw 'The elevated configuration phase must run as an administrator.'
}
if (-not $InstallPrereqs -and -not $ElevatedPhase -and $isAdministrator) {
    throw 'Run Apply-Configuration.ps1 from a non-administrator PowerShell session. It elevates only machine-level resources.'
}

if (-not $InstallPrereqs -and -not $Personal -and -not $Work) {
    switch ((Read-Host 'Select context: [P]ersonal or [W]ork').ToUpperInvariant()) {
        'P' { $Personal = $true }
        'W' { $Work = $true }
        default { throw 'Invalid choice. Use -Personal or -Work.' }
    }
}
Assert-StableWinGet -Install:$InstallPrereqs
$DscExePath = Get-DscRuntime -Install:$InstallPrereqs

$requiredModules = @(
    @{ Name = 'Microsoft.Windows.Developer'; Version = '0.4.0'; Prerelease = 'alpha' }
    @{ Name = 'Microsoft.VisualStudio.DSC'; Version = '1.0.35'; Prerelease = '' }
)
if ($Personal -or $InstallPrereqs) {
    $requiredModules += @{ Name = 'GitDsc'; Version = '0.2.0'; Prerelease = 'alpha' }
}
foreach ($module in $requiredModules) {
    $installed = Get-Module -ListAvailable -Name $module.Name | Where-Object {
        $_.Version -eq [version]$module.Version -and
        [string]$_.PrivateData.PSData.Prerelease -eq $module.Prerelease
    }
    if ($installed) { continue }
    if (-not $InstallPrereqs) {
        throw "Missing pinned module $($module.Name). Run -InstallPrereqs in an elevated PowerShell session."
    }
    $version = $module.Version
    if ($module.Prerelease) { $version += "-$($module.Prerelease)" }
    Install-Module -Name $module.Name -RequiredVersion $version -AllowPrerelease:([bool]$module.Prerelease) `
        -Scope AllUsers -Force -AllowClobber -ErrorAction Stop
}
if ($InstallPrereqs) {
    Write-Host 'Pinned DSC prerequisites are installed.' -ForegroundColor Green
    return
}

$context = if ($Personal) { 'personal' } else { 'work' }
$temporaryBundle = $null
try {
    if ($Remote) {
        $temporaryBundle = Join-Path $env:TEMP ("provision-machine-gist-" + [guid]::NewGuid().ToString('N'))
        Save-DscBundle -Directory $temporaryBundle -GistId 'f4c3a9194cd190a3b3de423aad5dc7e1'
        $configPath = Join-Path $temporaryBundle "winget\$context.winget"
    } else {
        $configPath = Join-Path $PSScriptRoot "..\winget\$context.winget"
    }
    $operation = if ($DryRun) { 'get' } elseif ($Test) { 'test' } else { 'set' }
    $userModules = @(
        'packages-common.dsc.yaml'
        'packages-personal.dsc.yaml'
        'packages-work.dsc.yaml'
        'powertoys.dsc.yaml'
        'vscode.dsc.yaml'
        'external-profiles.dsc.yaml'
    )
    $selection = Split-DscConfigurationModules -Path $configPath -Executable $DscExePath `
        -Only $Only -Skip $Skip -UserModules $userModules

    function Invoke-ConfigurationPhase {
        param(
            [Parameter(Mandatory)][string[]]$Modules,
            [Parameter(Mandatory)][string]$Phase
        )
        if ($Modules.Count -eq 0) { return $null }
        $configuration = Get-DscConfiguration -Path $configPath -Executable $DscExePath `
            -Only $Modules -Skip @()
        $previous = Enter-DscRuntime -Executable $DscExePath `
            -ConfigurationRoot (Split-Path (Resolve-Path $configPath).Path) -Context $context
        try {
            $runName = "apply-$(Get-Date -Format 'yyyyMMdd-HHmmssfff')-$context-$operation-$Phase"
            $logRoot = Join-Path $PSScriptRoot "..\sweep-logs\$runName"
            $result = Invoke-DscConfiguration -Executable $DscExePath -Configuration $configuration `
                -Operation $operation -LogRoot $logRoot -Preview:$Preview
            Write-Host "$Phase $($result.Status): $($result.ResultPath)"
            return $result
        } finally {
            Exit-DscRuntime -Previous $previous
        }
    }

    if ($ElevatedPhase) {
        $result = Invoke-ConfigurationPhase -Modules $selection.Elevated -Phase elevated
        exit $(if ($result) { $result.ExitCode } else { 0 })
    }

    $userResult = Invoke-ConfigurationPhase -Modules $selection.User -Phase user
    $elevatedExitCode = 0
    if ($selection.Elevated.Count -gt 0) {
        $elevatedParameters = @{}
        foreach ($entry in $PSBoundParameters.GetEnumerator()) {
            if ($entry.Key -ne 'ElevatedPhase') { $elevatedParameters[$entry.Key] = $entry.Value }
        }
        $elevatedParameters.ElevatedPhase = [switch]::new($true)
        if ($Personal) { $elevatedParameters.Personal = [switch]::new($true) }
        if ($Work) { $elevatedParameters.Work = [switch]::new($true) }
        Write-Host 'Requesting administrator access for machine-level resources...' -ForegroundColor Yellow
        $elevatedExitCode = Invoke-ElevatedScript -Path $PSCommandPath -BoundParameters $elevatedParameters
    }
    if ($elevatedExitCode -notin @(0, 2)) { exit $elevatedExitCode }
    if (($userResult -and $userResult.ExitCode -eq 2) -or $elevatedExitCode -eq 2) { exit 2 }
    exit 0
} finally {
    if ($temporaryBundle -and (Test-Path -LiteralPath $temporaryBundle)) {
        Remove-Item -LiteralPath $temporaryBundle -Recurse -Force -ErrorAction Stop
    }
}
