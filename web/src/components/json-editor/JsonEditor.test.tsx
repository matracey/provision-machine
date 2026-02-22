import { render, screen, fireEvent } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { JsonEditor } from "./JsonEditor";
import { AppContext } from "../../state/AppContextValue";
import { AppProvider } from "../../state/AppContext";
import type { AppState } from "../../types";
import type { ReactNode } from "react";

function makeState(overrides: Partial<AppState> = {}): AppState {
  return {
    json: null,
    yamlWork: null,
    yamlPersonal: null,
    miseData: null,
    currentTab: "json",
    filter: "",
    collapsedPanels: new Set<string>(),
    collapsedSections: new Set<string>(),
    hasLoadedFiles: false,
    editingItem: null,
    githubPat: null,
    statusText: "",
    lastModified: "",
    ...overrides,
  };
}

function renderWithState(ui: ReactNode, state: AppState) {
  const dispatch = vi.fn();
  return {
    dispatch,
    ...render(
      <AppContext.Provider value={{ state, dispatch }}>
        {ui}
      </AppContext.Provider>,
    ),
  };
}

describe("JsonEditor", () => {
  it("shows empty state when no json loaded", () => {
    render(
      <AppProvider>
        <JsonEditor onAddItem={vi.fn()} />
      </AppProvider>,
    );
    expect(
      screen.getByText("Load a Configuration.json file to begin editing"),
    ).toBeInTheDocument();
  });

  it("shows context menu on right-click of an item", async () => {
    const state = makeState({
      json: {
        Common: {
          Scoop: { Packages: ["git", "curl"] },
        },
        Work: {},
        Personal: {},
      },
    });

    renderWithState(<JsonEditor onAddItem={vi.fn()} />, state);

    const item = screen.getByText("git");
    fireEvent.contextMenu(item);

    expect(screen.getByTestId("context-menu")).toBeInTheDocument();
    expect(screen.getByText("Move to Work")).toBeInTheDocument();
    expect(screen.getByText("Move to Personal")).toBeInTheDocument();
  });

  it("dispatches SET_JSON when moving via context menu", async () => {
    const state = makeState({
      json: {
        Common: {
          Scoop: { Packages: ["git", "curl"] },
        },
        Work: { Scoop: { Packages: [] } },
        Personal: {},
      },
    });

    const { dispatch } = renderWithState(
      <JsonEditor onAddItem={vi.fn()} />,
      state,
    );

    fireEvent.contextMenu(screen.getByText("git"));
    await userEvent.click(screen.getByText("Move to Work"));

    const setJsonCall = dispatch.mock.calls.find(
      (c: unknown[]) => (c[0] as { type: string }).type === "SET_JSON",
    );
    expect(setJsonCall).toBeDefined();
  });

  it("closes context menu when clicking outside", async () => {
    const state = makeState({
      json: {
        Common: { Scoop: { Packages: ["git"] } },
        Work: {},
        Personal: {},
      },
    });

    renderWithState(<JsonEditor onAddItem={vi.fn()} />, state);

    fireEvent.contextMenu(screen.getByText("git"));
    expect(screen.getByTestId("context-menu")).toBeInTheDocument();

    // Click outside the menu
    fireEvent.mouseDown(document.body);
    expect(screen.queryByTestId("context-menu")).not.toBeInTheDocument();
  });

  it("shows copy and split options in context menu", () => {
    const state = makeState({
      json: {
        Common: { Scoop: { Packages: ["git"] } },
        Work: {},
        Personal: {},
      },
    });

    renderWithState(<JsonEditor onAddItem={vi.fn()} />, state);

    fireEvent.contextMenu(screen.getByText("git"));
    expect(screen.getByText("Copy to Work")).toBeInTheDocument();
    expect(screen.getByText("Copy to Personal")).toBeInTheDocument();
    expect(screen.getByText("Split to Work & Personal")).toBeInTheDocument();
  });

  it("dispatches SET_JSON when deleting via context menu", async () => {
    const state = makeState({
      json: {
        Common: { Scoop: { Packages: ["git", "curl"] } },
        Work: {},
        Personal: {},
      },
    });

    const { dispatch } = renderWithState(
      <JsonEditor onAddItem={vi.fn()} />,
      state,
    );

    fireEvent.contextMenu(screen.getByText("git"));
    await userEvent.click(screen.getByText("Delete"));

    const setJsonCall = dispatch.mock.calls.find(
      (c: unknown[]) => (c[0] as { type: string }).type === "SET_JSON",
    );
    expect(setJsonCall).toBeDefined();
  });
});
