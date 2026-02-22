import { renderHook, act } from "@testing-library/react";
import { AppProvider } from "../state/AppContext";
import { useAppState } from "../state/useAppState";
import type { ReactNode } from "react";

const wrapper = ({ children }: { children: ReactNode }) => (
  <AppProvider>{children}</AppProvider>
);

describe("AppContext", () => {
  it("provides initial state", () => {
    const { result } = renderHook(() => useAppState(), { wrapper });
    expect(result.current.state.json).toBeNull();
    expect(result.current.state.currentTab).toBe("json");
    expect(result.current.state.filter).toBe("");
    expect(result.current.state.hasLoadedFiles).toBe(false);
  });

  it("SET_JSON updates json and marks files loaded", () => {
    const { result } = renderHook(() => useAppState(), { wrapper });
    act(() => {
      result.current.dispatch({ type: "SET_JSON", payload: { Common: {} } });
    });
    expect(result.current.state.json).toEqual({ Common: {} });
    expect(result.current.state.hasLoadedFiles).toBe(true);
  });

  it("SET_TAB switches tabs", () => {
    const { result } = renderHook(() => useAppState(), { wrapper });
    act(() => {
      result.current.dispatch({ type: "SET_TAB", payload: "yaml" });
    });
    expect(result.current.state.currentTab).toBe("yaml");
  });

  it("SET_FILTER updates filter", () => {
    const { result } = renderHook(() => useAppState(), { wrapper });
    act(() => {
      result.current.dispatch({ type: "SET_FILTER", payload: "scoop" });
    });
    expect(result.current.state.filter).toBe("scoop");
  });

  it("TOGGLE_PANEL toggles collapsed state", () => {
    const { result } = renderHook(() => useAppState(), { wrapper });
    act(() => {
      result.current.dispatch({
        type: "TOGGLE_PANEL",
        payload: "panel-Common",
      });
    });
    expect(result.current.state.collapsedPanels.has("panel-Common")).toBe(true);
    act(() => {
      result.current.dispatch({
        type: "TOGGLE_PANEL",
        payload: "panel-Common",
      });
    });
    expect(result.current.state.collapsedPanels.has("panel-Common")).toBe(
      false,
    );
  });

  it("TOGGLE_SECTION toggles section collapsed state", () => {
    const { result } = renderHook(() => useAppState(), { wrapper });
    act(() => {
      result.current.dispatch({
        type: "TOGGLE_SECTION",
        payload: "Common-Git.System",
      });
    });
    expect(
      result.current.state.collapsedSections.has("Common-Git.System"),
    ).toBe(true);
  });

  it("SET_EDITING_ITEM sets and clears editing item", () => {
    const { result } = renderHook(() => useAppState(), { wrapper });
    const item = {
      context: "Common" as const,
      section: "Scoop.Packages",
      index: 0,
    };
    act(() => {
      result.current.dispatch({ type: "SET_EDITING_ITEM", payload: item });
    });
    expect(result.current.state.editingItem).toEqual(item);
    act(() => {
      result.current.dispatch({ type: "SET_EDITING_ITEM", payload: null });
    });
    expect(result.current.state.editingItem).toBeNull();
  });

  it("throws when used outside provider", () => {
    expect(() => {
      renderHook(() => useAppState());
    }).toThrow("useAppState must be used within AppProvider");
  });
});
