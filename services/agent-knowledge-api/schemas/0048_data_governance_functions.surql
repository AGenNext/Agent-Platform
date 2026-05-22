DEFINE TABLE data_governance_policies SCHEMAFULL;
DEFINE FIELD tenant_id ON data_governance_policies TYPE option<record<tenants>>;
DEFINE FIELD key ON data_governance_policies TYPE string;
DEFINE FIELD name ON data_governance_policies TYPE string;
DEFINE FIELD policy_kind ON data_governance_policies TYPE string;
DEFINE FIELD scope_kind ON data_governance_policies TYPE string DEFAULT 'tenant';
DEFINE FIELD scope_ref ON data_governance_policies TYPE option<record>;
DEFINE FIELD rules ON data_governance_policies TYPE array<object> DEFAULT [];
DEFINE FIELD enforcement_mode ON data_governance_policies TYPE string DEFAULT 'enforce';
DEFINE FIELD owner_id ON data_governance_policies TYPE string;
DEFINE FIELD enabled ON data_governance_policies TYPE bool DEFAULT true;
DEFINE FIELD created_at ON data_governance_policies TYPE datetime DEFAULT time::now();
DEFINE INDEX data_governance_policies_key_unique ON data_governance_policies FIELDS tenant_id, key UNIQUE;

DEFINE TABLE data_assets SCHEMAFULL;
DEFINE FIELD tenant_id ON data_assets TYPE option<record<tenants>>;
DEFINE FIELD asset_ref ON data_assets TYPE string;
DEFINE FIELD name ON data_assets TYPE string;
DEFINE FIELD asset_kind ON data_assets TYPE string;
DEFINE FIELD source_uri ON data_assets TYPE option<string>;
DEFINE FIELD owning_domain ON data_assets TYPE string;
DEFINE FIELD owner_id ON data_assets TYPE string;
DEFINE FIELD steward_id ON data_assets TYPE option<string>;
DEFINE FIELD classification ON data_assets TYPE string DEFAULT 'internal';
DEFINE FIELD sensitivity ON data_assets TYPE string DEFAULT 'medium';
DEFINE FIELD data_domains ON data_assets TYPE array<string> DEFAULT [];
DEFINE FIELD schema_hash ON data_assets TYPE option<string>;
DEFINE FIELD content_hash ON data_assets TYPE option<string>;
DEFINE FIELD retention_policy_id ON data_assets TYPE option<record<data_retention_policies>>;
DEFINE FIELD quality_profile_id ON data_assets TYPE option<record<data_quality_profiles>>;
DEFINE FIELD status ON data_assets TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON data_assets TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON data_assets TYPE datetime DEFAULT time::now();
DEFINE INDEX data_assets_ref_unique ON data_assets FIELDS tenant_id, asset_ref UNIQUE;

DEFINE TABLE data_asset_fields SCHEMAFULL;
DEFINE FIELD tenant_id ON data_asset_fields TYPE option<record<tenants>>;
DEFINE FIELD data_asset_id ON data_asset_fields TYPE record<data_assets>;
DEFINE FIELD field_path ON data_asset_fields TYPE string;
DEFINE FIELD field_type ON data_asset_fields TYPE string;
DEFINE FIELD classification ON data_asset_fields TYPE string DEFAULT 'internal';
DEFINE FIELD sensitivity ON data_asset_fields TYPE string DEFAULT 'medium';
DEFINE FIELD pii_category ON data_asset_fields TYPE option<string>;
DEFINE FIELD allowed_purposes ON data_asset_fields TYPE array<string> DEFAULT [];
DEFINE FIELD masking_strategy ON data_asset_fields TYPE option<string>;
DEFINE FIELD created_at ON data_asset_fields TYPE datetime DEFAULT time::now();
DEFINE INDEX data_asset_fields_unique ON data_asset_fields FIELDS data_asset_id, field_path UNIQUE;

