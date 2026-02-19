param(
  [Parameter()][switch]$Personal,
  [Parameter()][switch]$Work,
  [Parameter()][switch]$Cfg,
  [Parameter()][switch]$TurboRdpHw,
  [Parameter()][switch]$TurboRdpSw,
  [Parameter()][switch]$Winget,
  [Parameter()][switch]$WingetPkgs,
  [Parameter()][switch]$Scoop,
  [Parameter()][switch]$Mise,
  [Parameter()][switch]$VsRelease,
  [Parameter()][switch]$VsPreview,
  [Parameter()][switch]$VsIntPrev,
  [Parameter()][switch]$VsBldTool,
  [Parameter()][switch]$Fonts,
  [Parameter()][switch]$GoogleFonts,
  [Parameter()][switch]$NerdFonts,
  [Parameter()][switch]$WinTerminal,
  [Parameter()][switch]$OhMyPosh,
  [Parameter()][switch]$DryRun
)

#region Interactive Menu Functions

function Show-SingleSelectMenu {
  param(
    [string]$Title,
    [string[]]$Options,
    [int]$Default = 0
  )
  
  $selectedIndex = $Default
  $cursorTop = [Console]::CursorTop
  
  function Render {
    [Console]::SetCursorPosition(0, $cursorTop)
    for ($i = 0; $i -lt $Options.Count; $i++) {
      if ($i -eq $selectedIndex) {
        Write-Host -ForegroundColor Cyan "  > $($Options[$i])  " -NoNewline
        Write-Host ""
      } else {
        Write-Host "    $($Options[$i])  "
      }
    }
    Write-Host -ForegroundColor DarkGray "  (↑/↓ to move, Enter to select)"
  }
  
  Write-Host -ForegroundColor Yellow $Title
  Write-Host ""
  Render
  
  while ($true) {
    $key = $host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    switch ($key.VirtualKeyCode) {
      38 { $selectedIndex = [Math]::Max(0, $selectedIndex - 1) }  # Up
      40 { $selectedIndex = [Math]::Min($Options.Count - 1, $selectedIndex + 1) }  # Down
      13 { # Enter
        [Console]::SetCursorPosition(0, $cursorTop + $Options.Count + 1)
        Write-Host ""
        return $selectedIndex
      }
    }
    Render
  }
}

function Show-MultiSelectMenu {
  param(
    [string]$Title,
    [hashtable[]]$Options,  # @{ Name = ''; Selected = $false }
    [string]$HelpText = '(↑/↓ to move, Space to toggle, Enter to confirm)'
  )
  
  $selectedIndex = 0
  $cursorTop = [Console]::CursorTop
  
  function Render {
    [Console]::SetCursorPosition(0, $cursorTop)
    for ($i = 0; $i -lt $Options.Count; $i++) {
      $checkbox = if ($Options[$i].Selected) { '[■]' } else { '[ ]' }
      $color = if ($Options[$i].Selected) { 'Green' } else { 'White' }
      if ($i -eq $selectedIndex) {
        Write-Host -ForegroundColor Cyan -NoNewline "  > "
        Write-Host -ForegroundColor $color "$checkbox $($Options[$i].Name)  "
      } else {
        Write-Host -ForegroundColor $color "    $checkbox $($Options[$i].Name)  "
      }
    }
    Write-Host -ForegroundColor DarkGray "  $HelpText"
  }
  
  Write-Host -ForegroundColor Yellow $Title
  Write-Host ""
  Render
  
  while ($true) {
    $key = $host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    switch ($key.VirtualKeyCode) {
      38 { $selectedIndex = [Math]::Max(0, $selectedIndex - 1) }  # Up
      40 { $selectedIndex = [Math]::Min($Options.Count - 1, $selectedIndex + 1) }  # Down
      32 { $Options[$selectedIndex].Selected = -not $Options[$selectedIndex].Selected }  # Space
      13 { # Enter
        [Console]::SetCursorPosition(0, $cursorTop + $Options.Count + 1)
        Write-Host ""
        return $Options
      }
    }
    Render
  }
}

#endregion

#region Validation and Interactive Setup
if ($Personal -and $Work) {
  Write-Error 'Cannot specify both -Personal and -Work switches. Please choose one.'
  exit 1
}

# Interactive mode when no context specified
if (-not $Personal -and -not $Work) {
  Write-Host ''
  Write-Host -ForegroundColor Cyan '╔══════════════════════════════════════════════════════════════╗'
  Write-Host -ForegroundColor Cyan '║                    QuickInit Provisioning                    ║'
  Write-Host -ForegroundColor Cyan '╚══════════════════════════════════════════════════════════════╝'
  Write-Host ''
  
  $contextChoice = Show-SingleSelectMenu -Title 'Select context:' -Options @('Personal', 'Work')
  if ($contextChoice -eq 0) { $Personal = $true } else { $Work = $true }
}

