import { useState } from "react";
import { PlusCircle, Plus } from "lucide-react";
import { useAppState } from "../state/useAppState";
import { showToast } from "../utils/toast";
import { getNestedValue, setNestedValue } from "../utils/nested";
import { ADD_ITEM_SECTIONS, CONTEXTS } from "../utils/constants";
import type { ContextType } from "../types";

interface AddItemModalProps {
  open: boolean;
  defaultContext?: ContextType;
  onClose: () => void;
}

export function AddItemModal({
  open,
  defaultContext,
  onClose,
}: AddItemModalProps) {
  const { state, dispatch } = useAppState();
  const [context, setContext] = useState<ContextType>(
    defaultContext ?? "Common",
  );
  const [section, setSection] = useState(ADD_ITEM_SECTIONS[0].value);
  const [value, setValue] = useState("");

  const handleAdd = () => {
    const values = value
      .trim()
      .split("\n")
      .filter((v) => v.trim());
    if (values.length === 0) {
      showToast("Please enter at least one value", "error");
      return;
    }

    const json = structuredClone(state.json);
    if (!json) return;

    if (!json[context]) json[context] = {};
    let arr = getNestedValue(
      json[context] as Record<string, unknown>,
      section,
    ) as unknown[];
    if (!arr) {
      setNestedValue(json[context] as Record<string, unknown>, section, []);
      arr = getNestedValue(
        json[context] as Record<string, unknown>,
        section,
      ) as unknown[];
    }

    values.forEach((v) => arr.push(v.trim()));
    dispatch({ type: "SET_JSON", payload: { ...json } });
    dispatch({
      type: "SET_STATUS",
      payload: `Added ${values.length} item(s) to ${context}.${section}`,
    });
    dispatch({
      type: "SET_LAST_MODIFIED",
      payload: `Last updated: ${new Date().toLocaleTimeString()}`,
    });
    showToast(`Added ${values.length} item(s)`);
    setValue("");
    onClose();
  };

  // Sync defaultContext when modal opens
  if (open && defaultContext && defaultContext !== context) {
    setContext(defaultContext);
  }

  return (
    <dialog className={`modal ${open ? "modal-open" : ""}`}>
      <div className="modal-box">
        <h3 className="font-bold text-lg flex items-center gap-2">
          <PlusCircle className="w-5 h-5" /> Add Item
        </h3>

        <div className="form-control mt-4">
          <label className="label">
            <span className="label-text">Context</span>
          </label>
          <select
            className="select select-bordered"
            value={context}
            onChange={(e) => setContext(e.target.value as ContextType)}
          >
            {CONTEXTS.map((c) => (
              <option key={c} value={c}>
                {c}
              </option>
            ))}
          </select>
        </div>

        <div className="form-control mt-4">
          <label className="label">
            <span className="label-text">Section</span>
          </label>
          <select
            className="select select-bordered"
            value={section}
            onChange={(e) => setSection(e.target.value)}
          >
            {ADD_ITEM_SECTIONS.map((s) => (
              <option key={s.value} value={s.value}>
                {s.label}
              </option>
            ))}
          </select>
        </div>

        <div className="form-control mt-4">
          <label className="label">
            <span className="label-text">
              Value (one per line for multiple)
            </span>
          </label>
          <textarea
            className="textarea textarea-bordered font-mono"
            rows={4}
            placeholder={"e.g., main/git\nextras/vscode"}
            value={value}
            onChange={(e) => setValue(e.target.value)}
          />
        </div>

        <div className="modal-action">
          <button className="btn btn-ghost" onClick={onClose}>
            Cancel
          </button>
          <button className="btn btn-primary" onClick={handleAdd}>
            <Plus className="w-4 h-4" /> Add
          </button>
        </div>
      </div>
      <form method="dialog" className="modal-backdrop" onClick={onClose}>
        <button>close</button>
      </form>
    </dialog>
  );
}
