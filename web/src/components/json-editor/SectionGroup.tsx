import { ChevronDown } from "lucide-react";
import { DynamicIcon, type IconName } from "lucide-react/dynamic";
import { useAppState } from "../../state/useAppState";
import { getNestedValue } from "../../utils/nested";
import { getItemType } from "../../utils/fileIO";
import { AliasItem } from "./AliasItem";
import { DraggableItem } from "./DraggableItem";
import { EditableItem } from "./EditableItem";
import { KvpItem } from "./KvpItem";
import { NameUrlItem } from "./NameUrlItem";
import type { SectionType, ContextType } from "../../types";

interface SectionGroupProps {
  context: ContextType;
  sectionKey: string;
  label: string;
  icon: IconName | undefined;
  type: SectionType;
  data: Record<string, unknown>;
  onJsonChanged: () => void;
  onContextMenu: (
    e: React.MouseEvent,
    context: ContextType,
    section: string,
    index: number | string,
  ) => void;
}

export function SectionGroup({
  context,
  sectionKey,
  label,
  icon,
  type,
  data,
  onJsonChanged,
  onContextMenu,
}: SectionGroupProps) {
  const { state, dispatch } = useAppState();
  const value = getNestedValue(data, sectionKey);
  const sectionStateKey = `${context}-${sectionKey}`;
  const isCollapsed = state.collapsedSections.has(sectionStateKey);

  if (!value) return null;
  if (Array.isArray(value) && value.length === 0) return null;
  if (
    (type === "object" || type === "alias-object") &&
    typeof value === "object" &&
    Object.keys(value as object).length === 0
  )
    return null;

  const isEditingItem = (idx: number, isKvp = false, isNameUrl = false) =>
    state.editingItem?.context === context &&
    state.editingItem?.section === sectionKey &&
    state.editingItem?.index === idx &&
    (isKvp ? state.editingItem?.isKvp === true : true) &&
    (isNameUrl ? state.editingItem?.isNameUrl === true : true);

  const startEdit = (
    idx: number,
    opts: { isKvp?: boolean; isNameUrl?: boolean } = {},
  ) => {
    dispatch({
      type: "SET_EDITING_ITEM",
      payload: { context, section: sectionKey, index: idx, ...opts },
    });
  };

  const cancelEdit = () =>
    dispatch({ type: "SET_EDITING_ITEM", payload: null });

  let itemCount = 0;
  if (Array.isArray(value)) itemCount = value.length;
  else if (
    (type === "object" || type === "alias-object") &&
    typeof value === "object"
  )
    itemCount = Object.keys(value as object).length;
  else if (value) itemCount = 1;

  const renderItems = () => {
    if (type === "array" && Array.isArray(value)) {
      return value.map((item, i) => {
        if (isEditingItem(i)) {
          return (
            <EditableItem
              key={i}
              item={item}
              itemType={getItemType(item)}
              onSave={(newVal) => {
                (value as unknown[])[i] = newVal;
                cancelEdit();
                onJsonChanged();
              }}
              onCancel={cancelEdit}
            />
          );
        }
        return (
          <DraggableItem
            key={i}
            item={item}
            context={context}
            section={sectionKey}
            index={i}
            filter={state.filter}
            onEdit={() => startEdit(i)}
            onDelete={() => {
              (value as unknown[]).splice(i, 1);
              onJsonChanged();
            }}
            onContextMenu={(e) => onContextMenu(e, context, sectionKey, i)}
          />
        );
      });
    }

    if (type === "name-url-array" && Array.isArray(value)) {
      return value.map((item, i) => {
        const obj = item as { name: string; url: string };
        return (
          <NameUrlItem
            key={i}
            name={obj.name || ""}
            url={obj.url || ""}
            context={context}
            section={sectionKey}
            index={i}
            filter={state.filter}
            isEditing={isEditingItem(i, false, true)}
            onStartEdit={() => startEdit(i, { isNameUrl: true })}
            onSave={(name, url) => {
              (value as { name: string; url: string }[])[i] = { name, url };
              cancelEdit();
              onJsonChanged();
            }}
            onCancel={cancelEdit}
            onDelete={() => {
              (value as unknown[]).splice(i, 1);
              onJsonChanged();
            }}
            onContextMenu={(e) => onContextMenu(e, context, sectionKey, i)}
          />
        );
      });
    }

    if (type === "alias-object" && typeof value === "object" && value !== null) {
      return Object.entries(value as Record<string, unknown>).map(
        ([k, v], i) => {
          const arr = Array.isArray(v) ? v : [String(v), ""];
          const command = String(arr[0] ?? "");
          const description = String(arr[1] ?? "");
          return (
            <AliasItem
              key={`${k}-${i}`}
              aliasName={k}
              command={command}
              description={description}
              context={context}
              section={sectionKey}
              index={i}
              filter={state.filter}
              isEditing={isEditingItem(i, true)}
              onStartEdit={() => startEdit(i, { isKvp: true })}
              onSave={(newName, newCmd, newDesc) => {
                const obj = value as Record<string, unknown>;
                if (newName !== k) delete obj[k];
                obj[newName] = [newCmd, newDesc];
                cancelEdit();
                onJsonChanged();
              }}
              onCancel={cancelEdit}
              onDelete={() => {
                delete (value as Record<string, unknown>)[k];
                onJsonChanged();
              }}
              onContextMenu={(e) => onContextMenu(e, context, sectionKey, k)}
            />
          );
        },
      );
    }

    if (type === "object" && typeof value === "object" && value !== null) {
      return Object.entries(value as Record<string, string>).map(
        ([k, v], i) => (
          <KvpItem
            key={`${k}-${i}`}
            keyName={k}
            value={String(v)}
            context={context}
            section={sectionKey}
            index={i}
            filter={state.filter}
            isEditing={isEditingItem(i, true)}
            onStartEdit={() => startEdit(i, { isKvp: true })}
            onSave={(newKey, newValue) => {
              const obj = value as Record<string, unknown>;
              if (newKey !== k) delete obj[k];
              obj[newKey] = newValue;
              cancelEdit();
              onJsonChanged();
            }}
            onCancel={cancelEdit}
            onDelete={() => {
              delete (value as Record<string, unknown>)[k];
              onJsonChanged();
            }}
            onContextMenu={(e) => onContextMenu(e, context, sectionKey, k)}
          />
        ),
      );
    }

    if (type === "string") {
      return (
        <DraggableItem
          item={value}
          context={context}
          section={sectionKey}
          index={0}
          filter={state.filter}
          onEdit={() => startEdit(0)}
          onDelete={() => {
            // Can't delete a string field easily
          }}
        />
      );
    }

    return null;
  };

  return (
    <div className="mb-3">
      <div
        className="flex items-center justify-between text-xs uppercase text-base-content/40 px-1 pb-1 border-b border-base-300 mb-2 cursor-pointer hover:text-base-content/60"
        onClick={() =>
          dispatch({ type: "TOGGLE_SECTION", payload: sectionStateKey })
        }
      >
        <span className="flex items-center gap-1.5">
          <ChevronDown
            className={`w-3 h-3 transition-transform ${isCollapsed ? "-rotate-90" : ""}`}
          />
          <DynamicIcon
            name={(icon ?? "FileText") as IconName}
            className="w-3 h-3"
          />
          {label}
        </span>
        <span className="badge badge-ghost badge-sm">{itemCount}</span>
      </div>
      {!isCollapsed && (
        <div
          className="section-items"
          data-context={context}
          data-section={sectionKey}
          data-type={type}
        >
          {renderItems()}
        </div>
      )}
    </div>
  );
}
