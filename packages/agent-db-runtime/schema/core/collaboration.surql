-- ============================================================
-- AGenNext Agent DB Runtime
-- Core Collaboration / Exchange Schema
-- ============================================================

-- Purpose:
-- Collaboration models the social layer of the platform: conversations,
-- messages, proposals, requests, responses, offers, acceptances,
-- rejections, negotiation, coordination, handoff, delegation, context
-- transfer, authority transfer, and responsibility transfer between
-- humans, agents, teams, organizations, and systems.

DEFINE TABLE collaboration_space SCHEMAFULL;

DEFINE FIELD entity ON collaboration_space TYPE record<entity>;
DEFINE FIELD owner ON collaboration_space TYPE option<record<identity>>;
DEFINE FIELD space_type ON collaboration_space TYPE string
  ASSERT $value IN [
    "conversation",
    "project_space",
    "team_space",
    "agent_team_space",
    "customer_space",
    "vendor_space",
    "incident_room",
    "approval_room",
    "negotiation_room",
    "support_thread",
    "workflow_thread",
    "task_thread"
  ];

DEFINE FIELD name ON collaboration_space TYPE string;
DEFINE FIELD description ON collaboration_space TYPE option<string>;
DEFINE FIELD status ON collaboration_space TYPE string DEFAULT "active"
  ASSERT $value IN ["active", "inactive", "paused", "closed", "archived"];

DEFINE FIELD participants ON collaboration_space TYPE array<record<identity>> DEFAULT [];
DEFINE FIELD related_entities ON collaboration_space TYPE array<record<entity>> DEFAULT [];
DEFINE FIELD related_tasks ON collaboration_space TYPE array<record<task>> DEFAULT [];
DEFINE FIELD related_workflows ON collaboration_space TYPE array<record<workflow_run>> DEFAULT [];
DEFINE FIELD policy_refs ON collaboration_space TYPE array<record<governance_object>> DEFAULT [];
DEFINE FIELD created_at ON collaboration_space TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON collaboration_space TYPE datetime VALUE time::now();
DEFINE FIELD closed_at ON collaboration_space TYPE option<datetime>;
DEFINE FIELD metadata ON collaboration_space TYPE option<object>;

DEFINE INDEX collaboration_space_entity_idx ON collaboration_space FIELDS entity UNIQUE;
DEFINE INDEX collaboration_space_type_idx ON collaboration_space FIELDS space_type;
DEFINE INDEX collaboration_space_status_idx ON collaboration_space FIELDS status;
DEFINE INDEX collaboration_space_name_idx ON collaboration_space FIELDS name SEARCH ANALYZER ascii BM25;

-- ------------------------------------------------------------
-- Exchange
-- ------------------------------------------------------------

DEFINE TABLE exchange SCHEMAFULL;

DEFINE FIELD entity ON exchange TYPE record<entity>;
DEFINE FIELD collaboration_space ON exchange TYPE option<record<collaboration_space>>;
DEFINE FIELD sender ON exchange TYPE option<record<identity>>;
DEFINE FIELD recipients ON exchange TYPE array<record<identity>> DEFAULT [];
DEFINE FIELD in_reply_to ON exchange TYPE option<record<exchange>>;
DEFINE FIELD related_task ON exchange TYPE option<record<task>>;
DEFINE FIELD related_decision ON exchange TYPE option<record<decision>>;
DEFINE FIELD related_workflow_run ON exchange TYPE option<record<workflow_run>>;
DEFINE FIELD related_artifact ON exchange TYPE option<record<artifact>>;

DEFINE FIELD exchange_type ON exchange TYPE string
  ASSERT $value IN [
    "message",
    "request",
    "response",
    "proposal",
    "offer",
    "acceptance",
    "rejection",
    "counter_offer",
    "question",
    "answer",
    "notification",
    "approval_request",
    "approval_response",
    "handoff_request",
    "handoff_acceptance",
    "delegation_request",
    "delegation_acceptance",
    "status_update",
    "coordination_signal",
    "negotiation_message",
    "commitment",
    "acknowledgement"
  ];

DEFINE FIELD status ON exchange TYPE string DEFAULT "created"
  ASSERT $value IN ["created", "sent", "delivered", "read", "acknowledged", "accepted", "rejected", "expired", "archived"];

DEFINE FIELD subject ON exchange TYPE option<string>;
DEFINE FIELD body ON exchange TYPE option<string>;
DEFINE FIELD payload ON exchange TYPE object DEFAULT {};
DEFINE FIELD attachments ON exchange TYPE array<record<artifact>> DEFAULT [];
DEFINE FIELD protocol_message ON exchange TYPE option<record<protocol_message>>;
DEFINE FIELD evidence ON exchange TYPE option<object>;
DEFINE FIELD correlation_id ON exchange TYPE option<string>;
DEFINE FIELD created_at ON exchange TYPE datetime DEFAULT time::now();
DEFINE FIELD sent_at ON exchange TYPE option<datetime>;
DEFINE FIELD read_at ON exchange TYPE option<datetime>;
DEFINE FIELD updated_at ON exchange TYPE datetime VALUE time::now();
DEFINE FIELD metadata ON exchange TYPE option<object>;

