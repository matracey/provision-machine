import { useState, useCallback } from "react";
import { PlusCircle, Pencil } from "lucide-react";
import type { MiseTool, RegistryEntry } from "../../types";
import { ToolCombobox } from "./ToolCombobox";
import {
  categorize,
  parseMiseToolValue,
  serializeMiseToolValue,
} from "../../utils/mise";
import type { MiseToolOptions } from "../../utils/mise";

const OS_OPTIONS = ["linux", "macos", "windows"] as const;

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
    return {
      version: "latest",
      os: [],
      postinstall: "",
      installEnv: {},
      isComplex: false,
    };
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
  const [envKey, setEnvKey] = useState("");
  const [envVal, setEnvVal] = useState("");

  const isEdit = !!editTool;

  const handleToolInfo = useCallback(
    (info: RegistryEntry | null) => setToolInfo(info),
    [],
  );

  const handleSubmit = () => {
    const trimmedName = name.trim();
    if (!trimmedName) return;
    const finalOpts = { ...opts, version: opts.version.trim() || "latest" };
    const rawValue = serializeMiseToolValue(finalOpts);
    onSubmit(trimmedName, rawValue);
    onClose();
  };

  const toggleOs = (os: string) => {
    setOpts((prev) => ({
      ...prev,
      os: prev.os.includes(os)
        ? prev.os.filter((o) => o !== os)
        : [...prev.os, os],
    }));
  };

  const addEnvVar = () => {
    const k = envKey.trim();
    const v = envVal.trim();
    if (!k || !v) return;
    setOpts((prev) => ({
      ...prev,
      installEnv: { ...prev.installEnv, [k]: v },
    }));
    setEnvKey("");
    setEnvVal("");
  };

  const removeEnvVar = (key: string) => {
    setOpts((prev) => {
      const installEnv = { ...prev.installEnv };
      delete installEnv[key];
      return { ...prev, installEnv };
    });
  };

  const previewCategory = name.trim() ? categorize(name.trim()) : null;

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

        {/* Version */}
        <div className="form-control mb-3">
          <label className="label">
            <span className="label-text font-medium">Version</span>
          </label>
          {opts.isComplex ? (
            <textarea
              value={opts.version}
              onChange={(e) =>
                setOpts((prev) => ({ ...prev, version: e.target.value }))
              }
              className="textarea textarea-bordered w-full font-mono text-sm"
              rows={3}
              placeholder="Complex value (array of versions)"
            />
          ) : (
            <input
              type="text"
              value={opts.version}
              onChange={(e) =>
                setOpts((prev) => ({ ...prev, version: e.target.value }))
              }
              placeholder="e.g. latest, 20, 3.12"
              className="input input-bordered w-full font-mono"
              autoFocus={isEdit}
            />
          )}
        </div>

        {/* OS filter */}
        {!opts.isComplex && (
          <div className="form-control mb-3">
            <label className="label">
              <span className="label-text font-medium">
                OS filter{" "}
                <span className="text-base-content/40 font-normal">
                  (empty = all platforms)
                </span>
              </span>
            </label>
            <div className="flex gap-3">
              {OS_OPTIONS.map((os) => (
                <label key={os} className="label cursor-pointer gap-2">
                  <input
                    type="checkbox"
                    className="checkbox checkbox-sm"
                    checked={opts.os.includes(os)}
                    onChange={() => toggleOs(os)}
                  />
                  <span className="label-text">{os}</span>
                </label>
              ))}
            </div>
          </div>
        )}

        {/* Postinstall */}
        {!opts.isComplex && (
          <div className="form-control mb-3">
            <label className="label">
              <span className="label-text font-medium">
                Post-install command{" "}
                <span className="text-base-content/40 font-normal">
                  (optional)
                </span>
              </span>
            </label>
            <input
              type="text"
              value={opts.postinstall}
              onChange={(e) =>
                setOpts((prev) => ({ ...prev, postinstall: e.target.value }))
              }
              placeholder="e.g. corepack enable"
              className="input input-bordered w-full font-mono text-sm"
            />
          </div>
        )}

        {/* Install env */}
        {!opts.isComplex && (
          <div className="form-control mb-3">
            <label className="label">
              <span className="label-text font-medium">
                Install environment{" "}
                <span className="text-base-content/40 font-normal">
                  (optional)
                </span>
              </span>
            </label>
            {Object.entries(opts.installEnv).length > 0 && (
              <div className="mb-2 space-y-1">
                {Object.entries(opts.installEnv).map(([k, v]) => (
                  <div
                    key={k}
                    className="flex items-center gap-2 text-sm font-mono bg-base-200 rounded px-2 py-1"
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
                className="input input-bordered input-sm font-mono flex-1"
                onKeyDown={(e) => e.key === "Enter" && addEnvVar()}
              />
              <input
                type="text"
                value={envVal}
                onChange={(e) => setEnvVal(e.target.value)}
                placeholder="value"
                className="input input-bordered input-sm font-mono flex-1"
                onKeyDown={(e) => e.key === "Enter" && addEnvVar()}
              />
              <button
                className="btn btn-ghost btn-sm"
                onClick={addEnvVar}
                disabled={!envKey.trim() || !envVal.trim()}
              >
                +
              </button>
            </div>
          </div>
        )}

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
                <span className="font-medium">Category:</span> {previewCategory}
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
