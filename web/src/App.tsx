import { useState, useCallback, useRef } from "react";
import { AppProvider } from "./state/AppContext";
import { useAppState } from "./state/useAppState";
import { Header } from "./components/Header";
import { TabBar } from "./components/TabBar";
import { Footer } from "./components/Footer";
import { Toast } from "./components/Toast";
import { showToast } from "./utils/toast";
import { DropZone } from "./components/DropZone";
import { AddItemModal } from "./components/AddItemModal";
import { downloadFile, serializeJson, serializeYaml } from "./utils/fileIO";
import type { ContextType } from "./types";

function AppContent() {
  const { state } = useAppState();
  const [addModalOpen, setAddModalOpen] = useState(false);
  const [addModalContext] = useState<ContextType>("Common");
  const jsonInputRef = useRef<HTMLInputElement>(null);
  const yamlInputRef = useRef<HTMLInputElement>(null);

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

  return (
    <div className="min-h-screen flex flex-col bg-base-100 text-base-content font-sans">
      <Header
        onLoadJson={() => jsonInputRef.current?.click()}
        onLoadYaml={() => yamlInputRef.current?.click()}
        onExportJson={exportJson}
        onExportYaml={exportYaml}
      />
      <TabBar />

      <main className="flex-1 p-6 overflow-auto">
        <DropZone />

        {state.currentTab === "json" && (
          <div
            data-testid="json-editor-placeholder"
            className="text-base-content/50 text-center py-16"
          >
            JSON Editor (coming soon)
          </div>
        )}
        {state.currentTab === "yaml" && (
          <div
            data-testid="yaml-editor-placeholder"
            className="text-base-content/50 text-center py-16"
          >
            YAML Editor (coming soon)
          </div>
        )}
      </main>

      <Footer />
      <Toast />
      <AddItemModal
        open={addModalOpen}
        defaultContext={addModalContext}
        onClose={() => setAddModalOpen(false)}
      />

      {/* Hidden file inputs for Header load buttons */}
      <input ref={jsonInputRef} type="file" accept=".json" className="hidden" />
      <input
        ref={yamlInputRef}
        type="file"
        accept=".yaml,.yml"
        className="hidden"
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