DEFINE TABLE data_lineage_events SCHEMAFULL;
DEFINE FIELD tenant_id ON data_lineage_events TYPE option<record<tenants>>;
DEFINE FIELD lineage_ref ON data_lineage_events TYPE string;
DEFINE FIELD source_asset_id ON data_lineage_events TYPE option<record<data_assets>>;
DEFINE FIELD target_asset_id ON data_lineage_events TYPE option<record<data_assets>>;
DEFINE FIELD transformation_kind ON data_lineage_events TYPE string;
DEFINE FIELD actor_id ON data_lineage_events TYPE string;
DEFINE FIELD trace_id ON data_lineage_events TYPE option<string>;
DEFINE FIELD input_hashes ON data_lineage_events TYPE array<string> DEFAULT [];
DEFINE FIELD output_hashes ON data_lineage_events TYPE array<string> DEFAULT [];
DEFINE FIELD transformation_metadata ON data_lineage_events TYPE object DEFAULT {};
DEFINE FIELD created_at ON data_lineage_events TYPE datetime DEFAULT time::now();
DEFINE INDEX data_lineage_events_ref_unique ON data_lineage_events FIELDS tenant_id, lineage_ref UNIQUE;

DEFINE TABLE data_quality_profiles SCHEMAFULL;
DEFINE FIELD tenant_id ON data_quality_profiles TYPE option<record<tenants>>;
DEFINE FIELD key ON data_quality_profiles TYPE string;
DEFINE FIELD name ON data_quality_profiles TYPE string;
DEFINE FIELD dimensions ON data_quality_profiles TYPE array<object> DEFAULT [];
DEFINE FIELD min_quality_score ON data_quality_profiles TYPE number DEFAULT 0.8 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD owner_id ON data_quality_profiles TYPE string;
DEFINE FIELD created_at ON data_quality_profiles TYPE datetime DEFAULT time::now();
DEFINE INDEX data_quality_profiles_key_unique ON data_quality_profiles FIELDS tenant_id, key UNIQUE;

DEFINE TABLE data_quality_assessments SCHEMAFULL;
DEFINE FIELD tenant_id ON data_quality_assessments TYPE option<record<tenants>>;
DEFINE FIELD data_asset_id ON data_quality_assessments TYPE record<data_assets>;
DEFINE FIELD assessment_ref ON data_quality_assessments TYPE string;
DEFINE FIELD completeness_score ON data_quality_assessments TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD accuracy_score ON data_quality_assessments TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD consistency_score ON data_quality_assessments TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD freshness_score ON data_quality_assessments TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD validity_score ON data_quality_assessments TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD aggregate_score ON data_quality_assessments TYPE number DEFAULT 0 ASSERT $value >= 0 AND $value <= 1;
DEFINE FIELD findings ON data_quality_assessments TYPE array<object> DEFAULT [];
DEFINE FIELD evidence_refs ON data_quality_assessments TYPE array<record> DEFAULT [];
DEFINE FIELD created_at ON data_quality_assessments TYPE datetime DEFAULT time::now();
DEFINE INDEX data_quality_assessments_ref_unique ON data_quality_assessments FIELDS tenant_id, assessment_ref UNIQUE;

DEFINE TABLE data_retention_policies SCHEMAFULL;
DEFINE FIELD tenant_id ON data_retention_policies TYPE option<record<tenants>>;
DEFINE FIELD key ON data_retention_policies TYPE string;
DEFINE FIELD name ON data_retention_policies TYPE string;
DEFINE FIELD retention_days ON data_retention_policies TYPE int;
DEFINE FIELD deletion_mode ON data_retention_policies TYPE string DEFAULT 'tombstone';
DEFINE FIELD legal_hold_overrides ON data_retention_policies TYPE bool DEFAULT true;
DEFINE FIELD archive_before_delete ON data_retention_policies TYPE bool DEFAULT false;
DEFINE FIELD owner_id ON data_retention_policies TYPE string;
DEFINE FIELD created_at ON data_retention_policies TYPE datetime DEFAULT time::now();
DEFINE INDEX data_retention_policies_key_unique ON data_retention_policies FIELDS tenant_id, key UNIQUE;

