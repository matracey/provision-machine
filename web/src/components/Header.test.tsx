import { render, screen, fireEvent } from "@testing-library/react";
import { Header } from "./Header";
import { AppProvider } from "../state/AppContext";

const noop = () => {};

function renderHeader(props = {}) {
  return render(
    <AppProvider>
      <Header
        onLoadJson={noop}
        onLoadYaml={noop}
        onExportJson={noop}
        onExportYaml={noop}
        onSave={noop}
        {...props}
      />
    </AppProvider>,
  );
}

describe("Header", () => {
  it("renders the app title", () => {
    renderHeader();
    expect(screen.getByText("QuickInit Config Editor")).toBeInTheDocument();
  });

  it("renders filter input", () => {
    renderHeader();
    expect(screen.getByPlaceholderText("Filter items...")).toBeInTheDocument();
  });

  it("renders action buttons", () => {
    renderHeader();
    expect(screen.getByText("Load JSON")).toBeInTheDocument();
    expect(screen.getByText("Load YAML")).toBeInTheDocument();
    expect(screen.getByText("Export JSON")).toBeInTheDocument();
    expect(screen.getByText("Export YAML")).toBeInTheDocument();
    expect(screen.getByText("Save")).toBeInTheDocument();
  });

  it("calls onLoadJson when Load JSON clicked", () => {
    const onLoadJson = vi.fn();
    renderHeader({ onLoadJson });
    fireEvent.click(screen.getByText("Load JSON"));
    expect(onLoadJson).toHaveBeenCalledOnce();
  });
});
