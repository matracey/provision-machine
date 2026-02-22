import { describe, it, expect, vi, beforeEach } from "vitest";
import { saveToRepo } from "./gist";

describe("saveToRepo", () => {
  beforeEach(() => {
    vi.restoreAllMocks();
  });

  it("throws when no files are loaded", async () => {
    await expect(
      saveToRepo({
        pat: "ghp_test",
        json: null,
        yamlWork: null,
        yamlPersonal: null,
      }),
    ).rejects.toThrow("No files loaded to save");
  });

  it("sends PUT requests for each file with SHA", async () => {
    const mockFetch = vi
      .fn()
      // GET sha for Configuration.json
      .mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({ sha: "abc123" }),
      })
      // PUT Configuration.json
      .mockResolvedValueOnce({ ok: true });

    vi.stubGlobal("fetch", mockFetch);

    await saveToRepo({
      pat: "ghp_test",
      json: {
        Common: { "Scoop.Packages": ["git"] },
        Work: { "Scoop.Packages": ["slack"] },
      },
      yamlWork: null,
      yamlPersonal: null,
    });

    expect(mockFetch).toHaveBeenCalledTimes(2);
    // First call: GET sha
    const [getUrl, getOpts] = mockFetch.mock.calls[0];
    expect(getUrl).toContain("api.github.com/repos");
    expect(getUrl).toContain("Configuration.json");
    expect(getOpts.headers["Authorization"]).toBe("token ghp_test");
    // Second call: PUT content
    const [putUrl, putOpts] = mockFetch.mock.calls[1];
    expect(putUrl).toContain("Configuration.json");
    expect(putOpts.method).toBe("PUT");
    const body = JSON.parse(putOpts.body);
    expect(body.sha).toBe("abc123");
    expect(body.content).toBeDefined();
    expect(body.message).toContain("Configuration.json");
  });

  it("sends PUT without SHA for new files", async () => {
    const mockFetch = vi
      .fn()
      // GET sha returns 404
      .mockResolvedValueOnce({ ok: false, status: 404 })
      // PUT
      .mockResolvedValueOnce({ ok: true });

    vi.stubGlobal("fetch", mockFetch);

    await saveToRepo({
      pat: "ghp_test",
      json: { Common: {} },
      yamlWork: null,
      yamlPersonal: null,
    });

    const [, putOpts] = mockFetch.mock.calls[1];
    const body = JSON.parse(putOpts.body);
    expect(body.sha).toBeUndefined();
  });

  it("throws on HTTP error", async () => {
    vi.stubGlobal(
      "fetch",
      vi
        .fn()
        // GET sha
        .mockResolvedValueOnce({
          ok: true,
          json: () => Promise.resolve({ sha: "abc" }),
        })
        // PUT fails
        .mockResolvedValueOnce({
          ok: false,
          status: 401,
          json: () => Promise.resolve({ message: "Bad credentials" }),
        }),
    );

    await expect(
      saveToRepo({
        pat: "bad",
        json: { Common: {} },
        yamlWork: null,
        yamlPersonal: null,
      }),
    ).rejects.toThrow("Bad credentials");
  });
});