DEFINE TABLE legal_holds SCHEMAFULL;
DEFINE FIELD tenant_id ON legal_holds TYPE option<record<tenants>>;
DEFINE FIELD hold_ref ON legal_holds TYPE string;
DEFINE FIELD resource_ref ON legal_holds TYPE record;
DEFINE FIELD resource_type ON legal_holds TYPE string;
DEFINE FIELD reason ON legal_holds TYPE string;
DEFINE FIELD owner_id ON legal_holds TYPE string;
DEFINE FIELD status ON legal_holds TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON legal_holds TYPE datetime DEFAULT time::now();
DEFINE FIELD released_at ON legal_holds TYPE option<datetime>;
DEFINE INDEX legal_holds_ref_unique ON legal_holds FIELDS tenant_id, hold_ref UNIQUE;

DEFINE TABLE data_subject_requests SCHEMAFULL;
DEFINE FIELD tenant_id ON data_subject_requests TYPE option<record<tenants>>;
DEFINE FIELD request_ref ON data_subject_requests TYPE string;
DEFINE FIELD subject_id ON data_subject_requests TYPE string;
DEFINE FIELD request_kind ON data_subject_requests TYPE string;
DEFINE FIELD status ON data_subject_requests TYPE string DEFAULT 'open';
DEFINE FIELD scope ON data_subject_requests TYPE object DEFAULT {};
DEFINE FIELD response_summary ON data_subject_requests TYPE option<string>;
DEFINE FIELD evidence_refs ON data_subject_requests TYPE array<record> DEFAULT [];
DEFINE FIELD owner_id ON data_subject_requests TYPE string;
DEFINE FIELD created_at ON data_subject_requests TYPE datetime DEFAULT time::now();
DEFINE FIELD completed_at ON data_subject_requests TYPE option<datetime>;
DEFINE INDEX data_subject_requests_ref_unique ON data_subject_requests FIELDS tenant_id, request_ref UNIQUE;

DEFINE TABLE data_governance_decisions SCHEMAFULL;
DEFINE FIELD tenant_id ON data_governance_decisions TYPE option<record<tenants>>;
DEFINE FIELD subject_id ON data_governance_decisions TYPE string;
DEFINE FIELD data_asset_id ON data_governance_decisions TYPE option<record<data_assets>>;
DEFINE FIELD resource_ref ON data_governance_decisions TYPE option<record>;
DEFINE FIELD action ON data_governance_decisions TYPE string;
DEFINE FIELD purpose ON data_governance_decisions TYPE string;
DEFINE FIELD allowed ON data_governance_decisions TYPE bool DEFAULT false;
DEFINE FIELD reason ON data_governance_decisions TYPE string;
DEFINE FIELD matched_policy_ids ON data_governance_decisions TYPE array<record<data_governance_policies>> DEFAULT [];
DEFINE FIELD resource_access_decision_id ON data_governance_decisions TYPE option<record<resource_access_decisions>>;
DEFINE FIELD decision_log_id ON data_governance_decisions TYPE option<record<decision_context_logs>>;
DEFINE FIELD created_at ON data_governance_decisions TYPE datetime DEFAULT time::now();

DEFINE FUNCTION fn::create_data_governance_policy($tenant_id, $key, $name, $policy_kind, $scope_kind, $scope_ref, $rules, $enforcement_mode, $owner_id) {
  RETURN CREATE data_governance_policies CONTENT { tenant_id: $tenant_id, key: $key, name: $name, policy_kind: $policy_kind, scope_kind: $scope_kind, scope_ref: $scope_ref, rules: $rules, enforcement_mode: $enforcement_mode, owner_id: $owner_id, enabled: true, created_at: time::now() };
};

