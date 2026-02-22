import type { ContextType, YamlConfig, YamlResource } from "../types";

function getContextSection(
  json: Record<string, unknown>,
  context: ContextType,
  sectionKey: string,
): unknown {
  const ctx = json[context] as Record<string, unknown> | undefined;
  return ctx?.[sectionKey];
}

function setContextSection(
  json: Record<string, unknown>,
  context: ContextType,
  sectionKey: string,
  value: unknown,
): void {
  if (!json[context]) json[context] = {};
  (json[context] as Record<string, unknown>)[sectionKey] = value;
}

function deleteObjectKey(
  json: Record<string, unknown>,
  context: ContextType,
  sectionKey: string,
  key: string,
): void {
  const section = getContextSection(json, context, sectionKey);
  if (typeof section === "object" && section !== null) {
    delete (section as Record<string, unknown>)[key];
  }
}

// Move a JSON item from one context to another
export function moveJsonItem(
  json: Record<string, unknown>,
  sectionKey: string,
  index: number | string,
  sourceContext: ContextType,
  targetContext: ContextType,
): Record<string, unknown> {
  const result = structuredClone(json);
  const sourceData = getContextSection(result, sourceContext, sectionKey);

  if (Array.isArray(sourceData)) {
    const idx = typeof index === "number" ? index : parseInt(index, 10);
    const item = sourceData[idx];
    if (item === undefined) return result;
    sourceData.splice(idx, 1);
    const targetData = getContextSection(result, targetContext, sectionKey);
    const targetArr = Array.isArray(targetData) ? targetData : [];
    targetArr.push(item);
    setContextSection(result, targetContext, sectionKey, targetArr);
  } else if (typeof sourceData === "object" && sourceData !== null) {
    const key = String(index);
    const obj = sourceData as Record<string, unknown>;
    const value = obj[key];
    if (value === undefined) return result;
    delete obj[key];
    const targetData = getContextSection(result, targetContext, sectionKey);
    const targetObj =
      typeof targetData === "object" && targetData !== null
        ? (targetData as Record<string, unknown>)
        : {};
    targetObj[key] = value;
    setContextSection(result, targetContext, sectionKey, targetObj);
  }

  return result;
}

// Copy a JSON item to another context (keep source)
export function copyJsonItem(
  json: Record<string, unknown>,
  sectionKey: string,
  index: number | string,
  sourceContext: ContextType,
  targetContext: ContextType,
): Record<string, unknown> {
  const result = structuredClone(json);
  const sourceData = getContextSection(result, sourceContext, sectionKey);

  if (Array.isArray(sourceData)) {
    const idx = typeof index === "number" ? index : parseInt(index, 10);
    const item = structuredClone(sourceData[idx]);
    if (item === undefined) return result;
    const targetData = getContextSection(result, targetContext, sectionKey);
    const targetArr = Array.isArray(targetData) ? targetData : [];
    targetArr.push(item);
    setContextSection(result, targetContext, sectionKey, targetArr);
  } else if (typeof sourceData === "object" && sourceData !== null) {
    const key = String(index);
    const value = structuredClone((sourceData as Record<string, unknown>)[key]);
    if (value === undefined) return result;
    const targetData = getContextSection(result, targetContext, sectionKey);
    const targetObj =
      typeof targetData === "object" && targetData !== null
        ? (targetData as Record<string, unknown>)
        : {};
    targetObj[key] = value;
    setContextSection(result, targetContext, sectionKey, targetObj);
  }

  return result;
}

// Split a JSON item from Common to both Work and Personal
export function splitJsonItem(
  json: Record<string, unknown>,
  sectionKey: string,
  index: number | string,
): Record<string, unknown> {
  let result = copyJsonItem(json, sectionKey, index, "Common", "Work");
  result = copyJsonItem(result, sectionKey, index, "Common", "Personal");
  return deleteJsonItem(result, sectionKey, index, "Common");
}

// Delete a JSON item
export function deleteJsonItem(
  json: Record<string, unknown>,
  sectionKey: string,
  index: number | string,
  context: ContextType,
): Record<string, unknown> {
  const result = structuredClone(json);
  const data = getContextSection(result, context, sectionKey);

  if (Array.isArray(data)) {
    const idx = typeof index === "number" ? index : parseInt(index, 10);
    data.splice(idx, 1);
  } else if (typeof data === "object" && data !== null) {
    deleteObjectKey(result, context, sectionKey, String(index));
  }

  return result;
}

// Move a YAML resource between contexts
export function moveYamlResource(
  work: YamlConfig | null,
  personal: YamlConfig | null,
  resourceId: string,
  sourceContext: ContextType,
  targetContext: ContextType,
): { work: YamlConfig | null; personal: YamlConfig | null } {
  const workResources = work?.properties?.resources
    ? [...work.properties.resources]
    : [];
  const personalResources = personal?.properties?.resources
    ? [...personal.properties.resources]
    : [];

  const findAndRemove = (
    list: YamlResource[],
    id: string,
  ): YamlResource | undefined => {
    const idx = list.findIndex((r) => r.settings?.id === id);
    if (idx === -1) return undefined;
    return list.splice(idx, 1)[0];
  };

  let resource: YamlResource | undefined;

  if (sourceContext === "Common") {
    // Common means it's in both — remove from both, add to target
    const fromWork = findAndRemove(workResources, resourceId);
    findAndRemove(personalResources, resourceId);
    resource = fromWork;
  } else if (sourceContext === "Work") {
    resource = findAndRemove(workResources, resourceId);
  } else {
    resource = findAndRemove(personalResources, resourceId);
  }

  if (!resource) return { work, personal };

  if (targetContext === "Common" || targetContext === "Work") {
    workResources.push(resource);
  }
  if (targetContext === "Common" || targetContext === "Personal") {
    personalResources.push(structuredClone(resource));
  }

  return {
    work: {
      ...work!,
      properties: { ...work!.properties, resources: workResources },
    },
    personal: {
      ...personal!,
      properties: { ...personal!.properties, resources: personalResources },
    },
  };
}
