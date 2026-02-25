import {
  fuzzyScore,
  fuzzySearch,
  parseRegistryToml,
  hasBackendPrefix,
  COMMON_TOOLS,
} from "./miseRegistry";
import type { RegistryEntry } from "../types";

describe("fuzzyScore", () => {
  it("returns highest score for exact match", () => {
    expect(fuzzyScore("node", "node")).toBe(10000);
  });

  it("scores prefix match higher than contains", () => {
    const prefix = fuzzyScore("no", "node");
    const contains = fuzzyScore("od", "node");
    expect(prefix).toBeGreaterThan(contains);
  });

  it("returns -1 when query chars are not all present", () => {
    expect(fuzzyScore("xyz", "node")).toBe(-1);
  });

  it("scores consecutive matches higher", () => {
    const consecutive = fuzzyScore("rip", "ripgrep");
    const scattered = fuzzyScore("rgp", "ripgrep");
    expect(consecutive).toBeGreaterThan(scattered);
  });

  it("handles case insensitively", () => {
    expect(fuzzyScore("NODE", "node")).toBe(10000);
    expect(fuzzyScore("node", "Node")).toBe(10000);
  });
});

describe("fuzzySearch", () => {
  const items: RegistryEntry[] = [
    { name: "node" },
    { name: "python" },
    { name: "ripgrep", aliases: ["rg"] },
    { name: "golang" },
    { name: "nodemon" },
  ];

  it("returns all items when query is empty", () => {
    const result = fuzzySearch("", items);
    expect(result.length).toBe(items.length);
  });

  it("filters by name", () => {
    const result = fuzzySearch("node", items);
    expect(result[0].name).toBe("node");
    expect(result.some((r) => r.name === "nodemon")).toBe(true);
  });

  it("matches aliases", () => {
    const result = fuzzySearch("rg", items);
    expect(result.some((r) => r.name === "ripgrep")).toBe(true);
  });

  it("respects limit", () => {
    const result = fuzzySearch("", items, 2);
    expect(result.length).toBe(2);
  });

  it("returns empty array when nothing matches", () => {
    const result = fuzzySearch("zzzzz", items);
    expect(result.length).toBe(0);
  });
});

describe("parseRegistryToml", () => {
  it("parses description", () => {
    const content = `backends = ["core:node"]
description = "Node.js runtime"`;
    const entry = parseRegistryToml("node", content);
    expect(entry.name).toBe("node");
    expect(entry.description).toBe("Node.js runtime");
  });

  it("parses backends", () => {
    const content = `backends = [
  "aqua:BurntSushi/ripgrep",
  "cargo:ripgrep",
]
description = "fast search"`;
    const entry = parseRegistryToml("ripgrep", content);
    expect(entry.backends).toEqual([
      "aqua:BurntSushi/ripgrep",
      "cargo:ripgrep",
    ]);
  });

  it("parses aliases", () => {
    const content = `aliases = ["rg"]
backends = ["cargo:ripgrep"]
description = "search tool"`;
    const entry = parseRegistryToml("ripgrep", content);
    expect(entry.aliases).toEqual(["rg"]);
  });

  it("handles missing fields", () => {
    const content = `backends = ["core:go"]`;
    const entry = parseRegistryToml("go", content);
    expect(entry.name).toBe("go");
    expect(entry.description).toBeUndefined();
    expect(entry.aliases).toBeUndefined();
  });
});

describe("hasBackendPrefix", () => {
  it("detects known prefixes", () => {
    expect(hasBackendPrefix("cargo:ripgrep")).toBe(true);
    expect(hasBackendPrefix("npm:prettier")).toBe(true);
    expect(hasBackendPrefix("pipx:black")).toBe(true);
    expect(hasBackendPrefix("go:golang.org/x/tools")).toBe(true);
  });

  it("returns false for registry tool names", () => {
    expect(hasBackendPrefix("node")).toBe(false);
    expect(hasBackendPrefix("python")).toBe(false);
  });
});

describe("COMMON_TOOLS", () => {
  it("contains popular tools", () => {
    const names = COMMON_TOOLS.map((t) => t.name);
    expect(names).toContain("node");
    expect(names).toContain("python");
    expect(names).toContain("go");
  });

  it("all entries have descriptions", () => {
    for (const tool of COMMON_TOOLS) {
      expect(tool.description).toBeDefined();
    }
  });
});
