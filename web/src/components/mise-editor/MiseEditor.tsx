import { useEffect, useCallback, useState } from "react";
import { Box, Plus, Variable, Settings } from "lucide-react";
import { useAppState } from "../../state/useAppState";
import { MiseSection } from "./MiseSection";
import { AddToolModal } from "./AddToolModal";
import { MiseKeyValueSection } from "./MiseKeyValueSection";
import { parseMiseToml, categorize, formatMiseValue } from "../../utils/mise";
import { showToast } from "../../utils/toast";
import { MISE_GIST_RAW_URL } from "../../utils/constants";
import type { MiseTool } from "../../types";

const CATEGORY_ORDER = [
  "Core",
  "Plugins",
  "Cargo",
  "Dotnet",
  "NPM",
  "Pipx",
  "Go",
  "GitHub",
  "VFox",
];

export function MiseEditor() {
  const { state, dispatch } = useAppState();
  const [modalOpen, setModalOpen] = useState(false);
  const [editingTool, setEditingTool] = useState<{
    tool: MiseTool;
    index: number;
  } | null>(null);

  // Lazy-load from gist on first render
  useEffect(() => {
    if (state.miseData) return;
    const load = async () => {
      dispatch({
        type: "SET_STATUS",
        payload: "Loading mise.toml from gist...",
      });
      try {
        const response = await fetch(MISE_GIST_RAW_URL + "?t=" + Date.now());
        if (!response.ok) throw new Error(`HTTP ${response.status}`);
        const content = await response.text();
        dispatch({ type: "SET_MISE_DATA", payload: parseMiseToml(content) });
        showToast("Loaded mise.toml from gist");
        dispatch({ type: "SET_STATUS", payload: "Loaded mise.toml" });
      } catch (error) {
        const msg = error instanceof Error ? error.message : "Unknown error";
        showToast(`Failed to load mise.toml: ${msg}`, "error");
        dispatch({ type: "SET_STATUS", payload: "Load failed" });
      }
    };
    load();
  }, [state.miseData, dispatch]);

  const handleAddSubmit = useCallback(
    (name: string, rawValue: string) => {
      if (!state.miseData) return;
      const tool: MiseTool = {
        name,
        rawValue,
        displayValue: formatMiseValue(rawValue),
        category: categorize(name),
      };
      dispatch({
        type: "SET_MISE_DATA",
        payload: {
          ...state.miseData,
          tools: [...state.miseData.tools, tool],
        },
      });
      showToast(`Added ${name}`);
    },
    [state.miseData, dispatch],
  );

  const handleEditSubmit = useCallback(
    (name: string, rawValue: string) => {
      if (!state.miseData || editingTool === null) return;
      const tools = [...state.miseData.tools];
      tools[editingTool.index] = {
        name,
        rawValue,
        displayValue: formatMiseValue(rawValue),
        category: categorize(name),
      };
      dispatch({
        type: "SET_MISE_DATA",
        payload: { ...state.miseData, tools },
      });
      showToast(`Updated ${name}`);
    },
    [state.miseData, editingTool, dispatch],
  );

  const handleEdit = useCallback(
    (toolIndex: number) => {
      if (!state.miseData) return;
      setEditingTool({
        tool: state.miseData.tools[toolIndex],
        index: toolIndex,
      });
    },
    [state.miseData],
  );

  const handleDelete = useCallback(
    (toolIndex: number) => {
      if (!state.miseData) return;
      const tool = state.miseData.tools[toolIndex];
      const tools = state.miseData.tools.filter((_, i) => i !== toolIndex);
      dispatch({
        type: "SET_MISE_DATA",
        payload: { ...state.miseData, tools },
      });
      showToast(`Deleted ${tool.name}`);
    },
    [state.miseData, dispatch],
  );

  const handleEnvChange = useCallback(
    (env: Record<string, string>) => {
      if (!state.miseData) return;
      dispatch({
        type: "SET_MISE_DATA",
        payload: { ...state.miseData, env },
      });
    },
    [state.miseData, dispatch],
  );

  const handleSettingsChange = useCallback(
    (settings: Record<string, string>) => {
      if (!state.miseData) return;
      dispatch({
        type: "SET_MISE_DATA",
        payload: { ...state.miseData, settings },
      });
    },
    [state.miseData, dispatch],
  );

  if (!state.miseData) {
    return (
      <div className="text-center py-16 text-base-content/50">
        Loading mise.toml...
      </div>
    );
  }

  // Group by category
  const grouped: Record<
    string,
    { tool: (typeof state.miseData.tools)[0]; globalIndex: number }[]
  > = {};
  state.miseData.tools.forEach((tool, i) => {
    const cat = tool.category || "Core";
    if (!grouped[cat]) grouped[cat] = [];
    grouped[cat].push({ tool, globalIndex: i });
  });

  return (
    <>
      <div className="card bg-base-200 border border-base-300 border-l-4 border-l-primary overflow-hidden">
        <div className="p-4 border-b border-base-300 flex justify-between items-center">
          <span className="font-semibold flex items-center gap-2">
            <Box className="w-4 h-4" /> Mise Tools
          </span>
          <div className="flex items-center gap-2">
            <span className="badge badge-ghost badge-sm">
              {state.miseData.tools.length}
            </span>
            <button
              className="btn btn-ghost btn-xs"
              onClick={() => setModalOpen(true)}
              title="Add tool"
            >
              <Plus className="w-3 h-3" />
            </button>
          </div>
        </div>
        <div className="p-3 max-h-[60vh] overflow-y-auto">
          {CATEGORY_ORDER.map((cat) => {
            const categoryTools = grouped[cat];
            if (!categoryTools?.length) return null;
            return (
              <MiseSection
                key={cat}
                category={cat}
                tools={categoryTools.map((t) => t.tool)}
                filter={state.filter}
                onEdit={(localIdx) =>
                  handleEdit(categoryTools[localIdx].globalIndex)
                }
                onDelete={(localIdx) =>
                  handleDelete(categoryTools[localIdx].globalIndex)
                }
              />
            );
          })}

          <MiseKeyValueSection
            title="Environment"
            icon={<Variable className="w-3 h-3" />}
            data={state.miseData.env}
            onChange={handleEnvChange}
          />

          <MiseKeyValueSection
            title="Settings"
            icon={<Settings className="w-3 h-3" />}
            data={state.miseData.settings}
            onChange={handleSettingsChange}
          />
        </div>
      </div>

      <AddToolModal
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        onSubmit={handleAddSubmit}
        githubPat={state.githubPat}
      />

      <AddToolModal
        open={editingTool !== null}
        onClose={() => setEditingTool(null)}
        onSubmit={handleEditSubmit}
        editTool={editingTool?.tool}
        githubPat={state.githubPat}
      />
    </>
  );
}
