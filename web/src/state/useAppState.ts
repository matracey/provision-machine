import { useContext } from "react";
import { AppContext } from "./AppContextValue";

export function useAppState() {
  const ctx = useContext(AppContext);
  if (!ctx) throw new Error("useAppState must be used within AppProvider");
  return ctx;
}
