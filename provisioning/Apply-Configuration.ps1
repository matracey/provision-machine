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
    local clone.

.PARAMETER InstallPrereqs
    Install prerequisite DSC modules and DSCv3 Preview, then exit.

.PARAMETER Monolithic
    Apply the aggregate configuration in a single `dsc config set` call
    instead of iterating per-module. Faster, but any single resource
    failure aborts the entire deployment.

.PARAMETER Skip
    Module file names to skip (e.g. 'powertoys.dsc.yaml'). Defaults to
    modules that are known to hit upstream DSCv3 Preview bugs; see the
    $DefaultSkip definition below for the current list and rationale.
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
    [switch]$Remote,
    [switch]$Monolithic,
    [string[]]$Skip
)

# Modules skipped by default. Override with -Skip @() to attempt them anyway.
#   powertoys.dsc.yaml: the Microsoft.PowerToys/PowerToysConfigure resource
#     emits many empty-string ("") leaf values which the DSCv3 Preview
#     expression parser rejects before any resource runs. Track upstream:
#     https://github.com/PowerShell/DSC/issues (empty-string literal parsing).
#   uac.dsc.yaml: applying this disables/reconfigures UAC, which breaks
#     gsudo for the remainder of the session (gsudo relies on the current UAC
#     prompt behavior to auto-elevate). Run this module manually in an already
#     elevated shell when you're ready, not as part of an automated apply.
$DefaultSkip = @('powertoys.dsc.yaml', 'uac.dsc.yaml')
if (-not $PSBoundParameters.ContainsKey('Skip')) { $Skip = $DefaultSkip }

$ErrorActionPreference = 'Stop'

$GistBase = 'https://gist.githubusercontent.com/matracey/f4c3a9194cd190a3b3de423aad5dc7e1/raw'
$GistId = 'f4c3a9194cd190a3b3de423aad5dc7e1'
$DscGistPrefix = 'winget__'

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

# Clear DSC_RESOURCE_PATH for this process. When set, DSC uses the listed
# directories as the working directory for its discovery extensions
# (Microsoft.Windows.Appx/Discover, Microsoft.PowerShell/Discover) when
# invoking `pwsh`/`powershell`, and the resulting PATH lookup from inside
# WindowsApps-locked dirs fails with:
#   "Operation Executable 'powershell' not found with working directory
#    'C:\Program Files\WindowsApps\...DesiredStateConfiguration-Preview...'"
# DSC's default discovery (its own install dir + PATH, which already includes
# C:\Program Files\PowerToys\DSCModules and the DesktopAppInstaller AppX)
# finds everything we need, so an explicit list only causes regressions.
# Also clear the persistent user-scope value so future shells don't inherit a
# stale entry pointing at a deleted preview build.
if ($env:DSC_RESOURCE_PATH) {
    Write-Host "Clearing process DSC_RESOURCE_PATH (was: $($env:DSC_RESOURCE_PATH))" -ForegroundColor DarkGray
}
Remove-Item Env:\DSC_RESOURCE_PATH -ErrorAction SilentlyContinue
$persistedPath = [Environment]::GetEnvironmentVariable('DSC_RESOURCE_PATH', 'User')
if ($persistedPath) {
    Write-Host "Clearing persistent user DSC_RESOURCE_PATH (was: $persistedPath)" -ForegroundColor DarkGray
    [Environment]::SetEnvironmentVariable('DSC_RESOURCE_PATH', $null, 'User')
}

