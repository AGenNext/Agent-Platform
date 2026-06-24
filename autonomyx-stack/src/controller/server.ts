import { createServer } from "node:http";
import { admit, type AdmissionReview } from "./admission.js";

const port = Number(process.env.PORT ?? process.env.AUTONOMYX_WEBHOOK_PORT ?? 8443);

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

const server = createServer(async (request, response) => {
  if (request.method === "GET" && request.url === "/healthz") {
    response.writeHead(200, { "content-type": "application/json" });
    response.end(JSON.stringify({ status: "ok", service: "autonomyx-controller" }));
    return;
  }

  if (request.method !== "POST" || request.url !== "/admit") {
    response.writeHead(404, { "content-type": "application/json" });
    response.end(JSON.stringify({ error: "not_found" }));
    return;
  }

  try {
    const body = await readBody(request);
    const review = JSON.parse(body) as AdmissionReview;
    const decision = admit(review, request.headers);
    response.writeHead(200, { "content-type": "application/json" });
    response.end(JSON.stringify(decision));
  } catch (error) {
    const message = error instanceof Error ? error.message : "unknown error";
    response.writeHead(400, { "content-type": "application/json" });
    response.end(JSON.stringify({ error: "invalid_admission_review", message }));
  }
});

server.listen(port, "0.0.0.0", () => {
  console.log(`autonomyx-controller listening on :${port}`);
});
