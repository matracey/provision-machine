import { useState } from "react";
import { Check, X } from "lucide-react";

interface EditableItemProps {
  item: unknown;
  itemType: "string" | "name-url" | "object";
  onSave: (value: unknown) => void;
  onCancel: () => void;
}

export function EditableItem({
  item,
  itemType,
  onSave,
  onCancel,
}: EditableItemProps) {
  const [stringValue, setStringValue] = useState(
    typeof item === "string" ? item : "",
  );
  const [nameValue, setNameValue] = useState(
    item && typeof item === "object" && "name" in item
      ? String((item as { name: string }).name)
      : "",
  );
  const [urlValue, setUrlValue] = useState(
    item && typeof item === "object" && "url" in item
      ? String((item as { url: string }).url)
      : "",
  );
  const [jsonValue, setJsonValue] = useState(
    itemType === "object" ? JSON.stringify(item, null, 2) : "",
  );

  const handleSave = () => {
    if (itemType === "string") {
      if (stringValue.trim()) onSave(stringValue.trim());
    } else if (itemType === "name-url") {
      onSave({ name: nameValue.trim(), url: urlValue.trim() });
    } else {
      try {
        onSave(JSON.parse(jsonValue));
      } catch {
        return; // Invalid JSON, don't save
      }
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === "Enter" && itemType !== "object") handleSave();
    if (e.key === "Escape") onCancel();
  };

  return (
    <div className="bg-base-300/50 border border-primary rounded-lg px-3 py-2 mb-2 flex gap-2 items-center">
      {itemType === "string" && (
        <input
          type="text"
          className="input input-bordered input-sm flex-1"
          value={stringValue}
          onChange={(e) => setStringValue(e.target.value)}
          onKeyDown={handleKeyDown}
          autoFocus
        />
      )}
      {itemType === "name-url" && (
        <div className="flex-1 space-y-1">
          <input
            type="text"
            className="input input-bordered input-sm w-full"
            placeholder="Name"
            value={nameValue}
            onChange={(e) => setNameValue(e.target.value)}
            onKeyDown={handleKeyDown}
            autoFocus
          />
          <input
            type="text"
            className="input input-bordered input-sm w-full"
            placeholder="URL"
            value={urlValue}
            onChange={(e) => setUrlValue(e.target.value)}
            onKeyDown={handleKeyDown}
          />
        </div>
      )}
      {itemType === "object" && (
        <textarea
          className="textarea textarea-bordered textarea-sm flex-1 font-mono"
          rows={3}
          value={jsonValue}
          onChange={(e) => setJsonValue(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Escape") onCancel();
          }}
          autoFocus
        />
      )}
      <div className="flex flex-col gap-1">
        <button
          className="text-success hover:text-success/80 p-1 transition"
          onClick={handleSave}
          title="Save"
        >
          <Check className="w-4 h-4" />
        </button>
        <button
          className="text-base-content/50 hover:text-base-content p-1 transition"
          onClick={onCancel}
          title="Cancel"
        >
          <X className="w-4 h-4" />
        </button>
      </div>
    </div>
  );
}
