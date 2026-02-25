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

  it("rejects add when key is whitespace-only", async () => {
    const user = userEvent.setup();
    render(<MiseKeyValueSection {...defaultProps} />);

    const addButton = screen.getByTitle("Add environment");
    await user.click(addButton);

    const keyInput = screen.getByPlaceholderText("KEY");
    const valueInput = screen.getByPlaceholderText("value");
    await user.type(keyInput, "   ");
    await user.type(valueInput, "test");

    const confirmButton = screen.getByText("✓");
    await user.click(confirmButton);

    expect(defaultProps.onChange).not.toHaveBeenCalled();
  });

  it("rejects add when value is whitespace-only", async () => {
    const user = userEvent.setup();
    render(<MiseKeyValueSection {...defaultProps} />);

    const addButton = screen.getByTitle("Add environment");
    await user.click(addButton);

    const keyInput = screen.getByPlaceholderText("KEY");
    const valueInput = screen.getByPlaceholderText("value");
    await user.type(keyInput, "MY_KEY");
    await user.type(valueInput, "   ");

    const confirmButton = screen.getByText("✓");
    await user.click(confirmButton);

    expect(defaultProps.onChange).not.toHaveBeenCalled();
  });

  it("adds entry and auto-quotes value", async () => {
    const user = userEvent.setup();
    render(<MiseKeyValueSection {...defaultProps} />);

    const addButton = screen.getByTitle("Add environment");
    await user.click(addButton);

    const keyInput = screen.getByPlaceholderText("KEY");
    const valueInput = screen.getByPlaceholderText("value");
    await user.type(keyInput, "NEW_KEY");
    await user.type(valueInput, "new_value");

    const confirmButton = screen.getByText("✓");
    await user.click(confirmButton);

    expect(defaultProps.onChange).toHaveBeenCalledWith({
      ...defaultProps.data,
      NEW_KEY: '"new_value"',
    });
  });

  it("does not re-quote already quoted values", async () => {
    const user = userEvent.setup();
    render(<MiseKeyValueSection {...defaultProps} />);

    const addButton = screen.getByTitle("Add environment");
    await user.click(addButton);

    const keyInput = screen.getByPlaceholderText("KEY");
    const valueInput = screen.getByPlaceholderText("value");
    await user.type(keyInput, "MY_KEY");
    await user.type(valueInput, '"already_quoted"');

    const confirmButton = screen.getByText("✓");
    await user.click(confirmButton);

    expect(defaultProps.onChange).toHaveBeenCalledWith({
      ...defaultProps.data,
      MY_KEY: '"already_quoted"',
    });
  });

  it("submits add via Enter key", async () => {
    const user = userEvent.setup();
    render(<MiseKeyValueSection {...defaultProps} />);

    const addButton = screen.getByTitle("Add environment");
    await user.click(addButton);

    const keyInput = screen.getByPlaceholderText("KEY");
    const valueInput = screen.getByPlaceholderText("value");
    await user.type(keyInput, "MY_KEY");
    await user.type(valueInput, "my_value{Enter}");

    expect(defaultProps.onChange).toHaveBeenCalledWith({
      ...defaultProps.data,
      MY_KEY: '"my_value"',
    });
  });

  it("cancels add via Escape key", async () => {
    const user = userEvent.setup();
    render(<MiseKeyValueSection {...defaultProps} />);

    const addButton = screen.getByTitle("Add environment");
    await user.click(addButton);

    expect(screen.getByPlaceholderText("KEY")).toBeInTheDocument();

    await user.keyboard("{Escape}");
    expect(screen.queryByPlaceholderText("KEY")).not.toBeInTheDocument();
  });

  it("starts edit mode on edit button click", async () => {
    const user = userEvent.setup();
    render(<MiseKeyValueSection {...defaultProps} />);

    const editButtons = screen.getAllByTitle("Edit");
    await user.click(editButtons[0]);

    expect(screen.getByDisplayValue("NODE_ENV")).toBeInTheDocument();
    expect(screen.getByDisplayValue('"development"')).toBeInTheDocument();
  });

  it("cancels edit via cancel button", async () => {
    const user = userEvent.setup();
    render(<MiseKeyValueSection {...defaultProps} />);

    const editButtons = screen.getAllByTitle("Edit");
    await user.click(editButtons[0]);

    const cancelButton = screen.getByText("✕");
    await user.click(cancelButton);

    expect(defaultProps.onChange).not.toHaveBeenCalled();
    expect(screen.queryByDisplayValue("NODE_ENV")).not.toBeInTheDocument();
  });

  it("auto-expands when add button is clicked while collapsed", async () => {
    const user = userEvent.setup();
    render(<MiseKeyValueSection {...defaultProps} />);

    // Collapse
    await user.click(screen.getByText("Environment"));
    expect(screen.queryByText("NODE_ENV")).not.toBeInTheDocument();

    // Click add — should expand
    const addButton = screen.getByTitle("Add environment");
    await user.click(addButton);
    expect(screen.getByPlaceholderText("KEY")).toBeInTheDocument();
  });
});
