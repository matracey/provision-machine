import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { AddToolModal } from "./AddToolModal";
import { vi } from "vitest";

// Mock the ToolCombobox to avoid needing the full registry fetch
vi.mock("./ToolCombobox", () => ({
  ToolCombobox: ({
    value,
    onChange,
    autoFocus,
  }: {
    value: string;
    onChange: (v: string) => void;
    onToolInfo?: unknown;
    githubPat?: string | null;
    autoFocus?: boolean;
  }) => (
    <input
      data-testid="tool-combobox"
      value={value}
      onChange={(e) => onChange(e.target.value)}
      autoFocus={autoFocus}
    />
  ),
}));

describe("AddToolModal", () => {
  const defaultProps = {
    open: true,
    onClose: vi.fn(),
    onSubmit: vi.fn(),
    githubPat: null,
  };

  beforeEach(() => {
    defaultProps.onClose.mockClear();
    defaultProps.onSubmit.mockClear();
  });

  it("renders add mode title", () => {
    render(<AddToolModal {...defaultProps} />);
    expect(screen.getByText("Add Tool")).toBeInTheDocument();
  });

  it("renders edit mode title when editTool provided", () => {
    render(
      <AddToolModal
        {...defaultProps}
        editTool={{
          name: "node",
          rawValue: '"20"',
          displayValue: "20",
          category: "Core",
        }}
      />,
    );
    expect(screen.getByText("Edit Tool")).toBeInTheDocument();
  });

  it("does not render when closed", () => {
    render(<AddToolModal {...defaultProps} open={false} />);
    expect(screen.queryByText("Add Tool")).not.toBeInTheDocument();
  });

  it("calls onSubmit with name and quoted version", async () => {
    const user = userEvent.setup();
    render(<AddToolModal {...defaultProps} />);

    const combobox = screen.getByTestId("tool-combobox");
    await user.clear(combobox);
    await user.type(combobox, "python");

    const versionInput = screen.getByPlaceholderText(/latest/);
    await user.clear(versionInput);
    await user.type(versionInput, "3.12");

    await user.click(screen.getByText("Add"));
    expect(defaultProps.onSubmit).toHaveBeenCalledWith("python", '"3.12"');
    expect(defaultProps.onClose).toHaveBeenCalled();
  });

  it("disables Add button when name is empty", () => {
    render(<AddToolModal {...defaultProps} />);
    const addBtn = screen.getByText("Add");
    expect(addBtn).toBeDisabled();
  });

  it("calls onClose when Cancel is clicked", async () => {
    const user = userEvent.setup();
    render(<AddToolModal {...defaultProps} />);
    await user.click(screen.getByText("Cancel"));
    expect(defaultProps.onClose).toHaveBeenCalled();
  });

  it("pre-fills values in edit mode", () => {
    render(
      <AddToolModal
        {...defaultProps}
        editTool={{
          name: "node",
          rawValue: '"20"',
          displayValue: "20",
          category: "Core",
        }}
      />,
    );
    expect(screen.getByTestId("tool-combobox")).toHaveValue("node");
    expect(screen.getByPlaceholderText(/latest/)).toHaveValue("20");
  });
});
