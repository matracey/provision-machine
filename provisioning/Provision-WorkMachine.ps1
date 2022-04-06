Set-ExecutionPolicy Unrestricted -Scope CurrentUser
Set-ExecutionPolicy Unrestricted

@'
{
    "version": "1.0",
    "components": [
      "Microsoft.VisualStudio.Component.NuGet",
      "Microsoft.VisualStudio.Component.Roslyn.Compiler",
      "Microsoft.Component.MSBuild",
      "Microsoft.NetCore.Component.Runtime.6.0",
      "Microsoft.NetCore.Component.SDK",
      "Microsoft.Net.Component.4.7.2.TargetingPack",
      "Microsoft.VisualStudio.Component.Roslyn.LanguageServices",
      "Microsoft.VisualStudio.Component.FSharp",
      "Microsoft.ComponentGroup.ClickOnce.Publish",
      "Microsoft.NetCore.Component.DevelopmentTools",
      "Microsoft.VisualStudio.Component.MSODBC.SQL",
      "Microsoft.VisualStudio.Component.MSSQL.CMDLnUtils",
      "Microsoft.VisualStudio.Component.SQL.LocalDB.Runtime",
      "Microsoft.VisualStudio.Component.SQL.CLR",
      "Microsoft.VisualStudio.Component.CoreEditor",
      "Microsoft.VisualStudio.Workload.CoreEditor",
      "Microsoft.Net.Component.4.8.SDK",
      "Microsoft.Net.ComponentGroup.DevelopmentPrerequisites",
      "Microsoft.VisualStudio.Component.TypeScript.TSServer",
      "Microsoft.VisualStudio.ComponentGroup.WebToolsExtensions",
      "Microsoft.VisualStudio.Component.JavaScript.TypeScript",
      "Microsoft.VisualStudio.Component.JavaScript.Diagnostics",
      "Microsoft.VisualStudio.Component.TextTemplating",
      "Component.Microsoft.VisualStudio.RazorExtension",
      "Microsoft.VisualStudio.Component.IISExpress",
      "Microsoft.VisualStudio.Component.Common.Azure.Tools",
      "Microsoft.Component.ClickOnce",
      "Microsoft.VisualStudio.Component.ManagedDesktop.Core",
      "Microsoft.VisualStudio.Component.SQL.SSDT",
      "Microsoft.VisualStudio.Component.SQL.DataSources",
      "Component.Microsoft.Web.LibraryManager",
      "Component.Microsoft.WebTools.BrowserLink.WebLivePreview",
      "Microsoft.VisualStudio.ComponentGroup.Web",
      "Microsoft.VisualStudio.Component.FSharp.WebTemplates",
      "Microsoft.VisualStudio.Component.DockerTools",
      "Microsoft.NetCore.Component.Web",
      "Microsoft.VisualStudio.Component.WebDeploy",
      "Microsoft.VisualStudio.Component.AppInsights.Tools",
      "Microsoft.VisualStudio.Component.Web",
      "Microsoft.Net.Component.4.8.TargetingPack",
      "Microsoft.Net.ComponentGroup.4.8.DeveloperTools",
      "Microsoft.VisualStudio.Component.AspNet45",
      "Microsoft.VisualStudio.Component.AspNet",
      "Component.Microsoft.VisualStudio.Web.AzureFunctions",
      "Microsoft.VisualStudio.ComponentGroup.AzureFunctions",
      "Microsoft.VisualStudio.Component.Debugger.Snapshot",
      "Microsoft.VisualStudio.ComponentGroup.Web.CloudTools",
      "Microsoft.VisualStudio.Component.IntelliTrace.FrontEnd",
      "Microsoft.VisualStudio.Component.DiagnosticTools",
      "Microsoft.VisualStudio.Component.EntityFramework",
      "Microsoft.VisualStudio.Component.LiveUnitTesting",
      "Microsoft.VisualStudio.Component.Debugger.JustInTime",
      "Component.Microsoft.VisualStudio.LiveShare.2022",
      "Microsoft.VisualStudio.Component.WslDebugging",
      "Microsoft.VisualStudio.Component.IntelliCode",
      "Microsoft.VisualStudio.Workload.NetWeb",
      "Microsoft.VisualStudio.Component.Azure.ClientLibs",
      "Microsoft.VisualStudio.ComponentGroup.Azure.Prerequisites",
      "Microsoft.Component.Azure.DataLake.Tools",
      "Microsoft.VisualStudio.Component.Azure.ResourceManager.Tools",
      "Microsoft.VisualStudio.ComponentGroup.Azure.ResourceManager.Tools",
      "Microsoft.VisualStudio.Component.Azure.AuthoringTools",
      "Microsoft.VisualStudio.Component.Azure.Waverton.BuildTools",
      "Microsoft.VisualStudio.Component.Azure.Compute.Emulator",
      "Microsoft.VisualStudio.Component.Azure.Waverton",
      "Microsoft.VisualStudio.ComponentGroup.Azure.CloudServices",
      "Microsoft.VisualStudio.Component.Azure.ServiceFabric.Tools",
      "Microsoft.VisualStudio.Component.Azure.Powershell",
      "Microsoft.VisualStudio.Workload.Azure",
      "Microsoft.VisualStudio.Component.Node.Tools",
      "Microsoft.VisualStudio.Workload.Node",
      "Microsoft.VisualStudio.Component.ManagedDesktop.Prerequisites",
      "Microsoft.ComponentGroup.Blend",
      "Microsoft.VisualStudio.Component.DotNetModelBuilder",
      "Microsoft.VisualStudio.Workload.ManagedDesktop"
    ]
  }
