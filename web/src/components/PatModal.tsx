import { useState } from "react";
import { Key, CloudUpload } from "lucide-react";
import { useAppState } from "../state/useAppState";

interface PatModalProps {
  open: boolean;
  onClose: () => void;
  onConfirm: (pat: string) => void;
}

export function PatModal({ open, onClose, onConfirm }: PatModalProps) {
  const { state, dispatch } = useAppState();
  const [pat, setPat] = useState(state.githubPat ?? "");
  const [remember, setRemember] = useState(!!state.githubPat);

  if (!open) return null;

  const handleConfirm = () => {
    const trimmed = pat.trim();
    if (!trimmed) return;

    dispatch({ type: "SET_GITHUB_PAT", payload: trimmed });
    if (remember) {
      localStorage.setItem("quickinit_github_pat", trimmed);
    } else {
      localStorage.removeItem("quickinit_github_pat");
    }
    onConfirm(trimmed);
  };

  return (
    <dialog className="modal modal-open">
      <div className="modal-box">
        <div className="flex justify-between items-center mb-4">
          <h2 className="font-semibold flex items-center gap-2">
            <Key className="w-4 h-4" /> GitHub Personal Access Token
          </h2>
          <button className="btn btn-ghost btn-sm btn-circle" onClick={onClose}>
            ✕
          </button>
        </div>
        <p className="text-sm text-base-content/60 mb-4">
          To save to the repository, you need a GitHub Personal Access Token
          with <code className="bg-base-300 px-1 rounded">repo</code> scope.
        </p>
        <div className="form-control mb-3">
          <label className="label">
            <span className="label-text">Personal Access Token</span>
          </label>
          <input
            type="password"
            placeholder="ghp_xxxxxxxxxxxx"
            className="input input-bordered font-mono"
            value={pat}
            onChange={(e) => setPat(e.target.value)}
          />
        </div>
        <label className="flex items-center gap-2 cursor-pointer mb-3">
          <input
            type="checkbox"
            className="checkbox checkbox-sm"
            checked={remember}
            onChange={(e) => setRemember(e.target.checked)}
          />
          <span className="text-sm text-base-content/60">
            Remember token (stored in browser)
          </span>
        </label>
        <p className="text-xs text-base-content/40 mb-4">
          <a
            href="https://github.com/settings/tokens/new?scopes=repo&description=QuickInit%20Config%20Editor"
            target="_blank"
            rel="noopener noreferrer"
            className="link link-primary"
          >
            Create a new token with repo scope →
          </a>
        </p>
        <div className="modal-action">
          <button className="btn btn-ghost" onClick={onClose}>
            Cancel
          </button>
          <button
            className="btn btn-success"
            onClick={handleConfirm}
            disabled={!pat.trim()}
          >
            <CloudUpload className="w-4 h-4" /> Save
          </button>
        </div>
      </div>
      <form method="dialog" className="modal-backdrop">
        <button onClick={onClose}>close</button>
      </form>
    </dialog>
  );
}
