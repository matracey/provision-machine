import { Braces, Package } from "lucide-react";
import { useAppState } from "../state/useAppState";
import type { TabId } from "../types";

const TABS: { id: TabId; label: string; icon: React.ReactNode }[] = [
  {
    id: "json",
    label: "Configuration.json",
    icon: <Braces className="w-4 h-4" />,
  },
  { id: "yaml", label: "WinGet DSC", icon: <Package className="w-4 h-4" /> },
];

export function TabBar() {
  const { state, dispatch } = useAppState();

  return (
    <div
      role="tablist"
      className="tabs tabs-bordered bg-base-200 border-b border-base-300 px-6"
    >
      {TABS.map((tab) => (
        <button
          key={tab.id}
          role="tab"
          className={`tab gap-2 ${state.currentTab === tab.id ? "tab-active" : ""}`}
          onClick={() => dispatch({ type: "SET_TAB", payload: tab.id })}
        >
          {tab.icon}
          {tab.label}
        </button>
      ))}
    </div>
  );
}
