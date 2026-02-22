export function getNestedValue(
  obj: Record<string, unknown> | undefined,
  path: string,
): unknown {
  if (!obj) return undefined;
  return path.split(".").reduce<unknown>((curr, key) => {
    if (
      curr &&
      typeof curr === "object" &&
      key in (curr as Record<string, unknown>)
    ) {
      return (curr as Record<string, unknown>)[key];
    }
    return undefined;
  }, obj);
}

export function setNestedValue(
  obj: Record<string, unknown>,
  path: string,
  value: unknown,
): void {
  const keys = path.split(".");
  const lastKey = keys.pop()!;
  const parent = keys.reduce<Record<string, unknown>>((curr, key) => {
    if (!curr[key] || typeof curr[key] !== "object") {
      curr[key] = {};
    }
    return curr[key] as Record<string, unknown>;
  }, obj);
  parent[lastKey] = value;
}

export function deleteNestedValue(
  obj: Record<string, unknown> | undefined,
  path: string,
  index: number,
): void {
  const arr = getNestedValue(obj, path);
  if (Array.isArray(arr)) {
    arr.splice(index, 1);
  }
}