$Context = if ($Personal) { 'Personal' } else { 'Work' }
Write-Host -ForegroundColor Green "Context: $Context"
Write-Host ''
#endregion

#region Defaults
$AllSwitchesFalse = -not ($Cfg -or $TurboRdpHw -or $TurboRdpSw -or $Winget -or $WingetPkgs -or $Scoop -or $Mise -or $VsRelease -or $VsPreview -or $VsIntPrev -or $VsBldTool -or $Fonts -or $GoogleFonts -or $NerdFonts -or $WinTerminal -or $OhMyPosh)

if ($AllSwitchesFalse) {
  $featureOptions = @(
    @{ Name = 'Scoop packages'; Selected = $true; Variable = 'Scoop' }
    @{ Name = 'WinGet packages (DSC)'; Selected = $true; Variable = 'WingetPkgs' }
    @{ Name = 'Mise tools'; Selected = $true; Variable = 'Mise' }
    @{ Name = 'Visual Studio Preview'; Selected = $true; Variable = 'VsPreview' }
    @{ Name = 'Fonts (Google + Nerd)'; Selected = $true; Variable = 'Fonts' }
    @{ Name = 'Windows Terminal settings'; Selected = $true; Variable = 'WinTerminal' }
    @{ Name = 'Oh My Posh config'; Selected = $true; Variable = 'OhMyPosh' }
    @{ Name = 'System configuration'; Selected = $false; Variable = 'Cfg' }
  )
  
  $results = Show-MultiSelectMenu -Title 'Select features to install:' -Options $featureOptions
  
  foreach ($opt in $results) {
    Set-Variable -Name $opt.Variable -Value $opt.Selected
  }
  
  $selected = ($results | Where-Object { $_.Selected } | ForEach-Object { $_.Name }) -join ', '
  if ($selected) {
    Write-Host -ForegroundColor Green "Features: $selected"
  } else {
    Write-Host -ForegroundColor Yellow "No features selected. Exiting."
    exit 0
  }
}
#endregion

#region Helper Functions

# Gist ID for remote configuration files
$script:GistId = 'f4c3a9194cd190a3b3de423aad5dc7e1'
$script:GistBaseUrl = "https://gist.githubusercontent.com/matracey/$script:GistId/raw"

<#
.SYNOPSIS
Gets file content from the GitHub Gist or local file.

.DESCRIPTION
Attempts to fetch a file from the configured GitHub Gist. Falls back to local file if available.

.PARAMETER FileName
The name of the file to fetch.

.PARAMETER LocalPath
Optional local path to use as fallback.

.RETURNS
The content of the file as a string.
#>
function Get-ConfigFile {
  param(
    [Parameter(Mandatory = $true)]
    [string]$FileName,
    [string]$LocalPath
  )

  # Try to fetch from gist first
  $GistUrl = "$script:GistBaseUrl/$FileName"
  try {
    Write-Verbose "Fetching $FileName from gist..."
    $Response = Invoke-WebRequest -Uri $GistUrl -UseBasicParsing -ErrorAction Stop
    return $Response.Content
  } catch {
    Write-Verbose "Failed to fetch from gist: $_"
  }

  # Fall back to local file
  if ($LocalPath -and (Test-Path $LocalPath)) {
    Write-Verbose "Using local file: $LocalPath"
    return Get-Content -Path $LocalPath -Raw
  }

  throw "Could not load $FileName from gist or local path"
}

<#
.SYNOPSIS
Saves content to a temporary file and returns the path.

.PARAMETER Content
The content to save.

.PARAMETER FileName
The name of the file (used for extension).

.RETURNS
The path to the temporary file.
#>
function Save-TempFile {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Content,
    [Parameter(Mandatory = $true)]
    [string]$FileName
  )

  $TempPath = Join-Path $env:TEMP "QuickInit_$FileName"
  $Content | Set-Content -Path $TempPath -Encoding UTF8
  return $TempPath
}

<#
.SYNOPSIS
Tries to run a script block with elevated permissions.

.DESCRIPTION
If the current session is already elevated, the script block is run directly.
If not elevated, the script is re-run with elevated permissions.

.PARAMETER ScriptBlock
The script block to run.

.PARAMETER NotifyText
Text to display when elevation is required.

