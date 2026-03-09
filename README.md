# Provision-Machine

Automated Windows machine provisioning with support for personal and work environments.

## Features

- **Interactive provisioning script** â€” a single PowerShell script (`provisioning/Provision-Machine.ps1`) with an interactive menu for selecting what to install and configure
- **WinGet DSC configurations** â€” declarative package lists for personal and work machines (`winget/`)
- **Scoop package management** â€” bucket and package definitions driven by a JSON configuration file (`provisioning/Configuration.json`)
- **Windows Terminal settings** â€” pre-configured profiles for personal and work use (`terminal/`)
- **Oh My Posh themes** â€” custom prompt themes (`themes/`)
- **Visual Studio workload installation** â€” automated VS installer workload setup
- **Windows Defender exclusions** â€” dev-friendly process and folder exclusions
- **Web configuration editor** â€” a React + TypeScript SPA for visually editing JSON, YAML, and mise configuration files (`web/`)
- **CI/CD** â€” GitHub Actions workflow to validate and publish config files to a GitHub Gist

## Quick Start

```powershell
# Clone the repo
git clone https://github.com/matracey/provision-machine.git
cd provision-machine

# Run the provisioning script (interactive mode)
.\provisioning\Provision-Machine.ps1

# Or target specific components
.\provisioning\Provision-Machine.ps1 -Personal -Winget -Scoop -Fonts

# Apply a DSCv3 config via winget configure (uses preview DSC processor)
winget configure -f .\winget\work.winget --processor-path (Join-Path (Get-AppxPackage 'Microsoft.DesiredStateConfiguration-Preview').InstallLocation 'dsc.exe')
```

### Web Editor

```bash
cd web
npm install
npm run dev      # Start the dev server
npm run test     # Run tests
npm run build    # Production build
```

The web editor auto-loads configuration files from the repository and provides:

- **JSON editor** â€” edit `Configuration.json` (Scoop buckets/packages, VS workloads, Defender exclusions) with drag-and-drop reordering, inline editing, and context-aware panels
- **YAML editor** â€” edit WinGet DSC configurations for work and personal environments
- **Mise editor** â€” edit mise tool versions and settings
- **Import / Export** â€” drag-and-drop file loading, JSON and YAML export, and save back to the repository via GitHub PAT
- **Keyboard shortcuts** â€” `Ctrl+S` to export, `Escape` to dismiss modals

## Repository Structure

```text
provisioning/
  Provision-Machine.ps1   # Main provisioning script
  Configuration.json      # Scoop buckets, packages, VS workloads, Defender exclusions
winget/
  configuration.personal.dsc.yaml  # WinGet DSC config (personal)
  configuration.work.dsc.yaml      # WinGet DSC config (work)
terminal/
  windowsterminal.personal.json    # Windows Terminal settings (personal)
  windowsterminal.work.json        # Windows Terminal settings (work)
themes/
  mojada.work.omp.json             # Oh My Posh theme
web/                               # Configuration editor SPA (React, Vite, Tailwind, daisyUI)
  src/
    components/                    # UI components (editors, modals, drag-and-drop)
    state/                         # React context and reducer for app state
    types/                         # TypeScript type definitions
    utils/                         # File I/O, Gist API, sorting, constants
.github/workflows/
  publish-gist.yml                 # Validate & publish configs to a Gist
```

## License

This project is licensed under the [MIT License](LICENSE).
