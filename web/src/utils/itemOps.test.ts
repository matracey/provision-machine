import { describe, it, expect } from "vitest";
import {
  moveJsonItem,
  copyJsonItem,
  splitJsonItem,
  deleteJsonItem,
  moveYamlResource,
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

describe("moveJsonItem edge cases", () => {
  it("returns unchanged when item index out of bounds", () => {
    const json = makeJson();
    const result = moveJsonItem(json, "Scoop.Packages", 99, "Common", "Work");
    expect(result.Common).toEqual(json.Common);
  });

  it("returns unchanged when object key does not exist", () => {
    const json = makeJson();
    const result = moveJsonItem(
      json,
      "Git.System",
      "nonexistent",
      "Common",
      "Work",
    );
    expect(result.Common).toEqual(json.Common);
  });

  it("creates target section if it does not exist", () => {
    const json = {
      Common: { "Scoop.Packages": ["git"] },
      Work: {},
      Personal: {},
    };
    const result = moveJsonItem(json, "Scoop.Packages", 0, "Common", "Work");
    expect(result.Work).toEqual({ "Scoop.Packages": ["git"] });
  });
});

describe("moveYamlResource", () => {
  const makeYaml = () => ({
    work: {
      properties: {
        configurationVersion: "0.2.0",
        resources: [
          { resource: "pkg", settings: { id: "Git" } },
          { resource: "pkg", settings: { id: "VSCode" } },
        ],
      },
    },
    personal: {
      properties: {
        configurationVersion: "0.2.0",
        resources: [{ resource: "pkg", settings: { id: "Steam" } }],
      },
    },
  });

  it("moves resource from Work to Personal", () => {
    const { work, personal } = makeYaml();
    const result = moveYamlResource(work, personal, "Git", "Work", "Personal");
    expect(
      result.work?.properties?.resources?.some((r) => r.settings?.id === "Git"),
    ).toBe(false);
    expect(
      result.personal?.properties?.resources?.some(
        (r) => r.settings?.id === "Git",
      ),
    ).toBe(true);
  });

  it("returns unchanged when resource not found", () => {
    const { work, personal } = makeYaml();
    const result = moveYamlResource(
      work,
      personal,
      "NonExistent",
      "Work",
      "Personal",
    );
    expect(result.work).toBe(work);
    expect(result.personal).toBe(personal);
  });

  it("moves resource to Common (both contexts)", () => {
    const { work, personal } = makeYaml();
    const result = moveYamlResource(work, personal, "Git", "Work", "Common");
    expect(
      result.work?.properties?.resources?.some((r) => r.settings?.id === "Git"),
    ).toBe(true);
    expect(
      result.personal?.properties?.resources?.some(
        (r) => r.settings?.id === "Git",
      ),
    ).toBe(true);
  });
});
