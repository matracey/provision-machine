import { Pencil, Trash2, Monitor, Terminal } from "lucide-react";
import type { MiseTool } from "../../types";

interface MiseToolItemProps {
  tool: MiseTool;
  onEdit: () => void;
  onDelete: () => void;
  filter: string;
}

export function MiseToolItem({
  tool,
  onEdit,
  onDelete,
  filter,
}: MiseToolItemProps) {
  if (
    filter &&
    !tool.name.toLowerCase().includes(filter.toLowerCase()) &&
    !tool.displayValue.toLowerCase().includes(filter.toLowerCase())
  ) {
    return null;
  }

  const hasOs = tool.rawValue.includes("os =");
  const hasPostinstall = tool.rawValue.includes("postinstall =");

  return (
    <div className="flex items-center gap-2 py-1.5 px-2 rounded hover:bg-base-300 group text-sm">
      <span className="font-mono flex-1 truncate">{tool.name}</span>
      {hasOs && (
        <span title="OS-specific">
          <Monitor className="w-3 h-3 text-info/50 shrink-0" />
        </span>
      )}
      {hasPostinstall && (
        <span title="Has post-install command">
          <Terminal className="w-3 h-3 text-warning/50 shrink-0" />
        </span>
      )}
      <span className="text-base-content/50 text-xs truncate max-w-32">
        {tool.displayValue}
      </span>
      <div className="opacity-0 group-hover:opacity-100 flex gap-1">
        <button className="btn btn-ghost btn-xs" onClick={onEdit} title="Edit">
          <Pencil className="w-3 h-3" />
        </button>
        <button
          className="btn btn-ghost btn-xs text-error"
          onClick={onDelete}
          title="Delete"
        >
          <Trash2 className="w-3 h-3" />
        </button>
      </div>
    </div>
  );
}
