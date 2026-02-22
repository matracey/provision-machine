import { render, screen } from "@testing-library/react";
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
});
