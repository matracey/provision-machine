import { render, screen, fireEvent } from "@testing-library/react";
import { KvpItem } from "./KvpItem";

describe("KvpItem", () => {
  const defaultProps = {
    keyName: "core.longpaths",
    value: "true",
    context: "Common",
    section: "Git.System",
    index: 0,
    filter: "",
    isEditing: false,
    onStartEdit: vi.fn(),
    onSave: vi.fn(),
    onCancel: vi.fn(),
    onDelete: vi.fn(),
  };

  it("renders key and value", () => {
    render(<KvpItem {...defaultProps} />);
    expect(screen.getByText("core.longpaths")).toBeInTheDocument();
    expect(screen.getByText("true")).toBeInTheDocument();
  });

  it("hides when filter does not match", () => {
    const { container } = render(
      <KvpItem {...defaultProps} filter="nomatch" />,
    );
    expect(container.firstChild).toBeNull();
  });

  it("renders edit mode when isEditing", () => {
    render(<KvpItem {...defaultProps} isEditing={true} />);
    expect(screen.getByDisplayValue("core.longpaths")).toBeInTheDocument();
    expect(screen.getByDisplayValue("true")).toBeInTheDocument();
  });

  it("calls onStartEdit on double click", () => {
    const onStartEdit = vi.fn();
    render(<KvpItem {...defaultProps} onStartEdit={onStartEdit} />);
    fireEvent.doubleClick(screen.getByText("core.longpaths"));
    expect(onStartEdit).toHaveBeenCalledOnce();
  });

  it("calls onContextMenu on right-click", () => {
    const onContextMenu = vi.fn();
    render(<KvpItem {...defaultProps} onContextMenu={onContextMenu} />);
    fireEvent.contextMenu(screen.getByText("core.longpaths"));
    expect(onContextMenu).toHaveBeenCalledOnce();
  });
});
