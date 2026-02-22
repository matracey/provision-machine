import { ChevronDown, Plus } from "lucide-react";
import { DynamicIcon, type IconName } from "lucide-react/dynamic";
import { useAppState } from "../../state/useAppState";
import { SectionGroup } from "./SectionGroup";
import {
  JSON_SECTIONS,
  CONTEXT_COLORS,
  CONTEXT_ICONS,
} from "../../utils/constants";
import { getNestedValue } from "../../utils/nested";
import type { ContextType } from "../../types";

interface ContextPanelProps {
  context: ContextType;
  onAddItem: (context: ContextType) => void;
  onJsonChanged: () => void;
  onContextMenu: (
    e: React.MouseEvent,
    context: ContextType,
    section: string,
    index: number | string,
  ) => void;
}

export function ContextPanel({
  context,
  onAddItem,
  onJsonChanged,
  onContextMenu,
}: ContextPanelProps) {
  const { state, dispatch } = useAppState();
  const panelKey = `panel-${context}`;
  const isCollapsed = state.collapsedPanels.has(panelKey);
  const contextData = state.json?.[context] as
    | Record<string, unknown>
    | undefined;
  const color = CONTEXT_COLORS[context];

  // Count all items
  let count = 0;
  if (contextData) {
    JSON_SECTIONS.forEach(({ key, type }) => {
      const value = getNestedValue(contextData, key);
      if (Array.isArray(value)) count += value.length;
      else if (type === "object" && value && typeof value === "object")
        count += Object.keys(value).length;
      else if (value) count += 1;
    });
  }

  return (
    <div className="card bg-base-200 border border-base-300 overflow-hidden flex flex-col">
      <div
        className={`p-3 border-b border-base-300 border-l-4 flex justify-between items-center cursor-pointer hover:bg-base-300/30`}
        style={{ borderLeftColor: `var(--color-${color})` }}
        onClick={() => dispatch({ type: "TOGGLE_PANEL", payload: panelKey })}
      >
        <span className="font-semibold flex items-center gap-2">
          <ChevronDown
            className={`w-4 h-4 transition-transform ${isCollapsed ? "-rotate-90" : ""}`}
          />
          <DynamicIcon
            name={(CONTEXT_ICONS[context] ?? "FileText") as IconName}
            className="w-4 h-4"
          />
          {context}
        </span>
        <div className="flex items-center gap-2">
          <span className="badge badge-ghost badge-sm">{count}</span>
          <button
            className="btn btn-ghost btn-xs"
            onClick={(e) => {
              e.stopPropagation();
              onAddItem(context);
            }}
            title={`Add to ${context}`}
          >
            <Plus className="w-3 h-3" />
          </button>
        </div>
      </div>
      {!isCollapsed && (
        <div
          className="p-3 flex-1 overflow-y-auto max-h-[60vh]"
          id={`json-${context.toLowerCase()}`}
        >
          {contextData ? (
            JSON_SECTIONS.map(({ key, label, icon, type }) => (
              <SectionGroup
                key={key}
                context={context}
                sectionKey={key}
                label={label}
                icon={icon}
                type={type}
                data={contextData}
                onJsonChanged={onJsonChanged}
                onContextMenu={onContextMenu}
              />
            ))
          ) : (
            <div className="text-center py-4 text-base-content/40 text-sm italic">
              No configuration
            </div>
          )}
        </div>
      )}
    </div>
  );
}
