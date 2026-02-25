# Copilot Instructions

## Architecture

This repo provisions Windows machines (personal and work) using a single interactive PowerShell script backed by declarative config files, plus a React SPA for editing those configs visually.

### Provisioning layer (`provisioning/`)

- `Provision-Machine.ps1` — main orchestrator. Prompts for context (Personal/Work) and features, then installs/configures software.
- `Configuration.json` — hierarchical config: `Common` settings merged with context-specific (`Personal`/`Work`) overrides. Sections cover Git, Scoop (buckets, packages, aliases), Visual Studio workloads, and Windows Defender exclusions.
- The script fetches config from a GitHub Gist first (`Get-ConfigFile`), falling back to the local file. CI publishes validated configs to the Gist.

### Config files

- `winget/*.dsc.yaml` — WinGet DSC package declarations (per-context).
- `terminal/windowsterminal.*.json` — Windows Terminal profiles (per-context).
- `themes/*.omp.json` — Oh My Posh prompt themes.

### Web editor (`web/`)

React + TypeScript SPA (Vite, Tailwind CSS 4, daisyUI 5) for editing Configuration.json, WinGet YAML, and mise configs.

- **State management**: React Context + `useReducer` (no Redux). State defined in `src/state/AppContext.tsx`.
- **Component organization**: feature-based folders under `src/components/` (e.g., `json-editor/`, `yaml-editor/`, `mise-editor/`).
- **Business logic**: extracted into `src/utils/` — file I/O, Gist API, sorting, item operations.
- **Types**: centralized in `src/types/index.ts`. Key union types: `ContextType` ("Common" | "Work" | "Personal"), `TabId` ("json" | "yaml" | "mise").

### CI/CD (`.github/workflows/`)

- `publish-gist.yml` — validates config files and publishes to a GitHub Gist.
- `deploy-web.yml` — builds and deploys the web editor.

## Build / Test / Lint (web)

All commands run from the `web/` directory:

```bash
npm run build        # tsc -b && vite build
npm run lint         # eslint .
npm run test         # vitest run (all tests)
npm run test:watch   # vitest (watch mode)
npx vitest run src/utils/sorting.test.ts   # single test file
```

Tests use Vitest + React Testing Library + jsdom. Every component and utility has a co-located `.test.ts(x)` file.

## Conventions

- **Formatting**: Prettier with 2-space indentation, no tabs (`.prettierrc`).
- **Context pattern**: configs are split into Common + Personal/Work and merged at runtime. When adding new config sections, follow this same pattern in both `Configuration.json` and the provisioning script.
- **Co-located tests**: test files live next to the source files they test, named `*.test.ts` or `*.test.tsx`.
- **PowerShell style**: the provisioning script uses `Verb-Noun` cmdlet naming and `PascalCase` parameters. Admin tasks use `Invoke-BlockElevated` for auto-elevation.
