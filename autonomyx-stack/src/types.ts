export type DomainId = string;
export type IdentityId = string;
export type TrustScore = number;

export type ArithmeticOperator = "⊕" | "⊖" | "⊗" | "÷";

export type OamKind = "Component" | "Trait" | "Scope" | "Workflow" | "ApplicationConfiguration";

export interface Identity {
  id: IdentityId;
  issuer: "enterprise-iam" | "spiffe" | "oidc" | "local";
  subject: string;
  claims: Record<string, unknown>;
}

export interface Domain {
  id: DomainId;
  name: string;
  scope: "foundation" | "governance" | "runtime" | "oam" | "experience";
  status: "trusted" | "verified" | "suspended";
}

export interface GraphNode {
  "@id": string;
  "@type": string;
  domain: DomainId;
  data: Record<string, unknown>;
  createdAt: string;
}

export interface GraphEdge {
  from: string;
  to: string;
  relation: string;
  domain: DomainId;
  weight?: number;
}

export interface AnyDataGraph {
  nodes: GraphNode[];
  edges: GraphEdge[];
  version: number;
}

export interface ExecutionRequest {
  id: string;
  domain: DomainId;
  identity: Identity;
  op: ArithmeticOperator;
  target?: string;
  payload: Record<string, unknown>;
  context?: Record<string, unknown>;
}

export interface ExecutionResult {
  status: "allowed" | "denied" | "error";
  reason?: string;
  graph: AnyDataGraph;
  auditEvent: AuditEvent;
}

export interface AuditEvent {
  id: string;
  requestId: string;
  identity: IdentityId;
  domain: DomainId;
  op: ArithmeticOperator;
  status: "allowed" | "denied" | "error";
  reason?: string;
  graphVersion: number;
  timestamp: string;
}

export interface PlatformState {
  domains: Domain[];
  graph: AnyDataGraph;
  trust: Record<string, TrustScore>;
  audit: AuditEvent[];
}

export interface AppCapability {
  name: string;
  method: "GET" | "POST";
  path: string;
  requires: string[];
}

export interface AutonomyxApp {
  name: string;
  tier: "foundation" | "governance" | "runtime" | "oam" | "experience";
  domain: DomainId;
  oam: {
    component: string;
    traits: string[];
    scopes: string[];
    workflows: string[];
  };
  capabilities: AppCapability[];
}