'@ | Out-File "$env:USERPROFILE\.vsconfig"
$Downloads = "$env:USERPROFILE\Downloads"
$Fonts = "$env:USERPROFILE/fonts"
$Vs2022Url = 'https://c2rsetup.officeapps.live.com/c2r/downloadVS.aspx?sku=enterprise&channel=Release&version=VS2022'
$Vs2022PreviewUrl = 'https://c2rsetup.officeapps.live.com/c2r/downloadVS.aspx?sku=enterprise&channel=Preview&version=VS2022'

Write-Host 'Installing Visual Studio...'
Invoke-WebRequest -Uri $Vs2022Url -OutFile "$Downloads\vs_enterprise.exe"
Invoke-WebRequest -Uri $Vs2022PreviewUrl -OutFile "$Downloads\vs_enterprise_preview.exe"

Start-Process "$Downloads\vs_enterprise.exe" -ArgumentList '--norestart','-p',"--config $env:USERPROFILE\.vsconfig" -NoNewWindow -Wait
Start-Process "$Downloads\vs_enterprise_preview.exe" -ArgumentList '--norestart','-p',"--config $env:USERPROFILE\.vsconfig" -NoNewWindow -Wait

Write-Host 'Installing WinGet...'
$WinGetUrl = ((((Invoke-WebRequest 'https://api.github.com/repos/microsoft/winget-cli/releases/latest') | ConvertFrom-Json).assets.browser_download_url) -match 'msix')[0]
Invoke-WebRequest -Uri $WinGetUrl -OutFile "$Downloads\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
Add-AppPackage -Path "$Downloads\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -ForceUpdateFromAnyVersion