DEFINE INDEX exchange_entity_idx ON exchange FIELDS entity UNIQUE;
DEFINE INDEX exchange_space_idx ON exchange FIELDS collaboration_space;
DEFINE INDEX exchange_sender_idx ON exchange FIELDS sender;
DEFINE INDEX exchange_type_idx ON exchange FIELDS exchange_type;
DEFINE INDEX exchange_status_idx ON exchange FIELDS status;
DEFINE INDEX exchange_correlation_idx ON exchange FIELDS correlation_id;
DEFINE INDEX exchange_body_idx ON exchange FIELDS body SEARCH ANALYZER ascii BM25;

-- ------------------------------------------------------------
-- Handoff
-- ------------------------------------------------------------

DEFINE TABLE handoff SCHEMAFULL;

DEFINE FIELD entity ON handoff TYPE record<entity>;
DEFINE FIELD collaboration_space ON handoff TYPE option<record<collaboration_space>>;
DEFINE FIELD from_identity ON handoff TYPE record<identity>;
DEFINE FIELD to_identity ON handoff TYPE record<identity>;
DEFINE FIELD resource ON handoff TYPE option<record<entity>>;
DEFINE FIELD task ON handoff TYPE option<record<task>>;
DEFINE FIELD workflow_run ON handoff TYPE option<record<workflow_run>>;
DEFINE FIELD decision ON handoff TYPE option<record<decision>>;

DEFINE FIELD handoff_type ON handoff TYPE string
  ASSERT $value IN [
    "ownership_transfer",
    "responsibility_transfer",
    "context_transfer",
    "authority_transfer",
    "task_handoff",
    "workflow_handoff",
    "agent_handoff",
    "human_handoff",
    "support_escalation",
    "incident_escalation"
  ];

DEFINE FIELD status ON handoff TYPE string DEFAULT "requested"
  ASSERT $value IN ["requested", "accepted", "rejected", "in_progress", "completed", "cancelled", "expired"];

DEFINE FIELD context_snapshot ON handoff TYPE object DEFAULT {};
DEFINE FIELD authority_scope ON handoff TYPE option<object>;
DEFINE FIELD obligations ON handoff TYPE array<object> DEFAULT [];
DEFINE FIELD evidence ON handoff TYPE option<object>;
DEFINE FIELD requested_at ON handoff TYPE datetime DEFAULT time::now();
DEFINE FIELD accepted_at ON handoff TYPE option<datetime>;
DEFINE FIELD completed_at ON handoff TYPE option<datetime>;
DEFINE FIELD updated_at ON handoff TYPE datetime VALUE time::now();
DEFINE FIELD metadata ON handoff TYPE option<object>;

DEFINE INDEX handoff_entity_idx ON handoff FIELDS entity UNIQUE;
DEFINE INDEX handoff_from_idx ON handoff FIELDS from_identity;
DEFINE INDEX handoff_to_idx ON handoff FIELDS to_identity;
DEFINE INDEX handoff_type_idx ON handoff FIELDS handoff_type;
DEFINE INDEX handoff_status_idx ON handoff FIELDS status;

-- ------------------------------------------------------------
-- Functions
-- ------------------------------------------------------------

DEFINE FUNCTION fn::send_exchange(
  $entity: record<entity>,
  $space: option<record<collaboration_space>>,
  $sender: option<record<identity>>,
  $recipients: array<record<identity>>,
  $exchange_type: string,
  $subject: option<string>,
  $body: option<string>,
  $payload: object,
  $correlation_id: option<string>
) {
  RETURN CREATE exchange SET
    entity = $entity,
    collaboration_space = $space,
    sender = $sender,
    recipients = $recipients,
    exchange_type = $exchange_type,
    subject = $subject,
    body = $body,
    payload = $payload,
    correlation_id = $correlation_id,
    status = "sent",
    sent_at = time::now();
};

DEFINE FUNCTION fn::request_handoff(
  $entity: record<entity>,
  $from_identity: record<identity>,
  $to_identity: record<identity>,
  $handoff_type: string,
  $resource: option<record<entity>>,
  $task: option<record<task>>,
  $context_snapshot: object,
  $authority_scope: option<object>
) {
  RETURN CREATE handoff SET
    entity = $entity,
    from_identity = $from_identity,
    to_identity = $to_identity,
    handoff_type = $handoff_type,
    resource = $resource,
    task = $task,
    context_snapshot = $context_snapshot,
    authority_scope = $authority_scope,
    status = "requested";
};

DEFINE FUNCTION fn::accept_handoff(
  $handoff: record<handoff>,
  $actor: record<identity>
) {
  RETURN UPDATE $handoff SET
    status = "accepted",
    accepted_at = time::now(),
    metadata = object::extend(IF metadata = NONE THEN {} ELSE metadata END, { accepted_by: $actor });
};

DEFINE FUNCTION fn::complete_handoff(
  $handoff: record<handoff>,
  $actor: record<identity>,
  $evidence: option<object>
) {
  RETURN UPDATE $handoff SET
    status = "completed",
    completed_at = time::now(),
    evidence = $evidence,
    metadata = object::extend(IF metadata = NONE THEN {} ELSE metadata END, { completed_by: $actor });
};
