import { useState } from "react";
import { ChevronDown, ChevronRight } from "lucide-react";
import type { MiseTool } from "../../types";
import { MiseToolItem } from "./MiseToolItem";

interface MiseSectionProps {
  category: string;
  tools: MiseTool[];
  filter: string;
  onEdit: (toolIndex: number) => void;
  onDelete: (toolIndex: number) => void;
}

export function MiseSection({
  category,
  tools,
  filter,
  onEdit,
  onDelete,
}: MiseSectionProps) {
  const [collapsed, setCollapsed] = useState(false);

  const visibleTools = filter
    ? tools.filter(
        (t) =>
          t.name.toLowerCase().includes(filter.toLowerCase()) ||
          t.displayValue.toLowerCase().includes(filter.toLowerCase()),
      )
    : tools;

  if (visibleTools.length === 0) return null;

  return (
    <div className="mb-2">
      <button
        className="flex items-center gap-2 w-full text-left text-sm font-semibold py-1 px-2 hover:bg-base-300 rounded"
        onClick={() => setCollapsed(!collapsed)}
      >
        {collapsed ? (
          <ChevronRight className="w-3 h-3" />
        ) : (
          <ChevronDown className="w-3 h-3" />
        )}
        {category}
        <span className="badge badge-ghost badge-xs">
          {visibleTools.length}
        </span>
      </button>
      {!collapsed && (
        <div className="ml-4">
          {visibleTools.map((tool) => {
            const globalIdx = tools.indexOf(tool);
            return (
              <MiseToolItem
                key={`${tool.name}-${globalIdx}`}
                tool={tool}
                filter=""
                onEdit={() => onEdit(globalIdx)}
                onDelete={() => onDelete(globalIdx)}
              />
            );
          })}
        </div>
      )}
    </div>
  );
}
