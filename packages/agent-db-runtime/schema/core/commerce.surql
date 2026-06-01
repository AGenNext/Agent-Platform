-- ============================================================
-- AGenNext Agent DB Runtime
-- Core Commerce / Economic Exchange Schema
-- ============================================================

-- Purpose:
-- Commerce models economic exchange: quotes, offers, orders, contracts,
-- agreements, invoices, payments, settlements, usage, pricing, charges,
-- credits, debits, escrow, subscriptions, commission, and revenue share.
-- This supports Agent-Commerce, Agent-Pay, marketplace flows, AP2/UCP-like
-- payment flows, assurance/refund flows, and usage-based agent work.

DEFINE TABLE commerce_account SCHEMAFULL;

DEFINE FIELD entity ON commerce_account TYPE record<entity>;
DEFINE FIELD owner ON commerce_account TYPE record<identity>;
DEFINE FIELD account_type ON commerce_account TYPE string
  ASSERT $value IN [
    "customer",
    "merchant",
    "provider",
    "agent_provider",
    "marketplace",
    "escrow",
    "platform",
    "settlement",
    "tax",
    "commission",
    "revenue_share"
  ];

DEFINE FIELD status ON commerce_account TYPE string DEFAULT "active"
  ASSERT $value IN ["active", "inactive", "suspended", "closed", "archived"];

DEFINE FIELD currency ON commerce_account TYPE string DEFAULT "USD";
DEFINE FIELD balance_ref ON commerce_account TYPE option<string>;
DEFINE FIELD provider_ref ON commerce_account TYPE option<string>;
DEFINE FIELD metadata ON commerce_account TYPE option<object>;
DEFINE FIELD created_at ON commerce_account TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON commerce_account TYPE datetime VALUE time::now();

DEFINE INDEX commerce_account_entity_idx ON commerce_account FIELDS entity UNIQUE;
DEFINE INDEX commerce_account_owner_idx ON commerce_account FIELDS owner;
DEFINE INDEX commerce_account_type_idx ON commerce_account FIELDS account_type;
DEFINE INDEX commerce_account_status_idx ON commerce_account FIELDS status;

-- ------------------------------------------------------------
-- Commercial Document
-- ------------------------------------------------------------

DEFINE TABLE commercial_document SCHEMAFULL;

DEFINE FIELD entity ON commercial_document TYPE record<entity>;
DEFINE FIELD issuer ON commercial_document TYPE option<record<identity>>;
DEFINE FIELD recipient ON commercial_document TYPE option<record<identity>>;
DEFINE FIELD related_task ON commercial_document TYPE option<record<task>>;
DEFINE FIELD related_workflow_run ON commercial_document TYPE option<record<workflow_run>>;
DEFINE FIELD artifact ON commercial_document TYPE option<record<artifact>>;

DEFINE FIELD document_type ON commercial_document TYPE string
  ASSERT $value IN [
    "quote",
    "offer",
    "counter_offer",
    "order",
    "contract",
    "agreement",
    "invoice",
    "receipt",
    "credit_note",
    "debit_note",
    "refund_note",
    "settlement_statement",
    "usage_statement",
    "subscription_agreement",
    "purchase_order",
    "service_order"
  ];

DEFINE FIELD status ON commercial_document TYPE string DEFAULT "draft"
  ASSERT $value IN [
    "draft",
    "issued",
    "sent",
    "accepted",
    "rejected",
    "expired",
    "cancelled",
    "fulfilled",
    "paid",
    "partially_paid",
    "settled",
    "archived"
  ];

DEFINE FIELD title ON commercial_document TYPE string;
DEFINE FIELD line_items ON commercial_document TYPE array<object> DEFAULT [];
DEFINE FIELD subtotal_amount ON commercial_document TYPE number DEFAULT 0;
DEFINE FIELD tax_amount ON commercial_document TYPE number DEFAULT 0;
DEFINE FIELD discount_amount ON commercial_document TYPE number DEFAULT 0;
DEFINE FIELD total_amount ON commercial_document TYPE number DEFAULT 0;
DEFINE FIELD currency ON commercial_document TYPE string DEFAULT "USD";
DEFINE FIELD terms ON commercial_document TYPE option<object>;
DEFINE FIELD assurance_bindings ON commercial_document TYPE array<record<assurance_binding>> DEFAULT [];
DEFINE FIELD due_at ON commercial_document TYPE option<datetime>;
DEFINE FIELD issued_at ON commercial_document TYPE option<datetime>;
DEFINE FIELD accepted_at ON commercial_document TYPE option<datetime>;
DEFINE FIELD paid_at ON commercial_document TYPE option<datetime>;
DEFINE FIELD created_at ON commercial_document TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON commercial_document TYPE datetime VALUE time::now();
DEFINE FIELD metadata ON commercial_document TYPE option<object>;

