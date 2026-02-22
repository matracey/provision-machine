import { Info, Copy } from "lucide-react";
import { useAppState } from "../state/useAppState";
import { showToast } from "../utils/toast";
import { REPO_RAW_BASE_URL } from "../utils/constants";

const RUN_COMMAND = `iwr ${REPO_RAW_BASE_URL}/provisioning/Provision-Machine.ps1 | iex`;

export function Footer() {
  const { state } = useAppState();

  const copyCommand = () => {
    navigator.clipboard.writeText(RUN_COMMAND);
    showToast("Copied to clipboard!");
  };

  return (
    <footer className="bg-base-200 border-t border-base-300 px-6 py-3">
      <div className="flex justify-between items-center text-xs text-base-content/50 mb-2">
        <span className="flex items-center gap-2">
          <Info className="w-3 h-3" /> {state.statusText}
        </span>
        <span>{state.lastModified}</span>
      </div>
      <div className="flex items-center gap-2 text-xs">
        <span className="text-base-content/50">Run:</span>
        <code
          className="flex-1 bg-base-300 border border-base-content/20 rounded px-3 py-1.5 font-mono text-base-content/70 select-all cursor-pointer hover:border-base-content/40 transition"
          onClick={copyCommand}
          title="Click to copy"
        >
          {RUN_COMMAND}
        </code>
        <button className="btn btn-ghost btn-xs" onClick={copyCommand}>
          <Copy className="w-3 h-3" /> Copy
        </button>
      </div>
    </footer>
  );
}
