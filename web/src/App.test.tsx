import { render, screen } from "@testing-library/react";
import App from "./App";

describe("App", () => {
  it("renders the app shell with header, tabs, and footer", () => {
    render(<App />);
    expect(screen.getByText("QuickInit Config Editor")).toBeInTheDocument();
    expect(screen.getByText("Configuration.json")).toBeInTheDocument();
    expect(screen.getByText("WinGet DSC")).toBeInTheDocument();
    expect(
      screen.getByText("Ready - Load a configuration file to begin"),
    ).toBeInTheDocument();
  });

  it("renders drop zone", () => {
    render(<App />);
    expect(screen.getByText(/Drag & drop/)).toBeInTheDocument();
  });

  it("shows json editor empty state by default", () => {
    render(<App />);
    expect(
      screen.getByText("Load a Configuration.json file to begin editing"),
    ).toBeInTheDocument();
  });
});
