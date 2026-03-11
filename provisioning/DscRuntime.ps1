function Get-DscRuntime {
    [CmdletBinding()]
    param(
        [switch]$Install,
        [string]$CacheRoot = (Join-Path $env:LOCALAPPDATA 'provision-machine\dsc')
    )

    $version = '3.3.0'
    $architecture = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
    $packages = @{
        X64 = @('x86_64', '3f8b27f648661903d066cc19d5a6e7a8c13bd07eb738d4d765ce7239619b8b5f')
        Arm64 = @('aarch64', '4e4297429489893309d8b8061c3c1628c173debd6ea1812343d738d8135a997e')
    }
    if (-not $packages.ContainsKey($architecture)) { throw "Unsupported DSC architecture: $architecture" }
    $package = $packages[$architecture]
    $destination = Join-Path $CacheRoot "$version-$($package[0])"
    $executable = Join-Path $destination 'dsc.exe'
    if (-not (Test-Path -LiteralPath $executable)) {
        if (Test-Path -LiteralPath $destination) { throw "Incomplete DSC cache: $destination" }
        if (-not $Install) { throw "DSC $version is missing. Run Apply-Configuration.ps1 -InstallPrereqs." }
        $staging = Join-Path $CacheRoot ("staging-" + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $staging -Force -ErrorAction Stop | Out-Null
        try {
            $archive = Join-Path $staging 'dsc.zip'
            $asset = "DSC-$version-$($package[0])-pc-windows-msvc.zip"
            Invoke-WebRequest -Uri "https://github.com/PowerShell/DSC/releases/download/v$version/$asset" -OutFile $archive -ErrorAction Stop
            if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash -ne $package[1]) {
                throw "DSC $version archive checksum mismatch."
            }
            $expanded = Join-Path $staging 'expanded'
            Expand-Archive -LiteralPath $archive -DestinationPath $expanded -ErrorAction Stop
            $catalog = Join-Path $staging 'catalog'
            New-Item -ItemType Directory -Path $catalog -ErrorAction Stop | Out-Null
            # Explicit provider paths replace automatic discovery of unrelated preview packages.
            Get-ChildItem -LiteralPath $expanded |
                Where-Object Name -NotLike '*.dsc.extension.json' |
                Copy-Item -Destination $catalog -Recurse -ErrorAction Stop
            Move-Item -LiteralPath $catalog -Destination $destination -ErrorAction Stop
        } finally {
            Remove-Item -LiteralPath $staging -Recurse -Force -ErrorAction Stop
        }
    }
    $actual = & $executable --version
    if ($LASTEXITCODE -ne 0 -or $actual -ne "dsc $version") { throw "Unexpected DSC runtime at $executable`: $actual" }
    if (Get-ChildItem -LiteralPath $destination -Filter '*.dsc.extension.json') {
        throw "Unexpected automatic discovery extension in the pinned DSC runtime: $destination"
    }
    return $executable
}

function Enter-DscRuntime {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Executable,
        [Parameter(Mandatory)][string]$ConfigurationRoot
    )

    $previous = @{
        PATH = $env:PATH
        DSC_RESOURCE_PATH = $env:DSC_RESOURCE_PATH
        PROVISION_MACHINE_ROOT = $env:PROVISION_MACHINE_ROOT
    }
    $runtime = Split-Path $Executable
    $providers = @(
        $runtime
        $PSHOME
        (Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0')
        (Get-AppxPackage -Name Microsoft.DesktopAppInstaller -ErrorAction Stop).InstallLocation
        (Join-Path $env:ProgramFiles 'PowerToys')
        (Join-Path $env:ProgramFiles 'PowerToys\DSCModules')
        (Join-Path $env:LOCALAPPDATA 'PowerToys')
        (Join-Path $env:LOCALAPPDATA 'PowerToys\DSCModules')
    ) | Where-Object { $_ } | Select-Object -Unique
    $env:DSC_RESOURCE_PATH = $providers -join [IO.Path]::PathSeparator
    $env:PATH = "$runtime$([IO.Path]::PathSeparator)$env:PATH"
    $env:PROVISION_MACHINE_ROOT = $ConfigurationRoot
    return $previous
}

function Exit-DscRuntime {
    param([Parameter(Mandatory)][hashtable]$Previous)
    foreach ($name in $Previous.Keys) {
        [Environment]::SetEnvironmentVariable($name, $Previous[$name], 'Process')
    }
}

function Assert-StableWinGet {
    param([switch]$Install)
    $command = Get-Command winget -ErrorAction SilentlyContinue
    $version = if ($command) { & winget --version }
    if ($command -and $LASTEXITCODE -eq 0 -and $version -match '^v(\d+\.\d+\.\d+)$' -and
        [version]$Matches[1] -ge [version]'1.29.380') {
        return
    }
    if (-not $Install) {
        throw "Stable WinGet 1.29.380 or newer is required; found '$version'. Run -InstallPrereqs to install the stable release."
    }
    Install-Module -Name Microsoft.WinGet.Client -RequiredVersion '1.29.380' -Scope AllUsers -Force -ErrorAction Stop
    Import-Module Microsoft.WinGet.Client -RequiredVersion '1.29.380' -Force -ErrorAction Stop
    Repair-WinGetPackageManager -Version '1.29.380' -Force -ErrorAction Stop
    Assert-StableWinGet
}
