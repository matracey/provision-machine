import { useCallback, useState, useRef, type DragEvent } from "react";
import { UploadCloud, FolderOpen } from "lucide-react";
import { useAppState } from "../state/useAppState";
import { showToast } from "../utils/toast";
import { parseJsonConfig, parseYamlConfig } from "../utils/fileIO";

export function DropZone() {
  const { state, dispatch } = useAppState();
  const [dragOver, setDragOver] = useState(false);
  const jsonInputRef = useRef<HTMLInputElement>(null);
  const yamlInputRef = useRef<HTMLInputElement>(null);

  const handleFile = useCallback(
    (file: File) => {
      const reader = new FileReader();
      reader.onload = (e) => {
        const text = e.target?.result as string;
        try {
          if (file.name.endsWith(".json")) {
            dispatch({ type: "SET_JSON", payload: parseJsonConfig(text) });
            dispatch({ type: "SET_STATUS", payload: `Loaded ${file.name}` });
            showToast("Configuration loaded successfully");
          } else if (
            file.name.endsWith(".yaml") ||
            file.name.endsWith(".yml")
          ) {
            const yaml = parseYamlConfig(text);
            if (file.name.toLowerCase().includes("work")) {
              dispatch({ type: "SET_YAML_WORK", payload: yaml });
            } else {
              dispatch({ type: "SET_YAML_PERSONAL", payload: yaml });
            }
            dispatch({ type: "SET_TAB", payload: "yaml" });
            dispatch({ type: "SET_STATUS", payload: `Loaded ${file.name}` });
            showToast("YAML loaded successfully");
          } else {
            showToast("Unsupported file type", "error");
          }
        } catch (err) {
          showToast(`Error parsing file: ${(err as Error).message}`, "error");
        }
      };
      reader.readAsText(file);
    },
    [dispatch],
  );

  const onDrop = useCallback(
    (e: DragEvent) => {
      e.preventDefault();
      setDragOver(false);
      const file = e.dataTransfer.files[0];
      if (file) handleFile(file);
    },
    [handleFile],
  );

  const onBrowse = useCallback(() => {
    if (state.currentTab === "json") jsonInputRef.current?.click();
    else yamlInputRef.current?.click();
  }, [state.currentTab]);

  const hasFiles = state.json || state.yamlWork || state.yamlPersonal;

  return (
    <>
      {!hasFiles && (
        <div
          className={`border-2 border-dashed rounded-xl p-12 text-center mb-6 transition ${
            dragOver ? "border-primary bg-primary/10" : "border-base-300"
          }`}
          onDragOver={(e) => {
            e.preventDefault();
            setDragOver(true);
          }}
          onDragLeave={() => setDragOver(false)}
          onDrop={onDrop}
          data-testid="dropzone-full"
        >
          <UploadCloud className="w-12 h-12 text-base-content/30 mx-auto mb-4" />
          <p className="text-base-content/50 mb-4">
            Drag & drop Configuration.json or DSC YAML files here
          </p>
          <button className="btn btn-ghost btn-sm" onClick={onBrowse}>
            <FolderOpen className="w-4 h-4" /> Browse Files
          </button>
        </div>
      )}

      {hasFiles && (
        <div
          className={`border border-dashed rounded-lg px-4 py-2 mb-4 transition flex items-center justify-center gap-4 text-sm text-base-content/50 ${
            dragOver ? "border-primary bg-primary/10" : "border-base-300"
          }`}
          onDragOver={(e) => {
            e.preventDefault();
            setDragOver(true);
          }}
          onDragLeave={() => setDragOver(false)}
          onDrop={onDrop}
          data-testid="dropzone-compact"
        >
          <UploadCloud className="w-4 h-4" />
          <span>Drop files to load</span>
          <button className="btn btn-ghost btn-xs" onClick={onBrowse}>
            Browse
          </button>
        </div>
      )}

      <input
        ref={jsonInputRef}
        type="file"
        accept=".json"
        className="hidden"
        onChange={(e) => {
          if (e.target.files?.[0]) handleFile(e.target.files[0]);
        }}
      />
      <input
        ref={yamlInputRef}
        type="file"
        accept=".yaml,.yml"
        className="hidden"
        onChange={(e) => {
          if (e.target.files?.[0]) handleFile(e.target.files[0]);
        }}
      />
    </>
  );
}
