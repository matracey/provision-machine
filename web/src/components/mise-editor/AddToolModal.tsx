import { useState, useCallback } from "react";
import { PlusCircle, Pencil } from "lucide-react";
import type { MiseTool, RegistryEntry } from "../../types";
import { ToolCombobox } from "./ToolCombobox";
import { categorize, formatMiseValue } from "../../utils/mise";

interface AddToolModalProps {
  open: boolean;
  onClose: () => void;
  onSubmit: (name: string, rawValue: string) => void;
  editTool?: MiseTool | null;
  githubPat?: string | null;
}

export function AddToolModal({
  open,
  onClose,
  onSubmit,
  editTool,
  githubPat,
}: AddToolModalProps) {
  if (!open) return null;

  return (
    <AddToolModalContent
      onClose={onClose}
      onSubmit={onSubmit}
      editTool={editTool}
      githubPat={githubPat}
    />
  );
}

function AddToolModalContent({
  onClose,
  onSubmit,
  editTool,
  githubPat,
}: Omit<AddToolModalProps, "open">) {
  const [name, setName] = useState(editTool?.name ?? "");
  const [version, setVersion] = useState(
    editTool ? editTool.displayValue : "latest",
  );
  const [toolInfo, setToolInfo] = useState<RegistryEntry | null>(null);

  const isEdit = !!editTool;

  const handleToolInfo = useCallback(
    (info: RegistryEntry | null) => setToolInfo(info),
    [],
  );

  const handleSubmit = () => {
    const trimmedName = name.trim();
    if (!trimmedName) return;
    const trimmedVersion = version.trim() || "latest";
    const rawValue =
      trimmedVersion.startsWith('"') ||
      trimmedVersion.startsWith("[") ||
      trimmedVersion.startsWith("{")
        ? trimmedVersion
        : `"${trimmedVersion}"`;
    onSubmit(trimmedName, rawValue);
    onClose();
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      handleSubmit();
    }
  };

  const previewCategory = name.trim() ? categorize(name.trim()) : null;
  const previewValue = version.trim()
    ? formatMiseValue(
        version.trim().startsWith('"') ||
          version.trim().startsWith("[") ||
          version.trim().startsWith("{")
          ? version.trim()
          : `"${version.trim()}"`,
      )
    : null;

  return (
    <dialog className="modal modal-open">
      <div className="modal-box max-w-lg">
        <h3 className="font-bold text-lg flex items-center gap-2 mb-4">
          {isEdit ? (
            <Pencil className="w-5 h-5" />
          ) : (
            <PlusCircle className="w-5 h-5" />
          )}
          {isEdit ? "Edit Tool" : "Add Tool"}
        </h3>

        <div className="form-control mb-3">
          <label className="label">
            <span className="label-text font-medium">Tool name</span>
          </label>
          <ToolCombobox
            value={name}
            onChange={setName}
            onToolInfo={handleToolInfo}
            githubPat={githubPat}
            autoFocus={!isEdit}
          />
        </div>

        <div className="form-control mb-3">
          <label className="label">
            <span className="label-text font-medium">Version</span>
          </label>
          <input
            type="text"
            value={version}
            onChange={(e) => setVersion(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder='e.g. latest, 20, 3.12, ">=1.0"'
            className="input input-bordered w-full font-mono"
            autoFocus={isEdit}
          />
        </div>

        {(toolInfo || previewCategory) && (
          <div className="bg-base-200 rounded-lg p-3 text-sm space-y-1">
            {toolInfo?.description && (
              <p className="text-base-content/70">{toolInfo.description}</p>
            )}
            {toolInfo?.backends && toolInfo.backends.length > 0 && (
              <p className="text-base-content/50">
                <span className="font-medium">Backends:</span>{" "}
                {toolInfo.backends.join(", ")}
              </p>
            )}
            {toolInfo?.aliases && toolInfo.aliases.length > 0 && (
              <p className="text-base-content/50">
                <span className="font-medium">Aliases:</span>{" "}
                {toolInfo.aliases.join(", ")}
              </p>
            )}
            {previewCategory && (
              <p className="text-base-content/50">
                <span className="font-medium">Category:</span> {previewCategory}
              </p>
            )}
            {previewValue && (
              <p className="text-base-content/50">
                <span className="font-medium">Display:</span> {previewValue}
              </p>
            )}
          </div>
        )}

        <div className="modal-action">
          <button className="btn btn-ghost" onClick={onClose}>
            Cancel
          </button>
          <button
            className="btn btn-primary"
            onClick={handleSubmit}
            disabled={!name.trim()}
          >
            {isEdit ? "Save" : "Add"}
          </button>
        </div>
      </div>
      <form method="dialog" className="modal-backdrop" onClick={onClose}>
        <button type="button">close</button>
      </form>
    </dialog>
  );
}
