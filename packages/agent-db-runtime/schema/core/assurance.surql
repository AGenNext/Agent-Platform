-- ============================================================
-- AGenNext Agent DB Runtime
-- Core Assurance / Insurance / Refund Schema
-- ============================================================

-- Purpose:
-- Assurance models commercial and operational confidence commitments:
-- insurance, assurance, guarantee, warranty, refund, dispute, claim,
-- resolution, settlement, compensation, SLA credit, and liability terms.
-- This supports agent commerce, paid agent work, service guarantees,
-- AP2/UCP-like payment flows, and governed customer protection.

DEFINE TABLE assurance_product SCHEMAFULL;

DEFINE FIELD entity ON assurance_product TYPE record<entity>;
DEFINE FIELD owner ON assurance_product TYPE option<record<identity>>;
DEFINE FIELD assurance_type ON assurance_product TYPE string
  ASSERT $value IN [
    "insurance",
    "assurance",
    "guarantee",
    "warranty",
    "refund_policy",
    "service_credit",
    "liability_cover",
    "performance_guarantee",
    "quality_guarantee",
    "compliance_guarantee",
    "delivery_guarantee",
    "uptime_guarantee",
    "safety_guarantee",
    "trust_guarantee"
  ];

DEFINE FIELD name ON assurance_product TYPE string;
DEFINE FIELD description ON assurance_product TYPE option<string>;
DEFINE FIELD status ON assurance_product TYPE string DEFAULT "draft"
  ASSERT $value IN ["draft", "active", "inactive", "deprecated", "archived"];

DEFINE FIELD coverage_scope ON assurance_product TYPE object DEFAULT {};
DEFINE FIELD exclusions ON assurance_product TYPE array<object> DEFAULT [];
DEFINE FIELD eligibility_rules ON assurance_product TYPE array<object> DEFAULT [];
DEFINE FIELD trigger_conditions ON assurance_product TYPE array<object> DEFAULT [];
DEFINE FIELD payout_rules ON assurance_product TYPE array<object> DEFAULT [];
DEFINE FIELD evidence_requirements ON assurance_product TYPE array<object> DEFAULT [];
DEFINE FIELD policy_refs ON assurance_product TYPE array<record<governance_object>> DEFAULT [];

DEFINE FIELD max_liability_amount ON assurance_product TYPE option<number>;
DEFINE FIELD currency ON assurance_product TYPE string DEFAULT "USD";
DEFINE FIELD duration_seconds ON assurance_product TYPE option<int>;
DEFINE FIELD valid_from ON assurance_product TYPE datetime DEFAULT time::now();
DEFINE FIELD valid_to ON assurance_product TYPE option<datetime>;
DEFINE FIELD created_at ON assurance_product TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON assurance_product TYPE datetime VALUE time::now();
DEFINE FIELD metadata ON assurance_product TYPE option<object>;

DEFINE INDEX assurance_product_entity_idx ON assurance_product FIELDS entity UNIQUE;
DEFINE INDEX assurance_product_type_idx ON assurance_product FIELDS assurance_type;
DEFINE INDEX assurance_product_status_idx ON assurance_product FIELDS status;
DEFINE INDEX assurance_product_name_idx ON assurance_product FIELDS name SEARCH ANALYZER ascii BM25;

-- ------------------------------------------------------------
-- Assurance Binding
-- ------------------------------------------------------------

DEFINE TABLE assurance_binding SCHEMAFULL;

DEFINE FIELD assurance_product ON assurance_binding TYPE record<assurance_product>;
DEFINE FIELD subject ON assurance_binding TYPE option<record<identity>>;
DEFINE FIELD resource ON assurance_binding TYPE option<record<entity>>;
DEFINE FIELD task ON assurance_binding TYPE option<record<task>>;
DEFINE FIELD workflow_run ON assurance_binding TYPE option<record<workflow_run>>;
DEFINE FIELD artifact ON assurance_binding TYPE option<record<artifact>>;
DEFINE FIELD transaction_ref ON assurance_binding TYPE option<string>;

DEFINE FIELD status ON assurance_binding TYPE string DEFAULT "active"
  ASSERT $value IN ["active", "inactive", "expired", "cancelled", "claimed", "settled"];

DEFINE FIELD coverage_amount ON assurance_binding TYPE option<number>;
DEFINE FIELD currency ON assurance_binding TYPE string DEFAULT "USD";
DEFINE FIELD effective_from ON assurance_binding TYPE datetime DEFAULT time::now();
DEFINE FIELD effective_to ON assurance_binding TYPE option<datetime>;
DEFINE FIELD created_at ON assurance_binding TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON assurance_binding TYPE datetime VALUE time::now();
DEFINE FIELD metadata ON assurance_binding TYPE option<object>;

