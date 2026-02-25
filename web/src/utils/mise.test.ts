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
});

describe("formatMiseValue", () => {
  it("strips quotes from simple strings", () => {
    expect(formatMiseValue('"20.11.0"')).toBe("20.11.0");
  });

  it("formats arrays as comma-separated", () => {
    expect(formatMiseValue('["3.12", "3.11"]')).toBe("3.12, 3.11");
  });

  it("returns non-string values as-is", () => {
    expect(formatMiseValue("latest")).toBe("latest");
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
});

describe("parseMiseToolValue", () => {
  it("parses simple quoted string", () => {
    const opts = parseMiseToolValue('"20"');
    expect(opts.version).toBe("20");
    expect(opts.os).toEqual([]);
    expect(opts.postinstall).toBe("");
    expect(opts.isComplex).toBe(false);
  });

  it("parses inline table with version only", () => {
    const opts = parseMiseToolValue('{ version = "22" }');
    expect(opts.version).toBe("22");
    expect(opts.os).toEqual([]);
  });

  it("parses inline table with os", () => {
    const opts = parseMiseToolValue(
      '{ version = "22", os = ["linux", "macos"] }',
    );
    expect(opts.version).toBe("22");
    expect(opts.os).toEqual(["linux", "macos"]);
  });

  it("parses inline table with postinstall", () => {
    const opts = parseMiseToolValue(
      '{ version = "22", postinstall = "corepack enable" }',
    );
    expect(opts.version).toBe("22");
    expect(opts.postinstall).toBe("corepack enable");
  });

  it("parses inline table with install_env", () => {
    const opts = parseMiseToolValue(
      '{ version = "3.12", install_env = { CONFIGURE_OPTS = "--enable-shared" } }',
    );
    expect(opts.version).toBe("3.12");
    expect(opts.installEnv).toEqual({ CONFIGURE_OPTS: "--enable-shared" });
  });

  it("marks arrays as complex", () => {
    const opts = parseMiseToolValue('["3.11", "3.12"]');
    expect(opts.isComplex).toBe(true);
  });
});

describe("serializeMiseToolValue", () => {
  it("serializes simple version", () => {
    const result = serializeMiseToolValue({
      version: "20",
      os: [],
      postinstall: "",
      installEnv: {},
      isComplex: false,
    });
    expect(result).toBe('"20"');
  });

  it("serializes with os", () => {
    const result = serializeMiseToolValue({
      version: "22",
      os: ["linux", "macos"],
      postinstall: "",
      installEnv: {},
      isComplex: false,
    });
    expect(result).toBe('{ version = "22", os = ["linux", "macos"] }');
  });

  it("serializes with all options", () => {
    const result = serializeMiseToolValue({
      version: "22",
      os: ["linux"],
      postinstall: "corepack enable",
      installEnv: { NODE_ENV: "production" },
      isComplex: false,
    });
    expect(result).toContain('version = "22"');
    expect(result).toContain('os = ["linux"]');
    expect(result).toContain('postinstall = "corepack enable"');
    expect(result).toContain('install_env = { NODE_ENV = "production" }');
  });

  it("passes through complex values", () => {
    const result = serializeMiseToolValue({
      version: '["3.11", "3.12"]',
      os: [],
      postinstall: "",
      installEnv: {},
      isComplex: true,
    });
    expect(result).toBe('["3.11", "3.12"]');
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
});
