import { render, screen, fireEvent } from "@testing-library/react";
import { AliasItem } from "./AliasItem";

describe("AliasItem", () => {
  const defaultProps = {
    aliasName: "clean",
    command: "scoop cleanup *; scoop cache rm *;",
    description: "Clean up all the caches and remove all the old versions",
    context: "Common",
    section: "Scoop.Aliases",
    index: 0,
    filter: "",
    isEditing: false,
    onStartEdit: vi.fn(),
    onSave: vi.fn(),
    onCancel: vi.fn(),
    onDelete: vi.fn(),
  };

  it("renders alias name, command, and description", () => {
    render(<AliasItem {...defaultProps} />);
    expect(screen.getByText("clean")).toBeInTheDocument();
    expect(
      screen.getByText("scoop cleanup *; scoop cache rm *;"),
    ).toBeInTheDocument();
    expect(
      screen.getByText(
        "Clean up all the caches and remove all the old versions",
      ),
    ).toBeInTheDocument();
  });

  it("hides description when empty", () => {
    render(<AliasItem {...defaultProps} description="" />);
    expect(screen.getByText("clean")).toBeInTheDocument();
    expect(
      screen.getByText("scoop cleanup *; scoop cache rm *;"),
    ).toBeInTheDocument();
  });

  it("hides when filter does not match", () => {
    const { container } = render(
      <AliasItem {...defaultProps} filter="nomatch" />,
    );
    expect(container.firstChild).toBeNull();
  });

  it("shows when filter matches alias name", () => {
    render(<AliasItem {...defaultProps} filter="clean" />);
    expect(screen.getByText("clean")).toBeInTheDocument();
  });

  it("shows when filter matches command", () => {
    render(<AliasItem {...defaultProps} filter="cleanup" />);
    expect(screen.getByText("clean")).toBeInTheDocument();
  });

  it("shows when filter matches description", () => {
    render(<AliasItem {...defaultProps} filter="caches" />);
    expect(screen.getByText("clean")).toBeInTheDocument();
  });

  it("renders edit mode when isEditing", () => {
    render(<AliasItem {...defaultProps} isEditing={true} />);
    expect(screen.getByDisplayValue("clean")).toBeInTheDocument();
    expect(
      screen.getByDisplayValue("scoop cleanup *; scoop cache rm *;"),
    ).toBeInTheDocument();
    expect(
      screen.getByDisplayValue(
        "Clean up all the caches and remove all the old versions",
      ),
    ).toBeInTheDocument();
  });

  it("calls onStartEdit on double click", () => {
    const onStartEdit = vi.fn();
    render(<AliasItem {...defaultProps} onStartEdit={onStartEdit} />);
    fireEvent.doubleClick(screen.getByText("clean"));
    expect(onStartEdit).toHaveBeenCalledOnce();
  });

  it("calls onSave with trimmed values on Enter in description", () => {
    const onSave = vi.fn();
    render(<AliasItem {...defaultProps} isEditing={true} onSave={onSave} />);
    fireEvent.keyDown(
      screen.getByDisplayValue(
        "Clean up all the caches and remove all the old versions",
      ),
      { key: "Enter" },
    );
    expect(onSave).toHaveBeenCalledWith(
      "clean",
      "scoop cleanup *; scoop cache rm *;",
      "Clean up all the caches and remove all the old versions",
    );
  });

  it("calls onCancel on Escape", () => {
    const onCancel = vi.fn();
    render(
      <AliasItem {...defaultProps} isEditing={true} onCancel={onCancel} />,
    );
    fireEvent.keyDown(screen.getByDisplayValue("clean"), { key: "Escape" });
    expect(onCancel).toHaveBeenCalledOnce();
  });

  it("calls onContextMenu on right-click", () => {
    const onContextMenu = vi.fn();
    render(<AliasItem {...defaultProps} onContextMenu={onContextMenu} />);
    fireEvent.contextMenu(screen.getByText("clean"));
    expect(onContextMenu).toHaveBeenCalledOnce();
  });

  it("calls onDelete when delete button clicked", () => {
    const onDelete = vi.fn();
    render(<AliasItem {...defaultProps} onDelete={onDelete} />);
    fireEvent.click(screen.getByTitle("Delete"));
    expect(onDelete).toHaveBeenCalledOnce();
  });
});
