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
    expect(screen.getByDisplayValue("20")).toBeInTheDocument();
  });

  it("shows OS checkboxes", () => {
    render(<AddToolModal {...defaultProps} />);
    expect(screen.getByText("linux")).toBeInTheDocument();
    expect(screen.getByText("macos")).toBeInTheDocument();
    expect(screen.getByText("windows")).toBeInTheDocument();
  });

  it("shows postinstall field", () => {
    render(<AddToolModal {...defaultProps} />);
    expect(screen.getByPlaceholderText(/corepack enable/)).toBeInTheDocument();
  });

  it("pre-fills OS and postinstall in edit mode", () => {
    render(
      <AddToolModal
        {...defaultProps}
        editTool={{
          name: "node",
          rawValue:
            '{ version = "22", os = ["linux", "macos"], postinstall = "corepack enable" }',
          displayValue: "22 (linux, macos)",
          category: "Core",
        }}
      />,
    );
    const checkboxes = screen.getAllByRole("checkbox", { hidden: true });
    const linuxCheckbox = checkboxes.find((cb) =>
      cb.closest("label")?.textContent?.includes("linux"),
    ) as HTMLInputElement;
    const macosCheckbox = checkboxes.find((cb) =>
      cb.closest("label")?.textContent?.includes("macos"),
    ) as HTMLInputElement;
    const windowsCheckbox = checkboxes.find((cb) =>
      cb.closest("label")?.textContent?.includes("windows"),
    ) as HTMLInputElement;
    expect(linuxCheckbox.checked).toBe(true);
    expect(macosCheckbox.checked).toBe(true);
    expect(windowsCheckbox.checked).toBe(false);
    expect(screen.getByDisplayValue("corepack enable")).toBeInTheDocument();
  });

  it("shows Add version entry button", () => {
    render(<AddToolModal {...defaultProps} />);
    expect(screen.getByText("Add version entry")).toBeInTheDocument();
  });

  it("adds a second version entry when Add version entry is clicked", async () => {
    const user = userEvent.setup();
    render(<AddToolModal {...defaultProps} />);

    await user.click(screen.getByText("Add version entry"));

    const versionInputs = screen.getAllByPlaceholderText(/latest/);
    expect(versionInputs).toHaveLength(2);
  });

  it("submits multiple entries as array", async () => {
    const user = userEvent.setup();
    render(<AddToolModal {...defaultProps} />);

    const combobox = screen.getByTestId("tool-combobox");
    await user.clear(combobox);
    await user.type(combobox, "python");

    const versionInput = screen.getByPlaceholderText(/latest/);
    await user.clear(versionInput);
    await user.type(versionInput, "3.11");

    await user.click(screen.getByText("Add version entry"));
    const versionInputs = screen.getAllByPlaceholderText(/latest/);
    await user.clear(versionInputs[1]);
    await user.type(versionInputs[1], "3.12");

    await user.click(screen.getByText("Add"));
    expect(defaultProps.onSubmit).toHaveBeenCalledWith(
      "python",
      '["3.11", "3.12"]',
    );
  });

  it("pre-fills multiple entries in edit mode", () => {
    render(
      <AddToolModal
        {...defaultProps}
        editTool={{
          name: "python",
          rawValue: '["3.11", { version = "3.12", os = ["linux"] }]',
          displayValue: "3.11, 3.12",
          category: "Core",
        }}
      />,
    );
    expect(screen.getByDisplayValue("3.11")).toBeInTheDocument();
    expect(screen.getByDisplayValue("3.12")).toBeInTheDocument();
    expect(screen.getByText("Version 1")).toBeInTheDocument();
    expect(screen.getByText("Version 2")).toBeInTheDocument();
  });
});
