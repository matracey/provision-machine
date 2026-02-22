import { render, screen } from "@testing-library/react";
import { DropZone } from "./DropZone";
import { AppProvider } from "../state/AppContext";

describe("DropZone", () => {
  it("renders full drop zone when no files loaded", () => {
    render(
      <AppProvider>
        <DropZone />
      </AppProvider>,
    );
    expect(screen.getByText(/Drag & drop/)).toBeInTheDocument();
    expect(screen.getByTestId("dropzone-full")).toBeInTheDocument();
  });

  it("renders browse button", () => {
    render(
      <AppProvider>
        <DropZone />
      </AppProvider>,
    );
    expect(screen.getByText("Browse Files")).toBeInTheDocument();
  });
});
