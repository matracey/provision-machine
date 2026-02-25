import type { RegistryEntry } from "../types";

const CACHE_KEY = "mise-registry-cache";
const CACHE_TTL_MS = 24 * 60 * 60 * 1000;
const GITHUB_API_URL =
  "https://api.github.com/repos/jdx/mise/contents/registry";
const GITHUB_RAW_URL =
  "https://raw.githubusercontent.com/jdx/mise/main/registry";

const BACKEND_PREFIXES = [
  "core:",
  "asdf:",
  "aqua:",
  "cargo:",
  "npm:",
  "pipx:",
  "go:",
  "github:",
  "ubi:",
  "vfox:",
  "dotnet:",
];

export const COMMON_TOOLS: RegistryEntry[] = [
  { name: "node", description: "Node.js JavaScript runtime" },
  { name: "python", description: "Python programming language" },
  { name: "go", description: "Go programming language" },
  { name: "ruby", description: "Ruby programming language" },
  { name: "java", description: "Java programming language" },
  { name: "rust", description: "Rust programming language" },
  { name: "deno", description: "Deno JavaScript/TypeScript runtime" },
  { name: "bun", description: "Bun JavaScript runtime" },
  { name: "zig", description: "Zig programming language" },
  { name: "dotnet", description: ".NET SDK" },
  { name: "php", description: "PHP programming language" },
  { name: "erlang", description: "Erlang programming language" },
  { name: "elixir", description: "Elixir programming language" },
  { name: "lua", description: "Lua programming language" },
  { name: "terraform", description: "Infrastructure as code tool" },
  { name: "kubectl", description: "Kubernetes command-line tool" },
  { name: "helm", description: "Kubernetes package manager" },
  { name: "awscli", description: "AWS command-line interface" },
  { name: "hugo", description: "Static site generator" },
  { name: "jq", description: "Command-line JSON processor" },
  { name: "ripgrep", description: "Fast regex search tool" },
  { name: "fd", description: "Fast file finder" },
  { name: "bat", description: "Cat clone with syntax highlighting" },
  { name: "fzf", description: "Command-line fuzzy finder" },
  { name: "lazygit", description: "Terminal UI for git" },
  { name: "gh", description: "GitHub CLI" },
  { name: "shellcheck", description: "Shell script linter" },
  { name: "just", description: "Command runner" },
  { name: "direnv", description: "Per-directory environment variables" },
  { name: "maven", description: "Java build tool" },
  { name: "gradle", description: "Build automation tool" },
  { name: "cmake", description: "Cross-platform build system" },
  { name: "flutter", description: "UI toolkit for mobile/web/desktop" },
  { name: "dart", description: "Dart programming language" },
  { name: "kotlin", description: "Kotlin programming language" },
  { name: "scala", description: "Scala programming language" },
];

interface CachedRegistry {
  tools: RegistryEntry[];
  timestamp: number;
}

let memoryCache: RegistryEntry[] | null = null;

export function hasBackendPrefix(name: string): boolean {
  return BACKEND_PREFIXES.some((p) => name.startsWith(p));
}

export function fuzzyScore(query: string, target: string): number {
  const q = query.toLowerCase();
  const t = target.toLowerCase();

  if (t === q) return 10000;
  if (t.startsWith(q)) return 5000 + (q.length / t.length) * 1000;
  if (t.includes(q)) return 2000 + (q.length / t.length) * 1000;

  // Character-by-character fuzzy match
  let qi = 0;
  let score = 0;
  let consecutive = 0;
  for (let ti = 0; ti < t.length && qi < q.length; ti++) {
    if (t[ti] === q[qi]) {
      qi++;
      consecutive++;
      score += consecutive * 10;
      if (ti === 0 || t[ti - 1] === "-" || t[ti - 1] === "_") {
        score += 50;
      }
    } else {
      consecutive = 0;
    }
  }

  return qi < q.length ? -1 : score;
}

export function fuzzySearch(
  query: string,
  items: RegistryEntry[],
  limit = 30,
): RegistryEntry[] {
  if (!query.trim()) return items.slice(0, limit);

  const scored = items
    .map((item) => {
      const nameScore = fuzzyScore(query, item.name);
      const aliasScore = item.aliases
        ? Math.max(...item.aliases.map((a) => fuzzyScore(query, a)), -1)
        : -1;
      return { item, score: Math.max(nameScore, aliasScore) };
    })
    .filter((s) => s.score > 0)
    .sort((a, b) => b.score - a.score);

  return scored.slice(0, limit).map((s) => s.item);
}

function readCache(): RegistryEntry[] | null {
  try {
    const raw = localStorage.getItem(CACHE_KEY);
    if (!raw) return null;
    const cached: CachedRegistry = JSON.parse(raw);
    if (Date.now() - cached.timestamp > CACHE_TTL_MS) return null;
    return cached.tools;
  } catch {
    return null;
  }
}

function writeCache(tools: RegistryEntry[]): void {
  try {
    const data: CachedRegistry = { tools, timestamp: Date.now() };
    localStorage.setItem(CACHE_KEY, JSON.stringify(data));
  } catch {
    // localStorage may be full or unavailable
  }
}

export async function fetchRegistryTools(
  pat?: string | null,
): Promise<RegistryEntry[]> {
  if (memoryCache) return memoryCache;

  const cached = readCache();
  if (cached) {
    memoryCache = cached;
    return cached;
  }

  try {
    const headers: Record<string, string> = {
      Accept: "application/vnd.github.v3+json",
    };
    if (pat) headers["Authorization"] = `token ${pat}`;

    const response = await fetch(GITHUB_API_URL, { headers });
    if (!response.ok) throw new Error(`HTTP ${response.status}`);

    const files: { name: string }[] = await response.json();
    const tools: RegistryEntry[] = files
      .filter((f) => f.name.endsWith(".toml"))
      .map((f) => ({ name: f.name.replace(/\.toml$/, "") }));

    writeCache(tools);
    memoryCache = tools;
    return tools;
  } catch {
    memoryCache = COMMON_TOOLS;
    return COMMON_TOOLS;
  }
}

export async function fetchToolDetails(
  name: string,
): Promise<RegistryEntry | null> {
  try {
    const response = await fetch(`${GITHUB_RAW_URL}/${name}.toml`);
    if (!response.ok) return null;
    const content = await response.text();
    return parseRegistryToml(name, content);
  } catch {
    return null;
  }
}

export function parseRegistryToml(
  name: string,
  content: string,
): RegistryEntry {
  const entry: RegistryEntry = { name };

  const descMatch = content.match(/description\s*=\s*"([^"]*)"/);
  if (descMatch) entry.description = descMatch[1];

  const backendsMatch = content.match(/backends\s*=\s*\[([\s\S]*?)\]/);
  if (backendsMatch) {
    entry.backends = backendsMatch[1]
      .match(/"([^"]*)"/g)
      ?.map((s) => s.slice(1, -1));
  }

  const aliasMatch = content.match(/aliases\s*=\s*\[([\s\S]*?)\]/);
  if (aliasMatch) {
    entry.aliases = aliasMatch[1]
      .match(/"([^"]*)"/g)
      ?.map((s) => s.slice(1, -1));
  }

  return entry;
}

export function clearRegistryCache(): void {
  memoryCache = null;
  try {
    localStorage.removeItem(CACHE_KEY);
  } catch {
    // ignore
  }
}
