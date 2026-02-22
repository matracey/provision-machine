import {
  getNestedValue,
  setNestedValue,
  deleteNestedValue,
} from "../utils/nested";

describe("getNestedValue", () => {
  it("returns value at a single-level path", () => {
    expect(getNestedValue({ a: 1 }, "a")).toBe(1);
  });

  it("returns value at a nested path", () => {
    expect(getNestedValue({ a: { b: { c: 42 } } }, "a.b.c")).toBe(42);
  });

  it("returns undefined for missing path", () => {
    expect(getNestedValue({ a: 1 }, "b")).toBeUndefined();
  });

  it("returns undefined for undefined object", () => {
    expect(getNestedValue(undefined, "a")).toBeUndefined();
  });

  it("returns arrays", () => {
    const obj = { items: { list: [1, 2, 3] } };
    expect(getNestedValue(obj, "items.list")).toEqual([1, 2, 3]);
  });
});

describe("setNestedValue", () => {
  it("sets a value at a single-level path", () => {
    const obj: Record<string, unknown> = {};
    setNestedValue(obj, "a", 1);
    expect(obj.a).toBe(1);
  });

  it("sets a value at a nested path, creating intermediaries", () => {
    const obj: Record<string, unknown> = {};
    setNestedValue(obj, "a.b.c", "hello");
    expect((obj as { a: { b: { c: string } } }).a.b.c).toBe("hello");
  });

  it("overwrites existing values", () => {
    const obj: Record<string, unknown> = { a: { b: "old" } };
    setNestedValue(obj, "a.b", "new");
    expect((obj as { a: { b: string } }).a.b).toBe("new");
  });
});

describe("deleteNestedValue", () => {
  it("deletes an item from a nested array by index", () => {
    const obj = { items: ["a", "b", "c"] };
    deleteNestedValue(obj, "items", 1);
    expect(obj.items).toEqual(["a", "c"]);
  });

  it("does nothing when target is not an array", () => {
    const obj = { items: "not-an-array" };
    deleteNestedValue(obj as Record<string, unknown>, "items", 0);
    expect(obj.items).toBe("not-an-array");
  });

  it("does nothing for undefined object", () => {
    expect(() => deleteNestedValue(undefined, "items", 0)).not.toThrow();
  });
});
