-- ============================================================
-- AGenNext Agent DB Runtime
-- Core Trust Schema
-- ============================================================

-- Purpose:
-- Trust is a first-class governed object, not only a score.
-- It captures trust claims, attestations, scores, history, verification,
-- reputation, confidence, evidence, issuer, verifier, and scope across
-- identities, agents, credentials, decisions, knowledge, tools, providers,
-- organizations, and relationships.

DEFINE TABLE trust_assessment SCHEMAFULL;

DEFINE FIELD entity ON trust_assessment TYPE record<entity>;
DEFINE FIELD subject ON trust_assessment TYPE record<entity>;
DEFINE FIELD issuer ON trust_assessment TYPE option<record<identity>>;
DEFINE FIELD verifier ON trust_assessment TYPE option<record<identity>>;
DEFINE FIELD evaluation ON trust_assessment TYPE option<record<evaluation>>;
DEFINE FIELD credential ON trust_assessment TYPE option<record<credential>>;

DEFINE FIELD trust_type ON trust_assessment TYPE string
  ASSERT $value IN [
    "identity_trust",
    "credential_trust",
    "agent_trust",
    "human_trust",
    "knowledge_trust",
    "decision_trust",
    "tool_trust",
    "provider_trust",
    "organization_trust",
    "relationship_trust",
    "protocol_trust",
    "runtime_trust",
    "environment_trust",
    "evidence_trust"
  ];

DEFINE FIELD status ON trust_assessment TYPE string DEFAULT "active"
  ASSERT $value IN ["active", "inactive", "revoked", "expired", "disputed", "archived"];

DEFINE FIELD score ON trust_assessment TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD confidence ON trust_assessment TYPE option<number> ASSERT $value = NONE OR ($value >= 0 AND $value <= 1);
DEFINE FIELD reputation ON trust_assessment TYPE option<number> ASSERT $value = NONE OR ($value >= 0 AND $value <= 1);
DEFINE FIELD risk_level ON trust_assessment TYPE string DEFAULT "medium" ASSERT $value IN ["low", "medium", "high", "critical"];

DEFINE FIELD claims ON trust_assessment TYPE array<object> DEFAULT [];
DEFINE FIELD attestations ON trust_assessment TYPE array<object> DEFAULT [];
DEFINE FIELD evidence ON trust_assessment TYPE option<object>;
DEFINE FIELD verification_result ON trust_assessment TYPE option<object>;
DEFINE FIELD reason ON trust_assessment TYPE option<string>;
DEFINE FIELD scope ON trust_assessment TYPE object DEFAULT {};

DEFINE FIELD valid_from ON trust_assessment TYPE datetime DEFAULT time::now();
DEFINE FIELD valid_to ON trust_assessment TYPE option<datetime>;
DEFINE FIELD created_at ON trust_assessment TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON trust_assessment TYPE datetime VALUE time::now();
DEFINE FIELD metadata ON trust_assessment TYPE option<object>;

DEFINE INDEX trust_entity_idx ON trust_assessment FIELDS entity UNIQUE;
DEFINE INDEX trust_subject_idx ON trust_assessment FIELDS subject;
DEFINE INDEX trust_type_idx ON trust_assessment FIELDS trust_type;
DEFINE INDEX trust_status_idx ON trust_assessment FIELDS status;
DEFINE INDEX trust_score_idx ON trust_assessment FIELDS score;
DEFINE INDEX trust_risk_idx ON trust_assessment FIELDS risk_level;

-- ------------------------------------------------------------
-- Trust Event / History
-- ------------------------------------------------------------

DEFINE TABLE trust_event SCHEMAFULL;

DEFINE FIELD trust_assessment ON trust_event TYPE record<trust_assessment>;
DEFINE FIELD event_type ON trust_event TYPE string
  ASSERT $value IN [
    "created",
    "score_changed",
    "claim_added",
    "attestation_added",
    "verification_passed",
    "verification_failed",
    "disputed",
    "revoked",
    "expired",
    "reviewed",
    "archived"
  ];

