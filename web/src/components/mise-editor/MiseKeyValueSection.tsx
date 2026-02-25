import { useState } from "react";
import { ChevronDown, ChevronRight, Plus, Pencil, Trash2 } from "lucide-react";

interface MiseKeyValueSectionProps {
  title: string;
  icon: React.ReactNode;
  data: Record<string, string>;
  onChange: (data: Record<string, string>) => void;
}

export function MiseKeyValueSection({
  title,
  icon,
  data,
  onChange,
}: MiseKeyValueSectionProps) {
  const [collapsed, setCollapsed] = useState(false);
  const [editingKey, setEditingKey] = useState<string | null>(null);
  const [editKey, setEditKey] = useState("");
  const [editValue, setEditValue] = useState("");
  const [addingNew, setAddingNew] = useState(false);
  const [newKey, setNewKey] = useState("");
  const [newValue, setNewValue] = useState("");

  const entries = Object.entries(data);

  const handleAdd = () => {
    const key = newKey.trim();
    const value = newValue.trim();
    if (!key || !value) return;
    const quoted =
      value.startsWith('"') || value.startsWith("[") || value.startsWith("{")
        ? value
        : `"${value}"`;
    onChange({ ...data, [key]: quoted });
    setNewKey("");
    setNewValue("");
    setAddingNew(false);
  };

  const handleEdit = (originalKey: string) => {
    const key = editKey.trim();
    const value = editValue.trim();
    if (!key || !value) return;
    const quoted =
      value.startsWith('"') || value.startsWith("[") || value.startsWith("{")
        ? value
        : `"${value}"`;
    const newData = { ...data };
    if (key !== originalKey) delete newData[originalKey];
    newData[key] = quoted;
    onChange(newData);
    setEditingKey(null);
  };

  const handleDelete = (key: string) => {
    const newData = { ...data };
    delete newData[key];
    onChange(newData);
  };

  const startEdit = (key: string, value: string) => {
    setEditingKey(key);
    setEditKey(key);
    setEditValue(value);
  };

  const cancelEdit = () => {
    setEditingKey(null);
    setAddingNew(false);
  };

  return (
    <div className="mb-2">
      <div className="flex items-center gap-2">
        <button
          className="flex items-center gap-2 flex-1 text-left text-sm font-semibold py-1 px-2 hover:bg-base-300 rounded"
          onClick={() => setCollapsed(!collapsed)}
        >
          {collapsed ? (
            <ChevronRight className="w-3 h-3" />
          ) : (
            <ChevronDown className="w-3 h-3" />
          )}
          {icon}
          {title}
          <span className="badge badge-ghost badge-xs">{entries.length}</span>
        </button>
        <button
          className="btn btn-ghost btn-xs"
          onClick={() => {
            setAddingNew(true);
            setCollapsed(false);
          }}
          title={`Add ${title.toLowerCase()}`}
        >
          <Plus className="w-3 h-3" />
        </button>
      </div>

      {!collapsed && (
        <div className="ml-4 mt-1">
          {entries.map(([key, value]) =>
            editingKey === key ? (
              <div
                key={key}
                className="flex items-center gap-2 py-1 px-2 text-sm"
              >
                <input
                  type="text"
                  value={editKey}
                  onChange={(e) => setEditKey(e.target.value)}
                  className="input input-bordered input-xs font-mono flex-1"
                  onKeyDown={(e) => {
                    if (e.key === "Enter") handleEdit(key);
                    if (e.key === "Escape") cancelEdit();
                  }}
                />
                <span className="text-base-content/30">=</span>
                <input
                  type="text"
                  value={editValue}
                  onChange={(e) => setEditValue(e.target.value)}
                  className="input input-bordered input-xs font-mono flex-[2]"
                  onKeyDown={(e) => {
                    if (e.key === "Enter") handleEdit(key);
                    if (e.key === "Escape") cancelEdit();
                  }}
                />
                <button
                  className="btn btn-ghost btn-xs btn-success"
                  onClick={() => handleEdit(key)}
                >
                  ✓
                </button>
                <button className="btn btn-ghost btn-xs" onClick={cancelEdit}>
                  ✕
                </button>
              </div>
            ) : (
              <div
                key={key}
                className="flex items-center gap-2 py-1.5 px-2 rounded hover:bg-base-300 group text-sm"
              >
                <span className="font-mono flex-1 truncate">{key}</span>
                <span className="text-base-content/30">=</span>
                <span className="text-base-content/50 text-xs truncate max-w-48 font-mono">
                  {value}
                </span>
                <div className="opacity-0 group-hover:opacity-100 flex gap-1">
                  <button
                    className="btn btn-ghost btn-xs"
                    onClick={() => startEdit(key, value)}
                    title="Edit"
                  >
                    <Pencil className="w-3 h-3" />
                  </button>
                  <button
                    className="btn btn-ghost btn-xs text-error"
                    onClick={() => handleDelete(key)}
                    title="Delete"
                  >
                    <Trash2 className="w-3 h-3" />
                  </button>
                </div>
              </div>
            ),
          )}

          {addingNew && (
            <div className="flex items-center gap-2 py-1 px-2 text-sm">
              <input
                type="text"
                value={newKey}
                onChange={(e) => setNewKey(e.target.value)}
                placeholder="KEY"
                className="input input-bordered input-xs font-mono flex-1"
                autoFocus
                onKeyDown={(e) => {
                  if (e.key === "Enter") handleAdd();
                  if (e.key === "Escape") cancelEdit();
                }}
              />
              <span className="text-base-content/30">=</span>
              <input
                type="text"
                value={newValue}
                onChange={(e) => setNewValue(e.target.value)}
                placeholder="value"
                className="input input-bordered input-xs font-mono flex-[2]"
                onKeyDown={(e) => {
                  if (e.key === "Enter") handleAdd();
                  if (e.key === "Escape") cancelEdit();
                }}
              />
              <button
                className="btn btn-ghost btn-xs btn-success"
                onClick={handleAdd}
              >
                ✓
              </button>
              <button className="btn btn-ghost btn-xs" onClick={cancelEdit}>
                ✕
              </button>
            </div>
          )}

          {entries.length === 0 && !addingNew && (
            <div className="text-xs text-base-content/30 py-2 px-2">
              No entries
            </div>
          )}
        </div>
      )}
    </div>
  );
}
