param(
  [Parameter()] [switch]$Cfg,
  [Parameter()] [switch]$TurboRdpHw,
  [Parameter()] [switch]$TurboRdpSw,
  [Parameter()] [switch]$Scoop,
  [Parameter()] [switch]$WinGet,
  [Parameter()] [switch]$WinGetPkgs,
  [Parameter()] [switch]$NodeJs,
  [Parameter()] [switch]$VsRelease,
  [Parameter()] [switch]$VsPreview,
  [Parameter()] [switch]$VsIntPrev,
  [Parameter()] [switch]$Fonts,
  [Parameter()] [switch]$GoogleFonts,
  [Parameter()] [switch]$NerdFonts
)

# If no switches are passed, set the defaults
if ($Cfg -eq $false -and $TurboRdpHw -eq $false -and $TurboRdpSw -eq $false -and $Scoop -eq $false -and $WinGet -eq $false -and $WinGetPkgs -eq $false -and $NodeJs -eq $false -and $VsRelease -eq $false -and $VsPreview -eq $false -and $VsIntPrev -eq $false -and $Fonts -eq $false) {
  Write-Host -ForegroundColor Cyan 'No switches passed. Proceeding with default flags: -Scoop, -WinGetPkgs, -NodeJs, -VsPreview, -Fonts.'

  $Cfg = $false
  $TurboRdpHw = $false
  $TurboRdpSw = $false
  $Scoop = $true
  $WinGet = $false
  $WinGetPkgs = $true
  $NodeJs = $true
  $VsRelease = $false
  $VsPreview = $true
  $VsIntPrev = $false
  $Fonts = $true
  $GoogleFonts = $false
  $NerdFonts = $false
}

<#
.SYNOPSIS
Tries to run a script block with elevated permissions.

.DESCRIPTION
Tries to run a script block with elevated permissions. If the current session is already elevated, the script block is run directly. If the current session is not elevated, the script is re-run with elevated permissions.

.PARAMETER ScriptBlock
The script block to run.

