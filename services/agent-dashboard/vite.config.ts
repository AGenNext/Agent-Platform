import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  server: {
    host: "0.0.0.0",
    port: 3000,
    proxy: {
      "/api": {
        target: process.env.VITE_API_URL ?? "http://localhost:8001",
        rewrite: (path) => path.replace(/^\/api/, ""),
        changeOrigin: true,
      },
    },
  },
  define: {
    // Expose env vars to browser at build time
    "import.meta.env.VITE_API_URL": JSON.stringify(
      process.env.VITE_API_URL ?? "http://localhost:8001"
    ),
    "import.meta.env.VITE_SURREALDB_URL": JSON.stringify(
      process.env.VITE_SURREALDB_URL ?? "ws://localhost:8000/rpc"
    ),
    "import.meta.env.VITE_SURREALDB_NS": JSON.stringify(
      process.env.VITE_SURREALDB_NS ?? "agent_platform"
    ),
    "import.meta.env.VITE_SURREALDB_DB": JSON.stringify(
      process.env.VITE_SURREALDB_DB ?? "agent_platform"
    ),
  },
});
