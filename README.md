# Provision-Machine

Provision Windows machines for Work or Personal use with DSC configurations and a PowerShell launcher.

The configurations install apps through WinGet and Scoop, restore mise tools, and configure Windows settings. They also cover Visual Studio, fonts, Windows Terminal, Oh My Posh, and Edge profiles and extensions.

## Quick start

1. Install [PowerShell 7.4 or newer](https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-windows). Windows PowerShell 5.1 cannot run the launcher.
2. Clone this repository, or [download the ZIP](https://github.com/matracey/provision-machine/archive/refs/heads/main.zip) and extract it. The commands below assume the repository is at `C:\src\provision-machine`.
3. Review `winget\work.winget` or `winget\personal.winget` and the modules they include.
4. Open PowerShell 7 as Administrator under the Windows account you want to configure, then run:

```powershell
& {
    $ErrorActionPreference = 'Stop'
    Set-Location 'C:\src\provision-machine'

    & .\provisioning\Apply-Configuration.ps1 -InstallPrereqs
    & .\provisioning\Apply-Configuration.ps1 -Work
    if ($LASTEXITCODE -ne 0) {
        throw 'Provisioning failed. Check sweep-logs in the repository.'
    }
}
```

Replace `-Work` with `-Personal` for a personal machine. Omit both switches to choose the context at a prompt.

`-InstallPrereqs` installs or repairs stable WinGet and installs checksum-pinned DSC 3.3.0 and the required compatibility modules. Run it separately from `-Work` or `-Personal`. The launcher uses the portable DSC runtime directly; no preview DSC package is needed.

> [!WARNING]
> A full run changes Windows settings, including Defender exclusions, remote access, and file sharing. User settings apply to the account running the launcher. UAC changes are skipped by default.

Logs are saved under `sweep-logs\apply-<timestamp>-<context>-<operation>`. Restart if an installer requests it; browser-default and taskbar policies take effect at sign-in.

### Select what to apply

Run these examples from the repository root after installing the prerequisites. To install only the common and Work WinGet packages:

```powershell
& {
    $ErrorActionPreference = 'Stop'
    & .\provisioning\Apply-Configuration.ps1 -Work `
        -Only packages-common.dsc.yaml,packages-work.dsc.yaml
    if ($LASTEXITCODE -ne 0) {
        throw 'Package provisioning failed. Check sweep-logs.'
    }
}
```

`-Only` selects top-level included module filenames; it does not add their prerequisites automatically. Use `-Skip uac.dsc.yaml,fonts.dsc.yaml` to omit modules instead. Supplying `-Skip` replaces its default list, so keep `uac.dsc.yaml` in that list unless you intend to change UAC.

The launcher reads local manifests by default. Add `-Remote` to download the configuration bundle published to the Gist by GitHub Actions.

## Web editor

The React app in `web\` has JSON, YAML, and mise editors with drag-and-drop ordering and file import/export. Its JSON editor uses the older configuration format; current provisioning uses the DSC modules in `winget\modules\`.

With Node.js and npm installed, run this from the repository root:

```powershell
& {
    $ErrorActionPreference = 'Stop'
    Set-Location .\web
    npm ci
    if ($LASTEXITCODE -ne 0) { throw 'Dependency installation failed.' }
    npm run dev
    if ($LASTEXITCODE -ne 0) { throw 'The development server failed.' }
}
```

From `web\`, use `npm run test` for tests, `npm run lint` for linting, and `npm run build` for a production build.

## Repository layout

```text
provisioning\
  Apply-Configuration.ps1        # Provisioning entry point
  Diagnose-Modules.ps1           # Run selected modules and report results
  DscRuntime.ps1                 # Pinned runtime and prerequisite setup
  DscConfiguration.ps1           # Configuration loading and result handling
  *.Tests.ps1                    # Provisioning tests
winget\
  personal.winget                # Personal manifest
  work.winget                    # Work manifest
  modules\                      # Shared and context-specific DSC resources
terminal\                       # Windows Terminal settings
themes\                         # Oh My Posh themes
web\                            # React configuration editor
.github\workflows\
  publish-gist.yml               # Validate and publish configurations
  deploy-web.yml                 # Build and deploy the web editor
  update-dynamic-packages.yml    # Refresh selected WinGet package versions
```

## License

This project is licensed under the [MIT License](LICENSE).
