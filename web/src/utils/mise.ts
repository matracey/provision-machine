import type { MiseData, MiseTool } from "../types";

const CATEGORY_ORDER = [
  "Core",
  "Plugins",
  "Cargo",
  "Dotnet",
  "NPM",
  "Pipx",
  "Go",
  "GitHub",
  "VFox",
];

// Categorize a tool by its name prefix
export function categorize(name: string): string {
  if (name.startsWith("cargo:")) return "Cargo";
  if (name.startsWith("dotnet:")) return "Dotnet";
  if (name.startsWith("npm:")) return "NPM";
  if (name.startsWith("pipx:")) return "Pipx";
  if (name.startsWith("go:")) return "Go";
  if (name.startsWith("ubi:") || name.startsWith("github:")) return "GitHub";
  if (name.startsWith("vfox:")) return "VFox";
  return "Core";
}

// Count unbalanced brackets in a string, respecting quoted strings
function bracketDepth(str: string): { square: number; curly: number } {
  let square = 0;
  let curly = 0;
  let inString = false;
  let escape = false;
  for (const ch of str) {
    if (escape) {
      escape = false;
      continue;
    }
    if (ch === "\\") {
      escape = true;
      continue;
    }
    if (ch === '"') {
      inString = !inString;
      continue;
    }
    if (inString) continue;
    if (ch === "[") square++;
    else if (ch === "]") square--;
    else if (ch === "{") curly++;
    else if (ch === "}") curly--;
  }
  return { square, curly };
}

function isValueComplete(value: string): boolean {
  const { square, curly } = bracketDepth(value);
  return square <= 0 && curly <= 0;
}

// Format an inline table for display
function formatInlineTable(v: string): string {
  const versionMatch = v.match(/version\s*=\s*"([^"]*)"/);
  if (!versionMatch) return v;
  let display = versionMatch[1];
  const osMatch = v.match(/os\s*=\s*\[([^\]]*)\]/);
  if (osMatch) {
    const osList = osMatch[1]
      .match(/"([^"]*)"/g)
      ?.map((s) => s.slice(1, -1))
      .join(", ");
    if (osList) display += ` (${osList})`;
  }
  return display;
}

// Format a raw TOML value for display
export function formatMiseValue(rawValue: string): string {
  const v = rawValue.trim();
  // Simple quoted string
  if (/^"[^"]*"$/.test(v)) return v.slice(1, -1);
  if (/^'[^']*'$/.test(v)) return v.slice(1, -1);
  // Inline table: { version = "latest", os = [...] }
  if (v.startsWith("{") && v.endsWith("}")) {
    return formatInlineTable(v);
  }
  // Array (possibly multi-line)
  if (v.startsWith("[")) {
    const normalized = v.replace(/\n/g, " ").replace(/\s+/g, " ").trim();
    // Array containing inline tables
    if (normalized.includes("{")) {
      const tables = normalized.match(/\{[^}]*\}/g);
      if (tables) return tables.map((t) => formatInlineTable(t)).join(", ");
    }
    // Array of simple strings
    const matches = normalized.match(/"([^"]*)"/g);
    if (matches) return matches.map((m) => m.slice(1, -1)).join(", ");
    return v;
  }
  return v;
}

// Find the key-value separator `=`, skipping `=` inside quoted keys
function findSeparator(line: string): number {
  if (line.startsWith('"')) {
    const close = line.indexOf('"', 1);
    if (close === -1) return -1;
    return line.indexOf("=", close + 1);
  }
  return line.indexOf("=");
}

// Parse a mise.toml file into structured data
export function parseMiseToml(content: string): MiseData {
  const result: MiseData = { rawContent: content, tools: [], settings: {} };
  const lines = content.split("\n");
  let currentSection = "";
  let currentCategory = "Core";
  let i = 0;

  while (i < lines.length) {
    const trimmed = lines[i].trim();
    if (!trimmed) {
      i++;
      continue;
    }

    // Section header — must be [word] with no extra content
    if (/^\[[a-zA-Z_][\w.-]*\]\s*$/.test(trimmed)) {
      const match = trimmed.match(/^\[([^\]]+)\]/);
      if (match) currentSection = match[1];
      i++;
      continue;
    }

    // Comment — update current category only for recognized category names
    if (trimmed.startsWith("#")) {
      const commentText = trimmed.slice(1).trim();
      if (CATEGORY_ORDER.includes(commentText)) {
        currentCategory = commentText;
      }
      i++;
      continue;
    }

    // Key = value
    const eqIdx = findSeparator(trimmed);
    if (eqIdx === -1) {
      i++;
      continue;
    }

    const key = trimmed.slice(0, eqIdx).trim();
    let value = trimmed.slice(eqIdx + 1).trim();
    i++;

    // Accumulate multi-line values until brackets are balanced
    if (!isValueComplete(value)) {
      while (i < lines.length && !isValueComplete(value)) {
        value += "\n" + lines[i];
        i++;
      }
    }

    if (currentSection === "tools") {
      const cleanName = key.replace(/^"|"$/g, "");
      const prefixCategory = categorize(cleanName);
      // Use prefix-based category for prefixed tools, comment-based for unprefixed
      const category =
        prefixCategory !== "Core" ? prefixCategory : currentCategory;
      result.tools.push({
        name: cleanName,
        rawValue: value,
        displayValue: formatMiseValue(value),
        category,
      });
    } else if (currentSection === "settings") {
      result.settings[key] = value;
    }
  }

  return result;
}

// Serialize mise data back to TOML
export function miseToolsToToml(data: MiseData): string {
  const categories: Record<string, MiseTool[]> = {};
  for (const tool of data.tools) {
    const cat = tool.category || "Core";
    if (!categories[cat]) categories[cat] = [];
    categories[cat].push(tool);
  }

  let content = "[tools]\n";
  for (const cat of CATEGORY_ORDER) {
    if (!categories[cat] || categories[cat].length === 0) continue;
    content += `# ${cat}\n`;
    for (const tool of categories[cat]) {
      const name = tool.name.includes(":") ? `"${tool.name}"` : tool.name;
      content += `${name} = ${tool.rawValue}\n`;
    }
  }

  if (data.settings && Object.keys(data.settings).length > 0) {
    content += "\n[settings]\n";
    for (const [key, value] of Object.entries(data.settings)) {
      content += `${key} = ${value}\n`;
    }
  }

  return content;
}
