import { describe, it, expect } from "vitest";
import {
  parseMiseToml,
  miseToolsToToml,
  formatMiseValue,
  parseMiseToolValue,
  serializeMiseToolValue,
  categorize,
} from "./mise";

describe("categorize", () => {
  it("categorizes by prefix", () => {
    expect(categorize("node")).toBe("Core");
    expect(categorize("cargo:ripgrep")).toBe("Cargo");
    expect(categorize("npm:prettier")).toBe("NPM");
    expect(categorize("go:github.com/x")).toBe("Go");
    expect(categorize("ubi:sharkdp/bat")).toBe("GitHub");
  });

  it("categorizes github: prefix as GitHub", () => {
    expect(categorize("github:owner/repo")).toBe("GitHub");
  });

  it("categorizes dotnet: prefix", () => {
    expect(categorize("dotnet:some-tool")).toBe("Dotnet");
  });

  it("categorizes pipx: prefix", () => {
    expect(categorize("pipx:black")).toBe("Pipx");
  });

  it("categorizes vfox: prefix", () => {
    expect(categorize("vfox:some-tool")).toBe("VFox");
  });

  it("returns Core for unknown prefixes", () => {
    expect(categorize("xyz:unknown")).toBe("Core");
    expect(categorize("")).toBe("Core");
  });
});

describe("formatMiseValue", () => {
  it("strips quotes from simple strings", () => {
    expect(formatMiseValue('"20.11.0"')).toBe("20.11.0");
  });

  it("strips single quotes", () => {
    expect(formatMiseValue("'latest'")).toBe("latest");
  });

  it("formats arrays as comma-separated", () => {
    expect(formatMiseValue('["3.12", "3.11"]')).toBe("3.12, 3.11");
  });

  it("returns non-string values as-is", () => {
    expect(formatMiseValue("latest")).toBe("latest");
  });

  it("returns empty string as-is", () => {
    expect(formatMiseValue("")).toBe("");
  });

  it("handles whitespace-only input", () => {
    expect(formatMiseValue("   ")).toBe("");
  });

  it("formats inline tables with version", () => {
    expect(
      formatMiseValue('{ version = "latest", os = ["linux", "macos"] }'),
    ).toBe("latest (linux, macos)");
  });

  it("formats inline tables without os", () => {
    expect(
      formatMiseValue(
        '{ version = "latest", postinstall = "corepack enable" }',
      ),
    ).toBe("latest");
  });

  it("formats inline table without version match", () => {
    expect(formatMiseValue("{ foo = 42 }")).toBe("{ foo = 42 }");
  });

  it("formats multi-line arrays of inline tables", () => {
    const raw = `[
  { version = "lts", postinstall = "corepack enable" },
  { version = "latest", postinstall = "corepack enable" },
]`;
    expect(formatMiseValue(raw)).toBe("lts, latest");
  });

  it("formats arrays of inline tables with os", () => {
    const raw = `[
  { version = "latest", os = ["linux", "macos"] },
  { version = "8", os = ["linux", "macos"] },
]`;
    expect(formatMiseValue(raw)).toBe(
      "latest (linux, macos), 8 (linux, macos)",
    );
  });

  it("handles array with no quoted strings", () => {
    expect(formatMiseValue("[1, 2, 3]")).toBe("[1, 2, 3]");
  });
});

