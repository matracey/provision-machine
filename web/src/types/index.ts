import type { IconName } from "lucide-react/dynamic";

export type ContextType = "Common" | "Work" | "Personal";

export type SectionType =
  | "array"
  | "object"
  | "name-url-array"
  | "alias-object"
  | "string";

export interface JsonSection {
  key: string;
  label: string;
  icon: IconName | undefined;
  type: SectionType;
}

export interface NameUrlItem {
  name: string;
  url: string;
}

export interface ScoopAlias {
  [key: string]: [string, string];
}

export interface YamlResource {
  resource: string;
  directives?: {
    description?: string;
  };
  settings?: {
    id?: string;
    source?: string;
  };
}

export interface YamlConfig {
  properties?: {
    configurationVersion?: string;
    resources?: YamlResource[];
  };
}

export interface EditingItem {
  context: ContextType;
  section: string;
  index: number;
  key?: string;
  isKvp?: boolean;
  isNameUrl?: boolean;
}

export interface ContextMenuTarget {
  type: "json" | "yaml";
  context: string;
  section?: string;
  index: number;
  value?: unknown;
}

export interface MiseTool {
  name: string;
  rawValue: string;
  displayValue: string;
  category: string;
}

export interface MiseData {
  rawContent: string;
  tools: MiseTool[];
  settings: Record<string, string>;
  env: Record<string, string>;
}

export interface RegistryEntry {
  name: string;
  description?: string;
  backends?: string[];
  aliases?: string[];
}

export type TabId = "json" | "yaml" | "mise";

export interface AppState {
  json: Record<string, unknown> | null;
  yamlWork: YamlConfig | null;
  yamlPersonal: YamlConfig | null;
  miseData: MiseData | null;
  currentTab: TabId;
  filter: string;
  collapsedPanels: Set<string>;
  collapsedSections: Set<string>;
  hasLoadedFiles: boolean;
  editingItem: EditingItem | null;
  githubPat: string | null;
  statusText: string;
  lastModified: string;
}
