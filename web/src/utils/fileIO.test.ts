import {
  parseJsonConfig,
  parseYamlConfig,
  serializeJson,
  serializeYaml,
  getItemDisplayText,
  getItemType,
} from "../utils/fileIO";

describe("parseJsonConfig", () => {
  it("parses valid JSON", () => {
    const result = parseJsonConfig('{"Common": {"Git": {}}}');
    expect(result).toEqual({ Common: { Git: {} } });
  });

  it("throws on invalid JSON", () => {
    expect(() => parseJsonConfig("not json")).toThrow();
  });
});

describe("parseYamlConfig", () => {
  it("parses valid YAML", () => {
    const yaml =
      'properties:\n  configurationVersion: "0.2.0"\n  resources: []';
    const result = parseYamlConfig(yaml);
    expect(result).toEqual({
      properties: { configurationVersion: "0.2.0", resources: [] },
    });
  });
});

describe("serializeJson", () => {
  it("serializes with 2-space indentation", () => {
    const result = serializeJson({ a: 1 });
    expect(result).toBe('{\n  "a": 1\n}');
  });
});

describe("serializeYaml", () => {
  it("serializes to YAML string", () => {
    const result = serializeYaml({
      properties: { configurationVersion: "0.2.0" },
    });
    expect(result).toContain("configurationVersion");
  });
});

describe("getItemDisplayText", () => {
  it("returns string items directly", () => {
    expect(getItemDisplayText("hello")).toBe("hello");
  });

  it("returns name for name-url objects", () => {
    expect(getItemDisplayText({ name: "extras", url: "https://..." })).toBe(
      "extras",
    );
  });

  it("returns id for id objects", () => {
    expect(getItemDisplayText({ id: "Microsoft.Git" })).toBe("Microsoft.Git");
  });

  it("returns JSON for other objects", () => {
    expect(getItemDisplayText({ foo: "bar" })).toBe('{"foo":"bar"}');
  });
});

describe("getItemType", () => {
  it("returns string for strings", () => {
    expect(getItemType("hello")).toBe("string");
  });

  it("returns name-url for name+url objects", () => {
    expect(getItemType({ name: "a", url: "b" })).toBe("name-url");
  });

  it("returns object for other objects", () => {
    expect(getItemType({ foo: "bar" })).toBe("object");
  });
});