Write-Host 'Installing WinGet packages...'
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=7zip.7zip -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Adobe.Acrobat.Reader.64-bit -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Audacity.Audacity -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=DBBrowserForSQLite.DBBrowserForSQLite -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Discord.Discord -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=ExpressVPN.ExpressVPN -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=File-New-Project.EarTrumpet -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Git.Git -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=GitHub.cli -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=GitHub.GitHubDesktop -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=GitHub.GitLFS -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=GNE.DualMonitorTools -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Google.Chrome -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Google.ChromeRemoteDesktop -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Iterate.Cyberduck -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=JanDeDobbeleer.OhMyPosh -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=LLVM.LLVM -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.AzureCLI -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.AzureDataStudio -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.AzureFunctionsCoreTools -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.AzureStorageEmulator -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.AzureStorageExplorer -e
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
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.VC++2005Redist-x64 -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.VC++2005Redist-x86 -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.VC++2008Redist-x64 -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.VC++2008Redist-x86 -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.VC++2010Redist-x64 -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.VC++2010Redist-x86 -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.VC++2012Redist-x64 -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.VC++2012Redist-x86 -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.VC++2013Redist-x64 -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.VC++2013Redist-x86 -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.VC++2015-2022Redist-x64 -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.VC++2015-2022Redist-x86 -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.VisualStudioCode -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.VisualStudioCode.Insiders -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Microsoft.WindowsTerminal -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Mozilla.Firefox -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Mp3tag.Mp3tag -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Notepad++.Notepad++ -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=OpenWhisperSystems.Signal -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Postman.Postman -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Rufus.Rufus -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=TIDALMusicAS.TIDAL -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=VideoLAN.VLC -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=Volta.Volta -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=WhatsApp.WhatsApp -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=WinDirStat.WinDirStat -e
winget install -s winget -h --accept-package-agreements --accept-source-agreements --id=WinSCP.WinSCP -e

Write-Host 'Installing nodejs...'
& "$env:PROGRAMFILES\Volta\volta.exe" install node@17 node@16 npm@7 @angular/cli eslint playwright prettier typescript vsts-npm-auth

Write-Host 'Installing scoop...'
Invoke-WebRequest -useb get.scoop.sh -OutFile 'install.ps1'
.\install.ps1 -RunAsAdmin
Remove-Item 'install.ps1'

& "$env:USERPROFILE\scoop\apps\scoop\current\bin\scoop.ps1" install aria2

& "$env:USERPROFILE\scoop\apps\scoop\current\bin\scoop.ps1" bucket add dorado https://github.com/chawyehsu/dorado
& "$env:USERPROFILE\scoop\apps\scoop\current\bin\scoop.ps1" bucket add extras
& "$env:USERPROFILE\scoop\apps\scoop\current\bin\scoop.ps1" bucket add games
& "$env:USERPROFILE\scoop\apps\scoop\current\bin\scoop.ps1" bucket add main
& "$env:USERPROFILE\scoop\apps\scoop\current\bin\scoop.ps1" bucket add nerd-fonts
& "$env:USERPROFILE\scoop\apps\scoop\current\bin\scoop.ps1" bucket add nonportable
& "$env:USERPROFILE\scoop\apps\scoop\current\bin\scoop.ps1" bucket add versions

& "$env:USERPROFILE\scoop\apps\scoop\current\bin\scoop.ps1" install azure-functions-core-tools cacert chromedriver cru curl edgedriver ffmpeg geckodriver git-filter-repo nuget pyenv php resharper-clt servicebusexplorer sudo vim wget youtube-dl

Write-Host 'Installing fonts...'

if (!(Test-Path $Fonts)) {
  mkdir "$Fonts"
}

if (!(Test-Path "$Fonts/files")) {
  mkdir "$Fonts/files"
}

if (!(Test-Path "$Fonts/google-fonts")) {
  git clone --depth 1 https://github.com/google/fonts.git "$env:USERPROFILE/fonts/google-fonts"
}
Get-ChildItem -Path "$Fonts/google-fonts" -Include *.otf,*.ttf -Recurse | Move-Item -Destination "$Fonts/files"


if (!(Test-Path "$Fonts/nerd-fonts")) {
  git clone --depth 1 https://github.com/ryanoasis/nerd-fonts.git "$env:USERPROFILE/fonts/nerd-fonts"
}
Get-ChildItem -Path "$Fonts/nerd-fonts" -Include *.otf,*.ttf -Recurse | Move-Item -Destination "$Fonts/files"
