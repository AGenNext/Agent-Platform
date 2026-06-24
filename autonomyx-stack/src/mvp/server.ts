import { createServer, type ServerResponse } from "node:http";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { admit, type AdmissionReview } from "../controller/admission.js";
import { initialState, listApplications, runPlatform } from "../platform.js";
import type { ExecutionRequest, PlatformState } from "../types.js";
import { authorize, isAuthRequired } from "./auth.js";
import { renderMvpHtml } from "./html.js";
import { loadState, saveState, stateInfo } from "./store.js";

const port = Number(process.env.PORT ?? process.env.AUTONOMYX_MVP_PORT ?? 8080);
let state: PlatformState;

function json(response: ServerResponse, code: number, value: unknown): void {
  response.writeHead(code, { "content-type": "application/json" });
  response.end(JSON.stringify(value, null, 2));
}

function text(response: ServerResponse, code: number, value: string, type = "text/plain"): void {
  response.writeHead(code, { "content-type": type });
  response.end(value);
}

function readBody(request: NodeJS.ReadableStream): Promise<string> {
  return new Promise((resolve, reject) => {
    let body = "";
    request.setEncoding("utf8");
    request.on("data", (chunk) => {
      body += chunk;
    });
    request.on("end", () => resolve(body));
    request.on("error", reject);
  });
}

function readJsonFile(path: string): string {
  try {
    return readFileSync(join(process.cwd(), path), "utf8");
  } catch {
    return "";
  }
}

const server = createServer(async (request, response) => {
  const url = new URL(request.url ?? "/", `http://${request.headers.host ?? "localhost"}`);

  if (request.method === "GET" && url.pathname === "/") {
    text(response, 200, renderMvpHtml(), "text/html");
    return;
  }

  if (request.method === "GET" && url.pathname === "/healthz") {
    json(response, 200, {
      status: "ok",
      service: "autonomyx-mvp",
      version: "0.1.0",
      authRequired: isAuthRequired(),
      graphVersion: state.graph.version,
      storage: stateInfo(),
    });
    return;
  }

  if (url.pathname.startsWith("/api/") && request.method !== "GET") {
    const auth = authorize(request.headers);
    if (!auth.allowed) {
      json(response, 401, { ok: false, error: auth.reason });
      return;
    }
  }

  if (request.method === "GET" && url.pathname === "/api/apps") {
    json(response, 200, listApplications());
    return;
  }

  if (request.method === "GET" && url.pathname === "/api/state") {
    json(response, 200, {
      domains: state.domains,
      graphVersion: state.graph.version,
      nodes: state.graph.nodes.length,
      edges: state.graph.edges.length,
      storage: stateInfo(),
      audit: state.audit.slice(-10),
    });
    return;
  }

  if (request.method === "GET" && url.pathname === "/api/audit") {
    json(response, 200, { count: state.audit.length, events: state.audit });
    return;
  }

  if (request.method === "GET" && url.pathname === "/api/manifest") {
    text(response, 200, readJsonFile("autonomyx.manifest.yaml"), "text/yaml");
    return;
  }

  if (request.method === "GET" && url.pathname === "/api/binding") {
    text(response, 200, readJsonFile("bindings/autonomyx.stack.binding.yaml"), "text/yaml");
    return;
  }

  if (request.method === "POST" && url.pathname === "/api/execute") {
    try {
      const body = JSON.parse(await readBody(request)) as Partial<ExecutionRequest>;
      const requestId = `req:${Date.now()}`;
      const identityHeader = request.headers["x-spiffe-id"] ?? request.headers["x-oidc-subject"] ?? "mvp-operator";
      const identitySubject = Array.isArray(identityHeader) ? identityHeader[0] : identityHeader;
      const execution: ExecutionRequest = {
        id: requestId,
        domain: String(body.domain ?? "platform"),
        identity: {
          id: String(identitySubject).startsWith("spiffe://") ? String(identitySubject) : `oidc:${identitySubject}`,
          issuer: String(identitySubject).startsWith("spiffe://") ? "spiffe" : "oidc",
          subject: String(identitySubject),
          claims: { source: "mvp-api" },
        },
        op: (body.op ?? "⊕") as ExecutionRequest["op"],
        target: body.target,
        payload: body.payload ?? {},
        context: body.context,
      };
      state = runPlatform(execution, state);
      await saveState(state);
      json(response, 200, { ok: true, requestId, graphVersion: state.graph.version, audit: state.audit.at(-1), storage: stateInfo() });
    } catch (error) {
      const message = error instanceof Error ? error.message : "invalid request";
      json(response, 400, { ok: false, error: message });
    }
    return;
  }

  if (request.method === "POST" && url.pathname === "/api/reset") {
    state = initialState();
    await saveState(state);
    json(response, 200, { ok: true, graphVersion: state.graph.version, storage: stateInfo() });
    return;
  }

  if (request.method === "POST" && url.pathname === "/admit") {
    try {
      const review = JSON.parse(await readBody(request)) as AdmissionReview;
      json(response, 200, admit(review, request.headers));
    } catch (error) {
      const message = error instanceof Error ? error.message : "invalid admission review";
      json(response, 400, { error: message });
    }
    return;
  }

  json(response, 404, { error: "not_found" });
});

state = await loadState();
server.listen(port, "0.0.0.0", () => {
  console.log(`autonomyx MVP listening on :${port}`);
  console.log(JSON.stringify({ storage: stateInfo() }));
});
