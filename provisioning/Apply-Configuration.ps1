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
#>
[CmdletBinding(DefaultParameterSetName = 'Interactive')]
param(
    [Parameter(ParameterSetName = 'Personal')]
    [switch]$Personal,

    [Parameter(ParameterSetName = 'Work')]
    [switch]$Work,

    [switch]$DryRun,
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

# Verify dsc is available
if (-not (Get-Command dsc -ErrorAction SilentlyContinue)) {
    Write-Error @"
The 'dsc' command is not available. Install DSCv3:
  winget install Microsoft.DSC
Then restart your shell and try again.
"@
    exit 1
}

# Apply configuration
if ($DryRun) {
    Write-Host "`nRunning dsc config get (dry-run)..." -ForegroundColor Yellow
    dsc config get --path $configPath
} elseif ($Test) {
    Write-Host "`nRunning dsc config test (drift detection)..." -ForegroundColor Yellow
    dsc config test --path $configPath
} else {
    Write-Host "`nApplying $context configuration..." -ForegroundColor Green
    dsc config set --path $configPath
}
