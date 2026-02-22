import { useReducer, type ReactNode } from "react";
import type {
  AppState,
  EditingItem,
  TabId,
  YamlConfig,
  MiseData,
} from "../types";
import { AppContext } from "./AppContextValue";

// Actions
type Action =
  | { type: "SET_JSON"; payload: Record<string, unknown> }
  | { type: "SET_YAML_WORK"; payload: YamlConfig }
  | { type: "SET_YAML_PERSONAL"; payload: YamlConfig }
  | { type: "SET_MISE_DATA"; payload: MiseData | null }
  | { type: "SET_TAB"; payload: TabId }
  | { type: "SET_FILTER"; payload: string }
  | { type: "TOGGLE_PANEL"; payload: string }
  | { type: "TOGGLE_SECTION"; payload: string }
  | { type: "SET_EDITING_ITEM"; payload: EditingItem | null }
  | { type: "SET_GITHUB_PAT"; payload: string | null }
  | { type: "SET_STATUS"; payload: string }
  | { type: "SET_LAST_MODIFIED"; payload: string }
  | { type: "SET_HAS_LOADED_FILES"; payload: boolean };

const initialState: AppState = {
  json: null,
  yamlWork: null,
  yamlPersonal: null,
  miseData: null,
  currentTab: "json",
  filter: "",
  collapsedPanels: new Set<string>(),
  collapsedSections: new Set<string>(),
  hasLoadedFiles: false,
  editingItem: null,
  githubPat:
    typeof window !== "undefined"
      ? localStorage.getItem("quickinit_github_pat")
      : null,
  statusText: "Ready - Load a configuration file to begin",
  lastModified: "",
};

function appReducer(state: AppState, action: Action): AppState {
  switch (action.type) {
    case "SET_JSON":
      return { ...state, json: action.payload, hasLoadedFiles: true };
    case "SET_YAML_WORK":
      return { ...state, yamlWork: action.payload, hasLoadedFiles: true };
    case "SET_YAML_PERSONAL":
      return { ...state, yamlPersonal: action.payload, hasLoadedFiles: true };
    case "SET_MISE_DATA":
      return {
        ...state,
        miseData: action.payload,
        hasLoadedFiles: action.payload !== null || state.hasLoadedFiles,
      };
    case "SET_TAB":
      return { ...state, currentTab: action.payload };
    case "SET_FILTER":
      return { ...state, filter: action.payload };
    case "TOGGLE_PANEL": {
      const next = new Set(state.collapsedPanels);
      if (next.has(action.payload)) next.delete(action.payload);
      else next.add(action.payload);
      return { ...state, collapsedPanels: next };
    }
    case "TOGGLE_SECTION": {
      const next = new Set(state.collapsedSections);
      if (next.has(action.payload)) next.delete(action.payload);
      else next.add(action.payload);
      return { ...state, collapsedSections: next };
    }
    case "SET_EDITING_ITEM":
      return { ...state, editingItem: action.payload };
    case "SET_GITHUB_PAT":
      return { ...state, githubPat: action.payload };
    case "SET_STATUS":
      return { ...state, statusText: action.payload };
    case "SET_LAST_MODIFIED":
      return { ...state, lastModified: action.payload };
    case "SET_HAS_LOADED_FILES":
      return { ...state, hasLoadedFiles: action.payload };
    default:
      return state;
  }
}

export function AppProvider({ children }: { children: ReactNode }) {
  const [state, dispatch] = useReducer(appReducer, initialState);
  return (
    <AppContext.Provider value={{ state, dispatch }}>
      {children}
    </AppContext.Provider>
  );
}

export type { Action };
