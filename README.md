# Provision-Machine

Provision Windows machines for Work or Personal use with DSC configurations and a PowerShell launcher.

The configurations install apps through WinGet and Scoop, restore mise tools, and configure Windows settings. They also cover Visual Studio, fonts, Windows Terminal, and Oh My Posh.

## Quick start

1. Install WinGet and DSC v3. Ensure `dsc` is available on `PATH` before running the launcher.
2. Clone this repository, or [download the ZIP](https://github.com/matracey/provision-machine/archive/refs/heads/main.zip) and extract it. The commands below assume the repository is at `C:\src\provision-machine`.
3. Review `winget\work.winget` or `winget\personal.winget` and the modules they include.
4. Open PowerShell as Administrator under the Windows account you want to configure, then run:

```powershell
& {
    $ErrorActionPreference = 'Stop'
    Set-Location 'C:\src\provision-machine'

    & .\provisioning\Apply-Configuration.ps1 -Work
    if ($LASTEXITCODE -ne 0) {
        throw 'Provisioning failed. Check the DSC output.'
    }
}
```

Replace `-Work` with `-Personal` for a personal machine. Omit both switches to choose the context at a prompt.

The launcher invokes `dsc config set` directly. It does not install its prerequisites.

> [!WARNING]
> A full run changes Windows settings, including Defender exclusions, remote access, file sharing, and UAC. User settings apply to the account running the launcher.

### Select what to apply

Edit the top-level Includes in `winget\work.winget` or `winget\personal.winget` to choose which modules run. The launcher applies the selected manifest as a whole.

The launcher uses local manifests when available. Add `-Remote` to download the context manifest from the Gist.

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
