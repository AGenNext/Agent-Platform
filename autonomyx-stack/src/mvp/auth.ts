import type { IncomingHttpHeaders } from "node:http";

const token = process.env.AUTONOMYX_MVP_TOKEN;

export function isAuthRequired(): boolean {
  return Boolean(token);
}

export function authorize(headers: IncomingHttpHeaders): { allowed: boolean; reason?: string } {
  if (!token) return { allowed: true };

  const authorization = headers.authorization;
  const expected = `Bearer ${token}`;

  if (authorization === expected) return { allowed: true };
  return { allowed: false, reason: "MVP_TOKEN_REQUIRED" };
}