DEFINE FUNCTION fn::register_data_asset($tenant_id, $asset_ref, $name, $asset_kind, $source_uri, $owning_domain, $owner_id, $steward_id, $classification, $sensitivity, $data_domains, $schema_hash, $content_hash, $retention_policy_id, $quality_profile_id) {
  LET $asset = CREATE data_assets CONTENT { tenant_id: $tenant_id, asset_ref: $asset_ref, name: $name, asset_kind: $asset_kind, source_uri: $source_uri, owning_domain: $owning_domain, owner_id: $owner_id, steward_id: $steward_id, classification: $classification, sensitivity: $sensitivity, data_domains: $data_domains, schema_hash: $schema_hash, content_hash: $content_hash, retention_policy_id: $retention_policy_id, quality_profile_id: $quality_profile_id, status: 'active', created_at: time::now(), updated_at: time::now() };
  fn::label_resource_security($tenant_id, $asset.id, 'data_assets', $classification, $sensitivity, $owner_id, $data_domains, [], [], $sensitivity IN ['high','critical'], true, true);
  RETURN $asset;
};

DEFINE FUNCTION fn::register_data_asset_field($tenant_id, $data_asset_id, $field_path, $field_type, $classification, $sensitivity, $pii_category, $allowed_purposes, $masking_strategy) {
  LET $asset = SELECT * FROM $data_asset_id;
  IF count($asset) = 0 THEN { THROW 'data_asset_not_found'; };
  RETURN CREATE data_asset_fields CONTENT { tenant_id: $tenant_id, data_asset_id: $data_asset_id, field_path: $field_path, field_type: $field_type, classification: $classification, sensitivity: $sensitivity, pii_category: $pii_category, allowed_purposes: $allowed_purposes, masking_strategy: $masking_strategy, created_at: time::now() };
};

DEFINE FUNCTION fn::record_data_lineage_event($tenant_id, $lineage_ref, $source_asset_id, $target_asset_id, $transformation_kind, $actor_id, $trace_id, $input_hashes, $output_hashes, $transformation_metadata) {
  RETURN CREATE data_lineage_events CONTENT { tenant_id: $tenant_id, lineage_ref: $lineage_ref, source_asset_id: $source_asset_id, target_asset_id: $target_asset_id, transformation_kind: $transformation_kind, actor_id: $actor_id, trace_id: $trace_id, input_hashes: $input_hashes, output_hashes: $output_hashes, transformation_metadata: $transformation_metadata, created_at: time::now() };
};

DEFINE FUNCTION fn::create_data_quality_profile($tenant_id, $key, $name, $dimensions, $min_quality_score, $owner_id) {
  RETURN CREATE data_quality_profiles CONTENT { tenant_id: $tenant_id, key: $key, name: $name, dimensions: $dimensions, min_quality_score: $min_quality_score, owner_id: $owner_id, created_at: time::now() };
};

DEFINE FUNCTION fn::record_data_quality_assessment($tenant_id, $data_asset_id, $assessment_ref, $completeness_score, $accuracy_score, $consistency_score, $freshness_score, $validity_score, $findings, $evidence_refs) {
  LET $asset = SELECT * FROM $data_asset_id;
  IF count($asset) = 0 THEN { THROW 'data_asset_not_found'; };
  LET $aggregate = fn::clamp01(($completeness_score + $accuracy_score + $consistency_score + $freshness_score + $validity_score) / 5);
  LET $assessment = CREATE data_quality_assessments CONTENT { tenant_id: $tenant_id, data_asset_id: $data_asset_id, assessment_ref: $assessment_ref, completeness_score: fn::clamp01($completeness_score), accuracy_score: fn::clamp01($accuracy_score), consistency_score: fn::clamp01($consistency_score), freshness_score: fn::clamp01($freshness_score), validity_score: fn::clamp01($validity_score), aggregate_score: $aggregate, findings: $findings, evidence_refs: $evidence_refs, created_at: time::now() };
  UPDATE $data_asset_id SET quality_profile_id = $asset[0].quality_profile_id, updated_at = time::now();
  RETURN $assessment;
};

