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

function Import-ConfigurationJson {
  param(
    [Parameter(Mandatory = $false)]
    [string]$Path = "$PSScriptRoot\Configuration.json"
  )

  return Get-Content -Path $Path -Raw | ConvertFrom-Json
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
    [Parameter(Mandatory = $true)]
    [string[]]$PathExclusions,
    [Parameter(Mandatory = $true)]
    [string[]]$ProcessExclusions,
    [Parameter(Mandatory = $false)]
    [string]$ProjectsFolder,
    [bool]$DryRun = $false
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
    [array]$Packages,
    [bool]$DryRun = $false
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
    [string[]]$NodeTools,
    [bool]$DryRun = $false
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
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string[]]
    $ScoopPrereqs,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string[]]
    $ScoopApps,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string[]]
    $ScoopBuckets,

    [bool]$DryRun = $false
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
    [Parameter(Mandatory = $false)]
    [hashtable]
    $System,
    [Parameter(Mandatory = $false)]
    [hashtable]
    $Global,
    [bool]$DryRun = $false
  )

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
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string[]]$Components,
    [Parameter(Mandatory = $false)]
    [string]$DownloadsFolder = "$env:USERPROFILE\Downloads",
    [bool]$DryRun = $false
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

$Configuration = Import-ConfigurationJson
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

    Add-WindowsDefenderExclusions -DryRun $DryRun -PathExclusions $Configuration.WindowsDefender.PathExclusions -ProcessExclusions $Configuration.WindowsDefender.ProcessExclusions -ProjectsFolder $Configuration.WindowsDefender.ProjectsFolder

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
  Install-WingetPackages -DryRun $DryRun -Packages $Configuration.Winget.Packages
}

if ($NodeJs -eq $true) {
  Install-NodeTools -DryRun $DryRun -NodeTools $Configuration.Volta.Packages
}

if ($Scoop -eq $true) {
  Install-Scoop -DryRun $DryRun
  Install-ScoopApps -DryRun $DryRun -ScoopPrereqs $Configuration.Scoop.Prereqs -ScoopApps $Configuration.Scoop.Packages -ScoopBuckets $Configuration.Scoop.Buckets
}

if ($Cfg -eq $true) {
  Set-GitConfiguration -DryRun $DryRun -System $Configuration.Git.Config.System -Global $Configuration.Git.Config.Global
}

if ($VsRelease -eq $true -or $VsPreview -eq $true -or $VsBldTool -eq $true) {
  Install-VisualStudio -DryRun $DryRun -InstallVsRelease $VsRelease -InstallVsPreview $VsPreview -InstallVsBldTool $VsBldTool -Components $Configuration.VisualStudio.Components -DownloadsFolder $DownloadsFolder
}

if ($Fonts -eq $true -or $GoogleFonts -eq $true -or $NerdFonts -eq $true) {
  Get-FontSets -DryRun $DryRun -FontsFolder $FontsFolder -GoogleFonts $GoogleFonts -NerdFonts $NerdFonts
}