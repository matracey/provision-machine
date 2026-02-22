import { Pencil, Trash2 } from "lucide-react";
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

  return (
    <div className="flex items-center gap-2 py-1.5 px-2 rounded hover:bg-base-300 group text-sm">
      <span className="font-mono flex-1 truncate">{tool.name}</span>
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
