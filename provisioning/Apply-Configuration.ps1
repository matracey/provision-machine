<#
.SYNOPSIS
    Thin launcher for DSCv3-based machine provisioning.

.DESCRIPTION
    Fetches the appropriate DSCv3 configuration document (Personal or Work)
    and applies it using the DSCv3 Preview `dsc config set`. Supports both
    local file paths
    and remote Gist delivery.

    Workaround: uses dsc.exe directly instead of `winget configure` because
    winget configure does not yet support DSCv3 preview resource discovery
    (e.g. Microsoft.DSC.Transitional/PowerShellScript, Microsoft.DSC/Include).
    Revert to `winget configure --processor-path` once winget ships native
    DSCv3 preview support.

    and remote Gist URLs.

.PARAMETER Personal
    Apply the Personal context configuration.

.PARAMETER Work
    Apply the Work context configuration.

.PARAMETER DryRun
    Show current state without making changes (runs `dsc config get`).

.PARAMETER Test
    Show configuration drift (runs `dsc config test`).

.PARAMETER Remote
    Force fetching configuration from the Gist even when running from a
    local clone. By default the script auto-detects: if winget\ exists
    next to the repo root it uses local files, otherwise it fetches from
    the Gist (oneliner / standalone context).
#>
[CmdletBinding(DefaultParameterSetName = 'Interactive')]
param(
    [Parameter(ParameterSetName = 'Personal')]
    [switch]$Personal,

    [Parameter(ParameterSetName = 'Work')]
    [switch]$Work,

    [switch]$DryRun,
    [switch]$Test,
    [switch]$Remote
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
$fileName = "$context.winget"

# Resolve configuration file — auto-detect local repo vs oneliner context
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..') -ErrorAction SilentlyContinue
$localConfigPath = if ($repoRoot) { Join-Path $repoRoot "winget\$fileName" } else { $null }
$useLocal = -not $Remote -and $localConfigPath -and (Test-Path $localConfigPath)

if ($useLocal) {
    $configPath = $localConfigPath
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

# Apply configuration using dsc.exe directly
# Workaround: winget configure does not yet support DSCv3 preview resource
# discovery. Once it does, replace these with:
#   winget configure -f $configPath --processor-path $DscExePath --accept-configuration-agreements --disable-interactivity
if ($DryRun) {
    Write-Host "`nRunning dsc config get (dry-run)..." -ForegroundColor Yellow
    dsc config get --file $configPath
} elseif ($Test) {
    Write-Host "`nRunning dsc config test (drift detection)..." -ForegroundColor Yellow
    dsc config test --file $configPath
} else {
    Write-Host "`nApplying $context configuration..." -ForegroundColor Green
    dsc config set --file $configPath
}
