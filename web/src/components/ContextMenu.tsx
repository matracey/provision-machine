import { useEffect, useRef } from "react";
import { ArrowRight, Trash2, Copy, SplitSquareHorizontal } from "lucide-react";
import type { ContextType } from "../types";

export interface ContextMenuItem {
  label: string;
  icon: React.ReactNode;
  action: () => void;
  hidden?: boolean;
}

interface ContextMenuProps {
  x: number;
  y: number;
  sourceContext: ContextType;
  onClose: () => void;
  onMove: (target: ContextType) => void;
  onDelete: () => void;
  onCopy?: (target: ContextType) => void;
  onSplit?: () => void;
}

export function ContextMenu({
  x,
  y,
  sourceContext,
  onClose,
  onMove,
  onDelete,
  onCopy,
  onSplit,
}: ContextMenuProps) {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleClick = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) onClose();
    };
    const handleKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    document.addEventListener("mousedown", handleClick);
    document.addEventListener("keydown", handleKey);
    return () => {
      document.removeEventListener("mousedown", handleClick);
      document.removeEventListener("keydown", handleKey);
    };
  }, [onClose]);

  const moveTargets = (["Common", "Work", "Personal"] as ContextType[]).filter(
    (c) => c !== sourceContext,
  );

  return (
    <div
      ref={ref}
      className="fixed z-50 bg-base-200 border border-base-300 rounded-lg shadow-xl py-1 min-w-48"
      style={{ left: x, top: y }}
      data-testid="context-menu"
    >
      {moveTargets.map((target) => (
        <button
          key={`move-${target}`}
          className="w-full text-left px-4 py-2 text-sm hover:bg-base-300 flex items-center gap-2"
          onClick={() => {
            onMove(target);
            onClose();
          }}
        >
          <ArrowRight className="w-3 h-3" /> Move to {target}
        </button>
      ))}

      {onCopy &&
        moveTargets.map((target) => (
          <button
            key={`copy-${target}`}
            className="w-full text-left px-4 py-2 text-sm hover:bg-base-300 flex items-center gap-2"
            onClick={() => {
              onCopy(target);
              onClose();
            }}
          >
            <Copy className="w-3 h-3" /> Copy to {target}
          </button>
        ))}

      {onSplit && sourceContext === "Common" && (
        <button
          className="w-full text-left px-4 py-2 text-sm hover:bg-base-300 flex items-center gap-2"
          onClick={() => {
            onSplit();
            onClose();
          }}
        >
          <SplitSquareHorizontal className="w-3 h-3" /> Split to Work & Personal
        </button>
      )}

      <div className="border-t border-base-300 my-1" />
      <button
        className="w-full text-left px-4 py-2 text-sm hover:bg-base-300 flex items-center gap-2 text-error"
        onClick={() => {
          onDelete();
          onClose();
        }}
      >
        <Trash2 className="w-3 h-3" /> Delete
      </button>
    </div>
  );
}
