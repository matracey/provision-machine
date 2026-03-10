import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MiseToolItem } from "./MiseToolItem";

describe("MiseToolItem", () => {
  const tool = {
    name: "node",
    rawValue: '"20"',
    displayValue: "20",
    category: "Core",
  };

  it("renders tool name and value", () => {
    render(
      <MiseToolItem
        tool={tool}
        onEdit={vi.fn()}
        onDelete={vi.fn()}
        filter=""
      />,
    );
    expect(screen.getByText("node")).toBeInTheDocument();
    expect(screen.getByText("20")).toBeInTheDocument();
  });

  it("hides when filter does not match", () => {
    const { container } = render(
      <MiseToolItem
        tool={tool}
        onEdit={vi.fn()}
        onDelete={vi.fn()}
        filter="python"
      />,
    );
    expect(container.innerHTML).toBe("");
  });

  it("shows when filter matches name", () => {
    render(
      <MiseToolItem
        tool={tool}
        onEdit={vi.fn()}
        onDelete={vi.fn()}
        filter="nod"
      />,
    );
    expect(screen.getByText("node")).toBeInTheDocument();
  });

  it("shows when filter matches displayValue", () => {
    render(
      <MiseToolItem
        tool={tool}
        onEdit={vi.fn()}
        onDelete={vi.fn()}
        filter="20"
      />,
    );
    expect(screen.getByText("node")).toBeInTheDocument();
  });

  it("filter is case insensitive", () => {
    render(
      <MiseToolItem
        tool={tool}
        onEdit={vi.fn()}
        onDelete={vi.fn()}
        filter="NODE"
      />,
    );
    expect(screen.getByText("node")).toBeInTheDocument();
  });

  it("shows when filter is empty", () => {
    render(
      <MiseToolItem
        tool={tool}
        onEdit={vi.fn()}
        onDelete={vi.fn()}
        filter=""
      />,
    );
    expect(screen.getByText("node")).toBeInTheDocument();
  });

  it("calls onEdit when edit button is clicked", async () => {
    const onEdit = vi.fn();
    const user = userEvent.setup();
    render(
      <MiseToolItem tool={tool} onEdit={onEdit} onDelete={vi.fn()} filter="" />,
    );
    await user.click(screen.getByTitle("Edit"));
    expect(onEdit).toHaveBeenCalledOnce();
  });

  it("calls onDelete when delete button is clicked", async () => {
    const onDelete = vi.fn();
    const user = userEvent.setup();
    render(
      <MiseToolItem
        tool={tool}
        onEdit={vi.fn()}
        onDelete={onDelete}
        filter=""
      />,
    );
    await user.click(screen.getByTitle("Delete"));
    expect(onDelete).toHaveBeenCalledOnce();
  });

  it("shows OS indicator when rawValue contains os", () => {
    const osTool = {
      ...tool,
      rawValue: '{ version = "20", os = ["linux"] }',
    };
    render(
      <MiseToolItem
        tool={osTool}
        onEdit={vi.fn()}
        onDelete={vi.fn()}
        filter=""
      />,
    );
    expect(screen.getByTitle("OS-specific")).toBeInTheDocument();
  });

  it("shows postinstall indicator when rawValue contains postinstall", () => {
    const postTool = {
      ...tool,
      rawValue: '{ version = "20", postinstall = "corepack enable" }',
    };
    render(
      <MiseToolItem
        tool={postTool}
        onEdit={vi.fn()}
        onDelete={vi.fn()}
        filter=""
      />,
    );
    expect(screen.getByTitle("Has post-install command")).toBeInTheDocument();
  });

  it("shows both indicators together", () => {
    const bothTool = {
      ...tool,
      rawValue:
        '{ version = "20", os = ["linux"], postinstall = "corepack enable" }',
    };
    render(
      <MiseToolItem
        tool={bothTool}
        onEdit={vi.fn()}
        onDelete={vi.fn()}
        filter=""
      />,
    );
    expect(screen.getByTitle("OS-specific")).toBeInTheDocument();
    expect(screen.getByTitle("Has post-install command")).toBeInTheDocument();
  });

  it("does not show indicators for simple values", () => {
    render(
      <MiseToolItem
        tool={tool}
        onEdit={vi.fn()}
        onDelete={vi.fn()}
        filter=""
      />,
    );
    expect(screen.queryByTitle("OS-specific")).not.toBeInTheDocument();
    expect(
      screen.queryByTitle("Has post-install command"),
    ).not.toBeInTheDocument();
  });
});
