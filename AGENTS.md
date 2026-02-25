# AGENTS.md

## Project overview

Windows machine provisioning repo with two main parts:

1. **PowerShell provisioning** (`provisioning/`) — interactive script that installs and configures software for Personal or Work environments using Scoop, WinGet DSC, and registry settings.
2. **Web config editor** (`web/`) — React + TypeScript SPA for visually editing the JSON/YAML configuration files.

## Setup and build commands

### Web editor (from `web/` directory)

```bash
npm install              # install dependencies
npm run dev              # start Vite dev server
npm run build            # tsc -b && vite build
npm run lint             # eslint .
npm run test             # vitest run (full suite)
npm run test:watch       # vitest (watch mode)
npx vitest run src/utils/sorting.test.ts   # run a single test file
```

### Provisioning script

```powershell
.\provisioning\Provision-Machine.ps1                          # interactive mode
.\provisioning\Provision-Machine.ps1 -Personal -Winget -Scoop # targeted components
```

## Code style

- Prettier: 2-space indentation, no tabs (`.prettierrc`).
- TypeScript strict mode. Types centralized in `web/src/types/index.ts`.
- ESLint flat config with React Hooks and React Refresh plugins.
- PowerShell: `Verb-Noun` cmdlet names, `PascalCase` parameters.

## Testing instructions

- Tests use Vitest + React Testing Library + jsdom.
- Every component and utility has a co-located `.test.ts(x)` file — keep this pattern when adding new files.
- Run `npm run lint` and `npm run test` from `web/` before committing.
- To run a single test: `npx vitest run src/path/to/file.test.ts`.

## Architecture notes

- **Context pattern**: configuration is split into `Common` + `Personal`/`Work` and merged at runtime. Follow this pattern when adding new config sections.
- **State management**: React Context + `useReducer` in `web/src/state/AppContext.tsx` — no Redux.
- **Components**: organized by feature under `web/src/components/` (e.g., `json-editor/`, `yaml-editor/`, `mise-editor/`).
- **Business logic**: extracted into `web/src/utils/` — file I/O, Gist API, sorting, item operations.
- **Config fetching**: the provisioning script fetches config from a GitHub Gist first, falling back to the local file. CI publishes validated configs to the Gist.

## CI/CD

- `publish-gist.yml` — validates config files (OMP themes, DSC YAML, Terminal JSON) and publishes to a GitHub Gist.
- `deploy-web.yml` — builds and deploys the web editor.
