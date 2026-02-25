import { useState, useEffect, useRef, useMemo, useCallback } from "react";
import { Search, Loader2 } from "lucide-react";
import type { RegistryEntry } from "../../types";
import {
  fetchRegistryTools,
  fetchToolDetails,
  fuzzySearch,
  hasBackendPrefix,
} from "../../utils/miseRegistry";

interface ToolComboboxProps {
  value: string;
  onChange: (value: string) => void;
  onToolInfo?: (entry: RegistryEntry | null) => void;
  githubPat?: string | null;
  autoFocus?: boolean;
}

export function ToolCombobox({
  value,
  onChange,
  onToolInfo,
  githubPat,
  autoFocus,
}: ToolComboboxProps) {
  const [tools, setTools] = useState<RegistryEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [open, setOpen] = useState(false);
  const [highlightIndex, setHighlightIndex] = useState(0);
  const inputRef = useRef<HTMLInputElement>(null);
  const listRef = useRef<HTMLUListElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    fetchRegistryTools(githubPat)
      .then(setTools)
      .finally(() => setLoading(false));
  }, [githubPat]);

  const isBackendPrefixed = hasBackendPrefix(value);

  const suggestions = useMemo(() => {
    if (isBackendPrefixed) return [];
    return fuzzySearch(value, tools, 30);
  }, [value, tools, isBackendPrefixed]);

  // Fetch tool details when a registry tool is typed exactly
  useEffect(() => {
    if (!onToolInfo || !value.trim()) {
      onToolInfo?.(null);
      return;
    }
    const match = tools.find((t) => t.name === value.trim());
    if (!match) {
      onToolInfo(null);
      return;
    }
    if (match.description) {
      onToolInfo(match);
      return;
    }
    const timer = setTimeout(() => {
      fetchToolDetails(value.trim()).then((details) => {
        if (details) {
          match.description = details.description;
          match.backends = details.backends;
          match.aliases = details.aliases;
          onToolInfo(details);
        }
      });
    }, 300);
    return () => clearTimeout(timer);
  }, [value, tools, onToolInfo]);

  // Scroll highlighted item into view
  useEffect(() => {
    if (!listRef.current) return;
    const item = listRef.current.children[highlightIndex] as HTMLElement;
    item?.scrollIntoView({ block: "nearest" });
  }, [highlightIndex]);

  // Click outside to close
  useEffect(() => {
    if (!open) return;
    const handler = (e: MouseEvent) => {
      if (
        containerRef.current &&
        !containerRef.current.contains(e.target as Node)
      ) {
        setOpen(false);
      }
    };
    document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, [open]);

  const selectTool = useCallback(
    (tool: RegistryEntry) => {
      onChange(tool.name);
      setOpen(false);
      inputRef.current?.focus();
    },
    [onChange],
  );

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (!open || suggestions.length === 0) {
      if (e.key === "ArrowDown" && suggestions.length > 0) {
        setOpen(true);
        e.preventDefault();
      }
      return;
    }

    switch (e.key) {
      case "ArrowDown":
        e.preventDefault();
        setHighlightIndex((i) => Math.min(i + 1, suggestions.length - 1));
        break;
      case "ArrowUp":
        e.preventDefault();
        setHighlightIndex((i) => Math.max(i - 1, 0));
        break;
      case "Enter":
        e.preventDefault();
        if (suggestions[highlightIndex]) {
          selectTool(suggestions[highlightIndex]);
        }
        break;
      case "Escape":
        e.preventDefault();
        setOpen(false);
        break;
    }
  };

  const showDropdown = open && suggestions.length > 0 && !isBackendPrefixed;

  return (
    <div ref={containerRef} className="relative">
      <div className="relative">
        <input
          ref={inputRef}
          type="text"
          value={value}
          onChange={(e) => {
            onChange(e.target.value);
            setOpen(true);
            setHighlightIndex(0);
          }}
          onFocus={() => setOpen(true)}
          onKeyDown={handleKeyDown}
          placeholder="e.g. node, python, cargo:ripgrep"
          className="input input-bordered w-full font-mono pr-8"
          autoFocus={autoFocus}
          autoComplete="off"
        />
        <span className="absolute right-2 top-1/2 -translate-y-1/2 text-base-content/30">
          {loading ? (
            <Loader2 className="w-4 h-4 animate-spin" />
          ) : (
            <Search className="w-4 h-4" />
          )}
        </span>
      </div>

      {isBackendPrefixed && value.includes(":") && (
        <div className="text-xs text-base-content/50 mt-1">
          Custom backend tool — enter the full package name
        </div>
      )}

      {showDropdown && (
        <ul
          ref={listRef}
          className="absolute z-50 w-full mt-1 max-h-60 overflow-y-auto bg-base-100 border border-base-300 rounded-lg shadow-lg"
        >
          {suggestions.map((tool, i) => (
            <li
              key={tool.name}
              className={`px-3 py-2 cursor-pointer flex items-center justify-between gap-2 text-sm ${
                i === highlightIndex ? "bg-primary/10" : "hover:bg-base-200"
              }`}
              onMouseEnter={() => setHighlightIndex(i)}
              onMouseDown={(e) => {
                e.preventDefault();
                selectTool(tool);
              }}
            >
              <span className="font-mono truncate">{tool.name}</span>
              {tool.description && (
                <span className="text-xs text-base-content/40 truncate max-w-[50%] text-right">
                  {tool.description}
                </span>
              )}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