describe("parseMiseToml", () => {
  const toml = `[tools]
# Core
node = "20.11.0"
python = ["3.12", "3.11"]
# NPM
"npm:prettier" = "latest"

[settings]
experimental = true
`;

  it("parses tools and settings", () => {
    const result = parseMiseToml(toml);
    expect(result.tools).toHaveLength(3);
    expect(result.tools[0]).toEqual({
      name: "node",
      rawValue: '"20.11.0"',
      displayValue: "20.11.0",
      category: "Core",
    });
    expect(result.tools[2]).toEqual({
      name: "npm:prettier",
      rawValue: '"latest"',
      displayValue: "latest",
      category: "NPM",
    });
    expect(result.settings).toEqual({ experimental: "true" });
  });

  it("handles multi-line array values", () => {
    const toml = `[tools]
# Core
node = [
  { version = "lts", postinstall = "corepack enable" },
  { version = "latest", postinstall = "corepack enable" },
]
bun = "latest"
`;
    const result = parseMiseToml(toml);
    expect(result.tools).toHaveLength(2);
    expect(result.tools[0].name).toBe("node");
    expect(result.tools[0].displayValue).toBe("lts, latest");
    expect(result.tools[0].category).toBe("Core");
    expect(result.tools[1].name).toBe("bun");
    expect(result.tools[1].displayValue).toBe("latest");
  });

  it("handles inline table values", () => {
    const toml = `[tools]
# Plugins
erlang = { version = "latest", os = ["linux", "macos"] }
`;
    const result = parseMiseToml(toml);
    expect(result.tools).toHaveLength(1);
    expect(result.tools[0].name).toBe("erlang");
    expect(result.tools[0].displayValue).toBe("latest (linux, macos)");
    expect(result.tools[0].category).toBe("Plugins");
  });

  it("preserves category through non-category comments", () => {
    const toml = `[tools]
# Plugins
act = "latest"
# clang = "latest" # Disabled temporarily
cmdx = "latest"
fzf = "latest"
"cargo:bat" = "latest"
`;
    const result = parseMiseToml(toml);
    expect(result.tools[0]).toMatchObject({
      name: "act",
      category: "Plugins",
    });
    expect(result.tools[1]).toMatchObject({
      name: "cmdx",
      category: "Plugins",
    });
    expect(result.tools[2]).toMatchObject({
      name: "fzf",
      category: "Plugins",
    });
    // Prefixed tools get their prefix-based category
    expect(result.tools[3]).toMatchObject({
      name: "cargo:bat",
      category: "Cargo",
    });
  });

  it("handles multi-line arrays of inline tables with os", () => {
    const toml = `[tools]
# Plugins
dotnet = [
  { version = "latest", os = ["linux", "macos"] },
  { version = "8", os = ["linux", "macos"] },
]
`;
    const result = parseMiseToml(toml);
    expect(result.tools).toHaveLength(1);
    expect(result.tools[0].name).toBe("dotnet");
    expect(result.tools[0].displayValue).toBe(
      "latest (linux, macos), 8 (linux, macos)",
    );
    expect(result.tools[0].category).toBe("Plugins");
  });

  it("returns empty tools for empty content", () => {
    const result = parseMiseToml("");
    expect(result.tools).toEqual([]);
    expect(result.settings).toEqual({});
    expect(result.env).toEqual({});
  });

  it("returns empty tools when no [tools] section exists", () => {
    const result = parseMiseToml("[settings]\nexperimental = true\n");
    expect(result.tools).toEqual([]);
    expect(result.settings).toEqual({ experimental: "true" });
  });

  it("skips lines without a separator", () => {
    const toml = `[tools]
not-a-valid-line
node = "20"
`;
    const result = parseMiseToml(toml);
    expect(result.tools).toHaveLength(1);
    expect(result.tools[0].name).toBe("node");
  });

  it("parses [env] section", () => {
    const toml = `[env]
NODE_ENV = "development"
PORT = "3000"
`;
    const result = parseMiseToml(toml);
    expect(result.env).toEqual({
      NODE_ENV: '"development"',
      PORT: '"3000"',
    });
  });

  it("handles quoted keys", () => {
    const toml = `[tools]
"npm:prettier" = "latest"
"cargo:bat" = "latest"
`;
    const result = parseMiseToml(toml);
    expect(result.tools).toHaveLength(2);
    expect(result.tools[0].name).toBe("npm:prettier");
    expect(result.tools[1].name).toBe("cargo:bat");
  });
});

