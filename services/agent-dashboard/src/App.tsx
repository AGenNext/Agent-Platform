import { Route, Routes } from "react-router-dom";
import { Sidebar } from "./components/Sidebar";
import { AgentBuilderPage } from "./pages/AgentBuilderPage";
import { AgentsPage } from "./pages/AgentsPage";
import { HealthPage } from "./pages/HealthPage";
import { MemoryPage } from "./pages/MemoryPage";
import { ObjectivesPage } from "./pages/ObjectivesPage";
import { RuntimePage } from "./pages/RuntimePage";

export default function App() {
  return (
    <div style={{ display: "flex", minHeight: "100vh" }}>
      <Sidebar />
      <main
        style={{
          flex: 1,
          padding: "32px 36px",
          overflowY: "auto",
          maxWidth: 820,
        }}
      >
        <Routes>
          <Route path="/" element={<HealthPage />} />
          <Route path="/build" element={<AgentBuilderPage />} />
          <Route path="/agents" element={<AgentsPage />} />
          <Route path="/memory" element={<MemoryPage />} />
          <Route path="/objectives" element={<ObjectivesPage />} />
          <Route path="/runtime" element={<RuntimePage />} />
        </Routes>
      </main>
    </div>
  );
}
