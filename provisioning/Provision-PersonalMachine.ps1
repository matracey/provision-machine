param(
  [Parameter()][Switch]$Cfg,
  [Parameter()][Switch]$TurboRdpHw,
  [Parameter()][Switch]$TurboRdpSw,
  [Parameter()][Switch]$Winget,
  [Parameter()][Switch]$WingetPkgs,
  [Parameter()][Switch]$NodeJs,
  [Parameter()][Switch]$Scoop,
  [Parameter()][Switch]$VsRelease,
  [Parameter()][Switch]$VsPreview,
  [Parameter()][Switch]$VsBldTool,
  [Parameter()][Switch]$Fonts,
  [Parameter()][Switch]$GoogleFonts,
  [Parameter()][Switch]$NerdFonts,
  [Parameter()][Switch]$DryRun
)

# If no switches are passed, set the defaults
if ($Cfg -eq $false -and $TurboRdpHw -eq $false -and $TurboRdpSw -eq $false -and $Winget -eq $false -and $WingetPkgs -eq $false -and $NodeJs -eq $false -and $Scoop -eq $false -and $VsRelease -eq $false -and $VsPreview -eq $false -and $VsBldTool -eq $false -and $Fonts -eq $false) {
  $Cfg = $false
  $TurboRdpHw = $false
  $TurboRdpSw = $false
  $Winget = $false
  $WingetPkgs = $true
  $NodeJs = $true
  $Scoop = $true
  $VsRelease = $false
  $VsPreview = $true
  $VsBldTool = $false
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
  param ([scriptblock] $ScriptBlock, [string]$NotifyText = 'Restarting as administrator.')

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

function Set-ExecutionPolicyUnrestricted {
  param (
    [bool]$DryRun = $false
  )
  $CurrentUserPolicy = Get-ExecutionPolicy -Scope CurrentUser
  $LocalMachinePolicy = Get-ExecutionPolicy -Scope LocalMachine

  if ($DryRun) {
    if ($CurrentUserPolicy -ne 'Unrestricted') {
      Write-Host 'Execution policy for CurrentUser would be set to Unrestricted.'
    }
    if ($LocalMachinePolicy -ne 'Unrestricted') {
      Write-Host 'Execution policy for LocalMachine would be set to Unrestricted.'
    }
  } else {
    if ($CurrentUserPolicy -ne 'Unrestricted' -or $LocalMachinePolicy -ne 'Unrestricted') {
      Write-Host 'Setting execution policy to unrestricted.'
      Set-ExecutionPolicy Unrestricted -Scope CurrentUser
      Set-ExecutionPolicy Unrestricted
    } else {
      Write-Host 'Execution policy is already set to unrestricted.'
    }
  }
}

function Enable-RemoteDesktop {
  param (
    [bool]$DryRun = $false
  )
  $RemoteDesktopEnabled = (Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server').fDenyTSConnections -eq 0
  $FirewallRuleEnabled = (Get-NetFirewallRule -DisplayGroup 'Remote Desktop').Enabled -eq 'True'

  if ($DryRun) {
    if (-not $RemoteDesktopEnabled) {
      Write-Host 'Remote Desktop would be enabled.'
    }
    if (-not $FirewallRuleEnabled) {
      Write-Host 'Firewall rule for Remote Desktop would be enabled.'
    }
  } else {
    if (-not $RemoteDesktopEnabled) {
      Write-Host 'Enabling Remote Desktop.'
      Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections' -Value 0
    } else {
      Write-Host 'Remote Desktop is already enabled.'
    }

    if (-not $FirewallRuleEnabled) {
      Write-Host 'Enabling firewall rule for Remote Desktop.'
      Enable-NetFirewallRule -DisplayGroup 'Remote Desktop'
    } else {
      Write-Host 'Firewall rule for Remote Desktop is already enabled.'
    }
  }
}

function Enable-FileSharing {
  param (
    [bool]$DryRun = $false
  )
  $FirewallRuleEnabled = (Get-NetFirewallRule -DisplayGroup 'File And Printer Sharing').Enabled -eq 'True'
  $LongPathsEnabled = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem').LongPathsEnabled -eq 1

  if ($DryRun) {
    if (-not $FirewallRuleEnabled) {
      Write-Host 'File and printer sharing would be enabled.'
    }
    if (-not $LongPathsEnabled) {
      Write-Host 'Long paths would be enabled.'
    }
  } else {
    if (-not $FirewallRuleEnabled) {
      Write-Host 'Enabling file and printer sharing.'
      Set-NetFirewallRule -DisplayGroup 'File And Printer Sharing' -Enabled True -Profile Any
    } else {
      Write-Host 'File and printer sharing is already enabled.'
    }

    if (-not $LongPathsEnabled) {
      Write-Host 'Enabling long paths.'
      Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value 1
    } else {
      Write-Host 'Long paths are already enabled.'
    }
  }
}

function Add-WindowsDefenderExclusions {
  param (
    [Parameter(Mandatory = $false)]
    [string]$ProjectsFolder,
    [bool]$DryRun = $false
  )

  $PathExclusions = (
    'C:\Program Files (x86)\Microsoft SDKs',
    'C:\Program Files (x86)\Microsoft SDKs\NuGetPackages',
    'C:\Program Files (x86)\Microsoft Visual Studio 10.0',
    'C:\Program Files (x86)\Microsoft Visual Studio 14.0',
    'C:\Program Files (x86)\Microsoft Visual Studio',
    'C:\Program Files (x86)\MSBuild',
    'C:\Program Files\Microsoft Visual Studio\2022\Community',
    'C:\Program Files\Microsoft Visual Studio\2022\Enterprise',
    'C:\Program Files\Microsoft Visual Studio\2022\Preview',
    'C:\Program Files\Microsoft Visual Studio\2022\Professional',
    'C:\ProgramData\Microsoft\VisualStudio\Packages',
    'C:\Windows\assembly',
    'C:\Windows\Microsoft.NET',
    "$($env:LOCALAPPDATA)\Microsoft\VisualStudio",
    "$($env:LOCALAPPDATA)\Volta",
    "$($env:PROGRAMFILES)\Volta",
    "$($env:USERPROFILE)\scoop"
  )

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

  $ExclusionPaths = @($ProjectsFolder) + @($PathExclusions | Where-Object { Test-Path $_ })
  $ExistingExclusionPaths = Get-MpPreference | Select-Object -ExpandProperty ExclusionPath
  $NewExclusionPaths = Compare-Object $ExclusionPaths $ExistingExclusionPaths | Where-Object { $_.SideIndicator -eq '=>' } | Select-Object -ExpandProperty InputObject

  $ExclusionProcesses = $ProcessExclusions
  $ExistingExclusionProcesses = Get-MpPreference | Select-Object -ExpandProperty ExclusionProcess
  $NewExclusionProcesses = Compare-Object $ExclusionProcesses $ExistingExclusionProcesses | Where-Object { $_.SideIndicator -eq '=>' } | Select-Object -ExpandProperty InputObject

  if ($DryRun) {
    if ($NewExclusionPaths -or $NewExclusionProcesses) {
      Write-Host 'Windows Defender exclusions would be added for development folders and processes.'
    } else {
      Write-Host 'No new Windows Defender exclusions to add.'
    }
  } else {
    Write-Host 'Creating Windows Defender exclusions for development folders and processes.'

    if ($NewExclusionPaths) {
      Add-MpPreference -ExclusionPath $NewExclusionPaths
      Write-Host "Added exclusion paths: $($NewExclusionPaths -join ', ')"
    } else {
      Write-Host 'No new exclusion paths to add.'
    }

    if ($NewExclusionProcesses) {
      Add-MpPreference -ExclusionProcess $NewExclusionProcesses
      Write-Host "Added exclusion processes: $($NewExclusionProcesses -join ', ')"
    } else {
      Write-Host 'No new exclusion processes to add.'
    }
  }
}

function Set-UACLevel1 {
  param (
    [bool]$DryRun = $false
  )

  $GPOValues = @{
    ConsentPromptBehaviorAdmin  = 5
    ConsentPromptBehaviorUser   = 3
    EnableInstallerDetection    = 1
    EnableLUA                   = 1
    EnableVirtualization        = 1
    PromptOnSecureDesktop       = 0
    ValidateAdminCodeSignatures = 0
    FilterAdministratorToken    = 0
  }

  $CurrentValues = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'

  if ($DryRun) {
    foreach ($Property in $GPOValues.Keys) {
      $CurrentValue = $CurrentValues.$Property
      $ExpectedValue = $GPOValues.$Property
      if ($CurrentValue -ne $ExpectedValue) {
        Write-Host "Dry run: $Property would be set to $ExpectedValue."
      }
    }
  } else {
    $Changes = $false
    foreach ($Property in $GPOValues.Keys) {
      $CurrentValue = $CurrentValues.$Property
      $ExpectedValue = $GPOValues.$Property
      if ($CurrentValue -ne $ExpectedValue) {
        Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name $Property -Value $ExpectedValue
        $Changes = $true
      }
    }

    if (-not($Changes)) {
      Write-Host 'UAC is already set to Level 1.'
    }
  }
}

function Enable-DeveloperMode {
  param (
    [bool]$DryRun = $false
  )
  $DeveloperModeRegistryKeyPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'
  $DeveloperModeEnabled = (Get-ItemProperty -Path $DeveloperModeRegistryKeyPath).AllowDevelopmentWithoutDevLicense -eq 1

  if ($DryRun) {
    if (-not $DeveloperModeEnabled) {
      Write-Host 'Developer Mode would be enabled.'
    }
  } else {
    if (-not $DeveloperModeEnabled) {
      Write-Host 'Enabling Developer Mode.'
      if (-not(Test-Path -Path $DeveloperModeRegistryKeyPath)) {
        New-Item -Path $DeveloperModeRegistryKeyPath -ItemType Directory -Force
      }

      Set-ItemProperty -Path $DeveloperModeRegistryKeyPath -Name AllowDevelopmentWithoutDevLicense -Type [Microsoft.Win32.RegistryValueKind]::DWord -Value 1
    } else {
      Write-Host 'Developer Mode is already enabled.'
    }
  }
}

function Set-RdpOptimizations {
  param (
    [bool]$AvcHardwareEncodePreferred = $false,
    [bool]$DryRun = $false
  )

  $GPOValues = @{
    'Terminal Services|SelectTransport'                  = 0
    'Terminal Services|bEnumerateHWBeforeSW'             = 1
    'Terminal Services|AVC444ModePreferred'              = 1
    'Terminal Services|AVCHardwareEncodePreferred'       = [int]$AvcHardwareEncodePreferred
    'Terminal Services|MaxCompressionLevel'              = 0
    'Terminal Services|ImageQuality'                     = 2
    'Terminal Services|fEnableVirtualizedGraphics'       = 1
    'Terminal Services|VGOptimization_CaptureFrameRate'  = 1
    'Terminal Services|VGOptimization_CompressionRatio'  = 1
    'Terminal Services|VisualExperiencePolicy'           = 1
    'Terminal Services\Client|fUsbRedirectionEnableMode' = 2
  }

  $RegistryEntries = $($GPOValues.GetEnumerator() | ForEach-Object {
      $Item, $Property, $Value = $($_.Name.Split('|') + $($_.Value))
      @{
        Path  = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\$Item"
        Name  = $Property
        Value = $Value
        Type  = [Microsoft.Win32.RegistryValueKind]::DWord
      }
    }) + @(
    # Sets 60 FPS limit on RDP
    @{
      Path  = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations'
      Name  = 'DWMFRAMEINTERVAL'
      Value = 15
      Type  = [Microsoft.Win32.RegistryValueKind]::DWord
    },

    # Increase Windows Responsiveness
    @{
      Path  = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'
      Name  = 'SystemResponsiveness'
      Value = 0
      Type  = [Microsoft.Win32.RegistryValueKind]::DWord
    },

    # Sets the flow control for Display vs Channel Bandwidth (aka RemoteFX devices, including controllers)
    @{
      Path  = 'HKLM:\SYSTEM\CurrentControlSet\Services\TermDD'
      Name  = 'FlowControlDisable'
      Value = 1
      Type  = [Microsoft.Win32.RegistryValueKind]::DWord
    },

    @{
      Path  = 'HKLM:\SYSTEM\CurrentControlSet\Services\TermDD'
      Name  = 'FlowControlDisplayBandwidth'
      Value = 16
      Type  = [Microsoft.Win32.RegistryValueKind]::DWord
    },

    @{
      Path  = 'HKLM:\SYSTEM\CurrentControlSet\Services\TermDD'
      Name  = 'FlowControlChannelBandwidth'
      Value = 144
      Type  = [Microsoft.Win32.RegistryValueKind]::DWord
    },

    @{
      Path  = 'HKLM:\SYSTEM\CurrentControlSet\Services\TermDD'
      Name  = 'FlowControlChargePostCompression'
      Value = 0
      Type  = [Microsoft.Win32.RegistryValueKind]::DWord
    },

    # Removes the artificial latency delay for RDP
    @{
      Path  = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp'
      Name  = 'InteractiveDelay'
      Value = 0
      Type  = [Microsoft.Win32.RegistryValueKind]::DWord
    },

    # Disables Windows Network Throttling
    @{
      Path  = 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters'
      Name  = 'DisableBandwidthThrottling'
      Value = 1
      Type  = [Microsoft.Win32.RegistryValueKind]::DWord
    },

    # Enables large MTU packets
    @{
      Path  = 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters'
      Name  = 'DisableLargeMtu'
      Value = 0
      Type  = [Microsoft.Win32.RegistryValueKind]::DWord
    },

    # Disables the WDDM Drivers and goes back to legacy XDDM drivers (better for performance on Nvidia cards, you might want to change this setting for AMD cards)
    @{
      Path  = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
      Name  = 'fEnableWddmDriver'
      Value = 0
      Type  = [Microsoft.Win32.RegistryValueKind]::DWord
    }
  )

  $CurrentValues = $RegistryEntries | ForEach-Object {
    @{
      Path  = $_.Path
      Name  = $_.Name
      Value = (Get-ItemProperty -Path $_.Path -Name $_.Name -ErrorAction SilentlyContinue).$_.Name
      Type  = $_.Type
    }
  }

  if ($DryRun) {
    foreach ($RegistryEntry in $RegistryEntries) {
      $CurrentEntry = $CurrentValues | Where-Object { $_.Path -eq $RegistryEntry.Path -and $_.Name -eq $RegistryEntry.Name }
      if ($CurrentEntry.Value -ne $RegistryEntry.Value) {
        Write-Host "RDP optimization $($RegistryEntry.Path) would be set to $($RegistryEntry.Value)."
      }
    }
  } else {
    Write-Host 'Applying RDP optimizations...'

    Invoke-BlockElevated -NotifyText 'Elevation required to apply gp. Attempting to elevate...' -ScriptBlock {
      $LgpoTool = 'https://gist.github.com/matracey/9a4126bb243f4966a6d914c05e1fff6a/raw/5e31fdcf1b6591fb1ea376d41d5a93eca79c05f4/LGPO.zip'
      $LgpoFile = "$env:USERPROFILE\lgpo.txt"

      Remove-Item $LgpoFile -ErrorAction SilentlyContinue
      $GPOValues.GetEnumerator() | ForEach-Object {
        $Item, $Property, $Value = $($_.Name.Split('|') + $($_.Value))
        "Computer`nSoftware\Policies\Microsoft\Windows NT\$Item`n$Property`nDWORD:$Value`n" | Out-File $LgpoFile -Append
      }

      # Download the LGPO tool
      Invoke-WebRequest -Uri $LgpoTool -OutFile "$env:USERPROFILE\Downloads\LGPO.zip"

      # Unzip the LGPO tool
      Expand-Archive -Path "$env:USERPROFILE\Downloads\LGPO.zip" -DestinationPath "$env:USERPROFILE\Downloads\LGPO" -Force

      # Import the Group Policy
      & (Get-ChildItem -Path "$env:USERPROFILE\Downloads\LGPO" -Recurse -Filter 'LGPO.exe').FullName /t $LgpoFile

      # Run Set-ItemProperty on each registry entry
      $RegistryEntries | ForEach-Object {
        Set-ItemProperty -Path $_.Path -Name $_.Name -Value $_.Value -Type $_.Type -Force
      }
    }
  }
}

function Install-Winget {
  param (
    [string]$DownloadsFolder = "$env:USERPROFILE\Downloads",
    [bool]$DryRun = $false
  )

  if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host 'Winget is already installed.'
  } else {
    if ($DryRun) {
      Write-Host 'Dry run: Winget would be installed.'
    } else {
      Write-Host 'Installing winget...'
      $WingetUrl = ((((Invoke-WebRequest 'https://api.github.com/repos/microsoft/winget-cli/releases/latest') | ConvertFrom-Json).assets.browser_download_url) -match 'msix')[0]
      Invoke-WebRequest -Uri $WingetUrl -OutFile "$DownloadsFolder\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
      Add-AppPackage -Path "$DownloadsFolder\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -ForceUpdateFromAnyVersion
    }
  }
}

function Install-WingetPackages {
  param (
    [bool]$DryRun = $false
  )

  $Packages = @(
    [PSCustomObject]@{Id = 'Microsoft.VisualStudioCode'; Override = '/VERYSILENT /MERGETASKS="!runcode,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath"'; Force = $true },
    [PSCustomObject]@{Id = 'Microsoft.VisualStudioCode.Insiders'; Override = '/VERYSILENT /MERGETASKS="!runcode,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath"'; Force = $true },
    'Adobe.Acrobat.Reader.64-bit',
    'Amazon.Games',
    'ATLauncher.ATLauncher',
    'Audacity.Audacity',
    'Avidemux.Avidemux',
    'calibre.calibre',
    'ClockworkMod.UniversalADBDriver',
    'CodecGuide.K-LiteCodecPack.Full',
    'Codeusa.BorderlessGaming',
    'CPUID.CPU-Z.MSI',
    'CPUID.HWMonitor',
    'CrystalDewWorld.CrystalDiskInfo',
    'DasKeyboard.DasKeyboard',
    'DBBrowserForSQLite.DBBrowserForSQLite',
    'Discord.Discord',
    'Discord.Discord.PTB',
    'Docker.DockerDesktop',
    'DolphinEmulator.Dolphin',
    'ElectronicArts.EADesktop',
    'EmoteInteractive.RemoteMouse',
    'EpicGames.EpicGamesLauncher',
    'FelixRieseberg.MacintoshJS',
    'FelixRieseberg.Windows95',
    'File-New-Project.EarTrumpet',
    'Git.Git',
    'GitHub.cli',
    'GitHub.GitHubDesktop',
    'GitHub.GitLFS',
    'GNE.DualMonitorTools',
    'GOG.Galaxy',
    'Google.AndroidStudio',
    'Google.Chrome',
    'HandBrake.HandBrake',
    'Iterate.Cyberduck',
    'JanDeDobbeleer.OhMyPosh',
    'Lexikos.AutoHotkey',
    'Libretro.RetroArch',
    'LLVM.LLVM',
    'Logitech.GHUB',
    'M2Team.NanaZip',
    'MediaArea.MediaInfo.GUI',
    'Microsoft.Edge',
    'Microsoft.Edge.Beta',
    'Microsoft.EdgeWebView2Runtime',
    'Microsoft.GitCredentialManagerCore',
    'Microsoft.Office',
    'Microsoft.OneDrive',
    'Microsoft.OpenJDK.11',
    'Microsoft.OpenJDK.16',
    'Microsoft.OpenJDK.17',
    'Microsoft.PowerShell',
    'Microsoft.PowerToys',
    'Microsoft.RemoteDesktopClient',
    'Microsoft.WindowsTerminal.Preview',
    'MoritzBunkus.MKVToolNix',
    'Mozilla.Firefox',
    'Mp3tag.Mp3tag',
    'NordPassTeam.NordPass',
    'NordVPN.NordVPN',
    'Notepad++.Notepad++',
    'Nvidia.Broadcast',
    'Nvidia.GeForceExperience',
    'Nvidia.PhysX',
    'NZXT.CAM',
    'OBSProject.OBSStudio',
    'OpenWhisperSystems.Signal',
    'PeterPawlowski.foobar2000',
    'Plex.Plex',
    'Plex.PlexMediaServer',
    'Postman.Postman',
    'qBittorrent.qBittorrent',
    'REALiX.HWiNFO',
    'Rufus.Rufus',
    'SABnzbdTeam.SABnzbd',
    'SomePythonThings.ElevenClock',
    'SomePythonThings.WingetUIStore',
    'Spotify.Spotify',
    'tailscale.tailscale',
    'TeamProwlarr.Prowlarr',
    'TeamRadarr.Radarr',
    'TeamSonarr.Sonarr',
    'TIDALMusicAS.TIDAL',
    'Ubisoft.Connect',
    'Valve.Steam',
    'VideoLAN.VLC',
    'Volta.Volta',
    'WinDirStat.WinDirStat',
    'WinSCP.WinSCP',
    [PSCustomObject]@{Id = 'Microsoft.DotNet.SDK.7'; Force = $true },
    [PSCustomObject]@{Id = 'Microsoft.DotNet.SDK.6'; Force = $true },
    [PSCustomObject]@{Id = 'Microsoft.VCRedist.2015+.x64'; Force = $true },
    [PSCustomObject]@{Id = 'Microsoft.VCRedist.2015+.x86'; Force = $true },
    [PSCustomObject]@{Id = 'Microsoft.VCRedist.2013.x64'; Force = $true },
    [PSCustomObject]@{Id = 'Microsoft.VCRedist.2013.x86'; Force = $true },
    [PSCustomObject]@{Id = 'Microsoft.VCRedist.2012.x64'; Force = $true },
    [PSCustomObject]@{Id = 'Microsoft.VCRedist.2012.x86'; Force = $true },
    [PSCustomObject]@{Id = 'Microsoft.VCRedist.2010.x64'; Force = $true },
    [PSCustomObject]@{Id = 'Microsoft.VCRedist.2010.x86'; Force = $true },
    [PSCustomObject]@{Id = 'Microsoft.VCRedist.2008.x64'; Force = $true },
    [PSCustomObject]@{Id = 'Microsoft.VCRedist.2008.x86'; Force = $true },
    [PSCustomObject]@{Id = 'Microsoft.VCRedist.2005.x64'; Force = $true },
    [PSCustomObject]@{Id = 'Microsoft.VCRedist.2005.x86'; Force = $true },
    # Affinity Photo 2
    [PSCustomObject]@{Id = '9P8DVF1XW02V'; Source = 'msstore' },
    # Affinity Designer 2
    [PSCustomObject]@{Id = '9N2D0P16C80H'; Source = 'msstore' },
    # Affinity Publisher 2
    [PSCustomObject]@{Id = '9NTV2DZ11KD9'; Source = 'msstore' },
    # WhatsApp Beta
    [PSCustomObject]@{Id = '9NBDXK71NK08'; Source = 'msstore' }
  )

  if ($DryRun) {
    Write-Host 'Dry run: The following packages would be installed:'
    $Packages | ForEach-Object {
      if ($_ -is [string]) {
        Write-Host "- $_"
      } else {
        Write-Host "- $($_.Id)"
      }
    }
  } else {
    Write-Host 'Installing winget packages...'

    foreach ($Package in $Packages) {
      if ($Package -is [string]) {
        $Id = $Package
        $Force = $Source = $Override = ''
      } else {
        $Id = $Package.Id
        $Force = if ([bool]$Package.Force) { '--force' } else { '' }
        $Source = if ($Package.Source) { $Package.Source } else { 'winget' }
        $Override = if ($Package.Override) { "--override '$($Package.Override)'" } else { '' }
      }

      Invoke-Expression "winget install -s $Source -h --accept-package-agreements --accept-source-agreements --id=$Id -e $Force $Override"
    }
  }
}

function Install-NodeTools {
  param (
    [bool]$DryRun = $false
  )

  $NodeTools = (
    'node@18',
    'node@19',
    'npm@8',
    'eslint',
    'playwright',
    'prettier',
    'typescript'
  )

  if ($DryRun) {
    Write-Host 'Dry run: The following node tools would be installed:'
    $NodeTools | ForEach-Object {
      Write-Host "- $_"
    }
  } else {
    Write-Host 'Installing nodejs...'

    & "$env:PROGRAMFILES\Volta\volta.exe" install @NodeTools
  }
}

function Install-Scoop {
  param (
    [bool]$DryRun = $false
  )

  if (Get-Command scoop -ErrorAction SilentlyContinue) {
    Write-Host 'Scoop is already installed.'
  } else {
    if ($DryRun) {
      Write-Host 'Dry run: Scoop would be installed.'
    } else {
      Write-Host 'Installing scoop...'
      Invoke-WebRequest -useb get.scoop.sh -OutFile 'install.ps1'
      .\install.ps1 -RunAsAdmin
      Remove-Item 'install.ps1'
    }
  }
}

function Install-ScoopApps {
  param (
    [bool]$DryRun = $false
  )

  $ScoopPrereqs = (
    '7zip',
    'git',
    'innounp',
    'wixtoolset',
    'lessmsi',
    'dark'
  )

  $ScoopApps = $(
    'GameSaveManager',
    'adb',
    'android-clt',
    'dnsjumper',
    'duckstation',
    'gog-galaxy-plugin-downloader',
    'grep',
    'lessmsi',
    'mediainfo',
    'msiafterburner',
    'msikombustor',
    'pcsx2',
    'potrace',
    'sqlite',
    'xemu',
    'cacert',
    'chromedriver',
    'cru',
    'curl',
    'edgedriver',
    'ffmpeg',
    'geckodriver',
    'git-filter-repo',
    'nuget',
    'pyenv',
    'resharper-clt',
    'sudo',
    'sysinternals',
    'vim',
    'wget',
    'yt-dlp'
  )

  $ScoopBuckets = @(
    'extras',
    'games',
    @{
      'name' = 'ash258.ash258'
      'url'  = 'https://github.com/Ash258/Shovel-Ash258.git'
    },
    @{
      'name' = 'emulators'
      'url'  = 'https://github.com/hermanjustnu/scoop-emulators.git'
    }
  )

  if ($DryRun) {
    Write-Host 'Dry run: The following scoop apps would be installed:'
    $ScoopPrereqs | ForEach-Object {
      Write-Host "- $_"
    }
    $ScoopApps | ForEach-Object {
      Write-Host "- $_"
    }
    Write-Host 'The following scoop buckets would be added:'
    $ScoopBuckets | ForEach-Object {
      if ($_ -is [string]) {
        Write-Host "- $_"
      } else {
        Write-Host "- $($_.name) ($($_.url))"
      }
    }
  } else {
    Write-Host 'Installing scoop apps...'

    scoop install @ScoopPrereqs

    & "$env:USERPROFILE\scoop\apps\scoop\current\bin\scoop.ps1" config SCOOP_REPO 'https://github.com/Ash258/Scoop-Core'
    & "$env:USERPROFILE\scoop\apps\scoop\current\bin\scoop.ps1" update
    & "$env:USERPROFILE\scoop\apps\scoop\current\bin\scoop.ps1" status
    & "$env:USERPROFILE\scoop\apps\scoop\current\bin\scoop.ps1" checkup

    foreach ($bucket in $ScoopBuckets) {
      if ($bucket -is [string]) {
        & "$env:USERPROFILE\scoop\apps\scoop\current\bin\scoop.ps1" bucket add $bucket
      } else {
        & "$env:USERPROFILE\scoop\apps\scoop\current\bin\scoop.ps1" bucket add $bucket.name $bucket.url
      }
    }

    scoop install @ScoopApps
  }
}

function Set-GitConfiguration {
  param (
    [bool]$DryRun = $false
  )

  $System = @{
    'core.longpaths' = 'true'
  }

  $Global = @{
    'credential.helper' = 'manager'
  }

  if (Get-Command git -ErrorAction SilentlyContinue) {
    $existingSystem = git config --system --list | ConvertFrom-StringData
    $existingGlobal = git config --global --list | ConvertFrom-StringData
    $PendingSystem = $System.Keys | Where-Object { $null -ne $_ -and $existingSystem.ContainsKey($_) -and $existingSystem.Item($_) -ne $System.Item($_) }
    $PendingGlobal = $Global.Keys | Where-Object { $null -ne $_ -and $existingGlobal.ContainsKey($_) -and $existingGlobal.Item($_) -ne $Global.Item($_) }

    if ($PendingGlobal -or $PendingSystem) {
      if ($DryRun) {
        Write-Host 'Dry run: The following git configurations would be changed:'
        $PendingSystem | ForEach-Object { Write-Host "- $_ (system)" }
        $PendingGlobal | ForEach-Object { Write-Host "- $_ (global)" }
      } else {
        Write-Host 'Configuring git...'
        $System.GetEnumerator() | ForEach-Object { git config --system $_.Name $_.Value }
        $Global.GetEnumerator() | ForEach-Object { git config --global $_.Name $_.Value }
      }
    }
  }
}

function Install-VisualStudio {
  param (
    [Parameter(Mandatory = $false)]
    [bool]$InstallVsRelease,
    [Parameter(Mandatory = $false)]
    [bool]$InstallVsPreview,
    [Parameter(Mandatory = $false)]
    [bool]$InstallVsBldTool,
    [Parameter(Mandatory = $false)]
    [string]$DownloadsFolder = "$env:USERPROFILE\Downloads",
    [bool]$DryRun = $false
  )

  $Components = @(
    'Component.Android.SDK.MAUI',
    'Component.Microsoft.VisualStudio.LiveShare.2022',
    'Component.Microsoft.VisualStudio.RazorExtension',
    'Component.Microsoft.VisualStudio.Web.AzureFunctions',
    'Component.Microsoft.Web.LibraryManager',
    'Component.Microsoft.WebTools.BrowserLink.WebLivePreview',
    'Component.OpenJDK',
    'Component.Xamarin',
    'Component.Xamarin.RemotedSimulator',
    'Microsoft.Component.Azure.DataLake.Tools',
    'Microsoft.Component.ClickOnce',
    'Microsoft.Component.MSBuild',
    'Microsoft.ComponentGroup.Blend',
    'Microsoft.ComponentGroup.ClickOnce.Publish',
    'Microsoft.Net.Component.4.7.2.TargetingPack',
    'Microsoft.Net.Component.4.8.SDK',
    'Microsoft.Net.Component.4.8.TargetingPack',
    'Microsoft.Net.ComponentGroup.4.8.DeveloperTools',
    'Microsoft.Net.ComponentGroup.DevelopmentPrerequisites',
    'Microsoft.NetCore.Component.DevelopmentTools',
    'Microsoft.NetCore.Component.Runtime.6.0',
    'Microsoft.NetCore.Component.Runtime.7.0',
    'Microsoft.NetCore.Component.SDK',
    'Microsoft.NetCore.Component.Web',
    'Microsoft.VisualStudio.Component.AppInsights.Tools',
    'Microsoft.VisualStudio.Component.AspNet',
    'Microsoft.VisualStudio.Component.AspNet45',
    'Microsoft.VisualStudio.Component.Azure.AuthoringTools',
    'Microsoft.VisualStudio.Component.Azure.ClientLibs',
    'Microsoft.VisualStudio.Component.Azure.Compute.Emulator',
    'Microsoft.VisualStudio.Component.Azure.Powershell',
    'Microsoft.VisualStudio.Component.Azure.ResourceManager.Tools',
    'Microsoft.VisualStudio.Component.Azure.ServiceFabric.Tools',
    'Microsoft.VisualStudio.Component.Azure.Waverton',
    'Microsoft.VisualStudio.Component.Azure.Waverton.BuildTools',
    'Microsoft.VisualStudio.Component.ClassDesigner',
    'Microsoft.VisualStudio.Component.CodeMap',
    'Microsoft.VisualStudio.Component.Common.Azure.Tools',
    'Microsoft.VisualStudio.Component.CoreEditor',
    'Microsoft.VisualStudio.Component.Debugger.JustInTime',
    'Microsoft.VisualStudio.Component.DiagnosticTools',
    'Microsoft.VisualStudio.Component.DockerTools',
    'Microsoft.VisualStudio.Component.DotNetModelBuilder',
    'Microsoft.VisualStudio.Component.EntityFramework',
    'Microsoft.VisualStudio.Component.FSharp',
    'Microsoft.VisualStudio.Component.FSharp.WebTemplates',
    'Microsoft.VisualStudio.Component.GraphDocument',
    'Microsoft.VisualStudio.Component.Graphics.Tools',
    'Microsoft.VisualStudio.Component.IISExpress',
    'Microsoft.VisualStudio.Component.IntelliCode',
    'Microsoft.VisualStudio.Component.JavaScript.Diagnostics',
    'Microsoft.VisualStudio.Component.JavaScript.TypeScript',
    'Microsoft.VisualStudio.Component.MSODBC.SQL',
    'Microsoft.VisualStudio.Component.MSSQL.CMDLnUtils',
    'Microsoft.VisualStudio.Component.ManagedDesktop.Core',
    'Microsoft.VisualStudio.Component.ManagedDesktop.Prerequisites',
    'Microsoft.VisualStudio.Component.Merq',
    'Microsoft.VisualStudio.Component.MonoDebugger',
    'Microsoft.VisualStudio.Component.Node.Tools',
    'Microsoft.VisualStudio.Component.NuGet',
    'Microsoft.VisualStudio.Component.Roslyn.Compiler',
    'Microsoft.VisualStudio.Component.Roslyn.LanguageServices',
    'Microsoft.VisualStudio.Component.SQL.CLR',
    'Microsoft.VisualStudio.Component.SQL.DataSources',
    'Microsoft.VisualStudio.Component.SQL.LocalDB.Runtime',
    'Microsoft.VisualStudio.Component.SQL.SSDT',
    'Microsoft.VisualStudio.Component.TextTemplating',
    'Microsoft.VisualStudio.Component.TypeScript.TSServer',
    'Microsoft.VisualStudio.Component.VC.14.29.16.11.x86.x64',
    'Microsoft.VisualStudio.Component.VC.ASAN',
    'Microsoft.VisualStudio.Component.VC.ATL',
    'Microsoft.VisualStudio.Component.VC.CMake.Project',
    'Microsoft.VisualStudio.Component.VC.CoreIde',
    'Microsoft.VisualStudio.Component.VC.DiagnosticTools',
    'Microsoft.VisualStudio.Component.VC.Redist.14.Latest',
    'Microsoft.VisualStudio.Component.VC.TestAdapterForBoostTest',
    'Microsoft.VisualStudio.Component.VC.TestAdapterForGoogleTest',
    'Microsoft.VisualStudio.Component.VC.Tools.x86.x64',
    'Microsoft.VisualStudio.Component.Web',
    'Microsoft.VisualStudio.Component.WebDeploy',
    'Microsoft.VisualStudio.Component.Windows10SDK',
    'Microsoft.VisualStudio.Component.Windows10SDK.18362',
    'Microsoft.VisualStudio.Component.Windows10SDK.19041',
    'Microsoft.VisualStudio.Component.Windows10SDK.20348',
    'Microsoft.VisualStudio.Component.Windows11SDK.22000',
    'Microsoft.VisualStudio.Component.Windows11SDK.22621',
    'Microsoft.VisualStudio.Component.WslDebugging',
    'Microsoft.VisualStudio.ComponentGroup.ArchitectureTools.Native',
    'Microsoft.VisualStudio.ComponentGroup.Azure.CloudServices',
    'Microsoft.VisualStudio.ComponentGroup.Azure.Prerequisites',
    'Microsoft.VisualStudio.ComponentGroup.Azure.ResourceManager.Tools',
    'Microsoft.VisualStudio.ComponentGroup.AzureFunctions',
    'Microsoft.VisualStudio.ComponentGroup.MSIX.Packaging',
    'Microsoft.VisualStudio.ComponentGroup.Maui.All',
    'Microsoft.VisualStudio.ComponentGroup.Maui.Android',
    'Microsoft.VisualStudio.ComponentGroup.Maui.Blazor',
    'Microsoft.VisualStudio.ComponentGroup.Maui.MacCatalyst',
    'Microsoft.VisualStudio.ComponentGroup.Maui.Shared',
    'Microsoft.VisualStudio.ComponentGroup.Maui.Windows',
    'Microsoft.VisualStudio.ComponentGroup.Maui.iOS',
    'Microsoft.VisualStudio.ComponentGroup.NativeDesktop.Core',
    'Microsoft.VisualStudio.ComponentGroup.Web',
    'Microsoft.VisualStudio.ComponentGroup.Web.CloudTools',
    'Microsoft.VisualStudio.ComponentGroup.WebToolsExtensions',
    'Microsoft.VisualStudio.ComponentGroup.WebToolsExtensions.CMake',
    'Microsoft.VisualStudio.ComponentGroup.WebToolsExtensions.TemplateEngine',
    'Microsoft.VisualStudio.Workload.Azure',
    'Microsoft.VisualStudio.Workload.CoreEditor',
    'Microsoft.VisualStudio.Workload.Data',
    'Microsoft.VisualStudio.Workload.ManagedDesktop',
    'Microsoft.VisualStudio.Workload.NativeDesktop',
    'Microsoft.VisualStudio.Workload.NetCrossPlat',
    'Microsoft.VisualStudio.Workload.NetWeb',
    'Microsoft.VisualStudio.Workload.Node',
    'android',
    'ios',
    'maccatalyst',
    'maui.android',
    'maui.blazor',
    'maui.core',
    'maui.ios',
    'maui.maccatalyst',
    'maui.windows',
    'microsoft.net.runtime.android',
    'microsoft.net.runtime.android.aot',
    'microsoft.net.runtime.android.aot.net6',
    'microsoft.net.runtime.android.net6',
    'microsoft.net.runtime.ios',
    'microsoft.net.runtime.ios.net6',
    'microsoft.net.runtime.maccatalyst',
    'microsoft.net.runtime.maccatalyst.net6',
    'microsoft.net.runtime.mono.tooling',
    'microsoft.net.runtime.mono.tooling.net6',
    'runtimes.ios',
    'runtimes.ios.net6',
    'runtimes.maccatalyst',
    'runtimes.maccatalyst.net6',
    'runtimes.windows'
  )

  if ($DryRun) {
    if ($InstallVsRelease -or $InstallVsPreview) {
      Write-Host 'Dry run: The following components would be installed:'
      $Components | ForEach-Object {
        Write-Host "- $_"
      }
    }

    if ($InstallVsRelease) {
      Write-Host 'Dry run: Visual Studio 2022 (Release) would be installed.'
    }

    if ($InstallVsPreview) {
      Write-Host 'Dry run: Visual Studio 2022 (Preview) would be installed.'
    }

    if ($InstallVsBldTool) {
      Write-Host 'Dry run: Visual Studio 2022 Build Tools would be installed.'
    }
  } else {
    Write-Host 'Installing Visual Studio...'

    $Vs2022ReleaseUrl = 'https://c2rsetup.officeapps.live.com/c2r/downloadVS.aspx?sku=professional&channel=Release&version=VS2022'
    $Vs2022PreviewUrl = 'https://c2rsetup.officeapps.live.com/c2r/downloadVS.aspx?sku=professional&channel=Preview&version=VS2022'
    $Vs2022BldToolUrl = 'https://download.visualstudio.microsoft.com/download/pr/0502e0d3-64a5-4bb8-b049-6bcbea5ed247/d7293c5775ad824c05ee99d071d5262da3e7653d39f3ba8a28fb2917af7c041a/vs_BuildTools.exe'

    if ($InstallVsRelease -or $InstallVsPreview) {
      $VsConfigPath = Join-Path $env:USERPROFILE '.vsconfig'
      $VsInstallerArgs = @('--norestart', '-p', "--config $VsConfigPath")
  
      @{
        version    = '1.0'
        components = $Components
      } | ConvertTo-Json | Out-File $VsConfigPath
    }

    if ($InstallVsRelease) {
      $ExecutablePath = Join-Path $DownloadsFolder 'vs_installer_release.exe'
      Invoke-WebRequest -Uri $Vs2022ReleaseUrl -OutFile $ExecutablePath
      Start-Process $ExecutablePath -ArgumentList $VsInstallerArgs -NoNewWindow -Wait
    }

    if ($InstallVsPreview) {
      $ExecutablePath = Join-Path $DownloadsFolder 'vs_installer_preview.exe'
      Invoke-WebRequest -Uri $Vs2022PreviewUrl -OutFile $ExecutablePath
      Start-Process $ExecutablePath -ArgumentList $VsInstallerArgs -NoNewWindow -Wait
    }

    if ($InstallVsBldTool) {
      $ExecutablePath = Join-Path $DownloadsFolder 'vs_BuildTools.exe'
      Invoke-WebRequest -Uri $Vs2022BldToolUrl -OutFile $ExecutablePath
      Start-Process $ExecutablePath -ArgumentList '--norestart', '-p' -NoNewWindow -Wait
    }

    Remove-Item $ExecutablePath
  }
}

function Get-FontSet {
  param (
    [Parameter(Mandatory = $true)]
    [string]$RepoUrl,
    [Parameter(Mandatory = $true)]
    [string]$FontsFolder,
    [Parameter(Mandatory = $true)]
    [string]$FolderName,
    [Parameter(Mandatory = $false)]
    [scriptblock]$Filter,
    [bool]$DryRun = $false
  )

  $FontSetDestFolder = Join-Path $FontsFolder $FolderName
  $FontFilesFolder = Join-Path $FontsFolder 'files'

  if ($DryRun) {
    Write-Host "Dry run: The following font set would be fetched: $RepoUrl into $FontSetDestFolder"
  } else {
    if (-not (Test-Path $FontSetDestFolder)) {
      Remove-Item -Recurse -Force $FontSetDestFolder -ErrorAction SilentlyContinue
      git clone --depth 1 $RepoUrl $FontSetDestFolder
      Get-ChildItem -Path $FontSetDestFolder -Filter '*.ttf', '*.otf' -Recurse | Where-Object $Filter | Move-Item -Destination $FontFilesFolder
      Remove-Item -Recurse -Force $FontSetDestFolder
    }
  }
}

function Get-FontSets {
  param (
    [Parameter(Mandatory = $true)]
    [string]$FontsFolder,
    [Parameter(Mandatory = $false)]
    [bool]$GoogleFonts = $false,
    [Parameter(Mandatory = $false)]
    [bool]$NerdFonts = $false,
    [bool]$DryRun = $false
  )
  $FontFilesFolder = Join-Path $FontsFolder 'files'

  if ($GoogleFonts -eq $false -and $NerdFonts -eq $false) {
    $GoogleFonts = $true
    $NerdFonts = $true
  }
  
  if ($DryRun) {
    Write-Host 'Dry run: The following font sets would be fetched:'
    if ($GoogleFonts) {
      Write-Host '- Google Fonts'
    }
    if ($NerdFonts) {
      Write-Host '- Nerd Fonts'
    }
  } else {
    Write-Host "Downloading fonts to $FontFilesFolder..."

    if (!(Test-Path $FontFilesFolder)) {
      New-Item -Type Directory -Force $FontFilesFolder
    }

    if ($GoogleFonts -eq $true) {
      Get-FontSet -RepoUrl 'https://github.com/google/fonts.git' -FolderName 'google-fonts' -FontsFolder $FontsFolder -Filter { $_ -match '^apache\\' -or $_ -match '^ofl\\' -or $_ -match '^ufl\\' } -DryRun:$DryRun
    }

    if ($NerdFonts -eq $true) {
      Get-FontSet -RepoUrl 'https://github.com/ryanoasis/nerd-fonts.git' -FolderName 'nerd-fonts' -FontsFolder $FontsFolder -Filter { $_ -match '^patched-fonts\\' } -DryRun:$DryRun
    }
  }
}

$DownloadsFolder = "$env:USERPROFILE\Downloads"
$FontsFolder = "$env:USERPROFILE\fonts"

if ($TurboRdpHw -eq $true -or $TurboRdpSw -eq $true) {
  Set-RdpOptimizations -DryRun $DryRun -AvcHardwareEncodePreferred ($TurboRdpHw -eq $true -and $TurboRdpSw -eq $false)
}

if ($Cfg -eq $true) {
  $Script = {
    Set-ExecutionPolicyUnrestricted -DryRun $DryRun

    Enable-RemoteDesktop -DryRun $DryRun

    Enable-FileSharing -DryRun $DryRun

    Add-WindowsDefenderExclusions -DryRun $DryRun

    Set-UACLevel1 -DryRun $DryRun

    Enable-DeveloperMode -DryRun $DryRun
  }

  if (-not $DryRun) {
    Invoke-BlockElevated -NotifyText 'Elevation required to apply cfg. Attempting to elevate...' -ScriptBlock $Script
  } else {
    & $Script
  }
}

if ($Winget -eq $true) {
  Install-Winget -DryRun $DryRun
}

if ($WingetPkgs -eq $true) {
  Install-WingetPackages -DryRun $DryRun
}

if ($NodeJs -eq $true) {
  Install-NodeTools -DryRun $DryRun
}

if ($Scoop -eq $true) {
  Install-Scoop -DryRun $DryRun
  Install-ScoopApps -DryRun $DryRun
}

if ($Cfg -eq $true) {
  Set-GitConfiguration -DryRun $DryRun
}

if ($VsRelease -eq $true -or $VsPreview -eq $true -or $VsBldTool -eq $true) {
  Install-VisualStudio -DryRun $DryRun -InstallVsRelease $VsRelease -InstallVsPreview $VsPreview -InstallVsBldTool $VsBldTool -DownloadsFolder $DownloadsFolder
}

if ($Fonts -eq $true -or $GoogleFonts -eq $true -or $NerdFonts -eq $true) {
  Get-FontSets -DryRun $DryRun -FontsFolder $FontsFolder -GoogleFonts $GoogleFonts -NerdFonts $NerdFonts
}