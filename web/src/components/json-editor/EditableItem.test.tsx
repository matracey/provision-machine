import { render, screen, fireEvent } from "@testing-library/react";
import { EditableItem } from "./EditableItem";

describe("EditableItem", () => {
  it("renders string edit input", () => {
    render(
      <EditableItem
        item="hello"
        itemType="string"
        onSave={vi.fn()}
        onCancel={vi.fn()}
      />,
    );
    expect(screen.getByDisplayValue("hello")).toBeInTheDocument();
  });

  it("calls onSave with updated string on Enter", () => {
    const onSave = vi.fn();
    render(
      <EditableItem
        item="hello"
        itemType="string"
        onSave={onSave}
        onCancel={vi.fn()}
      />,
    );
    const input = screen.getByDisplayValue("hello");
    fireEvent.change(input, { target: { value: "world" } });
    fireEvent.keyDown(input, { key: "Enter" });
    expect(onSave).toHaveBeenCalledWith("world");
  });

  it("calls onCancel on Escape", () => {
    const onCancel = vi.fn();
    render(
      <EditableItem
        item="hello"
        itemType="string"
        onSave={vi.fn()}
        onCancel={onCancel}
      />,
    );
    fireEvent.keyDown(screen.getByDisplayValue("hello"), { key: "Escape" });
    expect(onCancel).toHaveBeenCalledOnce();
  });

  it("renders name-url edit inputs", () => {
    render(
      <EditableItem
        item={{ name: "extras", url: "https://..." }}
        itemType="name-url"
        onSave={vi.fn()}
        onCancel={vi.fn()}
      />,
    );
    expect(screen.getByDisplayValue("extras")).toBeInTheDocument();
    expect(screen.getByDisplayValue("https://...")).toBeInTheDocument();
  });

  it("renders object/JSON textarea", () => {
    render(
      <EditableItem
        item={{ key: "val" }}
        itemType="object"
        onSave={vi.fn()}
        onCancel={vi.fn()}
      />,
    );
    expect(screen.getByDisplayValue(/key/)).toBeInTheDocument();
  });
});