.EXAMPLE
Invoke-BlockElevated { Get-ChildItem 'C:\' }
#>
function Invoke-BlockElevated {
  param(
    [scriptblock]$ScriptBlock,
    [string]$NotifyText = 'Restarting as administrator.'
  )

  if ($IsWindows) {
    $IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if ($IsAdmin) {
      Invoke-Command -ScriptBlock $ScriptBlock
    } else {
      Write-Host $NotifyText
      Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$ScriptBlock`""
    }
  } else {
    Invoke-Command -ScriptBlock $ScriptBlock
  }
}

<#
.SYNOPSIS
Sets registry keys and values based on a hashtable.

.PARAMETER RegistryChanges
A hashtable where keys are registry paths and values are hashtables of name/value pairs.

.EXAMPLE
@{ 'HKLM:\SOFTWARE\MyApp' = @{ 'Setting1' = 1 } } | Set-RegistryChanges
#>
function Set-RegistryChanges {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [hashtable]$RegistryChanges,
    [bool]$DryRun = $false
  )

  process {
    foreach ($Path in $RegistryChanges.Keys) {
      if ($DryRun) {
        foreach ($Name in $RegistryChanges[$Path].Keys) {
          Write-Host -ForegroundColor DarkYellow "[DryRun] Would set $Name to $($RegistryChanges[$Path][$Name]) in $Path"
        }
        continue
      }

      if (-not (Test-Path -Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
      }

      foreach ($Name in $RegistryChanges[$Path].Keys) {
        $Value = $RegistryChanges[$Path][$Name]
        Write-Host -ForegroundColor DarkYellow "Setting $Name to $Value in $Path"
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type DWord -Force
      }
    }
  }
}

<#
.SYNOPSIS
Imports a module if it is available and not already imported.

.PARAMETER Name
The name of the module to import.

.RETURNS
$true if module is available/imported, $false otherwise.
#>
function Import-ModuleIfAvailable {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [string]$Name
  )

  if ($null -ne (Get-Module -Name $Name -ErrorAction SilentlyContinue)) {
    return $true
  }

  $AvailableModule = Get-Module -Name $Name -ListAvailable -ErrorAction SilentlyContinue | Select-Object -First 1

  if ($null -eq $AvailableModule) {
    return $false
  }

  $AvailableModule | Import-Module -Force
  return $true
}

<#
.SYNOPSIS
Filters out installed WinGet packages.

.DESCRIPTION
Pipeline filter that passes through only packages that are not already installed.
#>
filter Select-NotInstalled {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [object]$Package
  )

  if ($null -eq (Get-WinGetPackage $Package.Id -ErrorAction:SilentlyContinue)) {
    $_
  } else {
    Write-Host -ForegroundColor DarkGray "Package $($Package.Id) is already installed."
  }
}

<#
.SYNOPSIS
Imports Configuration.json and returns merged config for the specified context.

.PARAMETER Context
Either 'Personal' or 'Work'.

.RETURNS
Merged configuration object with Common + Context-specific settings.
#>
function Import-Configuration {
  param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Personal', 'Work')]
    [string]$Context
  )

  $ConfigContent = Get-ConfigFile -FileName 'Configuration.json' -LocalPath "$PSScriptRoot\Configuration.json"
  $Config = $ConfigContent | ConvertFrom-Json

  # Build merged configuration
  $Merged = @{
    Git = @{
      System = @{}
      Global = @{}
    }
    Scoop = @{
      Prereqs = @()
      Buckets = @()
      Packages = @()
      Aliases = @{}
    }
    VisualStudio = @{
      Workloads = @()
    }
    WindowsDefender = @{
      ProcessExclusions = @()
      ProjectsFolder = $null
    }
  }

  # Merge Common settings
  if ($Config.Common) {
    if ($Config.Common.Git) {
      if ($Config.Common.Git.System) {
        $Config.Common.Git.System.PSObject.Properties | ForEach-Object { $Merged.Git.System[$_.Name] = $_.Value }
      }
      if ($Config.Common.Git.Global) {
        $Config.Common.Git.Global.PSObject.Properties | ForEach-Object { $Merged.Git.Global[$_.Name] = $_.Value }
      }
    }
    if ($Config.Common.Scoop) {
      $Merged.Scoop.Prereqs = @($Config.Common.Scoop.Prereqs)
      $Merged.Scoop.Buckets = @($Config.Common.Scoop.Buckets)
      $Merged.Scoop.Packages = @($Config.Common.Scoop.Packages)
      if ($Config.Common.Scoop.Aliases) {
        $Config.Common.Scoop.Aliases.PSObject.Properties | ForEach-Object { $Merged.Scoop.Aliases[$_.Name] = $_.Value }
      }
    }
    if ($Config.Common.VisualStudio) {
      $Merged.VisualStudio.Workloads = @($Config.Common.VisualStudio.Workloads)
    }
    if ($Config.Common.WindowsDefender) {
      $Merged.WindowsDefender.ProcessExclusions = @($Config.Common.WindowsDefender.ProcessExclusions)
    }
  }

  # Merge Context-specific settings
  $ContextConfig = $Config.$Context
  if ($ContextConfig) {
    if ($ContextConfig.Git) {
      if ($ContextConfig.Git.System) {
        $ContextConfig.Git.System.PSObject.Properties | ForEach-Object { $Merged.Git.System[$_.Name] = $_.Value }
      }
      if ($ContextConfig.Git.Global) {
        $ContextConfig.Git.Global.PSObject.Properties | ForEach-Object { $Merged.Git.Global[$_.Name] = $_.Value }
      }
    }
    if ($ContextConfig.Scoop) {
      if ($ContextConfig.Scoop.Buckets) {
        $Merged.Scoop.Buckets += @($ContextConfig.Scoop.Buckets)
      }
      if ($ContextConfig.Scoop.Packages) {
        $Merged.Scoop.Packages += @($ContextConfig.Scoop.Packages)
      }
    }
    if ($ContextConfig.WindowsDefender) {
      if ($ContextConfig.WindowsDefender.ProjectsFolder) {
        $Merged.WindowsDefender.ProjectsFolder = $ContextConfig.WindowsDefender.ProjectsFolder
      }
    }
  }

  return [PSCustomObject]$Merged
}

#endregion

#region Main Script

$Configuration = Import-Configuration -Context $Context
$DownloadsFolder = "$env:USERPROFILE\Downloads"
$FontsFolder = "$env:USERPROFILE\fonts"

#region TurboRDP
if ($TurboRdpHw -or $TurboRdpSw) {
  Write-Host -ForegroundColor Cyan 'Applying RDP optimizations...'

  $RdpRegistryChanges = @{
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' = @{
      'SelectTransport' = 0
      'bEnumerateHWBeforeSW' = 1
      'AVC444ModePreferred' = 1
      'AVCHardwareEncodePreferred' = [int]($TurboRdpHw -and -not $TurboRdpSw)
      'MaxCompressionLevel' = 0
      'ImageQuality' = 2
      'fEnableVirtualizedGraphics' = 1
      'VGOptimization_CaptureFrameRate' = 1
      'VGOptimization_CompressionRatio' = 1
      'VisualExperiencePolicy' = 1
      'fEnableWddmDriver' = 0
    }
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\Client' = @{
      'fUsbRedirectionEnableMode' = 2
    }
    'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations' = @{
      'DWMFRAMEINTERVAL' = 15
    }
    'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' = @{
      'SystemResponsiveness' = 0
    }
    'HKLM:\SYSTEM\CurrentControlSet\Services\TermDD' = @{
      'FlowControlDisable' = 1
      'FlowControlDisplayBandwidth' = 16
      'FlowControlChannelBandwidth' = 144
      'FlowControlChargePostCompression' = 0
    }
    'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' = @{
      'InteractiveDelay' = 0
    }
    'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters' = @{
      'DisableBandwidthThrottling' = 1
      'DisableLargeMtu' = 0
    }
  }

  if ($DryRun) {
    $RdpRegistryChanges | Set-RegistryChanges -DryRun $true
  } else {
    Invoke-BlockElevated -NotifyText 'Elevation required for RDP optimizations...' -ScriptBlock {
      $RdpRegistryChanges | Set-RegistryChanges
    }
  }
}
#endregion

#region System Configuration
if ($Cfg) {
  Write-Host -ForegroundColor Cyan 'Applying system configuration...'

  $CfgScript = {
    param($Configuration, $DryRun)

    # Execution Policy
    Write-Host 'Setting execution policy to unrestricted.'
    if (-not $DryRun) {
      Set-ExecutionPolicy Unrestricted -Scope:CurrentUser -Force
      Set-ExecutionPolicy Unrestricted -Scope:LocalMachine -Force
    }

    # Remote Desktop
    Write-Host 'Enabling Remote Desktop.'
    if (-not $DryRun) {
      Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections' -Value 0
      Enable-NetFirewallRule -DisplayGroup 'Remote Desktop'
    }

    # File Sharing
    Write-Host 'Enabling file and printer sharing.'
    if (-not $DryRun) {
      Set-NetFirewallRule -DisplayGroup 'File And Printer Sharing' -Enabled True -Profile Any
      Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value 1
    }

    # Windows Defender Exclusions
    Write-Host 'Creating Windows Defender exclusions...'
    $PathExclusions = @(
      (Get-ChildItem -ErrorAction:SilentlyContinue -Path ${env:ProgramFiles(x86)} -Filter '*SDKs*'),
      (Get-ChildItem -ErrorAction:SilentlyContinue -Path ${env:ProgramFiles(x86)} -Filter '*Visual Studio*'),
      (Get-ChildItem -ErrorAction:SilentlyContinue -Path ${env:ProgramFiles(x86)} -Filter 'MSBuild'),
      (Get-ChildItem -ErrorAction:SilentlyContinue -Path "$env:ProgramFiles\Microsoft Visual Studio" -Directory | Get-ChildItem -ErrorAction:SilentlyContinue -Directory),
      (Get-ChildItem -ErrorAction:SilentlyContinue -Path $env:windir -Filter 'assembly'),
      (Get-ChildItem -ErrorAction:SilentlyContinue -Path $env:windir -Filter 'Microsoft.NET'),
      (Get-ChildItem -ErrorAction:SilentlyContinue -Path $env:LOCALAPPDATA -Filter 'Microsoft' | Get-ChildItem -ErrorAction:SilentlyContinue -Filter 'VisualStudio'),
      (Get-ChildItem -ErrorAction:SilentlyContinue -Path $env:USERPROFILE -Filter 'scoop')
    ) | ForEach-Object FullName | Where-Object { $_ }

    if ($Configuration.WindowsDefender.ProjectsFolder) {
      $PathExclusions += $Configuration.WindowsDefender.ProjectsFolder
    }

    if (-not $DryRun) {
      foreach ($Path in $PathExclusions | Where-Object { Test-Path $_ }) {
        Write-Verbose "Adding Path Exclusion: $Path"
        Add-MpPreference -ExclusionPath $Path
      }

      foreach ($Process in $Configuration.WindowsDefender.ProcessExclusions) {
        Write-Verbose "Adding Process Exclusion: $Process"
        Add-MpPreference -ExclusionProcess $Process
      }
    }

    # UAC Level 1
    Write-Host 'Setting UAC to Level 1.'
    @{
      'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' = @{
        'ConsentPromptBehaviorAdmin' = 5
        'ConsentPromptBehaviorUser' = 3
        'EnableInstallerDetection' = 1
        'EnableLUA' = 1
        'EnableVirtualization' = 1
        'PromptOnSecureDesktop' = 0
        'ValidateAdminCodeSignatures' = 0
        'FilterAdministratorToken' = 0
      }
    } | Set-RegistryChanges -DryRun $DryRun

    # Developer Mode
    Write-Host 'Enabling Developer Mode.'
    @{
      'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' = @{
        'AllowDevelopmentWithoutDevLicense' = 1
      }
    } | Set-RegistryChanges -DryRun $DryRun
  }

  if ($DryRun) {
    & $CfgScript -Configuration $Configuration -DryRun $true
  } else {
    Invoke-BlockElevated -NotifyText 'Elevation required for system configuration...' -ScriptBlock {
      & $CfgScript -Configuration $Configuration -DryRun $false
    }
  }
}
#endregion

#region Scoop
if ($Scoop) {
  Write-Host -ForegroundColor Cyan 'Installing Scoop...'

  if (-not $DryRun) {
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
      Invoke-WebRequest -useb get.scoop.sh -OutFile 'install.ps1'
      .\install.ps1 -RunAsAdmin
      Remove-Item 'install.ps1'
    }

    $ShimsPath = [IO.Path]::Combine($env:USERPROFILE, 'scoop', 'shims')
    $ModulesPath = [IO.Path]::Combine($env:USERPROFILE, 'scoop', 'modules')
    $env:Path = "$ShimsPath;$env:Path"
    $env:PSModulePath = "$ModulesPath;$env:PSModulePath"

    # Install prereqs
    scoop install @($Configuration.Scoop.Prereqs)
    scoop update
    scoop status
    scoop checkup

    # Add aliases
    foreach ($Alias in $Configuration.Scoop.Aliases.Keys) {
      $AliasValue = $Configuration.Scoop.Aliases[$Alias]
      scoop alias add $Alias $AliasValue[0] $AliasValue[1]
    }

    # Add buckets
    foreach ($Bucket in $Configuration.Scoop.Buckets) {
      if ($Bucket -is [string]) {
        scoop bucket add $Bucket
      } else {
        scoop bucket add $Bucket.name $Bucket.url
      }
    }

    # Install packages
    scoop install @($Configuration.Scoop.Packages)
  } else {
    Write-Host "[DryRun] Would install Scoop with prereqs: $($Configuration.Scoop.Prereqs -join ', ')"
    Write-Host "[DryRun] Would add buckets: $($Configuration.Scoop.Buckets | ForEach-Object { if ($_ -is [string]) { $_ } else { $_.name } } | Join-String -Separator ', ')"
    Write-Host "[DryRun] Would install packages: $($Configuration.Scoop.Packages -join ', ')"
  }
}
#endregion

#region WinGet
if ($Winget) {
  Write-Host -ForegroundColor Cyan 'Ensuring WinGet is installed...'

  if (-not $DryRun) {
    if (-not (Import-ModuleIfAvailable -Name 'Microsoft.WinGet.Client')) {
      Write-Host 'WinGet module not found. Please install the Microsoft.WinGet.Client module.'
    } else {
      Assert-WinGetPackageManager -ErrorVariable WinGetError -ErrorAction SilentlyContinue
      if ($WinGetError) {
        Write-Host 'WinGet package manager not found. Installing...'
        Repair-WinGetPackageManager -Latest -Force
      } else {
        Write-Host -ForegroundColor Green 'WinGet package manager is already installed.'
      }
    }
  } else {
    Write-Host '[DryRun] Would ensure WinGet is installed.'
  }
}

if ($WingetPkgs) {
  Write-Host -ForegroundColor Cyan 'Installing WinGet packages...'

  $DscFileName = "configuration.$($Context.ToLower()).dsc.yaml"
  $LocalDscPath = Join-Path $PSScriptRoot $DscFileName

  if (-not $DryRun) {
    try {
      $DscContent = Get-ConfigFile -FileName $DscFileName -LocalPath $LocalDscPath
      $DscConfigPath = Save-TempFile -Content $DscContent -FileName $DscFileName
      Write-Host "Applying WinGet DSC configuration..."
      winget configure --file $DscConfigPath --accept-configuration-agreements --disable-interactivity
    } catch {
      Write-Host -ForegroundColor Yellow "Could not load WinGet DSC configuration: $_"
    }

    # Dynamic packages (VS Code with custom install args)
    if (Import-ModuleIfAvailable -Name 'Microsoft.WinGet.Client') {
      Write-Host 'Installing dynamic WinGet packages...'

      $VsCodePackages = Find-WinGetPackage -Source:'winget' -Query 'Microsoft.VisualStudioCode' | Where-Object { $_.Id -notmatch '\.CLI' }
      $VsCodePackages | Select-NotInstalled | Install-WinGetPackage -Mode Silent -Override '/VERYSILENT /MERGETASKS="!runcode,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath"' -Force

      $DotNetSdkPackages = Find-WinGetPackage -Source:'winget' -Query 'Microsoft.DotNet.SDK' | Where-Object { $_.Id -notmatch '\.Preview' } | Select-Object -Last 2
      $VcRedistPackages = Find-WinGetPackage -Source:'winget' -Query 'Microsoft.VC' | Where-Object { $_.Id -notmatch '\.(x86|arm64)' } | Sort-Object -Descending -Property Id

      $DotNetSdkPackages | Select-NotInstalled | Install-WinGetPackage -Force -Mode Silent
      $VcRedistPackages | Select-NotInstalled | Install-WinGetPackage -Force -Mode Silent
    }
  } else {
    Write-Host "[DryRun] Would apply DSC config: $DscFileName"
    Write-Host '[DryRun] Would install VS Code, .NET SDKs, and VC Redistributables'
  }
}
#endregion

#region Mise
if ($Mise) {
  Write-Host -ForegroundColor Cyan 'Installing Mise tools...'
  
  $MiseGistUrl = 'https://gist.githubusercontent.com/matracey/e3febf8a83d05ae2d7ade96fd147cd20/raw/mise.toml'
  $MiseConfigDir = Join-Path $env:USERPROFILE '.config\mise'
  $MiseConfigPath = Join-Path $MiseConfigDir 'config.toml'
  
  if (-not $DryRun) {
    # Create config directory if it doesn't exist
    if (-not (Test-Path $MiseConfigDir)) {
      New-Item -ItemType Directory -Path $MiseConfigDir -Force | Out-Null
      Write-Host "Created directory: $MiseConfigDir"
    }
    
    # Download mise.toml
    try {
      Write-Host "Downloading mise config from gist..."
      Invoke-WebRequest -Uri $MiseGistUrl -OutFile $MiseConfigPath -UseBasicParsing
      Write-Host "Saved to: $MiseConfigPath"
    } catch {
      Write-Host -ForegroundColor Yellow "Failed to download mise config: $_"
    }
    
    # Run mise install
    $MisePath = Get-Command mise -ErrorAction SilentlyContinue
    if ($MisePath) {
      Write-Host "Running mise install..."
      & mise install
    } else {
      Write-Host -ForegroundColor Yellow "Mise not found. Install it first via WinGet (jdx.mise) and restart your shell."
    }
  } else {
    Write-Host "[DryRun] Would download mise config to: $MiseConfigPath"
    Write-Host "[DryRun] Would run: mise install"
  }
}
#endregion

#region Git Configuration
if ($Cfg -and (Get-Command git -ErrorAction SilentlyContinue)) {
  Write-Host -ForegroundColor Cyan 'Configuring Git...'

  if (-not $DryRun) {
    foreach ($Key in $Configuration.Git.System.Keys) {
      git config --replace-all --system $Key $Configuration.Git.System[$Key]
    }
    foreach ($Key in $Configuration.Git.Global.Keys) {
      git config --replace-all --global $Key $Configuration.Git.Global[$Key]
    }
  } else {
    Write-Host "[DryRun] Would configure Git system: $($Configuration.Git.System | ConvertTo-Json -Compress)"
    Write-Host "[DryRun] Would configure Git global: $($Configuration.Git.Global | ConvertTo-Json -Compress)"
  }
}
#endregion

#region Visual Studio
if ($VsRelease -or $VsPreview -or $VsIntPrev -or $VsBldTool) {
  Write-Host -ForegroundColor Cyan 'Installing Visual Studio...'

  if (-not $DryRun) {
    $VsConfigPath = Join-Path $env:USERPROFILE '.vsconfig'
    @{ version = '1.0'; components = $Configuration.VisualStudio.Workloads } | ConvertTo-Json | Out-File $VsConfigPath

    if (Import-ModuleIfAvailable -Name 'Microsoft.WinGet.Client') {
      $VsPackages = Find-WinGetPackage -Source:'winget' -Query 'Microsoft.VisualStudio.'
      $VsPackages | Where-Object { $_.Id -match 'ConfigFinder|Locator$' } | Install-WinGetPackage -Force

      if ($VsRelease) {
        $VsPackages | Where-Object { $_.Name -match 'Enterprise' -and $_.Name -notmatch 'Preview$' } |
          Sort-Object -Descending Version -Top 1 |
          Install-WinGetPackage -Custom "--norestart --config $VsConfigPath" -Force
      }

      if ($VsPreview) {
        $VsPackages | Where-Object { $_.Name -match 'Enterprise' -and $_.Name -match 'Preview$' } |
          Sort-Object -Descending Version -Top 1 |
          Install-WinGetPackage -Custom "--norestart --config $VsConfigPath" -Force
      }
    }

    if ($VsIntPrev) {
      $VsIntPrevPath = Join-Path $DownloadsFolder 'vs_enterprise_intpreview.exe'
      Invoke-WebRequest -Uri 'https://aka.ms/vs/17/intpreview/vs_enterprise.exe' -OutFile $VsIntPrevPath
      Start-Process $VsIntPrevPath -ArgumentList '--norestart', '-p', "--config $VsConfigPath" -NoNewWindow -Wait
      Remove-Item $VsIntPrevPath -ErrorAction SilentlyContinue
    }

    if ($VsBldTool) {
      $VsBldToolPath = Join-Path $DownloadsFolder 'vs_BuildTools.exe'
      Invoke-WebRequest -Uri 'https://download.visualstudio.microsoft.com/download/pr/0502e0d3-64a5-4bb8-b049-6bcbea5ed247/d7293c5775ad824c05ee99d071d5262da3e7653d39f3ba8a28fb2917af7c041a/vs_BuildTools.exe' -OutFile $VsBldToolPath
      Start-Process $VsBldToolPath -ArgumentList '--norestart', '-p' -NoNewWindow -Wait
      Remove-Item $VsBldToolPath -ErrorAction SilentlyContinue
    }
  } else {
    Write-Host "[DryRun] Would install Visual Studio with workloads: $($Configuration.VisualStudio.Workloads -join ', ')"
  }
}
#endregion

#region Fonts
if ($Fonts -or $GoogleFonts -or $NerdFonts) {
  Write-Host -ForegroundColor Cyan 'Setting up fonts...'

  if ($GoogleFonts -eq $false -and $NerdFonts -eq $false) {
    $GoogleFonts = $true
    $NerdFonts = $true
  }

  $FontBaseDir = [IO.Path]::Combine($env:USERPROFILE, 'FontBase')
  $GoogleFontsDir = "$FontsFolder\google-fonts"
  $NerdFontsDir = "$FontsFolder\nerd-fonts"

  if (-not $DryRun) {
    if (!(Test-Path $FontsFolder)) { New-Item -ItemType Directory $FontsFolder | Out-Null }
    if (!(Test-Path $FontBaseDir)) { New-Item -ItemType Directory $FontBaseDir | Out-Null }

    if ($GoogleFonts -and !(Test-Path $GoogleFontsDir)) {
      Write-Host 'Cloning Google Fonts...'
      git clone --depth 1 'https://github.com/google/fonts.git' $GoogleFontsDir
      Get-ChildItem $GoogleFontsDir -Directory | Where-Object { $_.Name -iin 'apache', 'ofl', 'ufl' } |
        Get-ChildItem | ForEach-Object {
          New-Item -ItemType Junction -Path "$GoogleFontsDir\all" -Name $_.Name -Value $_.FullName -Force
        }
      New-Item -ItemType Junction -Path $FontBaseDir -Name 'google-fonts' -Value "$GoogleFontsDir\all" -Force
    }

    if ($NerdFonts -and !(Test-Path $NerdFontsDir)) {
      Write-Host 'Cloning Nerd Fonts...'
      git clone --depth 1 'https://github.com/ryanoasis/nerd-fonts.git' $NerdFontsDir
      New-Item -ItemType Junction -Path $FontBaseDir -Name 'nerd-fonts' -Value "$NerdFontsDir\patched-fonts" -Force
    }
  } else {
    Write-Host "[DryRun] Would set up fonts in $FontsFolder"
    if ($GoogleFonts) { Write-Host '[DryRun] Would clone Google Fonts' }
    if ($NerdFonts) { Write-Host '[DryRun] Would clone Nerd Fonts' }
  }
}
#endregion

#endregion

#region Windows Terminal Configuration
if ($WinTerminal) {
  Write-Host -ForegroundColor Cyan 'Applying Windows Terminal settings...'

  $WtSettingsFileName = "windowsterminal.$($Context.ToLower()).json"
  $WtLocalPath = Join-Path $PSScriptRoot $WtSettingsFileName

  $WtSettingsContent = $null
  try {
    $WtSettingsContent = Get-ConfigFile -FileName $WtSettingsFileName -LocalPath $WtLocalPath
  } catch {
    Write-Host -ForegroundColor Yellow "Could not load Windows Terminal settings: $_"
  }

  if ($WtSettingsContent) {
    $WtPackageDirs = Get-ChildItem -Path "$env:LOCALAPPDATA\Packages" -Directory -Filter 'Microsoft.WindowsTerminal*' -ErrorAction SilentlyContinue

    if ($WtPackageDirs) {
      foreach ($Dir in $WtPackageDirs) {
        $LocalStateDir = Join-Path $Dir.FullName 'LocalState'
        $SettingsPath = Join-Path $LocalStateDir 'settings.json'

        if (-not (Test-Path $LocalStateDir)) {
          New-Item -ItemType Directory -Path $LocalStateDir -Force | Out-Null
        }

        if ($DryRun) {
          Write-Host -ForegroundColor DarkYellow "[DryRun] Would apply $WtSettingsFileName to $SettingsPath"
        } else {
          Write-Host "Applying $WtSettingsFileName to $($Dir.Name)..."
          $WtSettingsContent | Set-Content -Path $SettingsPath -Encoding UTF8 -Force
        }
      }
    } else {
      Write-Host -ForegroundColor Yellow 'No Windows Terminal installations detected.'
    }
  }
}
#endregion

#region Oh My Posh Configuration
if ($OhMyPosh) {
  $OmpFileName = "mojada.$($Context.ToLower()).omp.json"
  $OmpLocalPath = Join-Path $PSScriptRoot $OmpFileName
  $OmpTargetDir = Join-Path $env:USERPROFILE '.config\oh-my-posh'
  $OmpTargetPath = Join-Path $OmpTargetDir 'mojada.omp.json'

  $OmpContent = $null
  try {
    $OmpContent = Get-ConfigFile -FileName $OmpFileName -LocalPath $OmpLocalPath
  } catch {
    Write-Verbose "No Oh My Posh config for $Context context."
  }

  if ($OmpContent) {
    if ($DryRun) {
      Write-Host -ForegroundColor DarkYellow "[DryRun] Would deploy $OmpFileName to $OmpTargetPath"
    } else {
      if (-not (Test-Path $OmpTargetDir)) {
        New-Item -ItemType Directory -Path $OmpTargetDir -Force | Out-Null
      }
      Write-Host "Deploying Oh My Posh config ($OmpFileName)..."
      $OmpContent | Set-Content -Path $OmpTargetPath -Encoding UTF8 -Force
    }
  }
}
#endregion

Write-Host -ForegroundColor Green "`nProvisioning complete for $Context context!"
