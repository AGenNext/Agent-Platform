import { Route, Routes } from "react-router-dom";
import { Sidebar } from "./components/Sidebar";
import { AgentBuilderPage } from "./pages/AgentBuilderPage";
import { AgentsPage } from "./pages/AgentsPage";
import { ArtifactsPage } from "./pages/ArtifactsPage";
import { BillingPage } from "./pages/BillingPage";
import { HealthPage } from "./pages/HealthPage";
import { IntegrationsPage } from "./pages/IntegrationsPage";
import { MemoryPage } from "./pages/MemoryPage";
import { ObjectivesPage } from "./pages/ObjectivesPage";
import { OnboardingPage } from "./pages/OnboardingPage";
import { RuntimePage } from "./pages/RuntimePage";
import { TraceLogPage } from "./pages/TraceLogPage";
import { WorkflowRunPage } from "./pages/WorkflowRunPage";

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
          <Route path="/" element={<OnboardingPage />} />
          <Route path="/health" element={<HealthPage />} />
          <Route path="/build" element={<AgentBuilderPage />} />
          <Route path="/agents" element={<AgentsPage />} />
          <Route path="/memory" element={<MemoryPage />} />
          <Route path="/runs" element={<WorkflowRunPage />} />
          <Route path="/artifacts" element={<ArtifactsPage />} />
          <Route path="/traces" element={<TraceLogPage />} />
          <Route path="/billing" element={<BillingPage />} />
          <Route path="/integrations" element={<IntegrationsPage />} />
          <Route path="/objectives" element={<ObjectivesPage />} />
          <Route path="/runtime" element={<RuntimePage />} />
        </Routes>
      </main>
    </div>
  );
}
