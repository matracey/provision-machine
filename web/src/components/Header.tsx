import { Layers, Search, Download, Upload, CloudUpload } from "lucide-react";
import { useAppState } from "../state/useAppState";

interface HeaderProps {
  onLoadJson: () => void;
  onLoadYaml: () => void;
  onExportJson: () => void;
  onExportYaml: () => void;
  onSave: () => void;
}

export function Header({
  onLoadJson,
  onLoadYaml,
  onExportJson,
  onExportYaml,
  onSave,
}: HeaderProps) {
  const { state, dispatch } = useAppState();

  return (
    <header className="bg-base-200 border-b border-base-300 px-6 py-4 flex justify-between items-center flex-wrap gap-4">
      <h1 className="text-xl font-semibold flex items-center gap-2">
        <Layers className="w-6 h-6 text-primary" />
        QuickInit Config Editor
      </h1>
      <div className="flex gap-2 flex-wrap items-center">
        <label className="input input-bordered input-sm flex items-center gap-2 w-48">
          <Search className="w-4 h-4 opacity-50" />
          <input
            type="text"
            placeholder="Filter items..."
            value={state.filter}
            onChange={(e) =>
              dispatch({ type: "SET_FILTER", payload: e.target.value })
            }
            className="grow"
          />
        </label>
        <button className="btn btn-ghost btn-sm" onClick={onLoadJson}>
          <Download className="w-4 h-4" /> Load JSON
        </button>
        <button className="btn btn-ghost btn-sm" onClick={onLoadYaml}>
          <Download className="w-4 h-4" /> Load YAML
        </button>
        <button className="btn btn-ghost btn-sm" onClick={onExportJson}>
          <Upload className="w-4 h-4" /> Export JSON
        </button>
        <button className="btn btn-ghost btn-sm" onClick={onExportYaml}>
          <Upload className="w-4 h-4" /> Export YAML
        </button>
        <button className="btn btn-success btn-sm" onClick={onSave}>
          <CloudUpload className="w-4 h-4" /> Save
        </button>
      </div>
    </header>
  );
}
