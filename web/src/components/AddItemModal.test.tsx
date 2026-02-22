import { render, screen } from "@testing-library/react";
import { AddItemModal } from "./AddItemModal";
import { AppProvider } from "../state/AppContext";

describe("AddItemModal", () => {
  it("renders when open", () => {
    render(
      <AppProvider>
        <AddItemModal open={true} onClose={() => {}} />
      </AppProvider>,
    );
    expect(screen.getByText("Add Item")).toBeInTheDocument();
    expect(screen.getByText("Context")).toBeInTheDocument();
    expect(screen.getByText("Section")).toBeInTheDocument();
  });

  it("does not render visibly when closed", () => {
    const { container } = render(
      <AppProvider>
        <AddItemModal open={false} onClose={() => {}} />
      </AppProvider>,
    );
    const dialog = container.querySelector("dialog");
    expect(dialog?.className).not.toContain("modal-open");
  });

  it("renders context options", () => {
    render(
      <AppProvider>
        <AddItemModal open={true} onClose={() => {}} />
      </AppProvider>,
    );
    expect(screen.getByText("Common")).toBeInTheDocument();
    expect(screen.getByText("Work")).toBeInTheDocument();
    expect(screen.getByText("Personal")).toBeInTheDocument();
  });

  it("renders section options without Volta", () => {
    render(
      <AppProvider>
        <AddItemModal open={true} onClose={() => {}} />
      </AppProvider>,
    );
    expect(screen.getByText("Scoop Packages")).toBeInTheDocument();
    expect(screen.queryByText("Volta Packages")).not.toBeInTheDocument();
  });
});
