import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MiseKeyValueSection } from "./MiseKeyValueSection";

describe("MiseKeyValueSection", () => {
  const defaultProps = {
    title: "Environment",
    icon: <span data-testid="icon">🔧</span>,
    data: { NODE_ENV: '"development"', PORT: '"3000"' },
    onChange: vi.fn(),
  };

  beforeEach(() => {
    defaultProps.onChange.mockClear();
  });

  it("renders title and entry count", () => {
    render(<MiseKeyValueSection {...defaultProps} />);
    expect(screen.getByText("Environment")).toBeInTheDocument();
    expect(screen.getByText("2")).toBeInTheDocument();
  });

  it("renders key-value entries", () => {
    render(<MiseKeyValueSection {...defaultProps} />);
    expect(screen.getByText("NODE_ENV")).toBeInTheDocument();
    expect(screen.getByText('"development"')).toBeInTheDocument();
    expect(screen.getByText("PORT")).toBeInTheDocument();
  });

  it("collapses and expands", async () => {
    const user = userEvent.setup();
    render(<MiseKeyValueSection {...defaultProps} />);

    expect(screen.getByText("NODE_ENV")).toBeInTheDocument();

    await user.click(screen.getByText("Environment"));
    expect(screen.queryByText("NODE_ENV")).not.toBeInTheDocument();

    await user.click(screen.getByText("Environment"));
    expect(screen.getByText("NODE_ENV")).toBeInTheDocument();
  });

  it("shows empty state", () => {
    render(<MiseKeyValueSection {...defaultProps} data={{}} />);
    expect(screen.getByText("No entries")).toBeInTheDocument();
  });

  it("deletes an entry", async () => {
    const user = userEvent.setup();
    render(<MiseKeyValueSection {...defaultProps} />);

    const deleteButtons = screen.getAllByTitle("Delete");
    await user.click(deleteButtons[0]);

    expect(defaultProps.onChange).toHaveBeenCalledWith({ PORT: '"3000"' });
  });
});
