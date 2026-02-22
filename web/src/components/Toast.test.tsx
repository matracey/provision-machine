import { render, screen, act } from "@testing-library/react";
import { Toast } from "./Toast";
import { showToast } from "../utils/toast";

describe("Toast", () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("renders nothing when no toasts", () => {
    const { container } = render(<Toast />);
    expect(container.firstChild).toBeNull();
  });

  it("shows a success toast", () => {
    render(<Toast />);
    act(() => {
      showToast("Saved!");
    });
    expect(screen.getByText("Saved!")).toBeInTheDocument();
  });

  it("shows an error toast", () => {
    render(<Toast />);
    act(() => {
      showToast("Failed!", "error");
    });
    expect(screen.getByText("Failed!")).toBeInTheDocument();
  });

  it("auto-dismisses after 3 seconds", () => {
    render(<Toast />);
    act(() => {
      showToast("Temporary");
    });
    expect(screen.getByText("Temporary")).toBeInTheDocument();
    act(() => {
      vi.advanceTimersByTime(3100);
    });
    expect(screen.queryByText("Temporary")).not.toBeInTheDocument();
  });
});
