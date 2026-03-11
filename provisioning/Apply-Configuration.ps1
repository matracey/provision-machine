<#
.SYNOPSIS
    Thin launcher for DSCv3-based machine provisioning.

.DESCRIPTION
    Fetches the appropriate DSCv3 configuration document (Personal or Work)
    and applies it using `dsc config set`. Supports both local file paths
    and remote Gist URLs.

.PARAMETER Personal
    Apply the Personal context configuration.

.PARAMETER Work
    Apply the Work context configuration.

.PARAMETER DryRun
    Show current state without making changes (runs `dsc config get`).

.PARAMETER Test
    Show configuration drift (runs `dsc config test`).

.PARAMETER Local
    Use local configuration files instead of fetching from Gist.

.PARAMETER InstallPrereqs
    Install prerequisite DSC modules and DSCv3 Preview, then exit.
#>
[CmdletBinding(DefaultParameterSetName = 'Interactive')]
param(
    [Parameter(ParameterSetName = 'Personal')]
    [switch]$Personal,

    [Parameter(ParameterSetName = 'Work')]
    [switch]$Work,

    [Parameter(ParameterSetName = 'Prereqs')]
    [switch]$InstallPrereqs,

    [switch]$DryRun,
    [switch]$Test,
    [switch]$Local
)

$ErrorActionPreference = 'Stop'

$GistBase = 'https://gist.githubusercontent.com/matracey/f4c3a9194cd190a3b3de423aad5dc7e1/raw'

# --- Prerequisites -----------------------------------------------------------

# Ensure DSCv3 Preview is installed.
# The stable release (Microsoft.DSC / 3.1.x) does not include resources like
# Microsoft.DSC.Transitional/PowerShellScript that our configs require.
# WinGet's FindDscPackageStateMachine always installs/uses stable, so we pass
# --processor-path to override the DSC executable when using winget configure.
$previewPkg = Get-AppxPackage -Name 'Microsoft.DesiredStateConfiguration-Preview' -ErrorAction SilentlyContinue |
    Where-Object { $_.PackageFamilyName -eq 'Microsoft.DesiredStateConfiguration-Preview_8wekyb3d8bbwe' }

if (-not $previewPkg) {
    Write-Host "Installing DSCv3 Preview..." -ForegroundColor Cyan
    winget install --id Microsoft.DSC.Preview --source winget --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to install DSCv3 Preview. Exit code: $LASTEXITCODE"
        exit 1
    }
    $previewPkg = Get-AppxPackage -Name 'Microsoft.DesiredStateConfiguration-Preview' -ErrorAction SilentlyContinue |
        Where-Object { $_.PackageFamilyName -eq 'Microsoft.DesiredStateConfiguration-Preview_8wekyb3d8bbwe' }
    if (-not $previewPkg) {
        Write-Error "DSCv3 Preview package not found after installation."
        exit 1
    }
    Write-Host "DSCv3 Preview installed." -ForegroundColor Green
}

$DscExePath = Join-Path $previewPkg.InstallLocation 'dsc.exe'
if (-not (Test-Path $DscExePath)) {
    Write-Error "dsc.exe not found at expected path: $DscExePath"
    exit 1
}
Write-Host "Using DSCv3 Preview ($($previewPkg.Version)): $DscExePath" -ForegroundColor Cyan

# Ensure required DSC modules are installed
# Resources that ship with DSCv3 are not checked here:
#   Microsoft.DSC.Transitional (RunCommandOnSet, PowerShellScript)
# Modules that ship with Windows/WinGet are not checked here:
#   Microsoft.Windows, Microsoft.WinGet, Microsoft.WinGet.DSC
# Modules installed by their parent app are not checked here:
#   Microsoft.PowerToys (ships with PowerToys), Microsoft.VisualStudio.DSC (ships with VS)
$requiredModules = @(
    @{ Name = 'Microsoft.Windows.Developer'; Params = @{} }
    @{ Name = 'Microsoft.Windows.Settings';  Params = @{ AllowPrerelease = $true } }
    @{ Name = 'GitDsc';                      Params = @{} }
)

$missing = @()
foreach ($mod in $requiredModules) {
    if (-not (Get-Module -ListAvailable -Name $mod.Name)) {
        $missing += $mod
    }
}

if ($missing.Count -gt 0) {
    Write-Host "`nInstalling $($missing.Count) required DSC module(s)..." -ForegroundColor Yellow
    foreach ($mod in $missing) {
        Write-Host "  Installing $($mod.Name)..." -ForegroundColor Cyan
        $installParams = @{ Name = $mod.Name; Force = $true; Scope = 'CurrentUser' } + $mod.Params
        Install-Module @installParams
    }
    Write-Host "All required modules installed.`n" -ForegroundColor Green
}

if ($InstallPrereqs) {
    Write-Host "All prerequisites are installed." -ForegroundColor Green
    exit 0
}

# --- Configuration -----------------------------------------------------------

# Determine context
if (-not $Personal -and -not $Work) {
    $choice = Read-Host "Select context: [P]ersonal or [W]ork"
    switch ($choice.ToUpper()) {
        'P' { $Personal = $true }
        'W' { $Work = $true }
        default { Write-Error "Invalid choice. Use 'P' or 'W'."; exit 1 }
    }
}

$context = if ($Personal) { 'personal' } else { 'work' }
$fileName = "configuration.$context.dsc.yaml"

# Resolve configuration file
if ($Local) {
    $configPath = Join-Path $PSScriptRoot "..\$fileName"
    if (-not (Test-Path $configPath)) {
        $configPath = Join-Path $PSScriptRoot $fileName
    }
    if (-not (Test-Path $configPath)) {
        Write-Error "Local configuration file not found: $fileName"
        exit 1
    }
    Write-Host "Using local file: $configPath" -ForegroundColor Cyan
} else {
    $configPath = Join-Path $env:TEMP $fileName
    $url = "$GistBase/$fileName"
    Write-Host "Fetching configuration from Gist..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $url -OutFile $configPath -UseBasicParsing
    Write-Host "Downloaded: $configPath" -ForegroundColor Green
}

# Apply configuration
if ($DryRun) {
    Write-Host "`nRunning dsc config get (dry-run)..." -ForegroundColor Yellow
    & $DscExePath config get --path $configPath
} elseif ($Test) {
    Write-Host "`nRunning dsc config test (drift detection)..." -ForegroundColor Yellow
    & $DscExePath config test --path $configPath
} else {
    Write-Host "`nApplying $context configuration..." -ForegroundColor Green
    & $DscExePath config set --path $configPath
}
