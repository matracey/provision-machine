import {
  JSON_SECTIONS,
  CONTEXTS,
  CONTEXT_COLORS,
  CONTEXT_ICONS,
  ADD_ITEM_SECTIONS,
} from "../utils/constants";

describe("constants", () => {
  it("defines JSON_SECTIONS without Volta.Packages", () => {
    const keys = JSON_SECTIONS.map((s) => s.key);
    expect(keys).not.toContain("Volta.Packages");
    expect(keys).toContain("Scoop.Packages");
    expect(keys).toContain("Git.System");
    expect(keys).toContain("WindowsDefender.ProcessExclusions");
  });

  it("defines all three contexts", () => {
    expect(CONTEXTS).toEqual(["Common", "Work", "Personal"]);
  });

  it("has colors and icons for all contexts", () => {
    for (const ctx of CONTEXTS) {
      expect(CONTEXT_COLORS[ctx]).toBeDefined();
      expect(CONTEXT_ICONS[ctx]).toBeDefined();
    }
  });

  it("defines add-item sections without Volta", () => {
    const values = ADD_ITEM_SECTIONS.map((s) => s.value);
    expect(values).not.toContain("Volta.Packages");
    expect(values).toContain("Scoop.Packages");
  });
});