DEFINE INDEX commercial_document_entity_idx ON commercial_document FIELDS entity UNIQUE;
DEFINE INDEX commercial_document_type_idx ON commercial_document FIELDS document_type;
DEFINE INDEX commercial_document_status_idx ON commercial_document FIELDS status;
DEFINE INDEX commercial_document_issuer_idx ON commercial_document FIELDS issuer;
DEFINE INDEX commercial_document_recipient_idx ON commercial_document FIELDS recipient;

-- ------------------------------------------------------------
-- Usage Record
-- ------------------------------------------------------------

DEFINE TABLE usage_record SCHEMAFULL;

DEFINE FIELD entity ON usage_record TYPE record<entity>;
DEFINE FIELD subject ON usage_record TYPE option<record<identity>>;
DEFINE FIELD resource ON usage_record TYPE option<record<entity>>;
DEFINE FIELD task ON usage_record TYPE option<record<task>>;
DEFINE FIELD workflow_run ON usage_record TYPE option<record<workflow_run>>;
DEFINE FIELD action_invocation ON usage_record TYPE option<record<action_invocation>>;

DEFINE FIELD usage_type ON usage_record TYPE string
  ASSERT $value IN [
    "agent_execution",
    "tool_call",
    "model_call",
    "workflow_run",
    "storage",
    "api_call",
    "token_usage",
    "compute_time",
    "human_review",
    "artifact_generation",
    "knowledge_query",
    "memory_access",
    "protocol_message"
  ];

DEFINE FIELD quantity ON usage_record TYPE number DEFAULT 1;
DEFINE FIELD unit ON usage_record TYPE string DEFAULT "unit";
DEFINE FIELD unit_price ON usage_record TYPE option<number>;
DEFINE FIELD amount ON usage_record TYPE option<number>;
DEFINE FIELD currency ON usage_record TYPE string DEFAULT "USD";
DEFINE FIELD occurred_at ON usage_record TYPE datetime DEFAULT time::now();
DEFINE FIELD billing_ref ON usage_record TYPE option<string>;
DEFINE FIELD metadata ON usage_record TYPE option<object>;

DEFINE INDEX usage_record_entity_idx ON usage_record FIELDS entity UNIQUE;
DEFINE INDEX usage_record_subject_idx ON usage_record FIELDS subject;
DEFINE INDEX usage_record_resource_idx ON usage_record FIELDS resource;
DEFINE INDEX usage_record_type_idx ON usage_record FIELDS usage_type;

-- ------------------------------------------------------------
-- Payment / Settlement Transaction
-- ------------------------------------------------------------

DEFINE TABLE commerce_transaction SCHEMAFULL;

DEFINE FIELD entity ON commerce_transaction TYPE record<entity>;
DEFINE FIELD from_account ON commerce_transaction TYPE option<record<commerce_account>>;
DEFINE FIELD to_account ON commerce_transaction TYPE option<record<commerce_account>>;
DEFINE FIELD commercial_document ON commerce_transaction TYPE option<record<commercial_document>>;
DEFINE FIELD usage_records ON commerce_transaction TYPE array<record<usage_record>> DEFAULT [];
DEFINE FIELD assurance_claim ON commerce_transaction TYPE option<record<assurance_claim>>;

DEFINE FIELD transaction_type ON commerce_transaction TYPE string
  ASSERT $value IN [
    "authorization",
    "capture",
    "payment",
    "refund",
    "chargeback",
    "credit",
    "debit",
    "settlement",
    "escrow_hold",
    "escrow_release",
    "commission",
    "revenue_share",
    "tax",
    "subscription_charge",
    "usage_charge",
    "service_credit",
    "compensation"
  ];

DEFINE FIELD status ON commerce_transaction TYPE string DEFAULT "created"
  ASSERT $value IN [
    "created",
    "authorized",
    "pending",
    "processing",
    "succeeded",
    "failed",
    "cancelled",
    "reversed",
    "refunded",
    "settled",
    "disputed"
  ];

DEFINE FIELD amount ON commerce_transaction TYPE number;
DEFINE FIELD currency ON commerce_transaction TYPE string DEFAULT "USD";
DEFINE FIELD provider ON commerce_transaction TYPE option<string>;
DEFINE FIELD provider_transaction_ref ON commerce_transaction TYPE option<string>;
DEFINE FIELD idempotency_key ON commerce_transaction TYPE option<string>;
DEFINE FIELD evidence ON commerce_transaction TYPE option<object>;
DEFINE FIELD error ON commerce_transaction TYPE option<object>;
DEFINE FIELD created_at ON commerce_transaction TYPE datetime DEFAULT time::now();
DEFINE FIELD processed_at ON commerce_transaction TYPE option<datetime>;
DEFINE FIELD settled_at ON commerce_transaction TYPE option<datetime>;
DEFINE FIELD metadata ON commerce_transaction TYPE option<object>;

