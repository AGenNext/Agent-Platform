DEFINE TABLE schema_change_proposals SCHEMAFULL;
DEFINE FIELD tenant_id ON schema_change_proposals TYPE option<record<tenants>>;
DEFINE FIELD proposer_id ON schema_change_proposals TYPE string;
DEFINE FIELD proposal_kind ON schema_change_proposals TYPE string;
DEFINE FIELD target_term ON schema_change_proposals TYPE string;
DEFINE FIELD target_artifact ON schema_change_proposals TYPE string;
DEFINE FIELD justification ON schema_change_proposals TYPE string;
DEFINE FIELD examples ON schema_change_proposals TYPE array<object> DEFAULT [];
DEFINE FIELD impacted_tenants ON schema_change_proposals TYPE array<record<tenants>> DEFAULT [];
DEFINE FIELD risk_level ON schema_change_proposals TYPE string DEFAULT 'medium';
DEFINE FIELD backward_compatibility ON schema_change_proposals TYPE string DEFAULT 'compatible';
DEFINE FIELD migration_plan ON schema_change_proposals TYPE string;
DEFINE FIELD status ON schema_change_proposals TYPE string DEFAULT 'draft';
DEFINE FIELD evidence_ids ON schema_change_proposals TYPE array<record<trust_evidence>> DEFAULT [];
DEFINE FIELD observation_run_id ON schema_change_proposals TYPE option<record<observation_runs>>;
DEFINE FIELD jsonld_context ON schema_change_proposals TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON schema_change_proposals TYPE array<string> DEFAULT ['schema:Action', 'agx:SchemaChangeProposal'];
DEFINE FIELD created_at ON schema_change_proposals TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON schema_change_proposals TYPE datetime DEFAULT time::now();

DEFINE TABLE schema_change_votes SCHEMAFULL;
DEFINE FIELD proposal_id ON schema_change_votes TYPE record<schema_change_proposals>;
DEFINE FIELD voter_id ON schema_change_votes TYPE string;
DEFINE FIELD steward_role ON schema_change_votes TYPE string;
DEFINE FIELD decision ON schema_change_votes TYPE string;
DEFINE FIELD confidence ON schema_change_votes TYPE number ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD rationale ON schema_change_votes TYPE string;
DEFINE FIELD risks ON schema_change_votes TYPE array<string> DEFAULT [];
DEFINE FIELD amendments ON schema_change_votes TYPE array<string> DEFAULT [];
DEFINE FIELD jsonld_context ON schema_change_votes TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON schema_change_votes TYPE array<string> DEFAULT ['schema:VoteAction', 'agx:SchemaChangeVote'];
DEFINE FIELD created_at ON schema_change_votes TYPE datetime DEFAULT time::now();
DEFINE INDEX schema_change_votes_unique ON schema_change_votes FIELDS proposal_id, voter_id, steward_role UNIQUE;

DEFINE TABLE schema_change_reviews SCHEMAFULL;
DEFINE FIELD proposal_id ON schema_change_reviews TYPE record<schema_change_proposals>;
DEFINE FIELD reviewer_id ON schema_change_reviews TYPE string;
DEFINE FIELD review_kind ON schema_change_reviews TYPE string;
DEFINE FIELD passed ON schema_change_reviews TYPE bool;
DEFINE FIELD findings ON schema_change_reviews TYPE array<string> DEFAULT [];
DEFINE FIELD jsonld_context ON schema_change_reviews TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON schema_change_reviews TYPE array<string> DEFAULT ['schema:ReviewAction', 'agx:SchemaChangeReview'];
DEFINE FIELD created_at ON schema_change_reviews TYPE datetime DEFAULT time::now();

DEFINE TABLE schema_change_migrations SCHEMAFULL;
DEFINE FIELD proposal_id ON schema_change_migrations TYPE record<schema_change_proposals>;
DEFINE FIELD migration_kind ON schema_change_migrations TYPE string;
DEFINE FIELD migration_content ON schema_change_migrations TYPE string;
DEFINE FIELD checksum ON schema_change_migrations TYPE option<string>;
DEFINE FIELD status ON schema_change_migrations TYPE string DEFAULT 'proposed';
DEFINE FIELD jsonld_context ON schema_change_migrations TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON schema_change_migrations TYPE array<string> DEFAULT ['schema:Action', 'agx:SchemaMigration'];
DEFINE FIELD created_at ON schema_change_migrations TYPE datetime DEFAULT time::now();

DEFINE FUNCTION fn::create_schema_change_proposal($tenant_id, $proposer_id, $proposal_kind, $target_term, $target_artifact, $justification, $risk_level, $backward_compatibility, $migration_plan) {
  RETURN CREATE schema_change_proposals CONTENT {
    tenant_id: $tenant_id,
    proposer_id: $proposer_id,
    proposal_kind: $proposal_kind,
    target_term: $target_term,
    target_artifact: $target_artifact,
    justification: $justification,
    risk_level: $risk_level,
    backward_compatibility: $backward_compatibility,
    migration_plan: $migration_plan,
    status: 'draft',
    created_at: time::now(),
    updated_at: time::now()
  };
};

