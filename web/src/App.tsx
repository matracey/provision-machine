import { useState, useCallback, useEffect } from "react";
import { AppProvider } from "./state/AppContext";
import { useAppState } from "./state/useAppState";
import { Header } from "./components/Header";
import { TabBar } from "./components/TabBar";
import { Footer } from "./components/Footer";
import { Toast } from "./components/Toast";
import { showToast } from "./utils/toast";
import { DropZone } from "./components/DropZone";
import { AddItemModal } from "./components/AddItemModal";
import { JsonEditor } from "./components/json-editor/JsonEditor";
import { YamlEditor } from "./components/yaml-editor/YamlEditor";
import {
  downloadFile,
  serializeJson,
  serializeYaml,
  parseJsonConfig,
  parseYamlConfig,
} from "./utils/fileIO";
import { REPO_RAW_BASE_URL, REPO_FILES } from "./utils/constants";
import type { ContextType } from "./types";

function AppContent() {
  const { state, dispatch } = useAppState();
  const [addModalOpen, setAddModalOpen] = useState(false);
  const [addModalContext, setAddModalContext] = useState<ContextType>("Common");

  const exportJson = useCallback(() => {
    if (!state.json) {
      showToast("No JSON configuration to export", "error");
      return;
    }
    downloadFile(
      serializeJson(state.json),
      "Configuration.json",
      "application/json",
    );
    showToast("Configuration.json exported");
  }, [state.json]);

  const exportYaml = useCallback(() => {
    let exported = 0;
    if (state.yamlWork) {
      downloadFile(
        serializeYaml(state.yamlWork),
        "configuration.work.dsc.yaml",
        "text/yaml",
      );
      exported++;
    }
    if (state.yamlPersonal) {
      downloadFile(
        serializeYaml(state.yamlPersonal),
        "configuration.personal.dsc.yaml",
        "text/yaml",
      );
      exported++;
    }
    if (exported === 0) showToast("No YAML configurations to export", "error");
    else showToast(`Exported ${exported} YAML file(s)`);
  }, [state.yamlWork, state.yamlPersonal]);

  // Keyboard shortcuts
  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if (e.ctrlKey && e.key === "s") {
        e.preventDefault();
        if (state.currentTab === "json") exportJson();
        else exportYaml();
      }
      if (e.key === "Escape") {
        setAddModalOpen(false);
      }
    };
    document.addEventListener("keydown", handler);
    return () => document.removeEventListener("keydown", handler);
  }, [state.currentTab, exportJson, exportYaml]);

  // Auto-load configuration files from repository
  useEffect(() => {
    const autoLoad = async () => {
      const files = [
        { path: REPO_FILES.json, type: "json" },
        { path: REPO_FILES.yamlWork, type: "yaml-work" },
        { path: REPO_FILES.yamlPersonal, type: "yaml-personal" },
      ];

      let loadedCount = 0;
      for (const file of files) {
        try {
          const response = await fetch(
            `${REPO_RAW_BASE_URL}/${file.path}?t=${Date.now()}`,
          );
          if (!response.ok) continue;
          const text = await response.text();
          if (file.type === "json") {
            dispatch({ type: "SET_JSON", payload: parseJsonConfig(text) });
            loadedCount++;
          } else if (file.type === "yaml-work") {
            dispatch({ type: "SET_YAML_WORK", payload: parseYamlConfig(text) });
            loadedCount++;
          } else if (file.type === "yaml-personal") {
            dispatch({
              type: "SET_YAML_PERSONAL",
              payload: parseYamlConfig(text),
            });
            loadedCount++;
          }
        } catch {
          // Silently skip files that can't be loaded
        }
      }

      if (loadedCount > 0) {
        dispatch({
          type: "SET_STATUS",
          payload: `Auto-loaded ${loadedCount} configuration file(s)`,
        });
        dispatch({
          type: "SET_LAST_MODIFIED",
          payload: `Last updated: ${new Date().toLocaleTimeString()}`,
        });
        showToast(`Loaded ${loadedCount} configuration file(s)`);
      }
    };
    autoLoad();
  }, [dispatch]);

  const handleAddItem = (context: ContextType) => {
    setAddModalContext(context);
    setAddModalOpen(true);
  };

  return (
    <div className="min-h-screen flex flex-col bg-base-100 text-base-content font-sans">
      <Header
        onLoadJson={() => document.getElementById("json-file-input")?.click()}
        onLoadYaml={() => document.getElementById("yaml-file-input")?.click()}
        onExportJson={exportJson}
        onExportYaml={exportYaml}
      />
      <TabBar />

      <main className="flex-1 p-6 overflow-auto">
        <DropZone />

        {state.currentTab === "json" && (
          <JsonEditor onAddItem={handleAddItem} />
        )}
        {state.currentTab === "yaml" && <YamlEditor />}
      </main>

      <Footer />
      <Toast />
      <AddItemModal
        open={addModalOpen}
        defaultContext={addModalContext}
        onClose={() => setAddModalOpen(false)}
      />
    </div>
  );
}

function App() {
  return (
    <AppProvider>
      <AppContent />
    </AppProvider>
  );
}

export default App;
