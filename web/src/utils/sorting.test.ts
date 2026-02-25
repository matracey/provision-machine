import { describe, it, expect } from "vitest";
import { prefixAwareCompare, sortItems, sortObjectKeys } from "./sorting";

describe("prefixAwareCompare", () => {
  it("sorts alphabetically", () => {
    expect(prefixAwareCompare("apple", "banana")).toBeLessThan(0);
    expect(prefixAwareCompare("banana", "apple")).toBeGreaterThan(0);
  });

  it("shorter prefix comes first at boundary", () => {
    expect(prefixAwareCompare("graph", "graph-foo")).toBeLessThan(0);
    expect(prefixAwareCompare("graph-foo", "graph")).toBeGreaterThan(0);
  });

  it("does not treat as prefix without boundary", () => {
    expect(prefixAwareCompare("graph", "graphite")).toBeLessThan(0); // normal alphabetical
  });

  it("is case insensitive", () => {
    expect(prefixAwareCompare("ABC", "abc")).toBe(0);
  });

  it("handles equal strings", () => {
    expect(prefixAwareCompare("same", "same")).toBe(0);
  });

  it("handles empty strings", () => {
    expect(prefixAwareCompare("", "")).toBe(0);
    expect(prefixAwareCompare("", "a")).toBeLessThan(0);
    expect(prefixAwareCompare("a", "")).toBeGreaterThan(0);
  });

  it("treats dot as boundary", () => {
    expect(prefixAwareCompare("git", "git.system")).toBeLessThan(0);
  });

  it("treats colon as boundary", () => {
    expect(prefixAwareCompare("npm", "npm:prettier")).toBeLessThan(0);
  });

  it("treats slash as boundary", () => {
    expect(prefixAwareCompare("src", "src/utils")).toBeLessThan(0);
  });
});

describe("sortItems", () => {
  it("sorts strings", () => {
    expect(sortItems(["curl", "bat", "git"])).toEqual(["bat", "curl", "git"]);
  });

  it("sorts name-url objects by name", () => {
    const items = [{ name: "z-repo" }, { name: "a-repo" }];
    expect(sortItems(items)).toEqual([{ name: "a-repo" }, { name: "z-repo" }]);
  });

  it("sorts objects with Name property", () => {
    const items = [{ Name: "zebra" }, { Name: "alpha" }];
    expect(sortItems(items)).toEqual([{ Name: "alpha" }, { Name: "zebra" }]);
  });

  it("handles empty array", () => {
    expect(sortItems([])).toEqual([]);
  });

  it("handles single item", () => {
    expect(sortItems(["only"])).toEqual(["only"]);
  });

  it("does not mutate original array", () => {
    const original = ["c", "a", "b"];
    const sorted = sortItems(original);
    expect(original).toEqual(["c", "a", "b"]);
    expect(sorted).toEqual(["a", "b", "c"]);
  });
});

describe("sortObjectKeys", () => {
  it("sorts object keys alphabetically", () => {
    const obj = { "z.key": "val", "a.key": "val", "m.key": "val" };
    const result = sortObjectKeys(obj);
    expect(Object.keys(result)).toEqual(["a.key", "m.key", "z.key"]);
  });
});