DEFINE INDEX assurance_binding_product_idx ON assurance_binding FIELDS assurance_product;
DEFINE INDEX assurance_binding_subject_idx ON assurance_binding FIELDS subject;
DEFINE INDEX assurance_binding_resource_idx ON assurance_binding FIELDS resource;
DEFINE INDEX assurance_binding_status_idx ON assurance_binding FIELDS status;

-- ------------------------------------------------------------
-- Claim / Dispute / Refund Request
-- ------------------------------------------------------------

DEFINE TABLE assurance_claim SCHEMAFULL;

DEFINE FIELD entity ON assurance_claim TYPE record<entity>;
DEFINE FIELD assurance_binding ON assurance_claim TYPE option<record<assurance_binding>>;
DEFINE FIELD claimant ON assurance_claim TYPE record<identity>;
DEFINE FIELD respondent ON assurance_claim TYPE option<record<identity>>;
DEFINE FIELD resource ON assurance_claim TYPE option<record<entity>>;
DEFINE FIELD task ON assurance_claim TYPE option<record<task>>;
DEFINE FIELD decision ON assurance_claim TYPE option<record<decision>>;
DEFINE FIELD evaluation ON assurance_claim TYPE option<record<evaluation>>;
DEFINE FIELD artifact ON assurance_claim TYPE option<record<artifact>>;

DEFINE FIELD claim_type ON assurance_claim TYPE string
  ASSERT $value IN [
    "insurance_claim",
    "assurance_claim",
    "refund_request",
    "warranty_claim",
    "guarantee_claim",
    "service_credit_claim",
    "dispute",
    "chargeback",
    "liability_claim",
    "compensation_request",
    "sla_breach_claim",
    "quality_failure_claim",
    "delivery_failure_claim",
    "compliance_failure_claim"
  ];

DEFINE FIELD status ON assurance_claim TYPE string DEFAULT "submitted"
  ASSERT $value IN [
    "draft",
    "submitted",
    "under_review",
    "needs_evidence",
    "accepted",
    "rejected",
    "partially_accepted",
    "escalated",
    "settled",
    "paid",
    "closed",
    "cancelled"
  ];

DEFINE FIELD title ON assurance_claim TYPE string;
DEFINE FIELD description ON assurance_claim TYPE option<string>;
DEFINE FIELD requested_amount ON assurance_claim TYPE option<number>;
DEFINE FIELD approved_amount ON assurance_claim TYPE option<number>;
DEFINE FIELD currency ON assurance_claim TYPE string DEFAULT "USD";
DEFINE FIELD reason_code ON assurance_claim TYPE option<string>;
DEFINE FIELD evidence ON assurance_claim TYPE option<object>;
DEFINE FIELD policy_evaluations ON assurance_claim TYPE array<record<policy_evaluation>> DEFAULT [];
DEFINE FIELD evaluations ON assurance_claim TYPE array<record<evaluation>> DEFAULT [];
DEFINE FIELD resolution ON assurance_claim TYPE option<object>;
DEFINE FIELD settlement_ref ON assurance_claim TYPE option<string>;
DEFINE FIELD due_at ON assurance_claim TYPE option<datetime>;
DEFINE FIELD decided_at ON assurance_claim TYPE option<datetime>;
DEFINE FIELD created_at ON assurance_claim TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON assurance_claim TYPE datetime VALUE time::now();
DEFINE FIELD metadata ON assurance_claim TYPE option<object>;

DEFINE INDEX assurance_claim_entity_idx ON assurance_claim FIELDS entity UNIQUE;
DEFINE INDEX assurance_claim_binding_idx ON assurance_claim FIELDS assurance_binding;
DEFINE INDEX assurance_claim_claimant_idx ON assurance_claim FIELDS claimant;
DEFINE INDEX assurance_claim_type_idx ON assurance_claim FIELDS claim_type;
DEFINE INDEX assurance_claim_status_idx ON assurance_claim FIELDS status;

-- ------------------------------------------------------------
-- Claim Event
-- ------------------------------------------------------------

DEFINE TABLE assurance_claim_event SCHEMAFULL;

DEFINE FIELD claim ON assurance_claim_event TYPE record<assurance_claim>;
DEFINE FIELD event_type ON assurance_claim_event TYPE string
  ASSERT $value IN [
    "created",
    "submitted",
    "review_started",
    "evidence_requested",
    "evidence_added",
    "accepted",
    "rejected",
    "partially_accepted",
    "escalated",
    "settled",
    "paid",
    "closed",
    "cancelled"
  ];

