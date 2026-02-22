import { render, screen } from "@testing-library/react";
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
});