DEFINE FUNCTION fn::submit_schema_change_proposal($proposal_id) {
  LET $proposal = SELECT * FROM $proposal_id;
  IF count($proposal) = 0 THEN { THROW 'proposal_not_found'; };
  IF $proposal[0].status != 'draft' THEN { THROW 'proposal_not_draft'; };
  IF string::len($proposal[0].justification) < 20 THEN { THROW 'proposal_justification_too_short'; };
  IF string::len($proposal[0].migration_plan) < 20 THEN { THROW 'proposal_migration_plan_required'; };

  UPDATE $proposal_id SET status = 'voting', updated_at = time::now();
  RETURN SELECT * FROM $proposal_id;
};

DEFINE FUNCTION fn::vote_schema_change($proposal_id, $voter_id, $steward_role, $decision, $confidence, $rationale, $risks, $amendments) {
  LET $proposal = SELECT * FROM $proposal_id;
  IF count($proposal) = 0 THEN { THROW 'proposal_not_found'; };
  IF $proposal[0].status != 'voting' THEN { THROW 'proposal_not_in_voting'; };
  IF $proposal[0].proposer_id = $voter_id THEN { THROW 'proposer_vote_not_counted'; };
  IF $decision NOT IN ['approve', 'reject', 'abstain'] THEN { THROW 'invalid_vote_decision'; };

  RETURN UPSERT type::thing('schema_change_votes', rand::uuid()) CONTENT {
    proposal_id: $proposal_id,
    voter_id: $voter_id,
    steward_role: $steward_role,
    decision: $decision,
    confidence: $confidence,
    rationale: $rationale,
    risks: $risks,
    amendments: $amendments,
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::required_quorum_for_risk($risk_level) {
  RETURN IF $risk_level = 'low' THEN {
    min_approvals: 2,
    required_roles: ['ontology']
  } ELSE IF $risk_level = 'medium' THEN {
    min_approvals: 3,
    required_roles: ['ontology', 'migration']
  } ELSE IF $risk_level = 'high' THEN {
    min_approvals: 4,
    required_roles: ['ontology', 'security', 'migration', 'human_maintainer']
  } ELSE {
    min_approvals: 5,
    required_roles: ['ontology', 'security', 'migration', 'human_maintainer']
  } END;
};

DEFINE FUNCTION fn::evaluate_schema_change_quorum($proposal_id) {
  LET $proposal = SELECT * FROM $proposal_id;
  IF count($proposal) = 0 THEN { THROW 'proposal_not_found'; };

  LET $votes = SELECT * FROM schema_change_votes WHERE proposal_id = $proposal_id;
  LET $approvals = SELECT * FROM $votes WHERE decision = 'approve';
  LET $rejects = SELECT * FROM $votes WHERE decision = 'reject';
  LET $quorum = fn::required_quorum_for_risk($proposal[0].risk_level);
  LET $roles = array::distinct($approvals[*].steward_role);
  LET $missing_roles = array::filter($quorum.required_roles, |$role| !$role INSIDE $roles);
  LET $approved = count($approvals) >= $quorum.min_approvals AND count($rejects) = 0 AND count($missing_roles) = 0;

  RETURN {
    approved: $approved,
    approvals: count($approvals),
    rejects: count($rejects),
    required_approvals: $quorum.min_approvals,
    required_roles: $quorum.required_roles,
    present_roles: $roles,
    missing_roles: $missing_roles
  };
};

DEFINE FUNCTION fn::finalize_schema_change_proposal($proposal_id) {
  LET $quorum = fn::evaluate_schema_change_quorum($proposal_id);
  LET $proposal = SELECT * FROM $proposal_id;
  IF count($proposal) = 0 THEN { THROW 'proposal_not_found'; };

  IF $quorum.approved THEN {
    UPDATE $proposal_id SET status = 'approved', updated_at = time::now();
  } ELSE {
    UPDATE $proposal_id SET status = 'rejected', updated_at = time::now();
  };

  CREATE audit_logs CONTENT {
    tenant_id: $proposal[0].tenant_id,
    actor_id: 'system:governance',
    action: 'finalize_schema_change_proposal',
    resource_type: 'schema_change_proposals',
    resource_id: string::concat($proposal_id),
    metadata: $quorum,
    semantic_id: rand::uuid(),
    jsonld_context: { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' },
    jsonld_type: ['schema:Action', 'agx:AuditEvent'],
    time: { observed_at: time::now() },
    created_at: time::now()
  };

  RETURN SELECT * FROM $proposal_id;
};

DEFINE FUNCTION fn::attach_schema_migration($proposal_id, $migration_kind, $migration_content, $checksum) {
  LET $proposal = SELECT * FROM $proposal_id;
  IF count($proposal) = 0 THEN { THROW 'proposal_not_found'; };
  IF $proposal[0].status != 'approved' THEN { THROW 'proposal_not_approved'; };

  RETURN CREATE schema_change_migrations CONTENT {
    proposal_id: $proposal_id,
    migration_kind: $migration_kind,
    migration_content: $migration_content,
    checksum: $checksum,
    status: 'proposed',
    created_at: time::now()
  };
};
