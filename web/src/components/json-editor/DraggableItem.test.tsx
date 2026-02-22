import { render, screen, fireEvent } from "@testing-library/react";
import { DraggableItem } from "./DraggableItem";

describe("DraggableItem", () => {
  const defaultProps = {
    item: "main/git",
    context: "Common",
    section: "Scoop.Packages",
    index: 0,
    filter: "",
    onEdit: vi.fn(),
    onDelete: vi.fn(),
  };

  it("renders string item text", () => {
    render(<DraggableItem {...defaultProps} />);
    expect(screen.getByText("main/git")).toBeInTheDocument();
  });

  it("renders name-url item with subtitle", () => {
    render(
      <DraggableItem
        {...defaultProps}
        item={{
          name: "extras",
          url: "https://github.com/ScoopInstaller/Extras",
        }}
      />,
    );
    expect(screen.getByText("extras")).toBeInTheDocument();
  });

  it("hides when filter does not match", () => {
    const { container } = render(
      <DraggableItem {...defaultProps} filter="nomatch" />,
    );
    expect(container.firstChild).toBeNull();
  });

  it("calls onEdit on double click", () => {
    const onEdit = vi.fn();
    render(<DraggableItem {...defaultProps} onEdit={onEdit} />);
    fireEvent.doubleClick(screen.getByText("main/git"));
    expect(onEdit).toHaveBeenCalledOnce();
  });

  it("calls onDelete when delete button clicked", () => {
    const onDelete = vi.fn();
    render(<DraggableItem {...defaultProps} onDelete={onDelete} />);
    fireEvent.click(screen.getByTitle("Delete"));
    expect(onDelete).toHaveBeenCalledOnce();
  });

  it("calls onContextMenu on right-click", () => {
    const onContextMenu = vi.fn();
    render(<DraggableItem {...defaultProps} onContextMenu={onContextMenu} />);
    fireEvent.contextMenu(screen.getByText("main/git"));
    expect(onContextMenu).toHaveBeenCalledOnce();
  });

  it("does not error when onContextMenu is not provided", () => {
    render(<DraggableItem {...defaultProps} />);
    expect(() => {
      fireEvent.contextMenu(screen.getByText("main/git"));
    }).not.toThrow();
  });
});
