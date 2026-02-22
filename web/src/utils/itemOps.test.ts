import { describe, it, expect } from "vitest";
import {
  moveJsonItem,
  copyJsonItem,
  splitJsonItem,
  deleteJsonItem,
} from "./itemOps";

const makeJson = () => ({
  Common: {
    "Scoop.Packages": ["git", "curl"],
    "Git.System": { "core.autocrlf": "true" },
  },
  Work: { "Scoop.Packages": ["slack"] },
  Personal: { "Scoop.Packages": ["steam"] },
});

describe("moveJsonItem", () => {
  it("moves array item from Common to Work", () => {
    const result = moveJsonItem(
      makeJson(),
      "Scoop.Packages",
      0,
      "Common",
      "Work",
    );
    expect(result.Common).toEqual({
      "Scoop.Packages": ["curl"],
      "Git.System": { "core.autocrlf": "true" },
    });
    expect(result.Work).toEqual({ "Scoop.Packages": ["slack", "git"] });
  });

  it("moves object key from Common to Personal", () => {
    const result = moveJsonItem(
      makeJson(),
      "Git.System",
      "core.autocrlf",
      "Common",
      "Personal",
    );
    expect((result.Common as Record<string, unknown>)["Git.System"]).toEqual(
      {},
    );
    expect((result.Personal as Record<string, unknown>)["Git.System"]).toEqual({
      "core.autocrlf": "true",
    });
  });
});

describe("copyJsonItem", () => {
  it("copies array item to target without removing source", () => {
    const result = copyJsonItem(
      makeJson(),
      "Scoop.Packages",
      0,
      "Common",
      "Work",
    );
    expect(result.Common).toEqual({
      "Scoop.Packages": ["git", "curl"],
      "Git.System": { "core.autocrlf": "true" },
    });
    expect(result.Work).toEqual({ "Scoop.Packages": ["slack", "git"] });
  });
});

describe("splitJsonItem", () => {
  it("copies to Work and Personal, removes from Common", () => {
    const result = splitJsonItem(makeJson(), "Scoop.Packages", 0);
    expect(result.Common).toEqual({
      "Scoop.Packages": ["curl"],
      "Git.System": { "core.autocrlf": "true" },
    });
    expect(result.Work).toEqual({ "Scoop.Packages": ["slack", "git"] });
    expect(result.Personal).toEqual({ "Scoop.Packages": ["steam", "git"] });
  });
});

describe("deleteJsonItem", () => {
  it("deletes array item", () => {
    const result = deleteJsonItem(makeJson(), "Scoop.Packages", 0, "Common");
    expect(result.Common).toEqual({
      "Scoop.Packages": ["curl"],
      "Git.System": { "core.autocrlf": "true" },
    });
  });

  it("deletes object key", () => {
    const result = deleteJsonItem(
      makeJson(),
      "Git.System",
      "core.autocrlf",
      "Common",
    );
    expect((result.Common as Record<string, unknown>)["Git.System"]).toEqual(
      {},
    );
  });
});
