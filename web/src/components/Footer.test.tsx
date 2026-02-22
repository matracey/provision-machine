import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { Footer } from "./Footer";
import { AppProvider } from "../state/AppContext";

describe("Footer", () => {
  it("renders default status text", () => {
    render(
      <AppProvider>
        <Footer />
      </AppProvider>,
    );
    expect(
      screen.getByText("Ready - Load a configuration file to begin"),
    ).toBeInTheDocument();
  });

  it("renders run command with copy button", () => {
    render(
      <AppProvider>
        <Footer />
      </AppProvider>,
    );
    expect(screen.getByText("Run:")).toBeInTheDocument();
    expect(screen.getByText(/iwr.*Provision-Machine\.ps1/)).toBeInTheDocument();
    expect(screen.getByText("Copy")).toBeInTheDocument();
  });

  it("copies run command to clipboard when copy button clicked", async () => {
    const writeText = vi.fn().mockResolvedValue(undefined);
    Object.assign(navigator, { clipboard: { writeText } });

    render(
      <AppProvider>
        <Footer />
      </AppProvider>,
    );

    await userEvent.click(screen.getByText("Copy"));
    expect(writeText).toHaveBeenCalledWith(
      expect.stringContaining("Provision-Machine.ps1"),
    );
  });
});
