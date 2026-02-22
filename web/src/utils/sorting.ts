// Alphabetical comparison with shorter prefix first at /, -, ., : boundaries
export function prefixAwareCompare(strA: string, strB: string): number {
  const a = strA.toLowerCase();
  const b = strB.toLowerCase();

  const isBoundary = (ch: string) =>
    ch === "/" || ch === "-" || ch === "." || ch === ":";

  const aIsPrefix =
    b.startsWith(a) && (b.length === a.length || isBoundary(b[a.length]));
  const bIsPrefix =
    a.startsWith(b) && (a.length === b.length || isBoundary(a[b.length]));

  if (aIsPrefix && !bIsPrefix) return -1;
  if (bIsPrefix && !aIsPrefix) return 1;

  return a.localeCompare(b);
}

// Get a comparable string from any item type
function itemToString(item: unknown): string {
  if (typeof item === "string") return item;
  if (typeof item === "object" && item !== null) {
    const obj = item as Record<string, unknown>;
    return String(obj.name || obj.Name || JSON.stringify(item));
  }
  return String(item);
}

// Sort an array of items using prefix-aware comparison
export function sortItems<T>(items: T[]): T[] {
  return [...items].sort((a, b) =>
    prefixAwareCompare(itemToString(a), itemToString(b)),
  );
}

// Sort an object's keys using prefix-aware comparison
export function sortObjectKeys(
  obj: Record<string, unknown>,
): Record<string, unknown> {
  const entries = Object.entries(obj).sort((a, b) =>
    prefixAwareCompare(a[0], b[0]),
  );
  return Object.fromEntries(entries);
}