DEFINE INDEX commerce_transaction_entity_idx ON commerce_transaction FIELDS entity UNIQUE;
DEFINE INDEX commerce_transaction_type_idx ON commerce_transaction FIELDS transaction_type;
DEFINE INDEX commerce_transaction_status_idx ON commerce_transaction FIELDS status;
DEFINE INDEX commerce_transaction_from_idx ON commerce_transaction FIELDS from_account;
DEFINE INDEX commerce_transaction_to_idx ON commerce_transaction FIELDS to_account;
DEFINE INDEX commerce_transaction_doc_idx ON commerce_transaction FIELDS commercial_document;
DEFINE INDEX commerce_transaction_idempotency_idx ON commerce_transaction FIELDS idempotency_key;

-- ------------------------------------------------------------
-- Subscription
-- ------------------------------------------------------------

DEFINE TABLE subscription SCHEMAFULL;

DEFINE FIELD entity ON subscription TYPE record<entity>;
DEFINE FIELD customer ON subscription TYPE record<identity>;
DEFINE FIELD provider ON subscription TYPE option<record<identity>>;
DEFINE FIELD commercial_document ON subscription TYPE option<record<commercial_document>>;
DEFINE FIELD status ON subscription TYPE string DEFAULT "active"
  ASSERT $value IN ["trialing", "active", "past_due", "paused", "cancelled", "expired", "archived"];

DEFINE FIELD plan_ref ON subscription TYPE option<string>;
DEFINE FIELD pricing ON subscription TYPE object DEFAULT {};
DEFINE FIELD billing_period ON subscription TYPE string DEFAULT "monthly" ASSERT $value IN ["daily", "weekly", "monthly", "quarterly", "yearly", "usage_based", "custom"];
DEFINE FIELD current_period_start ON subscription TYPE datetime DEFAULT time::now();
DEFINE FIELD current_period_end ON subscription TYPE option<datetime>;
DEFINE FIELD cancelled_at ON subscription TYPE option<datetime>;
DEFINE FIELD created_at ON subscription TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON subscription TYPE datetime VALUE time::now();
DEFINE FIELD metadata ON subscription TYPE option<object>;

DEFINE INDEX subscription_entity_idx ON subscription FIELDS entity UNIQUE;
DEFINE INDEX subscription_customer_idx ON subscription FIELDS customer;
DEFINE INDEX subscription_status_idx ON subscription FIELDS status;

-- ------------------------------------------------------------
-- Functions
-- ------------------------------------------------------------

DEFINE FUNCTION fn::record_usage(
  $entity: record<entity>,
  $subject: option<record<identity>>,
  $resource: option<record<entity>>,
  $usage_type: string,
  $quantity: number,
  $unit: string,
  $unit_price: option<number>,
  $currency: string
) {
  RETURN CREATE usage_record SET
    entity = $entity,
    subject = $subject,
    resource = $resource,
    usage_type = $usage_type,
    quantity = $quantity,
    unit = $unit,
    unit_price = $unit_price,
    amount = IF $unit_price = NONE THEN NONE ELSE $quantity * $unit_price END,
    currency = $currency;
};

DEFINE FUNCTION fn::record_commerce_transaction(
  $entity: record<entity>,
  $transaction_type: string,
  $from_account: option<record<commerce_account>>,
  $to_account: option<record<commerce_account>>,
  $amount: number,
  $currency: string,
  $commercial_document: option<record<commercial_document>>,
  $idempotency_key: option<string>
) {
  RETURN CREATE commerce_transaction SET
    entity = $entity,
    transaction_type = $transaction_type,
    from_account = $from_account,
    to_account = $to_account,
    amount = $amount,
    currency = $currency,
    commercial_document = $commercial_document,
    idempotency_key = $idempotency_key,
    status = "created";
};

DEFINE FUNCTION fn::mark_transaction_succeeded(
  $transaction: record<commerce_transaction>,
  $provider_transaction_ref: option<string>,
  $evidence: option<object>
) {
  RETURN UPDATE $transaction SET
    status = "succeeded",
    provider_transaction_ref = $provider_transaction_ref,
    evidence = $evidence,
    processed_at = time::now();
};

DEFINE FUNCTION fn::settle_transaction(
  $transaction: record<commerce_transaction>,
  $evidence: option<object>
) {
  RETURN UPDATE $transaction SET
    status = "settled",
    evidence = $evidence,
    settled_at = time::now();
};
