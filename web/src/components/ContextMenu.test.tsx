import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { ContextMenu } from "./ContextMenu";

describe("ContextMenu", () => {
  const defaultProps = {
    x: 100,
    y: 200,
    sourceContext: "Common" as const,
    onClose: vi.fn(),
    onMove: vi.fn(),
    onDelete: vi.fn(),
  };

  it("renders move options excluding source context", () => {
    render(<ContextMenu {...defaultProps} />);
    expect(screen.getByText("Move to Work")).toBeInTheDocument();
    expect(screen.getByText("Move to Personal")).toBeInTheDocument();
    expect(screen.queryByText("Move to Common")).not.toBeInTheDocument();
  });

  it("calls onMove and onClose when move clicked", async () => {
    const onMove = vi.fn();
    const onClose = vi.fn();
    render(<ContextMenu {...defaultProps} onMove={onMove} onClose={onClose} />);
    await userEvent.click(screen.getByText("Move to Work"));
    expect(onMove).toHaveBeenCalledWith("Work");
    expect(onClose).toHaveBeenCalled();
  });

  it("calls onDelete when delete clicked", async () => {
    const onDelete = vi.fn();
    const onClose = vi.fn();
    render(
      <ContextMenu {...defaultProps} onDelete={onDelete} onClose={onClose} />,
    );
    await userEvent.click(screen.getByText("Delete"));
    expect(onDelete).toHaveBeenCalled();
  });

  it("renders copy options when onCopy provided", () => {
    render(<ContextMenu {...defaultProps} onCopy={vi.fn()} />);
    expect(screen.getByText("Copy to Work")).toBeInTheDocument();
    expect(screen.getByText("Copy to Personal")).toBeInTheDocument();
  });

  it("renders split option for Common context", () => {
    render(<ContextMenu {...defaultProps} onSplit={vi.fn()} />);
    expect(screen.getByText("Split to Work & Personal")).toBeInTheDocument();
  });

  it("hides split for non-Common context", () => {
    render(
      <ContextMenu {...defaultProps} sourceContext="Work" onSplit={vi.fn()} />,
    );
    expect(
      screen.queryByText("Split to Work & Personal"),
    ).not.toBeInTheDocument();
  });
});
