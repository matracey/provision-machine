import { render, screen, fireEvent } from "@testing-library/react";
import { TabBar } from "./TabBar";
import { AppProvider } from "../state/AppContext";

describe("TabBar", () => {
  it("renders json and yaml tabs", () => {
    render(
      <AppProvider>
        <TabBar />
      </AppProvider>,
    );
    expect(screen.getByText("Configuration.json")).toBeInTheDocument();
    expect(screen.getByText("WinGet DSC")).toBeInTheDocument();
  });

  it("highlights the active tab", () => {
    render(
      <AppProvider>
        <TabBar />
      </AppProvider>,
    );
    const jsonTab = screen.getByText("Configuration.json").closest("button");
    expect(jsonTab?.className).toContain("tab-active");
  });

  it("switches tab on click", () => {
    render(
      <AppProvider>
        <TabBar />
      </AppProvider>,
    );
    fireEvent.click(screen.getByText("WinGet DSC"));
    const yamlTab = screen.getByText("WinGet DSC").closest("button");
    expect(yamlTab?.className).toContain("tab-active");
  });
});
