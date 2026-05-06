# Per-module diagnostic runner.
# Iterates each active Include in a context manifest (work.winget / personal.winget)
# and invokes `dsc config test` (or set) individually, capturing a per-module
# trace log and a summary table. Designed to be run elevated (e.g., gsudo).
[CmdletBinding()]
param(
    [ValidateSet('work', 'personal')]
    [string]$Context = 'work',

    [ValidateSet('test', 'get', 'set')]
    [string]$Mode = 'test',

    [string]$LogRoot = (Join-Path $env:TEMP "dsc-diag-$(Get-Date -Format 'yyyyMMdd-HHmmss')"),

    [string[]]$Only,
    [string[]]$Skip
)

$ErrorActionPreference = 'Stop'

$previewPkg = Get-AppxPackage -Name 'Microsoft.DesiredStateConfiguration-Preview' -ErrorAction SilentlyContinue |
    Where-Object { $_.PackageFamilyName -eq 'Microsoft.DesiredStateConfiguration-Preview_8wekyb3d8bbwe' }
if (-not $previewPkg) { Write-Error "DSCv3 Preview not installed."; exit 1 }
$DscExePath = Join-Path $previewPkg.InstallLocation 'dsc.exe'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$wingetDir = Join-Path $repoRoot 'winget'
$manifest = Join-Path $wingetDir "$Context.winget"
if (-not (Test-Path $manifest)) { Write-Error "Manifest not found: $manifest"; exit 1 }

# Extract active (uncommented) module filenames from the manifest.
$modules = Get-Content $manifest | Where-Object {
    $_ -match '^\s*configurationFile:\s*\./modules/([^\s]+\.dsc\.yaml)'
} | ForEach-Object {
    if ($_ -match 'configurationFile:\s*\./modules/([^\s]+\.dsc\.yaml)') { $Matches[1] }
}

if ($Only) { $modules = $modules | Where-Object { $Only -contains $_ } }
if ($Skip) { $modules = $modules | Where-Object { $Skip -notcontains $_ } }

New-Item -ItemType Directory -Path $LogRoot -Force | Out-Null
Write-Host "Logs: $LogRoot" -ForegroundColor Cyan
Write-Host "Mode: $Mode | Context: $Context | Modules: $($modules.Count)`n" -ForegroundColor Cyan

$env:DSC_TRACE_LEVEL = 'trace'
$env:PROVISION_MACHINE_ROOT = $wingetDir

$results = @()
$i = 0
foreach ($m in $modules) {
    $i++
    $path = Join-Path $wingetDir "modules\$m"
    $log = Join-Path $LogRoot ("{0:00}-{1}.log" -f $i, ($m -replace '\.dsc\.yaml$', ''))
    $label = "[{0:00}/{1}] {2}" -f $i, $modules.Count, $m
    Write-Host "$label ... " -NoNewline

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    & $DscExePath config $Mode --file $path *> $log
    $exit = $LASTEXITCODE
    $sw.Stop()

    $errorLines = @(Select-String -Path $log -Pattern ' ERROR ' -ErrorAction SilentlyContinue)
    $firstError = if ($errorLines.Count -gt 0) { ($errorLines[0].Line -split 'trace_message="PID \d+: ')[-1] -replace '"\s*$','' } else { '' }
    if ($firstError.Length -gt 180) { $firstError = $firstError.Substring(0, 180) + '...' }

    $status = if ($exit -eq 0) { 'OK' } else { 'FAIL' }
    $color = if ($exit -eq 0) { 'Green' } else { 'Red' }
    Write-Host ("{0}  ({1:n1}s, exit={2})" -f $status, $sw.Elapsed.TotalSeconds, $exit) -ForegroundColor $color
    if ($firstError) { Write-Host "       $firstError" -ForegroundColor DarkYellow }

    $results += [PSCustomObject]@{
        Module     = $m
        Status     = $status
        Exit       = $exit
        Seconds    = [math]::Round($sw.Elapsed.TotalSeconds, 1)
        FirstError = $firstError
        Log        = $log
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
$results | Format-Table Module, Status, Exit, Seconds -AutoSize
$failed = $results | Where-Object { $_.Status -eq 'FAIL' }
Write-Host "`n$($failed.Count) failed, $($results.Count - $failed.Count) passed." -ForegroundColor Yellow

$summaryPath = Join-Path $LogRoot 'summary.json'
$results | ConvertTo-Json -Depth 5 | Set-Content $summaryPath
Write-Host "Summary: $summaryPath" -ForegroundColor Cyan
