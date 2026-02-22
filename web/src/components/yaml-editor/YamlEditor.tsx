import { useMemo, useCallback, useState } from "react";
import { Globe, Briefcase, User } from "lucide-react";
import { useAppState } from "../../state/useAppState";
import { YamlColumn } from "./YamlColumn";
import { ContextMenu } from "../ContextMenu";
import { moveYamlResource } from "../../utils/itemOps";
import { showToast } from "../../utils/toast";
import type { ContextType, YamlResource } from "../../types";

interface YamlContextMenuState {
  x: number;
  y: number;
  context: ContextType;
  resourceId: string;
}

export function YamlEditor() {
  const { state, dispatch } = useAppState();
  const [ctxMenu, setCtxMenu] = useState<YamlContextMenuState | null>(null);

  const { commonResources, workOnlyResources, personalOnlyResources } =
    useMemo(() => {
      const workResources = state.yamlWork?.properties?.resources || [];
      const personalResources = state.yamlPersonal?.properties?.resources || [];
      const workIds = new Set(workResources.map((r) => r.settings?.id));
      const personalIds = new Set(personalResources.map((r) => r.settings?.id));
      const commonIds = new Set(
        [...workIds].filter((id) => personalIds.has(id)),
      );

      return {
        commonResources: workResources.filter((r) =>
          commonIds.has(r.settings?.id),
        ),
        workOnlyResources: workResources.filter(
          (r) => !commonIds.has(r.settings?.id),
        ),
        personalOnlyResources: personalResources.filter(
          (r) => !commonIds.has(r.settings?.id),
        ),
      };
    }, [state.yamlWork, state.yamlPersonal]);

  const { yamlWork, yamlPersonal } = state;

  const deleteYamlItem = useCallback(
    (type: string, packageId: string) => {
      const filterOut = (resources: typeof yamlWork) => {
        if (!resources?.properties?.resources) return resources;
        return {
          ...resources,
          properties: {
            ...resources.properties,
            resources: resources.properties.resources.filter(
              (r) => r.settings?.id !== packageId,
            ),
          },
        };
      };

      if (type === "common" || type === "work") {
        if (yamlWork)
          dispatch({ type: "SET_YAML_WORK", payload: filterOut(yamlWork)! });
      }
      if (type === "common" || type === "personal") {
        if (yamlPersonal)
          dispatch({
            type: "SET_YAML_PERSONAL",
            payload: filterOut(yamlPersonal)!,
          });
      }
      dispatch({
        type: "SET_STATUS",
        payload: `Deleted ${packageId} from ${type}`,
      });
      dispatch({
        type: "SET_LAST_MODIFIED",
        payload: `Last updated: ${new Date().toLocaleTimeString()}`,
      });
    },
    [yamlWork, yamlPersonal, dispatch],
  );

  const handleContextMenu = useCallback(
    (e: React.MouseEvent, resource: YamlResource, type: string) => {
      e.preventDefault();
      const contextMap: Record<string, ContextType> = {
        common: "Common",
        work: "Work",
        personal: "Personal",
      };
      setCtxMenu({
        x: e.clientX,
        y: e.clientY,
        context: contextMap[type] || "Common",
        resourceId: resource.settings?.id || "",
      });
    },
    [],
  );

  const handleMove = useCallback(
    (target: ContextType) => {
      if (!ctxMenu) return;
      const { work: newWork, personal: newPersonal } = moveYamlResource(
        state.yamlWork,
        state.yamlPersonal,
        ctxMenu.resourceId,
        ctxMenu.context,
        target,
      );
      if (newWork) dispatch({ type: "SET_YAML_WORK", payload: newWork });
      if (newPersonal)
        dispatch({ type: "SET_YAML_PERSONAL", payload: newPersonal });
      dispatch({
        type: "SET_LAST_MODIFIED",
        payload: `Last updated: ${new Date().toLocaleTimeString()}`,
      });
      showToast(`Moved ${ctxMenu.resourceId} to ${target}`);
    },
    [ctxMenu, state.yamlWork, state.yamlPersonal, dispatch],
  );

  const handleDelete = useCallback(() => {
    if (!ctxMenu) return;
    deleteYamlItem(ctxMenu.context.toLowerCase(), ctxMenu.resourceId);
  }, [ctxMenu, deleteYamlItem]);

  if (!state.yamlWork && !state.yamlPersonal) {
    return (
      <div className="flex flex-col items-center justify-center py-16 text-base-content/40">
        <p>Load WinGet DSC YAML files to begin editing</p>
      </div>
    );
  }

  return (
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 min-h-[400px]">
      <YamlColumn
        title="Common"
        icon={<Globe className="w-4 h-4" />}
        color="common"
        resources={commonResources}
        count={commonResources.length}
        filter={state.filter}
        type="common"
        onDelete={(id) => deleteYamlItem("common", id)}
        onContextMenu={handleContextMenu}
      />
      <YamlColumn
        title="Work Only"
        icon={<Briefcase className="w-4 h-4" />}
        color="work"
        resources={workOnlyResources}
        count={workOnlyResources.length}
        filter={state.filter}
        type="work"
        onDelete={(id) => deleteYamlItem("work", id)}
        onContextMenu={handleContextMenu}
      />
      <YamlColumn
        title="Personal Only"
        icon={<User className="w-4 h-4" />}
        color="personal"
        resources={personalOnlyResources}
        count={personalOnlyResources.length}
        filter={state.filter}
        type="personal"
        onDelete={(id) => deleteYamlItem("personal", id)}
        onContextMenu={handleContextMenu}
      />
      {ctxMenu && (
        <ContextMenu
          x={ctxMenu.x}
          y={ctxMenu.y}
          sourceContext={ctxMenu.context}
          onClose={() => setCtxMenu(null)}
          onMove={handleMove}
          onDelete={handleDelete}
        />
      )}
    </div>
  );
}