.EXAMPLE
Try-RunBlockElevated { Get-ChildItem 'C:\' }

.NOTES
This function is based on the `Elevate` function from the `InvokeBuild` module:
#>
function Invoke-BlockElevated {
  param([scriptblock]$ScriptBlock,[string]$NotifyText = 'Restarting as administrator.')

  if ($IsWindows) {
    if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
      Invoke-Command -ScriptBlock $ScriptBlock
    } else {
      Write-Host $NotifyText
      Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$ScriptBlock`""
    }
  } else {
    Invoke-Command -ScriptBlock $ScriptBlock
  }
}

function Set-RegistryChanges {
<#
  .SYNOPSIS
  Sets registry keys and values based on a hashtable.

  .DESCRIPTION
  Sets registry keys and values based on a hashtable. The hashtable should have the registry key paths as keys and another hashtable as values, where the inner hashtable contains the names and values of the registry entries to set.

  .PARAMETER RegistryChanges
  A hashtable containing the registry key paths and their corresponding values. The keys of the outer hashtable are the registry key paths, and the values are hashtables containing the names and values of the registry entries to set.

  .EXAMPLE
  Set-RegistryChanges -RegistryChanges @{
    'HKLM:\SOFTWARE\MyApp' = @{
      'Setting1' = 1
      'Setting2' = 0
    }
    'HKLM:\SOFTWARE\AnotherApp' = @{
      'SettingA' = 'ValueA'
      'SettingB' = 'ValueB'
    }
  }
  #>

  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true,ValueFromPipeline = $true,HelpMessage = 'Hashtable of registry keys and values to set.')]
    [hashtable]$RegistryChanges
  )

  process {
    foreach ($Path in $RegistryChanges.Keys) {
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

function Import-ModuleIfAvailable {
<#
  .SYNOPSIS
  Imports a module if it is available and not already imported.

  .DESCRIPTION
  Imports a module if it is available and not already imported. If the module is not available, it returns $false. If the module is already imported, it returns $true.

  .PARAMETER Name
  The name of the module to import.

  .EXAMPLE
  Import-ModuleIfAvailable -Name 'MyModule'
  #>

  [CmdletBinding()]
  param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory = $true,ValueFromPipeline = $true,HelpMessage = 'Name of the module to import.')]
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

filter Select-NotInstalled {
<#
  .SYNOPSIS
  Filters out installed packages.
  
  .DESCRIPTION
  Filters out installed packages. This filter is used to select packages that are not already installed.
  
  .PARAMETER Package
  The package to check if installed.

  .EXAMPLE
  Find-WinGetPackage -Source 'winget' -Query 'Microsoft.VisualStudioCode' | Select-NotInstalled | Install-WinGetPackage -Mode Silent
  #>

  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true,ValueFromPipeline = $true,HelpMessage = 'Package to check if installed.')]
    [object]$Package
  )

  if ($null -eq (Get-WinGetPackage $Package.Id -ErrorAction:SilentlyContinue)) {
    $_
  } else {
    Write-Host -ForegroundColor DarkGray "Package $($Package.Id) is already installed."
  }
}

$Downloads = "$env:USERPROFILE\Downloads"
$FontsFolder = "$env:USERPROFILE\fonts"

if ($TurboRdpHw -eq $true -or $TurboRdpSw -eq $true) {
  Invoke-BlockElevated -NotifyText 'Elevation required to apply gp. Attempting to elevate...' -ScriptBlock {
    $RegistryChanges = @{
      'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' = @{
        'SelectTransport' = 0
        'bEnumerateHWBeforeSW' = 1
        'AVC444ModePreferred' = 1
        'AVCHardwareEncodePreferred' = [int]($TurboRdpHw -eq $true -and $TurboRdpSw -eq $false)
        'MaxCompressionLevel' = 0
        'ImageQuality' = 2
        'fEnableVirtualizedGraphics' = 1
        'VGOptimization_CaptureFrameRate' = 1
        'VGOptimization_CompressionRatio' = 1
        'VisualExperiencePolicy' = 1
        # Disables the WDDM Drivers and goes back to legacy XDDM drivers (better for performance on Nvidia cards, you might want to change this setting for AMD cards)
        'fEnableWddmDriver' = 0
      }
      'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\Client' = @{
        'fUsbRedirectionEnableMode' = 2
      }
      'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations' = @{
        # Sets 60 FPS limit on RDP
        'DWMFRAMEINTERVAL' = 15
      }
      'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' = @{
        # Increase Windows Responsiveness
        'SystemResponsiveness' = 0
      }
      'HKLM:\SYSTEM\CurrentControlSet\Services\TermDD' = @{
        # Sets the flow control for Display vs Channel Bandwidth (aka RemoteFX devices, including controllers)
        'FlowControlDisable' = 1
        'FlowControlDisplayBandwidth' = 16
        'FlowControlChannelBandwidth' = 144
        'FlowControlChargePostCompression' = 0
      }
      'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' = @{
        # Removes the artificial latency delay for RDP
        'InteractiveDelay' = 0
      }
      'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters' = @{
        # Disables Windows Network Throttling
        'DisableBandwidthThrottling' = 1
        # Enables large MTU packets
        'DisableLargeMtu' = 0
      }
      'HKLM:\System\CurrentControlSet\Control\Terminal Server' = @{
        'fDenyTSConnections' = 0
      }
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
    }

    $RegistryChanges | Set-RegistryChanges
  }
}

if ($Cfg -eq $true) {
  Invoke-BlockElevated -NotifyText 'Elevation required to apply cfg. Attempting to elevate...' -ScriptBlock {
    # Execution Policy
    Write-Host 'Setting execution policy to unrestricted.'
    Set-ExecutionPolicy Unrestricted -Scope:CurrentUser
    Set-ExecutionPolicy Unrestricted -Scope:LocalMachine

    # Remote Desktop
    Write-Host 'Enabling Remote Desktop.'
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections' -Value 0
    Enable-NetFirewallRule -DisplayGroup 'Remote Desktop'

    # File Sharing
    Write-Host 'Enabling file and printer sharing.'
    Set-NetFirewallRule -DisplayGroup 'File And Printer Sharing' -Enabled True -Profile Any
    Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value 1

    # Windows Defender Exceptions
    $PathExclusions = @(
      (Get-ChildItem -ErrorAction:SilentlyContinue -Path ${env:ProgramFiles(x86)} -Filter '*SDKs*'),
      (Get-ChildItem -ErrorAction:SilentlyContinue -Path ${env:ProgramFiles(x86)} -Filter '*SDKs*' | Get-ChildItem -ErrorAction:SilentlyContinue -Filter 'NuGetPackages'),
      (Get-ChildItem -ErrorAction:SilentlyContinue -Path ${env:ProgramFiles(x86)} -Filter '*Visual Studio*'),
      (Get-ChildItem -ErrorAction:SilentlyContinue -Path ${env:ProgramFiles(x86)} -Filter 'MSBuild'),
      (Get-ChildItem -ErrorAction:SilentlyContinue -Path "$env:ProgramFiles\Microsoft Visual Studio" -Directory | Get-ChildItem -ErrorAction:SilentlyContinue -Directory),
      (Get-ChildItem -ErrorAction:SilentlyContinue -Path $env:ProgramData | Get-Item -Filter 'Microsoft' | Get-ChildItem -ErrorAction:SilentlyContinue -Filter 'VisualStudio' | Get-ChildItem -ErrorAction:SilentlyContinue -Filter 'Packages'),
      (Get-ChildItem -ErrorAction:SilentlyContinue -Path $env:windir -Filter 'assembly'),
      (Get-ChildItem -ErrorAction:SilentlyContinue -Path $env:windir -Filter 'Microsoft.NET'),
      (Get-ChildItem -ErrorAction:SilentlyContinue -Path $env:LOCALAPPDATA -Filter 'Microsoft' | Get-ChildItem -ErrorAction:SilentlyContinue -Filter 'VisualStudio'),
      (Get-ChildItem -ErrorAction:SilentlyContinue -Path $env:LOCALAPPDATA -Filter 'Volta'),
      (Get-ChildItem -ErrorAction:SilentlyContinue -Path $env:ProgramFiles -Filter 'Volta'),
      (Get-ChildItem -ErrorAction:SilentlyContinue -Path $env:USERPROFILE -Filter 'scoop')
    ) | ForEach-Object FullName

    $ProcessExclusions = $(
      # VS
      'vshost-clr2.exe',
      'VSInitializer.exe',
      'VSIXInstaller.exe',
      'VSLaunchBrowser.exe',
      'vsn.exe',
      'VsRegEdit.exe',
      'VSWebHandler.exe',
      'VSWebLauncher.exe',
      'XDesProc.exe',
      'Blend.exe',
      'DDConfigCA.exe',
      'devenv.exe',
      'FeedbackCollector.exe',
      'Microsoft.VisualStudio.Web.Host.exe',
      'mspdbsrv.exe',
      'MSTest.exe',
      'PerfWatson2.exe',
      'Publicize.exe',
      'QTAgent.exe',
      'QTAgent_35.exe',
      'QTAgent_40.exe',
      'QTAgent32.exe',
      'QTAgent32_35.exe',
      'QTAgent32_40.exe',
      'QTDCAgent.exe',
      'QTDCAgent32.exe',
      'StorePID.exe',
      'T4VSHostProcess.exe',
      'TailoredDeploy.exe',
      'TCM.exe',
      'TextTransform.exe',
      'TfsLabConfig.exe',
      'UserControlTestContainer.exe',
      'vb7to8.exe',
      'VcxprojReader.exe',
      'VsDebugWERHelper.exe',
      'VSFinalizer.exe',
      'VsGa.exe',
      'VSHiveStub.exe',
      'vshost.exe',
      'vshost32.exe',
      'vshost32-clr2.exe',

      # VS Code
      'Code - Insiders.exe',
      'Code.exe',

      # Runtimes, build tools
      'dotnet.exe',
      'mono.exe',
      'mono-sgen.exe',
      'java.exe',
      'java64.exe',
      'msbuild.exe',
      'volta.exe',
      'node.exe',
      'node.js',
      'perfwatson2.exe',
      'ServiceHub.Host.Node.x86.exe',
      'vbcscompiler.exe',
      'nuget.exe',

      # VCS
      'git.exe',

      # Shells
      'git-bash.exe',
      'bash.exe',
      'powershell.exe',
      'pwsh.exe',
      'wsl.exe'
    )

    Write-Host 'Creating Windows Defender exclusions for common Visual Studio folders and processes.'

    Write-Verbose ''
    (
      (Get-ChildItem $env:USERPROFILE -Filter 'source' -ErrorAction:SilentlyContinue | ForEach-Object FullName) +
      (Get-Item 'C:\source' -ErrorAction:SilentlyContinue | ForEach-Object FullName) +
      ([IO.DriveInfo]::GetDrives() | Where-Object { $_.DriveFormat -eq 'ReFS' } | ForEach-Object RootDirectory | ForEach-Object FullName)
    ) | ForEach-Object {
      Write-Verbose "Adding Path Exclusion: $_"
      Add-MpPreference -ExclusionPath $_
    }

    foreach ($Exclusion in $PathExclusions | Where-Object { Test-Path $_ }) {
      Write-Verbose "Adding Path Exclusion: $Exclusion"
      Add-MpPreference -ExclusionPath $Exclusion
    }

    foreach ($Exclusion in $ProcessExclusions) {
      Write-Verbose "Adding Process Exclusion: $Exclusion"
      Add-MpPreference -ExclusionProcess $Exclusion
    }

    Write-Host ''
    Write-Host 'Windows Defender Exclusions:'

    $Prefs = Get-MpPreference
    $Prefs.ExclusionPath
    $Prefs.ExclusionProcess
    Write-Host ''
    Write-Host ''

    # UAC Settings to Level 1
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
    } | Set-RegistryChanges

    # Developer Mode
    Write-Host 'Enabling Developer Mode.'

    @{ 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' = @{ 'AllowDevelopmentWithoutDevLicense' = 1 } } | Set-RegistryChanges
  }
}

if ($Scoop -eq $true) {
  Write-Host 'Installing scoop...'
  Invoke-WebRequest -useb get.scoop.sh -OutFile 'install.ps1'
  .\install.ps1 -RunAsAdmin
  Remove-Item 'install.ps1'

  $ShimsPath = [IO.Path]::Combine($env:USERPROFILE,'scoop','shims')
  $ModulesPath = [IO.Path]::Combine($env:USERPROFILE,'scoop','modules')

  # Manually update path for this session so that scoop can be used immediately
  $env:Path = "$ShimsPath;$env:Path"
  $env:PSModulePath = "$ModulesPath;$env:PSModulePath"

  $ScoopPrereqs = '7zip',
  'git',
  'innounp',
  'wixtoolset',
  'lessmsi',
  'dark',
  'aria2'

  scoop install @ScoopPrereqs
  scoop update
  scoop status
  scoop checkup

  $Aliases = @{
    'upgrade' = @('scoop update; scoop update *;','Updates Scoop and all installed apps')
    'reinstall' = @('scoop uninstall ; scoop install ;','Uninstall and then reinstall an app')
    'clean' = @('scoop cleanup *; scoop cache rm *;','Clean up all the caches and remove all the old versions of the installed apps')
  }

  $Aliases.GetEnumerator() | ForEach-Object { scoop alias add $_.Key $_.Value[0] $_.Value[1] }

  $Buckets = @{
    'sysinternals' = 'https://github.com/niheaven/scoop-sysinternals'
    'knox-scoop' = 'https://github.com/KNOXDEV/knox-scoop'
    'matracey' = 'https://github.com/matracey/scoop-bucket'
    'main' = 'https://github.com/ScoopInstaller/Main.git'
    'extras' = 'https://github.com/ScoopInstaller/Extras'
  }

  $Buckets.GetEnumerator() | ForEach-Object { scoop bucket add $_.Key $_.Value }

  $ScoopApps = @(
    'main/1password-cli',
    'main/7zip',
    'main/aria2',
    'main/azure-functions-core-tools',
    'main/cacert',
    'main/chromedriver',
    'main/coreutils',
    'main/curl',
    'main/dark',
    'main/edgedriver',
    'main/ffmpeg',
    'main/fzf',
    'main/geckodriver',
    'main/gig',
    'main/git',
    'main/go',
    'main/grep',
    'main/gsudo',
    'main/innounp',
    'main/lessmsi',
    'main/pester',
    'main/php',
    'main/pipx',
    'main/powershell-beautifier',
    'main/pyenv',
    'main/resharper-clt',
    'main/rustup-msvc',
    'main/scoop-search',
    'main/vim',
    'main/vimtutor',
    'main/wget',
    'main/winget-ps',
    'main/wixtoolset',
    'main/yt-dlp',
    'extras/cru',
    'extras/git-credential-manager',
    'extras/scoop-completion',
    'extras/servicebusexplorer',
    'extras/sysinternals',
    'matracey/clickpaste',
    'matracey/microsoft-graph-applications',
    'matracey/microsoft-graph-authentication',
    'matracey/microsoft-graph-backuprestore',
    'matracey/microsoft-graph-bookings',
    'matracey/microsoft-graph-calendar',
    'matracey/microsoft-graph-changenotifications',
    'matracey/microsoft-graph-cloudcommunications',
    'matracey/microsoft-graph-compliance',
    'matracey/microsoft-graph-crossdeviceexperiences',
    'matracey/microsoft-graph-devicemanagement-administration',
    'matracey/microsoft-graph-devicemanagement-enrollment',
    'matracey/microsoft-graph-devicemanagement-functions',
    'matracey/microsoft-graph-devicemanagement',
    'matracey/microsoft-graph-devices-cloudprint',
    'matracey/microsoft-graph-devices-corporatemanagement',
    'matracey/microsoft-graph-devices-serviceannouncement',
    'matracey/microsoft-graph-directoryobjects',
    'matracey/microsoft-graph-education',
    'matracey/microsoft-graph-files',
    'matracey/microsoft-graph-groups',
    'matracey/microsoft-graph-identity-directorymanagement',
    'matracey/microsoft-graph-identity-governance',
    'matracey/microsoft-graph-identity-partner',
    'matracey/microsoft-graph-identity-signins',
    'matracey/microsoft-graph-mail',
    'matracey/microsoft-graph-notes',
    'matracey/microsoft-graph-people',
    'matracey/microsoft-graph-personalcontacts',
    'matracey/microsoft-graph-planner',
    'matracey/microsoft-graph-reports',
    'matracey/microsoft-graph-schemaextensions',
    'matracey/microsoft-graph-search',
    'matracey/microsoft-graph-security',
    'matracey/microsoft-graph-sites',
    'matracey/microsoft-graph-teams',
    'matracey/microsoft-graph-users-actions',
    'matracey/microsoft-graph-users-functions',
    'matracey/microsoft-graph-users',
    'matracey/microsoft-graph'
  )

  scoop install @ScoopApps
}

if ($WinGet -eq $true) {
  if (-not (Import-ModuleIfAvailable -Name 'Microsoft.WinGet.Client')) {
    Write-Host 'WinGet module not found. Please install the ps-winget module to install WinGet.'
  } else {
    Assert-WinGetPackageManager -ErrorVariable WinGetError -ErrorAction SilentlyContinue
    if ($WinGetError) {
      Write-Host 'WinGet package manager not found. Installing...'
      Repair-WinGetPackageManager -Latest -Force
    } else {
      Write-Host -ForegroundColor Green 'WinGet package manager is already installed.'
    }
  }
}

if ($WinGetPkgs -eq $true) {
  # Static packages (Microsoft, third-party, Store) are declared in configuration.dsc.yaml
  $DscConfigPath = Join-Path $PSScriptRoot 'configuration.dsc.yaml'
  if (Test-Path $DscConfigPath) {
    Write-Host 'Applying WinGet DSC configuration for static packages...'
    winget configure --file $DscConfigPath --accept-configuration-agreements --disable-interactivity
  } else {
    Write-Host -ForegroundColor Yellow "WinGet DSC configuration not found at $DscConfigPath. Skipping static packages."
  }

  # Dynamic packages require version filtering or search-based resolution and cannot be expressed in DSC
  if (-not (Import-ModuleIfAvailable -Name 'Microsoft.WinGet.Client')) {
    Write-Host 'Microsoft.WinGet.Client module not found. Skipping dynamic WinGet packages.'
  } else {
    Write-Host 'Installing dynamic WinGet packages...'

    # VS Code needs custom installer override args not supported by WinGet DSC
    $VisualStudioCodePackages = Find-WinGetPackage -Source:'winget' -Query 'Microsoft.VisualStudioCode' | Where-Object { $_.Id -notmatch '\.CLI' }

    $MicrosoftPackagesForced = (Find-WinGetPackage -Source:'winget' -Query 'Microsoft.DotNet.SDK' | Where-Object { $_.Id -notmatch '\.Preview' } | Select-Object -Last 2) +
    (Find-WinGetPackage -Source:'winget' -Query 'Microsoft.DotNet.Runtime' | Where-Object { $_.Id -notmatch '\.Preview' } | Sort-Object -Descending -Property Id | Select-Object -Skip 2) +
    (Find-WinGetPackage -Source:'winget' -Query 'Microsoft.VC' | Where-Object { $_.Id -notmatch '\.(x86|arm64)' } | Sort-Object -Descending -Property Id)

    $MicrosoftPackages = (Find-WinGetPackage -Source:'winget' -Query 'Microsoft.OpenJDK') +
    (Find-WinGetPackage -Source:'winget' -Query 'Microsoft.UI.Xaml') +
    (Find-WinGetPackage -Source:'winget' -Query 'Microsoft.WindowsSDK' | Sort-Object -Descending Version | Select-Object -First 1)

    $VisualStudioCodePackages | Select-NotInstalled | Install-WinGetPackage -Mode Silent -Override '/VERYSILENT /MERGETASKS="!runcode,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath"' -Force
    $MicrosoftPackagesForced | Select-NotInstalled | Install-WinGetPackage -Force -Mode Silent
    $MicrosoftPackages | Select-NotInstalled | Install-WinGetPackage -Mode Silent
  }
}

if ($NodeJs -eq $true) {
  Write-Host 'Installing nodejs...'

  $NodeTools = (
    'node@lts',
    'node@latest',
    'npm@latest',
    '@angular/cli',
    'eslint',
    'playwright',
    'prettier',
    'typescript',
    'vsts-npm-auth'
  )

  & "$env:PROGRAMFILES\Volta\volta.exe" install @NodeTools
}

if ($Cfg -eq $true -and (Get-Command git -ErrorAction SilentlyContinue)) {
  Write-Host 'Configuring git...'
  git config --replace-all --system core.longpaths true
  git config --replace-all --global credential.helper manager
}

if ($VsRelease -eq $true -or $VsPreview -eq $true -or $VsIntPrev -eq $true) {
  Write-Host 'Installing Visual Studio Enterprise...'

  $VsWorkloads = @(
    'Microsoft.VisualStudio.Workload.CoreEditor',
    'Microsoft.VisualStudio.Workload.Azure',
    'Microsoft.VisualStudio.Workload.Data',
    # 'Microsoft.VisualStudio.Workload.DataScience',
    'Microsoft.VisualStudio.Workload.ManagedDesktop',
    # 'Microsoft.VisualStudio.Workload.ManagedGame',
    # 'Microsoft.VisualStudio.Workload.NativeCrossPlat',
    'Microsoft.VisualStudio.Workload.NativeDesktop',
    # 'Microsoft.VisualStudio.Workload.NativeGame',
    # 'Microsoft.VisualStudio.Workload.NativeMobile',
    'Microsoft.VisualStudio.Workload.NetCrossPlat',
    'Microsoft.VisualStudio.Workload.NetWeb',
    'Microsoft.VisualStudio.Workload.Node'
    # 'Microsoft.VisualStudio.Workload.Office',
    # 'Microsoft.VisualStudio.Workload.Python',
    # 'Microsoft.VisualStudio.Workload.Universal',
    # 'Microsoft.VisualStudio.Workload.VisualStudioExtension'
  )

  @{ version = '1.0'; components = $VsWorkloads } | ConvertTo-Json | Out-File "$env:USERPROFILE\.vsconfig"

  $VsPackages = Find-WinGetPackage -Source:'winget' -Query 'Microsoft.VisualStudio.'

  $VsPackages | Where-Object { $_.Id -match 'ConfigFinder|Locator$' } | Install-WinGetPackage -Force

  if ($VsRelease -eq $true) {
    $VsPackages | Where-Object { $_.Name -match 'Enterprise' -and $_.Name -notmatch 'Preview$' } `
       | Sort-Object -Descending Version -Top 1 `
       | Install-WinGetPackage -Custom "--norestart --config $env:USERPROFILE\.vsconfig" -Force
  }

  if ($VsPreview -eq $true) {
    $VsPackages | Where-Object { $_.Name -match 'Enterprise' -and $_.Name -match 'Preview$' } `
       | Sort-Object -Descending Version -Top 1 `
       | Install-WinGetPackage -Custom "--norestart --config $env:USERPROFILE\.vsconfig" -Force
  }

  if ($VsIntPrev -eq $true) {
    Invoke-WebRequest -Uri 'https://aka.ms/vs/17/intpreview/vs_enterprise.exe' -OutFile "$Downloads\vs_enterprise_intpreview.exe"
    Start-Process "$Downloads\vs_enterprise_intpreview.exe" -ArgumentList '--norestart','-p',"--config $env:USERPROFILE\.vsconfig" -NoNewWindow -Wait
  }
}

if ($Fonts -eq $true -or $GoogleFonts -eq $true -or $NerdFonts -eq $true) {
  Write-Host "Downloading fonts to $FontsFolder/files..."

  if ($GoogleFonts -eq $false -and $NerdFonts -eq $false) {
    $GoogleFonts = $true
    $NerdFonts = $true
  }

  $FontBaseDir = [IO.Path]::Combine($env:USERPROFILE,'FontBase')
  $GoogleFontsDir = "$FontsFolder/google-fonts"
  $NerdFontsDir = "$FontsFolder/nerd-fonts"

  if (!(Test-Path $FontsFolder)) {
    New-Item -ItemType Directory $FontsFolder
  }

  if (!(Test-Path $FontBaseDir)) {
    New-Item -ItemType Directory $FontBaseDir
  }

  if ($GoogleFonts -eq $true -and !(Test-Path $GoogleFontsDir)) {
    Remove-Item -Recurse -Force $GoogleFontsDir -ErrorAction SilentlyContinue
    git clone --depth 1 'https://github.com/google/fonts.git' $GoogleFontsDir
    Get-ChildItem $GoogleFontsDir -Directory | Where-Object { $_.Name -iin 'apache','ofl','ufl' } | Get-ChildItem | ForEach-Object { New-Item -ItemType Junction -Path "$GoogleFontsDir/all" -Name $_.Name -Value $_.FullName -Force }
    New-Item -ItemType Junction -Path $FontBaseDir -Name 'google-fonts' -Value "$GoogleFontsDir/all"
  }

  if ($NerdFonts -eq $true -and !(Test-Path $NerdFontsDir)) {
    Remove-Item -Recurse -Force $NerdFontsDir -ErrorAction SilentlyContinue
    git clone --depth 1 'https://github.com/ryanoasis/nerd-fonts.git' $NerdFontsDir
    New-Item -ItemType Junction -Path $FontBaseDir -Name 'nerd-fonts' -Value "$NerdFontsDir/patched-fonts"
  }
}