describe("miseToolsToToml", () => {
  it("serializes back to TOML format", () => {
    const data = {
      rawContent: "",
      tools: [
        {
          name: "node",
          rawValue: '"20"',
          displayValue: "20",
          category: "Core",
        },
        {
          name: "npm:prettier",
          rawValue: '"latest"',
          displayValue: "latest",
          category: "NPM",
        },
      ],
      settings: { experimental: "true" },
      env: {},
    };
    const result = miseToolsToToml(data);
    expect(result).toContain("[tools]");
    expect(result).toContain("# Core");
    expect(result).toContain('node = "20"');
    expect(result).toContain("# NPM");
    expect(result).toContain('"npm:prettier" = "latest"');
    expect(result).toContain("[settings]");
    expect(result).toContain("experimental = true");
  });

  it("serializes empty tools list", () => {
    const data = {
      rawContent: "",
      tools: [],
      settings: {},
      env: {},
    };
    const result = miseToolsToToml(data);
    expect(result).toContain("[tools]");
    expect(result).not.toContain("# Core");
  });

  it("serializes env section", () => {
    const data = {
      rawContent: "",
      tools: [],
      settings: {},
      env: { NODE_ENV: '"development"' },
    };
    const result = miseToolsToToml(data);
    expect(result).toContain("[env]");
    expect(result).toContain('NODE_ENV = "development"');
  });

  it("omits empty settings and env sections", () => {
    const data = {
      rawContent: "",
      tools: [
        {
          name: "node",
          rawValue: '"20"',
          displayValue: "20",
          category: "Core",
        },
      ],
      settings: {},
      env: {},
    };
    const result = miseToolsToToml(data);
    expect(result).not.toContain("[settings]");
    expect(result).not.toContain("[env]");
  });
});

describe("parseMiseToolValue", () => {
  it("parses simple quoted string", () => {
    const opts = parseMiseToolValue('"20"');
    expect(opts.entries).toHaveLength(1);
    expect(opts.entries[0].version).toBe("20");
    expect(opts.entries[0].os).toEqual([]);
    expect(opts.entries[0].postinstall).toBe("");
  });

  it("parses single-quoted string", () => {
    const opts = parseMiseToolValue("'latest'");
    expect(opts.entries).toHaveLength(1);
    expect(opts.entries[0].version).toBe("latest");
  });

  it("parses bare/unquoted value", () => {
    const opts = parseMiseToolValue("latest");
    expect(opts.entries).toHaveLength(1);
    expect(opts.entries[0].version).toBe("latest");
  });

  it("handles whitespace around value", () => {
    const opts = parseMiseToolValue('  "20"  ');
    expect(opts.entries).toHaveLength(1);
    expect(opts.entries[0].version).toBe("20");
  });

  it("parses inline table with version only", () => {
    const opts = parseMiseToolValue('{ version = "22" }');
    expect(opts.entries).toHaveLength(1);
    expect(opts.entries[0].version).toBe("22");
    expect(opts.entries[0].os).toEqual([]);
  });

  it("parses inline table with os", () => {
    const opts = parseMiseToolValue(
      '{ version = "22", os = ["linux", "macos"] }',
    );
    expect(opts.entries).toHaveLength(1);
    expect(opts.entries[0].version).toBe("22");
    expect(opts.entries[0].os).toEqual(["linux", "macos"]);
  });

  it("parses inline table with postinstall", () => {
    const opts = parseMiseToolValue(
      '{ version = "22", postinstall = "corepack enable" }',
    );
    expect(opts.entries).toHaveLength(1);
    expect(opts.entries[0].version).toBe("22");
    expect(opts.entries[0].postinstall).toBe("corepack enable");
  });

  it("parses inline table with install_env", () => {
    const opts = parseMiseToolValue(
      '{ version = "3.12", install_env = { CONFIGURE_OPTS = "--enable-shared" } }',
    );
    expect(opts.entries).toHaveLength(1);
    expect(opts.entries[0].version).toBe("3.12");
    expect(opts.entries[0].installEnv).toEqual({
      CONFIGURE_OPTS: "--enable-shared",
    });
  });

  it("parses inline table with all fields", () => {
    const opts = parseMiseToolValue(
      '{ version = "22", os = ["linux"], postinstall = "corepack enable", install_env = { NODE_ENV = "production" } }',
    );
    expect(opts.entries[0].version).toBe("22");
    expect(opts.entries[0].os).toEqual(["linux"]);
    expect(opts.entries[0].postinstall).toBe("corepack enable");
    expect(opts.entries[0].installEnv).toEqual({ NODE_ENV: "production" });
  });

  it("parses inline table missing version field", () => {
    const opts = parseMiseToolValue('{ os = ["linux"] }');
    expect(opts.entries[0].version).toBe("");
    expect(opts.entries[0].os).toEqual(["linux"]);
  });

  it("parses array of simple strings into multiple entries", () => {
    const opts = parseMiseToolValue('["3.11", "3.12"]');
    expect(opts.entries).toHaveLength(2);
    expect(opts.entries[0].version).toBe("3.11");
    expect(opts.entries[1].version).toBe("3.12");
  });

  it("parses array of mixed entries", () => {
    const opts = parseMiseToolValue(
      '["lts", { version = "latest", os = ["linux"] }]',
    );
    expect(opts.entries).toHaveLength(2);
    expect(opts.entries[0].version).toBe("lts");
    expect(opts.entries[0].os).toEqual([]);
    expect(opts.entries[1].version).toBe("latest");
    expect(opts.entries[1].os).toEqual(["linux"]);
  });

  it("parses empty array", () => {
    const opts = parseMiseToolValue("[]");
    expect(opts.entries).toEqual([]);
  });

  it("parses array with multiple install_env entries", () => {
    const opts = parseMiseToolValue(
      '{ version = "3.12", install_env = { A = "1", B = "2" } }',
    );
    expect(opts.entries[0].installEnv).toEqual({ A: "1", B: "2" });
  });
});

