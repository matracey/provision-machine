import type { JsonSection, ContextType } from "../types";

export const JSON_SECTIONS: JsonSection[] = [
  {
    key: "Git.System",
    label: "Git System",
    icon: "git-branch",
    type: "object",
  },
  {
    key: "Git.Global",
    label: "Git Global",
    icon: "git-branch",
    type: "object",
  },
  {
    key: "Scoop.Prereqs",
    label: "Scoop Prereqs",
    icon: "package",
    type: "array",
  },
  {
    key: "Scoop.Buckets",
    label: "Scoop Buckets",
    icon: "archive",
    type: "name-url-array",
  },
  {
    key: "Scoop.Packages",
    label: "Scoop Packages",
    icon: "package",
    type: "array",
  },
  {
    key: "Scoop.Aliases",
    label: "Scoop Aliases",
    icon: "terminal",
    type: "alias-object",
  },
  {
    key: "VisualStudio.Workloads",
    label: "VS Workloads",
    icon: "code-2",
    type: "array",
  },
  {
    key: "WindowsDefender.ProcessExclusions",
    label: "Defender Processes",
    icon: "shield",
    type: "array",
  },
  {
    key: "WindowsDefender.ProjectsFolder",
    label: "Projects Folder",
    icon: "folder",
    type: "string",
  },
];

export const CONTEXTS: ContextType[] = ["Common", "Work", "Personal"];

export const CONTEXT_COLORS: Record<ContextType, string> = {
  Common: "common",
  Work: "work",
  Personal: "personal",
};

export const CONTEXT_ICONS: Record<ContextType, string> = {
  Common: "globe",
  Work: "briefcase",
  Personal: "user",
};

export const REPO_OWNER = "matracey";
export const REPO_NAME = "provision-machine";
export const REPO_API_URL = `https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}`;
export const REPO_RAW_BASE_URL = `https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/main`;

// Repo file paths for configuration files
export const REPO_FILES = {
  json: "provisioning/Configuration.json",
  yamlWork: "work.winget",
  yamlPersonal: "personal.winget",
} as const;

export const MISE_GIST_ID = "e3febf8a83d05ae2d7ade96fd147cd20";
export const MISE_GIST_API_URL = `https://api.github.com/gists/${MISE_GIST_ID}`;
export const MISE_GIST_RAW_URL = `https://gist.githubusercontent.com/matracey/${MISE_GIST_ID}/raw/mise.toml`;

export const ADD_ITEM_SECTIONS = [
  { value: "Scoop.Packages", label: "Scoop Packages" },
  { value: "Scoop.Buckets", label: "Scoop Buckets" },
  { value: "VisualStudio.Workloads", label: "VS Workloads" },
  {
    value: "WindowsDefender.ProcessExclusions",
    label: "Defender Process Exclusions",
  },
];
