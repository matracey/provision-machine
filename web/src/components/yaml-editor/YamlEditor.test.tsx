import { render, screen, fireEvent } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { YamlEditor } from "./YamlEditor";
import { AppContext } from "../../state/AppContextValue";
import { AppProvider } from "../../state/AppContext";
import type { AppState, YamlConfig } from "../../types";
import type { ReactNode } from "react";

function makeState(overrides: Partial<AppState> = {}): AppState {
  return {
    json: null,
    yamlWork: null,
    yamlPersonal: null,
    miseData: null,
    currentTab: "yaml",
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

const workOnly: YamlConfig = {
  properties: {
    configurationVersion: "0.2.0",
    resources: [
      {
        resource: "Microsoft.WinGet.DSC/WinGetPackage",
        settings: {
          id: "Microsoft.VisualStudio.2022.Enterprise",
          source: "winget",
        },
        directives: { description: "VS Enterprise" },
      },
    ],
  },
};

const personalOnly: YamlConfig = {
  properties: {
    configurationVersion: "0.2.0",
    resources: [
      {
        resource: "Microsoft.WinGet.DSC/WinGetPackage",
        settings: { id: "Valve.Steam", source: "winget" },
        directives: { description: "Steam" },
      },
    ],
  },
};

describe("YamlEditor", () => {
  it("shows empty state when no YAML loaded", () => {
    render(
      <AppProvider>
        <YamlEditor />
      </AppProvider>,
    );
    expect(
      screen.getByText("Load WinGet DSC YAML files to begin editing"),
    ).toBeInTheDocument();
  });

  it("shows context menu on right-click of a YAML item", () => {
    const state = makeState({
      yamlWork: workOnly,
      yamlPersonal: personalOnly,
    });

    renderWithState(<YamlEditor />, state);

    const item = screen.getByText("Microsoft.VisualStudio.2022.Enterprise");
    fireEvent.contextMenu(item);

    expect(screen.getByTestId("context-menu")).toBeInTheDocument();
    expect(screen.getByText("Move to Common")).toBeInTheDocument();
    expect(screen.getByText("Move to Personal")).toBeInTheDocument();
    expect(screen.queryByText("Move to Work")).not.toBeInTheDocument();
  });

  it("moves a YAML item via context menu", async () => {
    const state = makeState({
      yamlWork: workOnly,
      yamlPersonal: personalOnly,
    });

    const { dispatch } = renderWithState(<YamlEditor />, state);

    fireEvent.contextMenu(
      screen.getByText("Microsoft.VisualStudio.2022.Enterprise"),
    );
    await userEvent.click(screen.getByText("Move to Personal"));

    const workCall = dispatch.mock.calls.find(
      (c: unknown[]) => (c[0] as { type: string }).type === "SET_YAML_WORK",
    );
    const personalCall = dispatch.mock.calls.find(
      (c: unknown[]) => (c[0] as { type: string }).type === "SET_YAML_PERSONAL",
    );
    expect(workCall).toBeDefined();
    expect(personalCall).toBeDefined();
  });

  it("deletes a YAML item via context menu", async () => {
    const state = makeState({
      yamlWork: workOnly,
      yamlPersonal: personalOnly,
    });

    const { dispatch } = renderWithState(<YamlEditor />, state);

    fireEvent.contextMenu(
      screen.getByText("Microsoft.VisualStudio.2022.Enterprise"),
    );
    await userEvent.click(screen.getByText("Delete"));

    const workCall = dispatch.mock.calls.find(
      (c: unknown[]) => (c[0] as { type: string }).type === "SET_YAML_WORK",
    );
    expect(workCall).toBeDefined();
    const newWork = (workCall![0] as { payload: typeof workOnly }).payload;
    expect(
      newWork.properties?.resources?.some(
        (r) => r.settings?.id === "Microsoft.VisualStudio.2022.Enterprise",
      ),
    ).toBe(false);
  });

  it("closes context menu when pressing Escape", () => {
    const state = makeState({
      yamlWork: workOnly,
      yamlPersonal: personalOnly,
    });

    renderWithState(<YamlEditor />, state);

    fireEvent.contextMenu(
      screen.getByText("Microsoft.VisualStudio.2022.Enterprise"),
    );
    expect(screen.getByTestId("context-menu")).toBeInTheDocument();

    fireEvent.keyDown(document, { key: "Escape" });
    expect(screen.queryByTestId("context-menu")).not.toBeInTheDocument();
  });
});
