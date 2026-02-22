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
});

describe("sortItems", () => {
  it("sorts strings", () => {
    expect(sortItems(["curl", "bat", "git"])).toEqual(["bat", "curl", "git"]);
  });

  it("sorts name-url objects by name", () => {
    const items = [{ name: "z-repo" }, { name: "a-repo" }];
    expect(sortItems(items)).toEqual([{ name: "a-repo" }, { name: "z-repo" }]);
  });
});

describe("sortObjectKeys", () => {
  it("sorts object keys alphabetically", () => {
    const obj = { "z.key": "val", "a.key": "val", "m.key": "val" };
    const result = sortObjectKeys(obj);
    expect(Object.keys(result)).toEqual(["a.key", "m.key", "z.key"]);
  });
});
