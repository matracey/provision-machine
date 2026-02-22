# Provision-Machine

Provision Windows machines for Work or Personal use.

The PowerShell script installs apps through WinGet and Scoop, restores mise tools, and configures Windows settings. It also covers Visual Studio, fonts, Windows Terminal, and Oh My Posh.

## Quick start

1. Clone this repository, or [download the ZIP](https://github.com/matracey/provision-machine/archive/refs/heads/main.zip) and extract it. The commands below assume the repository is at `C:\src\provision-machine`.
2. Review `provisioning\Configuration.json` and the configuration files in `winget\`.
3. Open PowerShell under the Windows account you want to configure, then run:

```powershell
& {
    $ErrorActionPreference = 'Stop'
    Set-Location 'C:\src\provision-machine'
    & .\provisioning\Provision-Machine.ps1
}
```

Choose Work or Personal at the prompt, then select the components to install. The script prompts for elevation when needed.

> [!WARNING]
> System configuration can change Defender exclusions, remote access, execution policies, and UAC. Review the settings before selecting that component.

### Select what to apply

To set up WinGet and install its Work packages, run this from the repository root:

```powershell
& {
    $ErrorActionPreference = 'Stop'
    & .\provisioning\Provision-Machine.ps1 -Work -Winget -WingetPkgs
}
```

Replace `-Work` with `-Personal` for a personal machine. Other component switches include `-Scoop`, `-Mise`, `-Fonts`, `-VsPreview`, `-WinTerminal`, and `-OhMyPosh`.

The script fetches configuration files from the Gist first, then falls back to local copies.

## Web editor

The React app in `web\` has JSON, YAML, and mise editors with drag-and-drop ordering and file import/export. The JSON editor covers `Configuration.json`; the YAML editor covers the Work and Personal WinGet configurations. You can edit values inline, save repository files with a GitHub PAT, use `Ctrl+S` to export, or press `Escape` to dismiss modals.

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
  Provision-Machine.ps1          # Provisioning entry point
  Configuration.json            # Shared and context-specific settings
winget\
  configuration.personal.dsc.yaml
  configuration.work.dsc.yaml
terminal\                       # Windows Terminal settings
themes\                         # Oh My Posh themes
web\                            # React configuration editor
.github\workflows\
  publish-gist.yml               # Validate and publish configurations
  deploy-web.yml                 # Build and deploy the web editor
```

## License

This project is licensed under the [MIT License](LICENSE).