DEFINE FUNCTION fn::create_data_retention_policy($tenant_id, $key, $name, $retention_days, $deletion_mode, $legal_hold_overrides, $archive_before_delete, $owner_id) {
  RETURN CREATE data_retention_policies CONTENT { tenant_id: $tenant_id, key: $key, name: $name, retention_days: $retention_days, deletion_mode: $deletion_mode, legal_hold_overrides: $legal_hold_overrides, archive_before_delete: $archive_before_delete, owner_id: $owner_id, created_at: time::now() };
};

DEFINE FUNCTION fn::place_legal_hold($tenant_id, $hold_ref, $resource_ref, $resource_type, $reason, $owner_id) {
  RETURN CREATE legal_holds CONTENT { tenant_id: $tenant_id, hold_ref: $hold_ref, resource_ref: $resource_ref, resource_type: $resource_type, reason: $reason, owner_id: $owner_id, status: 'active', created_at: time::now() };
};

DEFINE FUNCTION fn::release_legal_hold($legal_hold_id, $actor_id) {
  LET $hold = SELECT * FROM $legal_hold_id;
  IF count($hold) = 0 THEN { THROW 'legal_hold_not_found'; };
  UPDATE $legal_hold_id SET status = 'released', released_at = time::now();
  CREATE audit_logs CONTENT { tenant_id: $hold[0].tenant_id, actor_id: $actor_id, action: 'legal_hold_released', resource_type: 'legal_holds', resource_id: string::concat($legal_hold_id), metadata: {}, semantic_id: rand::uuid(), jsonld_context: { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' }, jsonld_type: ['schema:Action', 'agx:AuditEvent'], time: { observed_at: time::now() }, created_at: time::now() };
  RETURN SELECT * FROM $legal_hold_id;
};

DEFINE FUNCTION fn::open_data_subject_request($tenant_id, $request_ref, $subject_id, $request_kind, $scope, $owner_id) {
  RETURN CREATE data_subject_requests CONTENT { tenant_id: $tenant_id, request_ref: $request_ref, subject_id: $subject_id, request_kind: $request_kind, status: 'open', scope: $scope, evidence_refs: [], owner_id: $owner_id, created_at: time::now() };
};

DEFINE FUNCTION fn::complete_data_subject_request($request_id, $response_summary, $evidence_refs, $actor_id) {
  LET $request = SELECT * FROM $request_id;
  IF count($request) = 0 THEN { THROW 'data_subject_request_not_found'; };
  UPDATE $request_id SET status = 'completed', response_summary = $response_summary, evidence_refs = $evidence_refs, completed_at = time::now();
  CREATE audit_logs CONTENT { tenant_id: $request[0].tenant_id, actor_id: $actor_id, action: 'data_subject_request_completed', resource_type: 'data_subject_requests', resource_id: string::concat($request_id), metadata: { request_kind: $request[0].request_kind }, semantic_id: rand::uuid(), jsonld_context: { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' }, jsonld_type: ['schema:Action', 'agx:AuditEvent'], time: { observed_at: time::now() }, created_at: time::now() };
  RETURN SELECT * FROM $request_id;
};

DEFINE FUNCTION fn::evaluate_data_governance_access($tenant_id, $subject_id, $data_asset_id, $resource_ref, $action, $purpose, $actor_id, $resource_access_decision_id) {
  LET $asset = IF $data_asset_id = NONE THEN [] ELSE SELECT * FROM $data_asset_id END;
  LET $policies = SELECT * FROM data_governance_policies WHERE (tenant_id = $tenant_id OR tenant_id = NONE) AND enabled = true;
  LET $fields = IF $data_asset_id = NONE THEN [] ELSE SELECT * FROM data_asset_fields WHERE data_asset_id = $data_asset_id END;
  LET $purpose_blocked_fields = SELECT * FROM $fields WHERE count(allowed_purposes) > 0 AND !$purpose INSIDE allowed_purposes;
  LET $legal_hold = IF $resource_ref = NONE THEN [] ELSE SELECT * FROM legal_holds WHERE tenant_id = $tenant_id AND resource_ref = $resource_ref AND status = 'active' END;
  LET $resource_allowed = IF $resource_access_decision_id = NONE THEN true ELSE (SELECT * FROM $resource_access_decision_id)[0].allowed END;
  LET $blocked_by_purpose = count($purpose_blocked_fields) > 0;
  LET $blocked_by_legal_hold = $action IN ['delete','erase','purge'] AND count($legal_hold) > 0;
  LET $allowed = $resource_allowed AND !$blocked_by_purpose AND !$blocked_by_legal_hold;
  LET $decision_log = fn::log_decision_context($tenant_id, 'data_governance_access_decision', $subject_id, $actor_id, NONE, NONE, { data_asset_id: $data_asset_id, resource_ref: $resource_ref, action: $action, purpose: $purpose }, {}, {}, {}, {}, {}, {}, { policies: $policies[*].id, blocked_fields: $purpose_blocked_fields[*].field_path, legal_hold_count: count($legal_hold), resource_access_decision_id: $resource_access_decision_id }, [{ kind: 'purpose_limitation' }, { kind: 'legal_hold_blocks_delete' }, { kind: 'resource_access_required' }], { resource_allowed: $resource_allowed, blocked_by_purpose: $blocked_by_purpose, blocked_by_legal_hold: $blocked_by_legal_hold }, [{ decision: 'allow' }, { decision: 'deny' }], { decision: IF $allowed THEN 'allow' ELSE 'deny' END }, [], 'data_governance_access_evaluated', {}, array::concat($policies[*].id, $purpose_blocked_fields[*].id, $legal_hold[*].id), NONE, [], false);
  RETURN CREATE data_governance_decisions CONTENT { tenant_id: $tenant_id, subject_id: $subject_id, data_asset_id: $data_asset_id, resource_ref: $resource_ref, action: $action, purpose: $purpose, allowed: $allowed, reason: IF $allowed THEN 'data_governance_access_allowed' ELSE 'data_governance_access_denied' END, matched_policy_ids: $policies[*].id, resource_access_decision_id: $resource_access_decision_id, decision_log_id: $decision_log.id, created_at: time::now() };
};

DEFINE FUNCTION fn::require_data_governance_access($tenant_id, $subject_id, $data_asset_id, $resource_ref, $action, $purpose, $actor_id, $resource_access_decision_id) {
  LET $decision = fn::evaluate_data_governance_access($tenant_id, $subject_id, $data_asset_id, $resource_ref, $action, $purpose, $actor_id, $resource_access_decision_id);
  IF !$decision.allowed THEN { THROW 'data_governance_access_denied'; };
  RETURN true;
};

DEFINE FUNCTION fn::get_data_governance_dashboard($tenant_id) {
  RETURN { assets: count(SELECT * FROM data_assets WHERE tenant_id = $tenant_id), high_sensitivity_assets: count(SELECT * FROM data_assets WHERE tenant_id = $tenant_id AND sensitivity IN ['high','critical']), legal_holds: count(SELECT * FROM legal_holds WHERE tenant_id = $tenant_id AND status = 'active'), data_subject_requests_open: count(SELECT * FROM data_subject_requests WHERE tenant_id = $tenant_id AND status = 'open'), latest_quality: SELECT * FROM data_quality_assessments WHERE tenant_id = $tenant_id ORDER BY created_at DESC LIMIT 10, lineage_recent: SELECT * FROM data_lineage_events WHERE tenant_id = $tenant_id ORDER BY created_at DESC LIMIT 10, governance_decisions_recent: SELECT * FROM data_governance_decisions WHERE tenant_id = $tenant_id ORDER BY created_at DESC LIMIT 25 };
};
