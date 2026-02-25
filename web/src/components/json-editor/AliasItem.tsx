import { useState } from "react";
import { Check, X, Pencil } from "lucide-react";

interface AliasItemProps {
  aliasName: string;
  command: string;
  description: string;
  context: string;
  section: string;
  index: number;
  filter: string;
  isEditing: boolean;
  onStartEdit: () => void;
  onSave: (name: string, command: string, description: string) => void;
  onCancel: () => void;
  onDelete: () => void;
  onContextMenu?: (e: React.MouseEvent) => void;
}

export function AliasItem({
  aliasName,
  command,
  description,
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
}: AliasItemProps) {
  const [editName, setEditName] = useState(aliasName);
  const [editCommand, setEditCommand] = useState(command);
  const [editDescription, setEditDescription] = useState(description);

  const hidden =
    filter &&
    !`${aliasName} ${command} ${description}`
      .toLowerCase()
      .includes(filter.toLowerCase());
  if (hidden && !isEditing) return null;

  if (isEditing) {
    return (
      <div className="bg-base-300/50 border border-primary rounded-lg px-3 py-2 mb-2 space-y-1">
        <div className="flex gap-2 items-center">
          <input
            type="text"
            className="input input-bordered input-sm w-1/4"
            placeholder="Alias name"
            value={editName}
            onChange={(e) => setEditName(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Escape") onCancel();
            }}
            autoFocus
          />
          <input
            type="text"
            className="input input-bordered input-sm flex-1 font-mono"
            placeholder="Command"
            value={editCommand}
            onChange={(e) => setEditCommand(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Escape") onCancel();
            }}
          />
          <div className="flex gap-1">
            <button
              className="text-success hover:text-success/80 p-1"
              onClick={() =>
                onSave(
                  editName.trim(),
                  editCommand.trim(),
                  editDescription.trim(),
                )
              }
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
        <input
          type="text"
          className="input input-bordered input-sm w-full"
          placeholder="Description"
          value={editDescription}
          onChange={(e) => setEditDescription(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Enter")
              onSave(
                editName.trim(),
                editCommand.trim(),
                editDescription.trim(),
              );
            if (e.key === "Escape") onCancel();
          }}
        />
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
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2">
          <span className="text-sm text-info font-medium">{aliasName}</span>
          <span className="text-sm font-mono truncate text-base-content/70">
            {command}
          </span>
        </div>
        {description && (
          <div className="text-xs text-base-content/40 truncate">
            {description}
          </div>
        )}
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