DEFINE FIELD actor ON trust_event TYPE option<record<identity>>;
DEFINE FIELD previous_score ON trust_event TYPE option<number>;
DEFINE FIELD new_score ON trust_event TYPE option<number>;
DEFINE FIELD reason ON trust_event TYPE option<string>;
DEFINE FIELD evidence ON trust_event TYPE option<object>;
DEFINE FIELD created_at ON trust_event TYPE datetime DEFAULT time::now();
DEFINE FIELD metadata ON trust_event TYPE option<object>;

DEFINE INDEX trust_event_assessment_idx ON trust_event FIELDS trust_assessment;
DEFINE INDEX trust_event_type_idx ON trust_event FIELDS event_type;

-- ------------------------------------------------------------
-- Functions
-- ------------------------------------------------------------

DEFINE FUNCTION fn::record_trust_assessment(
  $entity: record<entity>,
  $subject: record<entity>,
  $trust_type: string,
  $score: number,
  $confidence: option<number>,
  $issuer: option<record<identity>>,
  $verifier: option<record<identity>>,
  $reason: option<string>,
  $evidence: option<object>
) {
  LET $created = CREATE trust_assessment SET
    entity = $entity,
    subject = $subject,
    trust_type = $trust_type,
    score = $score,
    confidence = $confidence,
    issuer = $issuer,
    verifier = $verifier,
    reason = $reason,
    evidence = $evidence,
    risk_level = IF $score >= 0.80 THEN "low" ELSE IF $score >= 0.60 THEN "medium" ELSE IF $score >= 0.40 THEN "high" ELSE "critical" END;

  CREATE trust_event SET
    trust_assessment = $created.id,
    event_type = "created",
    actor = $issuer,
    new_score = $score,
    reason = $reason,
    evidence = $evidence;

  RETURN $created;
};

DEFINE FUNCTION fn::update_trust_score(
  $trust_assessment: record<trust_assessment>,
  $score: number,
  $actor: option<record<identity>>,
  $reason: option<string>,
  $evidence: option<object>
) {
  LET $before = SELECT * FROM ONLY $trust_assessment;

  LET $updated = UPDATE $trust_assessment SET
    score = $score,
    risk_level = IF $score >= 0.80 THEN "low" ELSE IF $score >= 0.60 THEN "medium" ELSE IF $score >= 0.40 THEN "high" ELSE "critical" END;

  CREATE trust_event SET
    trust_assessment = $trust_assessment,
    event_type = "score_changed",
    actor = $actor,
    previous_score = $before.score,
    new_score = $score,
    reason = $reason,
    evidence = $evidence;

  RETURN $updated;
};

DEFINE FUNCTION fn::revoke_trust(
  $trust_assessment: record<trust_assessment>,
  $actor: option<record<identity>>,
  $reason: string,
  $evidence: option<object>
) {
  LET $updated = UPDATE $trust_assessment SET
    status = "revoked",
    valid_to = time::now();

  CREATE trust_event SET
    trust_assessment = $trust_assessment,
    event_type = "revoked",
    actor = $actor,
    reason = $reason,
    evidence = $evidence;

  RETURN $updated;
};

DEFINE FUNCTION fn::trust_is_usable($trust_assessment: record<trust_assessment>) {
  LET $t = SELECT * FROM ONLY $trust_assessment;
  RETURN $t.status = "active"
    AND $t.score >= 0.70
    AND ($t.valid_to = NONE OR $t.valid_to > time::now());
};

DEFINE FUNCTION fn::trust_requires_review($trust_assessment: record<trust_assessment>) {
  LET $t = SELECT * FROM ONLY $trust_assessment;
  RETURN $t.status IN ["disputed", "revoked", "expired"]
    OR $t.score < 0.70
    OR ($t.confidence != NONE AND $t.confidence < 0.70)
    OR $t.risk_level IN ["high", "critical"];
};
