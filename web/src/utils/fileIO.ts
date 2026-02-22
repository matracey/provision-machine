import jsyaml from "js-yaml";
import type { YamlConfig } from "../types";

export function downloadFile(
  content: string,
  filename: string,
  type: string,
): void {
  const blob = new Blob([content], { type });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}

export function parseJsonConfig(text: string): Record<string, unknown> {
  return JSON.parse(text) as Record<string, unknown>;
}

export function parseYamlConfig(text: string): YamlConfig {
  return jsyaml.load(text) as YamlConfig;
}

export function serializeJson(data: Record<string, unknown>): string {
  return JSON.stringify(data, null, 2);
}

export function serializeYaml(data: YamlConfig): string {
  return jsyaml.dump(data, { lineWidth: -1, noRefs: true });
}

export function getItemDisplayText(item: unknown): string {
  if (typeof item === "string") return item;
  if (item && typeof item === "object") {
    const obj = item as Record<string, unknown>;
    if (obj.name && obj.url) return String(obj.name);
    if (obj.id) return String(obj.id);
    return JSON.stringify(item);
  }
  return String(item);
}

export function getItemType(item: unknown): "string" | "name-url" | "object" {
  if (typeof item === "string") return "string";
  if (item && typeof item === "object") {
    const obj = item as Record<string, unknown>;
    if (obj.name !== undefined && obj.url !== undefined) return "name-url";
    return "object";
  }
  return "string";
}
