import { useState, useCallback } from "react";
import { FileJson } from "lucide-react";
import { useAppState } from "../../state/useAppState";
import { ContextPanel } from "./ContextPanel";
import { ContextMenu } from "../ContextMenu";
import { CONTEXTS } from "../../utils/constants";
import {
  moveJsonItem,
  copyJsonItem,
  splitJsonItem,
  deleteJsonItem,
} from "../../utils/itemOps";
import { showToast } from "../../utils/toast";
import type { ContextType } from "../../types";

interface ContextMenuState {
  x: number;
  y: number;
  context: ContextType;
  section: string;
  index: number | string;
}

interface JsonEditorProps {
  onAddItem: (context: ContextType) => void;
}

export function JsonEditor({ onAddItem }: JsonEditorProps) {
  const { state, dispatch } = useAppState();
  const [ctxMenu, setCtxMenu] = useState<ContextMenuState | null>(null);

  const handleJsonChanged = () => {
    if (state.json) {
      dispatch({ type: "SET_JSON", payload: { ...state.json } });
      dispatch({
        type: "SET_LAST_MODIFIED",
        payload: `Last updated: ${new Date().toLocaleTimeString()}`,
      });
    }
  };

  const applyJsonUpdate = useCallback(
    (newJson: Record<string, unknown>) => {
      dispatch({ type: "SET_JSON", payload: newJson });
      dispatch({
        type: "SET_LAST_MODIFIED",
        payload: `Last updated: ${new Date().toLocaleTimeString()}`,
      });
    },
    [dispatch],
  );

  const handleContextMenu = useCallback(
    (
      e: React.MouseEvent,
      context: ContextType,
      section: string,
      index: number | string,
    ) => {
      e.preventDefault();
      setCtxMenu({ x: e.clientX, y: e.clientY, context, section, index });
    },
    [],
  );

  const handleMove = useCallback(
    (target: ContextType) => {
      if (!state.json || !ctxMenu) return;
      const result = moveJsonItem(
        state.json,
        ctxMenu.section,
        ctxMenu.index,
        ctxMenu.context,
        target,
      );
      applyJsonUpdate(result);
      showToast(`Moved item to ${target}`);
    },
    [state.json, ctxMenu, applyJsonUpdate],
  );

  const handleCopy = useCallback(
    (target: ContextType) => {
      if (!state.json || !ctxMenu) return;
      const result = copyJsonItem(
        state.json,
        ctxMenu.section,
        ctxMenu.index,
        ctxMenu.context,
        target,
      );
      applyJsonUpdate(result);
      showToast(`Copied item to ${target}`);
    },
    [state.json, ctxMenu, applyJsonUpdate],
  );

  const handleSplit = useCallback(() => {
    if (!state.json || !ctxMenu) return;
    const result = splitJsonItem(state.json, ctxMenu.section, ctxMenu.index);
    applyJsonUpdate(result);
    showToast("Split item to Work & Personal");
  }, [state.json, ctxMenu, applyJsonUpdate]);

  const handleDelete = useCallback(() => {
    if (!state.json || !ctxMenu) return;
    const result = deleteJsonItem(
      state.json,
      ctxMenu.section,
      ctxMenu.index,
      ctxMenu.context,
    );
    applyJsonUpdate(result);
    showToast("Deleted item");
  }, [state.json, ctxMenu, applyJsonUpdate]);

  if (!state.json) {
    return (
      <div className="col-span-3 flex flex-col items-center justify-center py-16 text-base-content/40">
        <FileJson className="w-12 h-12 mb-4" />
        <p>Load a Configuration.json file to begin editing</p>
      </div>
    );
  }

  return (
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 min-h-[400px]">
      {CONTEXTS.map((context) => (
        <ContextPanel
          key={context}
          context={context}
          onAddItem={onAddItem}
          onJsonChanged={handleJsonChanged}
          onContextMenu={handleContextMenu}
        />
      ))}
      {ctxMenu && (
        <ContextMenu
          x={ctxMenu.x}
          y={ctxMenu.y}
          sourceContext={ctxMenu.context}
          onClose={() => setCtxMenu(null)}
          onMove={handleMove}
          onDelete={handleDelete}
          onCopy={handleCopy}
          onSplit={handleSplit}
        />
      )}
    </div>
  );
}
