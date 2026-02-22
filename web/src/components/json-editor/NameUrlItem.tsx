import { useState } from "react";
import { Check, X, Pencil } from "lucide-react";

interface NameUrlItemProps {
  name: string;
  url: string;
  context: string;
  section: string;
  index: number;
  filter: string;
  isEditing: boolean;
  onStartEdit: () => void;
  onSave: (name: string, url: string) => void;
  onCancel: () => void;
  onDelete: () => void;
  onContextMenu?: (e: React.MouseEvent) => void;
}

export function NameUrlItem({
  name,
  url,
  context,
  section,
  index,
  filter,
  isEditing,
  onStartEdit,
  onSave,
  onCancel,
  onDelete,
  onContextMenu,
}: NameUrlItemProps) {
  const [editName, setEditName] = useState(name);
  const [editUrl, setEditUrl] = useState(url);

  const hidden =
    filter && !`${name} ${url}`.toLowerCase().includes(filter.toLowerCase());
  if (hidden && !isEditing) return null;

  if (isEditing) {
    return (
      <div className="bg-base-300/50 border border-primary rounded-lg px-3 py-2 mb-2 flex gap-2 items-center">
        <input
          type="text"
          className="input input-bordered input-sm w-1/3"
          placeholder="Name"
          value={editName}
          onChange={(e) => setEditName(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Escape") onCancel();
          }}
          autoFocus
        />
        <span className="text-base-content/40">:</span>
        <input
          type="text"
          className="input input-bordered input-sm flex-1"
          placeholder="URL"
          value={editUrl}
          onChange={(e) => setEditUrl(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Enter") onSave(editName.trim(), editUrl.trim());
            if (e.key === "Escape") onCancel();
          }}
        />
        <div className="flex gap-1">
          <button
            className="text-success hover:text-success/80 p-1"
            onClick={() => onSave(editName.trim(), editUrl.trim())}
            title="Save"
          >
            <Check className="w-4 h-4" />
          </button>
          <button
            className="text-base-content/50 hover:text-base-content p-1"
            onClick={onCancel}
            title="Cancel"
          >
            <X className="w-4 h-4" />
          </button>
        </div>
      </div>
    );
  }

  const escapedValue = JSON.stringify({ name, url }).replace(/'/g, "&#39;");

  return (
    <div
      className="bg-base-300/50 border border-base-300 rounded-lg px-3 py-2 mb-2 cursor-grab hover:bg-base-300 transition flex justify-between items-center gap-2 group"
      data-context={context}
      data-section={section}
      data-index={index}
      data-value={escapedValue}
      data-type="json"
      onDoubleClick={onStartEdit}
      onContextMenu={onContextMenu}
    >
      <div className="flex-1 min-w-0 flex items-center gap-2">
        <span className="text-sm text-info font-medium">{name}</span>
        <span className="text-base-content/40">:</span>
        <span className="text-sm truncate">{url}</span>
      </div>
      <div className="flex items-center gap-1">
        <button
          className="opacity-0 group-hover:opacity-100 text-base-content/40 hover:text-info p-1 transition"
          onClick={(e) => {
            e.stopPropagation();
            onStartEdit();
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