DEFINE FIELD actor ON assurance_claim_event TYPE option<record<identity>>;
DEFINE FIELD from_status ON assurance_claim_event TYPE option<string>;
DEFINE FIELD to_status ON assurance_claim_event TYPE option<string>;
DEFINE FIELD reason ON assurance_claim_event TYPE option<string>;
DEFINE FIELD payload ON assurance_claim_event TYPE object DEFAULT {};
DEFINE FIELD created_at ON assurance_claim_event TYPE datetime DEFAULT time::now();
DEFINE FIELD metadata ON assurance_claim_event TYPE option<object>;

DEFINE INDEX assurance_claim_event_claim_idx ON assurance_claim_event FIELDS claim;
DEFINE INDEX assurance_claim_event_type_idx ON assurance_claim_event FIELDS event_type;

-- ------------------------------------------------------------
-- Functions
-- ------------------------------------------------------------

DEFINE FUNCTION fn::bind_assurance(
  $assurance_product: record<assurance_product>,
  $subject: option<record<identity>>,
  $resource: option<record<entity>>,
  $coverage_amount: option<number>,
  $currency: string,
  $transaction_ref: option<string>
) {
  RETURN CREATE assurance_binding SET
    assurance_product = $assurance_product,
    subject = $subject,
    resource = $resource,
    coverage_amount = $coverage_amount,
    currency = $currency,
    transaction_ref = $transaction_ref,
    status = "active";
};

DEFINE FUNCTION fn::submit_assurance_claim(
  $entity: record<entity>,
  $assurance_binding: option<record<assurance_binding>>,
  $claimant: record<identity>,
  $claim_type: string,
  $title: string,
  $description: option<string>,
  $requested_amount: option<number>,
  $currency: string,
  $evidence: option<object>
) {
  LET $created = CREATE assurance_claim SET
    entity = $entity,
    assurance_binding = $assurance_binding,
    claimant = $claimant,
    claim_type = $claim_type,
    title = $title,
    description = $description,
    requested_amount = $requested_amount,
    currency = $currency,
    evidence = $evidence,
    status = "submitted";

  CREATE assurance_claim_event SET
    claim = $created.id,
    event_type = "submitted",
    actor = $claimant,
    to_status = "submitted",
    payload = { claim_type: $claim_type, requested_amount: $requested_amount, currency: $currency };

  RETURN $created;
};

DEFINE FUNCTION fn::accept_assurance_claim(
  $claim: record<assurance_claim>,
  $actor: option<record<identity>>,
  $approved_amount: option<number>,
  $resolution: object,
  $reason: option<string>
) {
  LET $before = SELECT * FROM ONLY $claim;

  LET $updated = UPDATE $claim SET
    status = "accepted",
    approved_amount = $approved_amount,
    resolution = $resolution,
    decided_at = time::now();

  CREATE assurance_claim_event SET
    claim = $claim,
    event_type = "accepted",
    actor = $actor,
    from_status = $before.status,
    to_status = "accepted",
    reason = $reason,
    payload = { approved_amount: $approved_amount, resolution: $resolution };

  RETURN $updated;
};

DEFINE FUNCTION fn::reject_assurance_claim(
  $claim: record<assurance_claim>,
  $actor: option<record<identity>>,
  $resolution: object,
  $reason: string
) {
  LET $before = SELECT * FROM ONLY $claim;

  LET $updated = UPDATE $claim SET
    status = "rejected",
    resolution = $resolution,
    decided_at = time::now();

  CREATE assurance_claim_event SET
    claim = $claim,
    event_type = "rejected",
    actor = $actor,
    from_status = $before.status,
    to_status = "rejected",
    reason = $reason,
    payload = { resolution: $resolution };

  RETURN $updated;
};

DEFINE FUNCTION fn::settle_assurance_claim(
  $claim: record<assurance_claim>,
  $actor: option<record<identity>>,
  $settlement_ref: string,
  $reason: option<string>
) {
  LET $before = SELECT * FROM ONLY $claim;

  LET $updated = UPDATE $claim SET
    status = "settled",
    settlement_ref = $settlement_ref;

  CREATE assurance_claim_event SET
    claim = $claim,
    event_type = "settled",
    actor = $actor,
    from_status = $before.status,
    to_status = "settled",
    reason = $reason,
    payload = { settlement_ref: $settlement_ref };

  RETURN $updated;
};

DEFINE FUNCTION fn::assurance_is_active($binding: record<assurance_binding>) {
  LET $b = SELECT * FROM ONLY $binding;
  RETURN $b.status = "active"
    AND ($b.effective_to = NONE OR $b.effective_to > time::now());
};
