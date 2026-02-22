import { createContext } from "react";
import type { AppState } from "../types";

export interface AppContextValue {
  state: AppState;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  dispatch: React.Dispatch<any>;
}

export const AppContext = createContext<AppContextValue | null>(null);
