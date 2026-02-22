import { X, Pencil } from "lucide-react";
import { getItemDisplayText } from "../../utils/fileIO";

interface DraggableItemProps {
  item: unknown;
  context: string;
  section: string;
  index: number;
  filter: string;
  onEdit: () => void;
  onDelete: () => void;
  onContextMenu?: (e: React.MouseEvent) => void;
}

export function DraggableItem({
  item,
  context,
  section,
  index,
  filter,
  onEdit,
  onDelete,
  onContextMenu,
}: DraggableItemProps) {
  const text = getItemDisplayText(item);
  const subtitle =
    typeof item === "object" && item !== null && "url" in item
      ? String((item as { url: string }).url)
      : null;
  const hidden = filter && !text.toLowerCase().includes(filter.toLowerCase());

  if (hidden) return null;

  const escapedValue = (
    typeof item === "string" ? item : JSON.stringify(item)
  ).replace(/'/g, "&#39;");

  return (
    <div
      className="bg-base-300/50 border border-base-300 rounded-lg px-3 py-2 mb-2 cursor-grab hover:bg-base-300 transition flex justify-between items-center gap-2 group"
      data-context={context}
      data-section={section}
      data-index={index}
      data-value={escapedValue}
      data-type="json"
      onDoubleClick={onEdit}
      onContextMenu={onContextMenu}
    >
      <div className="flex-1 min-w-0">
        <span className="text-sm block truncate">{text}</span>
        {subtitle && (
          <span className="text-xs text-base-content/40 block truncate">
            {subtitle}
          </span>
        )}
      </div>
      <div className="flex items-center gap-1">
        <button
          className="opacity-0 group-hover:opacity-100 text-base-content/40 hover:text-info p-1 transition"
          onClick={(e) => {
            e.stopPropagation();
            onEdit();
          }}
          title="Edit"
        >
          <Pencil className="w-3 h-3" />
        </button>
        <button
          className="opacity-0 group-hover:opacity-100 text-base-content/40 hover:text-error p-1 transition"
          onClick={(e) => {
            e.stopPropagation();
            onDelete();
          }}
          title="Delete"
        >
          <X className="w-4 h-4" />
        </button>
      </div>
    </div>
  );
}
