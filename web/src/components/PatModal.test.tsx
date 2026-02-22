import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { PatModal } from "./PatModal";
import { AppProvider } from "../state/AppContext";

const renderModal = (props = {}) => {
  const defaultProps = { open: true, onClose: vi.fn(), onConfirm: vi.fn() };
  return render(
    <AppProvider>
      <PatModal {...defaultProps} {...props} />
    </AppProvider>,
  );
};

describe("PatModal", () => {
  it("renders when open", () => {
    renderModal();
    expect(
      screen.getByText("GitHub Personal Access Token"),
    ).toBeInTheDocument();
    expect(screen.getByPlaceholderText("ghp_xxxxxxxxxxxx")).toBeInTheDocument();
  });

  it("does not render when closed", () => {
    renderModal({ open: false });
    expect(
      screen.queryByText("GitHub Personal Access Token"),
    ).not.toBeInTheDocument();
  });

  it("disables save when PAT is empty", () => {
    renderModal();
    expect(screen.getByText("Save").closest("button")).toBeDisabled();
  });

  it("calls onConfirm with PAT value", async () => {
    const onConfirm = vi.fn();
    renderModal({ onConfirm });

    await userEvent.type(
      screen.getByPlaceholderText("ghp_xxxxxxxxxxxx"),
      "ghp_test123",
    );
    await userEvent.click(screen.getByText("Save"));

    expect(onConfirm).toHaveBeenCalledWith("ghp_test123");
  });

  it("calls onClose when cancel clicked", async () => {
    const onClose = vi.fn();
    renderModal({ onClose });
    await userEvent.click(screen.getByText("Cancel"));
    expect(onClose).toHaveBeenCalled();
  });
});
