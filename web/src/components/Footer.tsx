import { Info } from "lucide-react";
import { useAppState } from "../state/useAppState";

export function Footer() {
  const { state } = useAppState();

  return (
    <footer className="bg-base-200 border-t border-base-300 px-6 py-2 text-xs text-base-content/50 flex justify-between">
      <span className="flex items-center gap-2">
        <Info className="w-3 h-3" /> {state.statusText}
      </span>
      <span>{state.lastModified}</span>
    </footer>
  );
}