# Ensure required DSC modules are installed
# Resources that ship with DSCv3 are not checked here:
#   Microsoft.DSC.Transitional (RunCommandOnSet, PowerShellScript)
# Modules that ship with Windows/WinGet are not checked here:
#   Microsoft.Windows, Microsoft.WinGet, Microsoft.WinGet.DSC
# Modules installed by their parent app are not checked here:
#   Microsoft.PowerToys (ships with PowerToys), Microsoft.VisualStudio.DSC (ships with VS)
# PSDscResources and ComputerManagementDsc are no longer required: the modules
# that used them (windows-features, execution-policy) were rewritten to use
# native Microsoft.DSC.Transitional/PowerShellScript resources to avoid the
# unreliable Microsoft.Windows/WindowsPowerShell adapter under corporate
# OneDrive-redirected Documents folders.
$requiredModules = @(
    @{ Name = 'Microsoft.Windows.Developer'; Params = @{ AllowPrerelease = $true } }
    @{ Name = 'Microsoft.Windows.Settings';  Params = @{ AllowPrerelease = $true } }
    @{ Name = 'GitDsc';                      Params = @{ AllowPrerelease = $true } }
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
        # Scope=AllUsers installs to C:\Program Files\PowerShell\Modules (and
        # the WindowsPowerShell equivalent under Program Files), NOT the user's
        # Documents folder. This matters because on corporate machines the
        # Documents folder is redirected to OneDrive, and org policy flags the
        # hundreds of module files as not-for-sync. AllUsers keeps DSC modules
        # machine-local. Requires admin; the script is expected to be run
        # elevated (e.g. via gsudo).
        $installParams = @{ Name = $mod.Name; Force = $true; AllowClobber = $true; Scope = 'AllUsers' } + $mod.Params
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
$fileName = "$context.winget"

# Resolve configuration file
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..') -ErrorAction SilentlyContinue
$localConfigPath = if ($repoRoot) { Join-Path $repoRoot "winget\$fileName" } else { $null }
$useLocal = -not $Remote -and $localConfigPath -and (Test-Path $localConfigPath)

if ($useLocal) {
    $configPath = $localConfigPath
    $configPath = Join-Path $PSScriptRoot "..\winget\$fileName"
    if (-not (Test-Path $configPath)) {
        $configPath = Join-Path $PSScriptRoot "..\winget\$fileName"
    }
    if (-not (Test-Path $configPath)) {
        Write-Error "Local configuration file not found: $fileName"
        exit 1
    }
    Write-Host "Using local file: $configPath" -ForegroundColor Cyan
} else {
    $tempRoot = Join-Path $env:TEMP "provision-machine-gist"
    if (Test-Path $tempRoot) { Remove-Item -Path $tempRoot -Recurse -Force }
    New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

    Write-Host "Fetching DSC configuration bundle from Gist..." -ForegroundColor Cyan
    $gist = Invoke-RestMethod -Uri "https://api.github.com/gists/$GistId" -Headers @{ 'User-Agent' = 'Provision-Machine' }
    $gistFiles = @($gist.files.PSObject.Properties) | Where-Object { $_.Name -like "$DscGistPrefix*" }
    if ($gistFiles.Count -eq 0) { Write-Error "No DSC files found in Gist."; exit 1 }
    foreach ($gistFile in $gistFiles) {
        $relativePath = ($gistFile.Name -split '__') -join '\'
        $targetPath = Join-Path $tempRoot $relativePath
        $targetDir = Split-Path $targetPath -Parent
        if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
        Invoke-WebRequest -Uri $gistFile.Value.raw_url -OutFile $targetPath -UseBasicParsing
    }
    $configPath = Join-Path $tempRoot "winget\$fileName"
    if (-not (Test-Path $configPath)) { Write-Error "Config not found after Gist reconstruction: winget\$fileName"; exit 1 }
    Write-Host "Downloaded and reconstructed: $configPath" -ForegroundColor Green
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

# Set config root so DSC PowerShellScript resources can resolve local file paths
$env:PROVISION_MACHINE_ROOT = Split-Path $configPath

# Apply configuration per-module so a single resource failure does not abort
# the rest of the deployment. Each Include in the aggregate .winget manifest is
# executed as its own `dsc config <op>` call; results are summarized at the end.
#
# Use -Monolithic to preserve the legacy single-call behavior (faster, but any
# failure aborts the run and later modules never execute).
#
# Workaround: winget configure does not yet support DSCv3 preview resource
# discovery. Once it does, replace this block with:
#   winget configure -f $configPath --processor-path $DscExePath --accept-configuration-agreements --disable-interactivity
$op = if ($DryRun) { 'get' } elseif ($Test) { 'test' } else { 'set' }
$opLabel = @{ get = 'dsc config get (dry-run)'; test = 'dsc config test (drift detection)'; set = "Applying $context configuration" }[$op]

if ($Monolithic) {
    Write-Host "`n$opLabel (monolithic)..." -ForegroundColor Green
    & $DscExePath config $op --file $configPath
    exit $LASTEXITCODE
}

$configDir = Split-Path $configPath -Parent
$modules = Get-Content $configPath | ForEach-Object {
    if ($_ -match '^\s*configurationFile:\s*\./modules/([^\s]+\.dsc\.yaml)') { $Matches[1] }
}
if (-not $modules -or $modules.Count -eq 0) {
    Write-Warning "No included modules found in manifest. Falling back to monolithic run."
    & $DscExePath config $op --file $configPath
    exit $LASTEXITCODE
}

Write-Host "`n$opLabel across $($modules.Count) module(s)..." -ForegroundColor Green

# Capture per-module output to a log directory so failures can be diagnosed
# after the fact. Previously we discarded DSC output with Out-Null, leaving
# users with no actionable error when a module failed.
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$logRoot = Join-Path $PSScriptRoot '..\sweep-logs'
if (-not (Test-Path $logRoot)) { New-Item -ItemType Directory -Path $logRoot -Force | Out-Null }
$runLogDir = Join-Path $logRoot ("apply-{0}-{1}-{2}" -f $timestamp, $context, $op)
New-Item -ItemType Directory -Path $runLogDir -Force | Out-Null
Write-Host "Per-module logs: $runLogDir" -ForegroundColor DarkGray

$results = @()
$i = 0
foreach ($m in $modules) {
    $i++
    $path = Join-Path $configDir "modules\$m"
    $label = "[{0:00}/{1}] {2}" -f $i, $modules.Count, $m
    if ($Skip -and ($Skip -contains $m)) {
        Write-Host "$label  SKIP (in -Skip list)" -ForegroundColor DarkGray
        $results += [PSCustomObject]@{ Module = $m; Status = 'SKIP'; Exit = $null; Seconds = 0; LogPath = $null }
        continue
    }
    if (-not (Test-Path $path)) {
        Write-Host "$label  SKIP (not found)" -ForegroundColor DarkGray
        $results += [PSCustomObject]@{ Module = $m; Status = 'SKIP'; Exit = $null; Seconds = 0; LogPath = $null }
        continue
    }
    Write-Host "$label ... " -NoNewline
    $moduleLog = Join-Path $runLogDir ($m -replace '\.dsc\.yaml$', '.log')
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    & $DscExePath config $op --file $path *>&1 | Tee-Object -FilePath $moduleLog | Out-Null
    $exit = $LASTEXITCODE
    $sw.Stop()
    # Classify result. Exit-code semantics are overloaded in DSC v3 Preview:
    #   0  => success (in desired state, or set succeeded).
    #   2  => EITHER drift-detected (normal for `test`) OR a resource/discovery
    #         error. Disambiguate by scanning the log for explicit ERROR lines
    #         (e.g. "Resource not found", "Operation Executable ... not found").
    #   other => real failure.
    $logText = Get-Content $moduleLog -Raw -ErrorAction SilentlyContinue
    $hasError = $logText -and ($logText -match '(?m)^\S+Z\s+ERROR\s')
    if ($exit -eq 0) {
        $status = 'OK'; $color = 'Green'
    } elseif ($exit -eq 2 -and $op -eq 'test' -and -not $hasError) {
        $status = 'DRIFT'; $color = 'Yellow'
    } else {
        $status = 'FAIL'; $color = 'Red'
    }
    Write-Host ("{0}  ({1:n1}s)" -f $status, $sw.Elapsed.TotalSeconds) -ForegroundColor $color
    if ($status -eq 'FAIL') {
        # Surface the tail of the failed module's log so the user sees the
        # actual error without having to open the file.
        Write-Host "  --- tail of $moduleLog ---" -ForegroundColor DarkYellow
        Get-Content $moduleLog -Tail 25 -ErrorAction SilentlyContinue | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
        Write-Host "  --- end tail ---" -ForegroundColor DarkYellow
    }
    $results += [PSCustomObject]@{ Module = $m; Status = $status; Exit = $exit; Seconds = [math]::Round($sw.Elapsed.TotalSeconds, 1); LogPath = $moduleLog }
}

$failed = @($results | Where-Object { $_.Status -eq 'FAIL' })
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
$results | Format-Table Module, Status, Exit, Seconds -AutoSize | Out-Host
$okCount = @($results | Where-Object { $_.Status -eq 'OK' }).Count
$driftCount = @($results | Where-Object { $_.Status -eq 'DRIFT' }).Count
$skipCount = @($results | Where-Object { $_.Status -eq 'SKIP' }).Count
Write-Host ("{0} failed, {1} succeeded, {2} drifted, {3} skipped." -f $failed.Count, $okCount, $driftCount, $skipCount) -ForegroundColor Yellow
Write-Host "Full per-module logs: $runLogDir" -ForegroundColor DarkGray
if ($failed.Count -gt 0) {
    Write-Host "`nFailed modules:" -ForegroundColor Red
    foreach ($f in $failed) {
        Write-Host ("  {0}  (exit {1})  log: {2}" -f $f.Module, $f.Exit, $f.LogPath) -ForegroundColor Red
    }
    Write-Host "`nRe-run a single failing module with: dsc config $op --file <path-to-module.dsc.yaml>" -ForegroundColor DarkYellow
    exit 1
}
