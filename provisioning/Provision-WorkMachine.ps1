param(
  [Parameter()] [switch]$Cfg,
  [Parameter()] [switch]$Scoop,
  [Parameter()] [switch]$WinGet,
  [Parameter()] [switch]$WinGetPkgs,
  [Parameter()] [switch]$NodeJs,
  [Parameter()] [switch]$VsRelease,
  [Parameter()] [switch]$VsPreview,
  [Parameter()] [switch]$VsIntPrev,
  [Parameter()] [switch]$Fonts
)

# If no switches are passed, set the defaults
if ($Cfg -eq $false -and $Scoop -eq $false -and $WinGet -eq $false -and $WinGetPkgs -eq $false -and $NodeJs -eq $false -and $VsRelease -eq $false -and $VsPreview -eq $false -and $VsIntPrev -eq $false -and $Fonts -eq $false) {
  Write-Host -ForegroundColor Cyan 'No switches passed. Proceeding with default flags: -Scoop, -WinGetPkgs, -NodeJs, -VsPreview, -Fonts.'

  $Cfg = $false
  $Scoop = $true
  $WinGet = $false
  $WinGetPkgs = $true
  $NodeJs = $true
  $VsRelease = $false
  $VsPreview = $true
  $VsIntPrev = $false
  $Fonts = $true
}

$Downloads = "$env:USERPROFILE\Downloads"
$FontsFolder = "$env:USERPROFILE\fonts"

