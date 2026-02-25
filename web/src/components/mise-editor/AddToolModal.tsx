import { useState, useCallback } from "react";
import { PlusCircle, Pencil, Trash2, Plus } from "lucide-react";
import type { MiseTool, RegistryEntry } from "../../types";
import { ToolCombobox } from "./ToolCombobox";
import {
  categorize,
  parseMiseToolValue,
  serializeMiseToolValue,
} from "../../utils/mise";
import type { MiseToolEntry, MiseToolOptions } from "../../utils/mise";

const OS_OPTIONS = ["linux", "macos", "windows"] as const;

function defaultEntry(): MiseToolEntry {
  return { version: "latest", os: [], postinstall: "", installEnv: {} };
}

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

function initOptions(editTool?: MiseTool | null): MiseToolOptions {
  if (!editTool) {
    return { entries: [defaultEntry()] };
  }
  return parseMiseToolValue(editTool.rawValue);
}

function AddToolModalContent({
  onClose,
  onSubmit,
  editTool,
  githubPat,
}: Omit<AddToolModalProps, "open">) {
  const [name, setName] = useState(editTool?.name ?? "");
  const [opts, setOpts] = useState<MiseToolOptions>(() =>
    initOptions(editTool),
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
    const finalOpts: MiseToolOptions = {
      entries: opts.entries.map((e) => ({
        ...e,
        version: e.version.trim() || "latest",
      })),
    };
    const rawValue = serializeMiseToolValue(finalOpts);
    onSubmit(trimmedName, rawValue);
    onClose();
  };

  const updateEntry = (index: number, patch: Partial<MiseToolEntry>) => {
    setOpts((prev) => ({
      entries: prev.entries.map((e, i) => (i === index ? { ...e, ...patch } : e)),
    }));
  };

  const removeEntry = (index: number) => {
    setOpts((prev) => ({
      entries: prev.entries.filter((_, i) => i !== index),
    }));
  };

  const addEntry = () => {
    setOpts((prev) => ({
      entries: [...prev.entries, defaultEntry()],
    }));
  };

  const toggleOs = (index: number, os: string) => {
    setOpts((prev) => ({
      entries: prev.entries.map((e, i) =>
        i === index
          ? {
              ...e,
              os: e.os.includes(os)
                ? e.os.filter((o) => o !== os)
                : [...e.os, os],
            }
          : e,
      ),
    }));
  };

  const previewCategory = name.trim() ? categorize(name.trim()) : null;

  return (
    <dialog className="modal modal-open">
      <div className="modal-box max-w-lg max-h-[85vh]">
        <h3 className="font-bold text-lg flex items-center gap-2 mb-4">
          {isEdit ? (
            <Pencil className="w-5 h-5" />
          ) : (
            <PlusCircle className="w-5 h-5" />
          )}
          {isEdit ? "Edit Tool" : "Add Tool"}
        </h3>

        {/* Tool name */}
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

        {/* Version entries */}
        <div className="space-y-3 mb-3">
          {opts.entries.map((entry, index) => (
            <EntryCard
              key={index}
              entry={entry}
              index={index}
              total={opts.entries.length}
              isEdit={isEdit}
              onUpdate={(patch) => updateEntry(index, patch)}
              onRemove={() => removeEntry(index)}
              onToggleOs={(os) => toggleOs(index, os)}
            />
          ))}
        </div>

        <button
          type="button"
          className="btn btn-ghost btn-sm gap-1 mb-3"
          onClick={addEntry}
        >
          <Plus className="w-4 h-4" />
          Add version entry
        </button>

        {/* Tool info from registry */}
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
                <span className="font-medium">Category:</span>{" "}
                {previewCategory}
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
            disabled={!name.trim() || opts.entries.length === 0}
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

interface EntryCardProps {
  entry: MiseToolEntry;
  index: number;
  total: number;
  isEdit: boolean;
  onUpdate: (patch: Partial<MiseToolEntry>) => void;
  onRemove: () => void;
  onToggleOs: (os: string) => void;
}

function EntryCard({
  entry,
  index,
  total,
  isEdit,
  onUpdate,
  onRemove,
  onToggleOs,
}: EntryCardProps) {
  const [envKey, setEnvKey] = useState("");
  const [envVal, setEnvVal] = useState("");

  const addEnvVar = () => {
    const k = envKey.trim();
    const v = envVal.trim();
    if (!k || !v) return;
    onUpdate({ installEnv: { ...entry.installEnv, [k]: v } });
    setEnvKey("");
    setEnvVal("");
  };

  const removeEnvVar = (key: string) => {
    const installEnv = { ...entry.installEnv };
    delete installEnv[key];
    onUpdate({ installEnv });
  };

  return (
    <div className="border border-base-300 rounded-lg p-3 relative">
      {total > 1 && (
        <div className="flex items-center justify-between mb-2">
          <span className="text-xs font-medium text-base-content/50">
            Version {index + 1}
          </span>
          <button
            type="button"
            className="btn btn-ghost btn-xs text-error"
            onClick={onRemove}
            title="Remove this version entry"
          >
            <Trash2 className="w-3 h-3" />
          </button>
        </div>
      )}

      {/* Version */}
      <div className="form-control mb-2">
        <label className="label py-1">
          <span className="label-text text-sm">Version</span>
        </label>
        <input
          type="text"
          value={entry.version}
          onChange={(e) => onUpdate({ version: e.target.value })}
          placeholder="e.g. latest, 20, 3.12"
          className="input input-bordered input-sm w-full font-mono"
          autoFocus={isEdit && index === 0}
        />
      </div>

      {/* OS filter */}
      <div className="form-control mb-2">
        <label className="label py-1">
          <span className="label-text text-sm">
            OS filter{" "}
            <span className="text-base-content/40 font-normal">
              (empty = all)
            </span>
          </span>
        </label>
        <div className="flex gap-3">
          {OS_OPTIONS.map((os) => (
            <label key={os} className="label cursor-pointer gap-1 py-0">
              <input
                type="checkbox"
                className="checkbox checkbox-xs"
                checked={entry.os.includes(os)}
                onChange={() => onToggleOs(os)}
              />
              <span className="label-text text-sm">{os}</span>
            </label>
          ))}
        </div>
      </div>

      {/* Postinstall */}
      <div className="form-control mb-2">
        <label className="label py-1">
          <span className="label-text text-sm">
            Post-install{" "}
            <span className="text-base-content/40 font-normal">
              (optional)
            </span>
          </span>
        </label>
        <input
          type="text"
          value={entry.postinstall}
          onChange={(e) => onUpdate({ postinstall: e.target.value })}
          placeholder="e.g. corepack enable"
          className="input input-bordered input-sm w-full font-mono text-xs"
        />
      </div>

      {/* Install env */}
      <div className="form-control">
        <label className="label py-1">
          <span className="label-text text-sm">
            Install env{" "}
            <span className="text-base-content/40 font-normal">
              (optional)
            </span>
          </span>
        </label>
        {Object.entries(entry.installEnv).length > 0 && (
          <div className="mb-1 space-y-1">
            {Object.entries(entry.installEnv).map(([k, v]) => (
              <div
                key={k}
                className="flex items-center gap-2 text-xs font-mono bg-base-200 rounded px-2 py-1"
              >
                <span className="flex-1 truncate">
                  {k}={v}
                </span>
                <button
                  className="btn btn-ghost btn-xs text-error"
                  onClick={() => removeEnvVar(k)}
                >
                  ✕
                </button>
              </div>
            ))}
          </div>
        )}
        <div className="flex gap-2">
          <input
            type="text"
            value={envKey}
            onChange={(e) => setEnvKey(e.target.value)}
            placeholder="KEY"
            className="input input-bordered input-xs font-mono flex-1"
            onKeyDown={(e) => e.key === "Enter" && addEnvVar()}
          />
          <input
            type="text"
            value={envVal}
            onChange={(e) => setEnvVal(e.target.value)}
            placeholder="value"
            className="input input-bordered input-xs font-mono flex-1"
            onKeyDown={(e) => e.key === "Enter" && addEnvVar()}
          />
          <button
            className="btn btn-ghost btn-xs"
            onClick={addEnvVar}
            disabled={!envKey.trim() || !envVal.trim()}
          >
            +
          </button>
        </div>
      </div>
    </div>
  );
}
