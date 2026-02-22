import { X } from "lucide-react";
import type { YamlResource } from "../../types";

interface YamlColumnProps {
  title: string;
  icon: React.ReactNode;
  color: string;
  resources: YamlResource[];
  count: number;
  filter: string;
  onDelete: (id: string) => void;
  onContextMenu?: (
    e: React.MouseEvent,
    resource: YamlResource,
    type: string,
  ) => void;
  type: string;
}

export function YamlColumn({
  title,
  icon,
  color,
  resources,
  count,
  filter,
  onDelete,
  onContextMenu,
  type,
}: YamlColumnProps) {
  return (
    <div className="card bg-base-200 border border-base-300 overflow-hidden flex flex-col">
      <div
        className="p-4 border-b border-base-300 border-l-4 flex justify-between items-center"
        style={{ borderLeftColor: `var(--color-${color})` }}
      >
        <span className="font-semibold flex items-center gap-2">
          {icon} {title}
        </span>
        <span className="badge badge-ghost badge-sm">{count}</span>
      </div>
      <div
        className="p-3 flex-1 overflow-y-auto max-h-[60vh]"
        id={`yaml${type.charAt(0).toUpperCase() + type.slice(1)}Content`}
      >
        {resources.length === 0 ? (
          <div className="text-center py-8 text-base-content/40 text-sm italic">
            {type === "common"
              ? "No shared packages"
              : `No ${type}-only packages`}
          </div>
        ) : (
          resources.map((resource, i) => {
            const id = resource.settings?.id || "Unknown";
            const desc = resource.directives?.description || "";
            const hidden =
              filter &&
              !`${id} ${desc}`.toLowerCase().includes(filter.toLowerCase());
            if (hidden) return null;

            return (
              <div
                key={`${id}-${i}`}
                className="bg-base-300/50 border border-base-300 rounded-lg px-3 py-2 mb-2 cursor-grab hover:bg-base-300 transition flex justify-between items-center gap-2"
                data-index={i}
                data-type={type}
                data-id={id}
                onContextMenu={(e) => onContextMenu?.(e, resource, type)}
              >
                <div className="flex-1 min-w-0">
                  <span className="text-sm block truncate font-medium">
                    {id}
                  </span>
                  {desc && (
                    <span className="text-xs text-base-content/40 block truncate">
                      {desc}
                    </span>
                  )}
                </div>
                <button
                  className="opacity-0 group-hover:opacity-100 text-base-content/40 hover:text-error p-1 transition"
                  onClick={() => onDelete(id)}
                >
                  <X className="w-4 h-4" />
                </button>
              </div>
            );
          })
        )}
      </div>
    </div>
  );
}