if ($Cfg -eq $true) {
  # Execution Policy
  Write-Host 'Setting execution policy to unrestricted.'
  Set-ExecutionPolicy Unrestricted -Scope CurrentUser
  Set-ExecutionPolicy Unrestricted

  # Remote Desktop
  Write-Host 'Enabling Remote Desktop.'
  Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections' -Value 0
  Enable-NetFirewallRule -DisplayGroup 'Remote Desktop'

  # File Sharing
  Write-Host 'Enabling file and printer sharing.'
  Set-NetFirewallRule -DisplayGroup 'File And Printer Sharing' -Enabled True -Profile Any
  Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value 1

  # Windows Defender Exceptions
  $PathExclusions = (
    'C:\Program Files (x86)\Microsoft SDKs',
    'C:\Program Files (x86)\Microsoft SDKs\NuGetPackages',
    'C:\Program Files (x86)\Microsoft Visual Studio 10.0',
    'C:\Program Files (x86)\Microsoft Visual Studio 14.0',
    'C:\Program Files (x86)\Microsoft Visual Studio',
    'C:\Program Files (x86)\MSBuild',
    'C:\Program Files\Microsoft Visual Studio\2022\Community',
    'C:\Program Files\Microsoft Visual Studio\2022\Enterprise',
    'C:\Program Files\Microsoft Visual Studio\2022\IntPreview',
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

  Write-Host 'Creating Windows Defender exclusions for common Visual Studio folders and processes.'
  $ProjectsFolder = 'C:\source'

  Write-Verbose ''
  Write-Verbose "Adding Path Exclusion: $ProjectsFolder"
  Add-MpPreference -ExclusionPath $ProjectsFolder

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
  Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'ConsentPromptBehaviorAdmin' -Value 5
  Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'ConsentPromptBehaviorUser' -Value 3
  Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'EnableInstallerDetection' -Value 1
  Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'EnableLUA' -Value 1
  Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'EnableVirtualization' -Value 1
  Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'PromptOnSecureDesktop' -Value 0
  Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'ValidateAdminCodeSignatures' -Value 0
  Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'FilterAdministratorToken' -Value 0

  # Developer Mode
  Write-Host 'Enabling Developer Mode.'
  $DeveloperModeRegistryKeyPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'
  if (-not (Test-Path -Path $DeveloperModeRegistryKeyPath)) {
    New-Item -Path $DeveloperModeRegistryKeyPath -ItemType Directory -Force
  }

  Set-ItemProperty -Path $DeveloperModeRegistryKeyPath -Name AllowDevelopmentWithoutDevLicense -Type DWord -Value 1
}

if ($Scoop -eq $true) {
  Write-Host 'Installing scoop...'
  Invoke-WebRequest -useb get.scoop.sh -OutFile 'install.ps1'
  .\install.ps1 -RunAsAdmin
  Remove-Item 'install.ps1'

  $ScoopPrereqs = (
    '7zip',
    'git',
    'innounp',
    'wixtoolset',
    'lessmsi',
    'dark'
  )

  $ScoopApps = $(
    'azure-functions-core-tools',
    'php',
    'servicebusexplorer',
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

  scoop install @ScoopPrereqs

  & "$env:USERPROFILE\scoop\apps\scoop\current\bin\scoop.ps1" config SCOOP_REPO 'https://github.com/Ash258/Scoop-Core'
  & "$env:USERPROFILE\scoop\apps\scoop\current\bin\scoop.ps1" update
  & "$env:USERPROFILE\scoop\apps\scoop\current\bin\scoop.ps1" status
  & "$env:USERPROFILE\scoop\apps\scoop\current\bin\scoop.ps1" checkup

  & "$env:USERPROFILE\scoop\apps\scoop\current\bin\scoop.ps1" install aria2

  & "$env:USERPROFILE\scoop\apps\scoop\current\bin\scoop.ps1" bucket add extras

  # Optional buckets, disabled for now.
  # & "$env:USERPROFILE\scoop\apps\scoop\current\bin\scoop.ps1" bucket add games
  # & "$env:USERPROFILE\scoop\apps\scoop\current\bin\scoop.ps1" bucket add 'ash258.ash258' 'https://github.com/Ash258/Shovel-Ash258.git'
  # & "$env:USERPROFILE\scoop\apps\scoop\current\bin\scoop.ps1" bucket add emulators 'https://github.com/hermanjustnu/scoop-emulators.git'

  scoop install @ScoopApps
}

if ($WinGet -eq $true) {
  Write-Host 'Installing WinGet...'
  $WinGetUrl = ((((Invoke-WebRequest 'https://api.github.com/repos/microsoft/winget-cli/releases/latest') | ConvertFrom-Json).assets.browser_download_url) -match 'msix')[0]
  Invoke-WebRequest -Uri $WinGetUrl -OutFile "$Downloads\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
  Add-AppPackage -Path "$Downloads\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -ForceUpdateFromAnyVersion
}

if ($WinGetPkgs -eq $true) {
  Write-Host 'Installing WinGet packages...'
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Adobe.Acrobat.Reader.64-bit -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Audacity.Audacity -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=DBBrowserForSQLite.DBBrowserForSQLite -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Discord.Discord -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=File-New-Project.EarTrumpet -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Git.Git -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=NordPassTeam.NordPass -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=NordVPN.NordVPN -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=GitHub.cli -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=GitHub.GitHubDesktop -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=GitHub.GitLFS -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=GNE.DualMonitorTools -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Google.Chrome -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Iterate.Cyberduck -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=JanDeDobbeleer.OhMyPosh -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=LLVM.LLVM -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=M2Team.NanaZip -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.AzureCLI -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.AzureDataStudio -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.AzureFunctionsCoreTools -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.AzureStorageEmulator -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.AzureStorageExplorer -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.DotNet.SDK.7 -e --force
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.DotNet.SDK.6 -e --force
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.Edge -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.Edge.Beta -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.EdgeWebView2Runtime -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.GitCredentialManagerCore -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.Office -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.OneDrive -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.OpenJDK.11 -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.OpenJDK.16 -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.OpenJDK.17 -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.PowerShell -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.PowerToys -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.RemoteDesktopClient -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.SQLServerManagementStudio -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.VCRedist.2015+.x64 -e --force
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.VCRedist.2015+.x86 -e --force
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.VCRedist.2013.x64 -e --force
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.VCRedist.2013.x86 -e --force
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.VCRedist.2012.x64 -e --force
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.VCRedist.2012.x86 -e --force
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.VCRedist.2010.x64 -e --force
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.VCRedist.2010.x86 -e --force
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.VCRedist.2008.x64 -e --force
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.VCRedist.2008.x86 -e --force
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.VCRedist.2005.x64 -e --force
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.VCRedist.2005.x86 -e --force
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.VisualStudioCode -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.VisualStudioCode.Insiders -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.WindowsTerminal -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Mozilla.Firefox -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Mp3tag.Mp3tag -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=NordPassTeam.NordPass -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=NordVPN.NordVPN -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Notepad++.Notepad++ -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=OpenWhisperSystems.Signal -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=PeterPawlowski.foobar2000 -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Postman.Postman -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Rufus.Rufus -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=SomePythonThings.WinGetUIStore -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Spotify.Spotify -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=tailscale.tailscale -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=TIDALMusicAS.TIDAL -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=VideoLAN.VLC -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Volta.Volta -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=WinDirStat.WinDirStat -e
  winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=WinSCP.WinSCP -e
  winget install -s msstore -h --accept-package-agreements --accept-source-agreements --id=9P8DVF1XW02V -e # Affinity Photo 2
  winget install -s msstore -h --accept-package-agreements --accept-source-agreements --id=9N2D0P16C80H -e # Affinity Designer 2
  winget install -s msstore -h --accept-package-agreements --accept-source-agreements --id=9NTV2DZ11KD9 -e # Affinity Publisher 2
  winget install -s msstore -h --accept-package-agreements --accept-source-agreements --id=9NBDXK71NK08 -e # WhatsApp Beta
}

if ($NodeJs -eq $true) {
  Write-Host 'Installing nodejs...'

  $NodeTools = (
    'node@18',
    'node@19',
    'npm@8',
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
  git config --system core.longpaths true
  git config --global credential.helper manager
}

if ($VsRelease -eq $true -or $VsPreview -eq $true -or $VsIntPrev -eq $true) {
  Write-Host 'Installing Visual Studio Enterprise...'
  $Vs2022ReleaseUrl = 'https://c2rsetup.officeapps.live.com/c2r/downloadVS.aspx?sku=enterprise&channel=Release&version=VS2022'
  $Vs2022PreviewUrl = 'https://c2rsetup.officeapps.live.com/c2r/downloadVS.aspx?sku=enterprise&channel=Preview&version=VS2022'
  $Vs2022IntPrevUrl = 'https://aka.ms/vs/17/intpreview/vs_enterprise.exe'

  $VsComponents = @(
    'Component.Microsoft.VisualStudio.LiveShare.2022',
    'Component.Microsoft.VisualStudio.RazorExtension',
    'Component.Microsoft.VisualStudio.Web.AzureFunctions',
    'Component.Microsoft.Web.LibraryManager',
    'Component.Microsoft.WebTools.BrowserLink.WebLivePreview',
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
    'Microsoft.VisualStudio.Component.Common.Azure.Tools',
    'Microsoft.VisualStudio.Component.CoreEditor',
    'Microsoft.VisualStudio.Component.Debugger.JustInTime',
    'Microsoft.VisualStudio.Component.Debugger.Snapshot',
    'Microsoft.VisualStudio.Component.DiagnosticTools',
    'Microsoft.VisualStudio.Component.DockerTools',
    'Microsoft.VisualStudio.Component.DotNetModelBuilder',
    'Microsoft.VisualStudio.Component.EntityFramework',
    'Microsoft.VisualStudio.Component.FSharp',
    'Microsoft.VisualStudio.Component.FSharp.WebTemplates',
    'Microsoft.VisualStudio.Component.IISExpress',
    'Microsoft.VisualStudio.Component.IntelliCode',
    'Microsoft.VisualStudio.Component.IntelliTrace.FrontEnd',
    'Microsoft.VisualStudio.Component.JavaScript.Diagnostics',
    'Microsoft.VisualStudio.Component.JavaScript.TypeScript',
    'Microsoft.VisualStudio.Component.LiveUnitTesting',
    'Microsoft.VisualStudio.Component.MSODBC.SQL',
    'Microsoft.VisualStudio.Component.MSSQL.CMDLnUtils',
    'Microsoft.VisualStudio.Component.ManagedDesktop.Core',
    'Microsoft.VisualStudio.Component.ManagedDesktop.Prerequisites',
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
    'Microsoft.VisualStudio.Component.Web',
    'Microsoft.VisualStudio.Component.WebDeploy',
    'Microsoft.VisualStudio.Component.WslDebugging',
    'Microsoft.VisualStudio.ComponentGroup.Azure.CloudServices',
    'Microsoft.VisualStudio.ComponentGroup.Azure.Prerequisites',
    'Microsoft.VisualStudio.ComponentGroup.Azure.ResourceManager.Tools',
    'Microsoft.VisualStudio.ComponentGroup.AzureFunctions',
    'Microsoft.VisualStudio.ComponentGroup.Web',
    'Microsoft.VisualStudio.ComponentGroup.Web.CloudTools',
    'Microsoft.VisualStudio.ComponentGroup.WebToolsExtensions',
    'Microsoft.VisualStudio.Workload.Azure',
    'Microsoft.VisualStudio.Workload.CoreEditor',
    'Microsoft.VisualStudio.Workload.ManagedDesktop',
    'Microsoft.VisualStudio.Workload.NetWeb',
    'Microsoft.VisualStudio.Workload.Node'
  )

  @{ version = '1.0'; components = $VsComponents } | ConvertTo-Json | Out-File "$env:USERPROFILE\.vsconfig"
}

if ($VsRelease -eq $true) {
  Invoke-WebRequest -Uri $Vs2022ReleaseUrl -OutFile "$Downloads\vs_enterprise.exe"
  Start-Process "$Downloads\vs_enterprise.exe" -ArgumentList '--norestart','-p',"--config $env:USERPROFILE\.vsconfig" -NoNewWindow -Wait
}

if ($VsPreview -eq $true) {
  Invoke-WebRequest -Uri $Vs2022PreviewUrl -OutFile "$Downloads\vs_enterprise_preview.exe"
  Start-Process "$Downloads\vs_enterprise_preview.exe" -ArgumentList '--norestart','-p',"--config $env:USERPROFILE\.vsconfig" -NoNewWindow -Wait
}

if ($VsIntPrev -eq $true) {
  Invoke-WebRequest -Uri $Vs2022IntPrevUrl -OutFile "$Downloads\vs_enterprise_intpreview.exe"
  Start-Process "$Downloads\vs_enterprise_intpreview.exe" -ArgumentList '--norestart','-p',"--config $env:USERPROFILE\.vsconfig" -NoNewWindow -Wait
}

if ($Fonts -eq $true) {
  Write-Host 'Installing fonts...'

  if (!(Test-Path $FontsFolder)) {
    mkdir "$FontsFolder"
  }

  if (!(Test-Path "$FontsFolder/files")) {
    mkdir "$FontsFolder/files"
  }

  if (!(Test-Path "$FontsFolder/google-fonts")) {
    git clone --depth 1 https://github.com/google/fonts.git "$env:USERPROFILE/fonts/google-fonts"
  }
  Get-ChildItem -Path "$FontsFolder/google-fonts" -Include *.otf,*.ttf -Recurse | Move-Item -Destination "$FontsFolder/files"


  if (!(Test-Path "$FontsFolder/nerd-fonts")) {
    git clone --depth 1 https://github.com/ryanoasis/nerd-fonts.git "$env:USERPROFILE/fonts/nerd-fonts"
  }
  Get-ChildItem -Path "$FontsFolder/nerd-fonts" -Include *.otf,*.ttf -Recurse | Move-Item -Destination "$FontsFolder/files"
}
