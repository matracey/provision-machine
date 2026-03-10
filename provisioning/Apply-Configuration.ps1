<#
.SYNOPSIS
    Thin launcher for WinGet-based machine provisioning.

.DESCRIPTION
    Applies the appropriate WinGet configuration document (Personal or Work)
    using `winget configure`. Supports both remote Gist URLs and local file paths.

.PARAMETER Personal
    Apply the Personal context configuration.

.PARAMETER Work
    Apply the Work context configuration.

.PARAMETER Test
    Show configuration drift (runs `winget configure test`).

.PARAMETER Local
    Use local configuration files instead of fetching from Gist.
#>
[CmdletBinding(DefaultParameterSetName = 'Interactive')]
param(
    [Parameter(ParameterSetName = 'Personal')]
    [switch]$Personal,

    [Parameter(ParameterSetName = 'Work')]
    [switch]$Work,

    [switch]$Test,
    [switch]$Local
)

$ErrorActionPreference = 'Stop'

$GistBase = 'https://gist.githubusercontent.com/matracey/f4c3a9194cd190a3b3de423aad5dc7e1/raw'

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

# Verify winget is available
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error @"
The 'winget' command is not available. Install Windows Package Manager:
  https://learn.microsoft.com/windows/package-manager/winget/#install-winget
Then restart your shell and try again.
"@
    exit 1
}

# Apply configuration
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

    if ($Test) {
        Write-Host "`nRunning winget configure test..." -ForegroundColor Yellow
        winget configure test -f $configPath --accept-configuration-agreements
    } else {
        Write-Host "`nApplying $context configuration..." -ForegroundColor Green
        winget configure -f $configPath --accept-configuration-agreements
    }
} else {
    $url = "$GistBase/$fileName"
    Write-Host "Applying $context configuration from Gist..." -ForegroundColor Cyan

    if ($Test) {
        Write-Host "`nRunning winget configure test..." -ForegroundColor Yellow
        winget configure test -f $url --accept-configuration-agreements
    } else {
        Write-Host "`nApplying $context configuration..." -ForegroundColor Green
        winget configure -f $url --accept-configuration-agreements
    }
}
