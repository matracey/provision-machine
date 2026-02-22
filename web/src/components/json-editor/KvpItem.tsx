import { useState } from "react";
import { Check, X, Pencil } from "lucide-react";

interface KvpItemProps {
  keyName: string;
  value: string;
  context: string;
  section: string;
  index: number;
  filter: string;
  isEditing: boolean;
  onStartEdit: () => void;
  onSave: (newKey: string, newValue: string) => void;
  onCancel: () => void;
  onDelete: () => void;
  onContextMenu?: (e: React.MouseEvent) => void;
}

export function KvpItem({
  keyName,
  value,
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
}: KvpItemProps) {
  const [editKey, setEditKey] = useState(keyName);
  const [editValue, setEditValue] = useState(value);

  const hidden =
    filter &&
    !`${keyName} ${value}`.toLowerCase().includes(filter.toLowerCase());
  if (hidden && !isEditing) return null;

  if (isEditing) {
    return (
      <div className="bg-base-300/50 border border-primary rounded-lg px-3 py-2 mb-2 flex gap-2 items-center">
        <input
          type="text"
          className="input input-bordered input-sm w-1/3"
          value={editKey}
          onChange={(e) => setEditKey(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Escape") onCancel();
          }}
          autoFocus
        />
        <span className="text-base-content/40">:</span>
        <input
          type="text"
          className="input input-bordered input-sm flex-1"
          value={editValue}
          onChange={(e) => setEditValue(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Enter") onSave(editKey.trim(), editValue.trim());
            if (e.key === "Escape") onCancel();
          }}
        />
        <div className="flex gap-1">
          <button
            className="text-success hover:text-success/80 p-1"
            onClick={() => onSave(editKey.trim(), editValue.trim())}
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

  return (
    <div
      className="bg-base-300/50 border border-base-300 rounded-lg px-3 py-2 mb-2 hover:bg-base-300 transition flex justify-between items-center gap-2 group"
      data-type="json"
      data-context={context}
      data-section={section}
      data-index={index}
      onDoubleClick={onStartEdit}
      onContextMenu={onContextMenu}
    >
      <div className="flex-1 min-w-0 flex items-center gap-2">
        <span className="text-sm text-info font-medium">{keyName}</span>
        <span className="text-base-content/40">:</span>
        <span className="text-sm truncate">{value}</span>
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