describe("serializeMiseToolValue", () => {
  it("serializes single simple version", () => {
    const result = serializeMiseToolValue({
      entries: [{ version: "20", os: [], postinstall: "", installEnv: {} }],
    });
    expect(result).toBe('"20"');
  });

  it("serializes single entry with os", () => {
    const result = serializeMiseToolValue({
      entries: [
        {
          version: "22",
          os: ["linux", "macos"],
          postinstall: "",
          installEnv: {},
        },
      ],
    });
    expect(result).toBe('{ version = "22", os = ["linux", "macos"] }');
  });

  it("serializes single entry with all options", () => {
    const result = serializeMiseToolValue({
      entries: [
        {
          version: "22",
          os: ["linux"],
          postinstall: "corepack enable",
          installEnv: { NODE_ENV: "production" },
        },
      ],
    });
    expect(result).toContain('version = "22"');
    expect(result).toContain('os = ["linux"]');
    expect(result).toContain('postinstall = "corepack enable"');
    expect(result).toContain('install_env = { NODE_ENV = "production" }');
  });

  it("serializes multiple entries as array", () => {
    const result = serializeMiseToolValue({
      entries: [
        { version: "3.11", os: [], postinstall: "", installEnv: {} },
        { version: "3.12", os: [], postinstall: "", installEnv: {} },
      ],
    });
    expect(result).toBe('["3.11", "3.12"]');
  });

  it("serializes mixed entries as array", () => {
    const result = serializeMiseToolValue({
      entries: [
        { version: "lts", os: [], postinstall: "", installEnv: {} },
        { version: "latest", os: ["linux"], postinstall: "", installEnv: {} },
      ],
    });
    expect(result).toBe('["lts", { version = "latest", os = ["linux"] }]');
  });

  it("serializes empty entries as latest", () => {
    const result = serializeMiseToolValue({ entries: [] });
    expect(result).toBe('"latest"');
  });

  it("roundtrips a simple value", () => {
    const parsed = parseMiseToolValue('"latest"');
    expect(serializeMiseToolValue(parsed)).toBe('"latest"');
  });

  it("roundtrips an inline table", () => {
    const raw = '{ version = "22", os = ["linux", "macos"] }';
    const parsed = parseMiseToolValue(raw);
    expect(serializeMiseToolValue(parsed)).toBe(raw);
  });

  it("roundtrips an array of mixed entries", () => {
    const raw = '["lts", { version = "latest", os = ["linux"] }]';
    const parsed = parseMiseToolValue(raw);
    expect(serializeMiseToolValue(parsed)).toBe(raw);
  });

  it("serializes entry with multiple install_env vars", () => {
    const result = serializeMiseToolValue({
      entries: [
        {
          version: "3.12",
          os: [],
          postinstall: "",
          installEnv: { A: "1", B: "2" },
        },
      ],
    });
    expect(result).toContain('A = "1"');
    expect(result).toContain('B = "2"');
  });

  it("serializes entry with only postinstall", () => {
    const result = serializeMiseToolValue({
      entries: [
        {
          version: "latest",
          os: [],
          postinstall: "corepack enable",
          installEnv: {},
        },
      ],
    });
    expect(result).toBe(
      '{ version = "latest", postinstall = "corepack enable" }',
    );
  });
});
