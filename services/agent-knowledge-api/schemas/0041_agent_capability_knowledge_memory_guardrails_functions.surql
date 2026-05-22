DEFINE TABLE agent_skill_catalog SCHEMAFULL;
DEFINE FIELD tenant_id ON agent_skill_catalog TYPE option<record<tenants>>;
DEFINE FIELD key ON agent_skill_catalog TYPE string;
DEFINE FIELD name ON agent_skill_catalog TYPE string;
DEFINE FIELD description ON agent_skill_catalog TYPE string;
DEFINE FIELD skill_kind ON agent_skill_catalog TYPE string DEFAULT 'general';
DEFINE FIELD input_modalities ON agent_skill_catalog TYPE array<string> DEFAULT ['text'];
DEFINE FIELD output_modalities ON agent_skill_catalog TYPE array<string> DEFAULT ['text'];
DEFINE FIELD required_tools ON agent_skill_catalog TYPE array<string> DEFAULT [];
DEFINE FIELD required_knowledge_domains ON agent_skill_catalog TYPE array<string> DEFAULT [];
DEFINE FIELD required_guardrail_ids ON agent_skill_catalog TYPE array<record<agent_guardrails>> DEFAULT [];
DEFINE FIELD default_constraints ON agent_skill_catalog TYPE array<object> DEFAULT [];
DEFINE FIELD status ON agent_skill_catalog TYPE string DEFAULT 'active';
DEFINE FIELD source_grounding_refs ON agent_skill_catalog TYPE array<string> DEFAULT [];
DEFINE FIELD jsonld_context ON agent_skill_catalog TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON agent_skill_catalog TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:AgentSkill'];
DEFINE FIELD created_at ON agent_skill_catalog TYPE datetime DEFAULT time::now();
DEFINE INDEX agent_skill_catalog_key_unique ON agent_skill_catalog FIELDS tenant_id, key UNIQUE;

DEFINE TABLE agent_knowledge_bases SCHEMAFULL;
DEFINE FIELD tenant_id ON agent_knowledge_bases TYPE option<record<tenants>>;
DEFINE FIELD key ON agent_knowledge_bases TYPE string;
DEFINE FIELD name ON agent_knowledge_bases TYPE string;
DEFINE FIELD description ON agent_knowledge_bases TYPE string;
DEFINE FIELD domain ON agent_knowledge_bases TYPE string;
DEFINE FIELD source_policy ON agent_knowledge_bases TYPE object DEFAULT { require_source_grounding: true, require_hash: true };
DEFINE FIELD retrieval_policy ON agent_knowledge_bases TYPE object DEFAULT { default_top_k: 8, require_citations: true };
DEFINE FIELD retention_policy ON agent_knowledge_bases TYPE object DEFAULT { retention_days: 365, pii_minimization: true };
DEFINE FIELD status ON agent_knowledge_bases TYPE string DEFAULT 'active';
DEFINE FIELD jsonld_context ON agent_knowledge_bases TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON agent_knowledge_bases TYPE array<string> DEFAULT ['schema:Dataset', 'agx:AgentKnowledgeBase'];
DEFINE FIELD created_at ON agent_knowledge_bases TYPE datetime DEFAULT time::now();
DEFINE INDEX agent_knowledge_bases_key_unique ON agent_knowledge_bases FIELDS tenant_id, key UNIQUE;

DEFINE TABLE agent_knowledge_items SCHEMAFULL;
DEFINE FIELD tenant_id ON agent_knowledge_items TYPE option<record<tenants>>;
DEFINE FIELD knowledge_base_id ON agent_knowledge_items TYPE record<agent_knowledge_bases>;
DEFINE FIELD item_ref ON agent_knowledge_items TYPE string;
DEFINE FIELD title ON agent_knowledge_items TYPE string;
DEFINE FIELD content_kind ON agent_knowledge_items TYPE string DEFAULT 'text';
DEFINE FIELD content_text ON agent_knowledge_items TYPE option<string>;
DEFINE FIELD source_uri ON agent_knowledge_items TYPE option<string>;
DEFINE FIELD source_hash ON agent_knowledge_items TYPE string;
DEFINE FIELD embedding_ref ON agent_knowledge_items TYPE option<string>;
DEFINE FIELD metadata ON agent_knowledge_items TYPE object DEFAULT {};
DEFINE FIELD trust_score_id ON agent_knowledge_items TYPE option<record<trust_scores>>;
DEFINE FIELD status ON agent_knowledge_items TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON agent_knowledge_items TYPE datetime DEFAULT time::now();
DEFINE FIELD expires_at ON agent_knowledge_items TYPE option<datetime>;
DEFINE FIELD jsonld_context ON agent_knowledge_items TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON agent_knowledge_items TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:AgentKnowledgeItem'];
DEFINE INDEX agent_knowledge_items_ref_unique ON agent_knowledge_items FIELDS knowledge_base_id, item_ref UNIQUE;

DEFINE TABLE agent_memory_profiles SCHEMAFULL;
DEFINE FIELD tenant_id ON agent_memory_profiles TYPE option<record<tenants>>;
DEFINE FIELD key ON agent_memory_profiles TYPE string;
DEFINE FIELD name ON agent_memory_profiles TYPE string;
DEFINE FIELD memory_mode ON agent_memory_profiles TYPE string DEFAULT 'graph_ranked';
DEFINE FIELD short_term_policy ON agent_memory_profiles TYPE object DEFAULT { enabled: true, retention_hours: 24 };
DEFINE FIELD long_term_policy ON agent_memory_profiles TYPE object DEFAULT { enabled: true, retention_days: 365, require_importance_threshold: 0.5 };
DEFINE FIELD episodic_policy ON agent_memory_profiles TYPE object DEFAULT { enabled: true };
DEFINE FIELD semantic_policy ON agent_memory_profiles TYPE object DEFAULT { enabled: true };
DEFINE FIELD privacy_policy ON agent_memory_profiles TYPE object DEFAULT { pii_minimization: true, consent_required: true };
DEFINE FIELD retrieval_policy ON agent_memory_profiles TYPE object DEFAULT { top_k: 8, min_trust: 0.5, min_reliability: 0.5 };
DEFINE FIELD status ON agent_memory_profiles TYPE string DEFAULT 'active';
DEFINE FIELD jsonld_context ON agent_memory_profiles TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON agent_memory_profiles TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:AgentMemoryProfile'];
DEFINE FIELD created_at ON agent_memory_profiles TYPE datetime DEFAULT time::now();
DEFINE INDEX agent_memory_profiles_key_unique ON agent_memory_profiles FIELDS tenant_id, key UNIQUE;

DEFINE TABLE agent_constraint_sets SCHEMAFULL;
DEFINE FIELD tenant_id ON agent_constraint_sets TYPE option<record<tenants>>;
DEFINE FIELD key ON agent_constraint_sets TYPE string;
DEFINE FIELD name ON agent_constraint_sets TYPE string;
DEFINE FIELD scope_kind ON agent_constraint_sets TYPE string DEFAULT 'agent';
DEFINE FIELD scope_ref ON agent_constraint_sets TYPE option<record>;
DEFINE FIELD hard_constraints ON agent_constraint_sets TYPE array<object> DEFAULT [];
DEFINE FIELD soft_constraints ON agent_constraint_sets TYPE array<object> DEFAULT [];
DEFINE FIELD budget_constraints ON agent_constraint_sets TYPE object DEFAULT {};
DEFINE FIELD latency_constraints ON agent_constraint_sets TYPE object DEFAULT {};
DEFINE FIELD data_constraints ON agent_constraint_sets TYPE object DEFAULT {};
DEFINE FIELD status ON agent_constraint_sets TYPE string DEFAULT 'active';
DEFINE FIELD jsonld_context ON agent_constraint_sets TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON agent_constraint_sets TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:AgentConstraintSet'];
DEFINE FIELD created_at ON agent_constraint_sets TYPE datetime DEFAULT time::now();
DEFINE INDEX agent_constraint_sets_key_unique ON agent_constraint_sets FIELDS tenant_id, key UNIQUE;

DEFINE TABLE agent_constitutions SCHEMAFULL;
DEFINE FIELD tenant_id ON agent_constitutions TYPE option<record<tenants>>;
DEFINE FIELD key ON agent_constitutions TYPE string;
DEFINE FIELD name ON agent_constitutions TYPE string;
DEFINE FIELD version ON agent_constitutions TYPE string DEFAULT '1.0.0';
DEFINE FIELD principles ON agent_constitutions TYPE array<object> DEFAULT [];
DEFINE FIELD prohibited_behaviors ON agent_constitutions TYPE array<object> DEFAULT [];
DEFINE FIELD required_behaviors ON agent_constitutions TYPE array<object> DEFAULT [];
DEFINE FIELD escalation_rules ON agent_constitutions TYPE array<object> DEFAULT [];
DEFINE FIELD human_override_policy ON agent_constitutions TYPE object DEFAULT { allowed: true, require_logging: true };
DEFINE FIELD constitution_hash ON agent_constitutions TYPE string;
DEFINE FIELD status ON agent_constitutions TYPE string DEFAULT 'active';
DEFINE FIELD source_grounding_refs ON agent_constitutions TYPE array<string> DEFAULT [];
DEFINE FIELD jsonld_context ON agent_constitutions TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON agent_constitutions TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:AgentConstitution'];
DEFINE FIELD created_at ON agent_constitutions TYPE datetime DEFAULT time::now();
DEFINE INDEX agent_constitutions_key_unique ON agent_constitutions FIELDS tenant_id, key, version UNIQUE;

DEFINE TABLE agent_guardrail_sets SCHEMAFULL;
DEFINE FIELD tenant_id ON agent_guardrail_sets TYPE option<record<tenants>>;
DEFINE FIELD key ON agent_guardrail_sets TYPE string;
DEFINE FIELD name ON agent_guardrail_sets TYPE string;
DEFINE FIELD input_guardrails ON agent_guardrail_sets TYPE array<object> DEFAULT [];
DEFINE FIELD output_guardrails ON agent_guardrail_sets TYPE array<object> DEFAULT [];
DEFINE FIELD tool_guardrails ON agent_guardrail_sets TYPE array<object> DEFAULT [];
DEFINE FIELD memory_guardrails ON agent_guardrail_sets TYPE array<object> DEFAULT [];
DEFINE FIELD commerce_guardrails ON agent_guardrail_sets TYPE array<object> DEFAULT [];
DEFINE FIELD escalation_policy ON agent_guardrail_sets TYPE object DEFAULT { require_human_review_on_violation: true };
DEFINE FIELD status ON agent_guardrail_sets TYPE string DEFAULT 'active';
DEFINE FIELD jsonld_context ON agent_guardrail_sets TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON agent_guardrail_sets TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:AgentGuardrailSet'];
DEFINE FIELD created_at ON agent_guardrail_sets TYPE datetime DEFAULT time::now();
DEFINE INDEX agent_guardrail_sets_key_unique ON agent_guardrail_sets FIELDS tenant_id, key UNIQUE;

DEFINE TABLE agent_blueprints SCHEMAFULL;
DEFINE FIELD tenant_id ON agent_blueprints TYPE option<record<tenants>>;
DEFINE FIELD key ON agent_blueprints TYPE string;
DEFINE FIELD name ON agent_blueprints TYPE string;
DEFINE FIELD description ON agent_blueprints TYPE string;
DEFINE FIELD application_id ON agent_blueprints TYPE option<record<applications>>;
DEFINE FIELD project_id ON agent_blueprints TYPE option<record<projects>>;
DEFINE FIELD skill_ids ON agent_blueprints TYPE array<record<agent_skill_catalog>> DEFAULT [];
DEFINE FIELD knowledge_base_ids ON agent_blueprints TYPE array<record<agent_knowledge_bases>> DEFAULT [];
DEFINE FIELD memory_profile_id ON agent_blueprints TYPE option<record<agent_memory_profiles>>;
DEFINE FIELD constraint_set_id ON agent_blueprints TYPE option<record<agent_constraint_sets>>;
DEFINE FIELD constitution_id ON agent_blueprints TYPE option<record<agent_constitutions>>;
DEFINE FIELD guardrail_set_id ON agent_blueprints TYPE option<record<agent_guardrail_sets>>;
DEFINE FIELD environment_config_id ON agent_blueprints TYPE option<record<environment_configurations>>;
DEFINE FIELD tool_config_id ON agent_blueprints TYPE option<record<tool_configurations>>;
DEFINE FIELD collaboration_space_id ON agent_blueprints TYPE option<record<collaboration_spaces>>;
DEFINE FIELD status ON agent_blueprints TYPE string DEFAULT 'draft';
DEFINE FIELD decision_log_id ON agent_blueprints TYPE option<record<decision_context_logs>>;
DEFINE FIELD created_at ON agent_blueprints TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON agent_blueprints TYPE datetime DEFAULT time::now();
DEFINE FIELD jsonld_context ON agent_blueprints TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON agent_blueprints TYPE array<string> DEFAULT ['schema:SoftwareApplication', 'agx:AgentBlueprint'];
DEFINE INDEX agent_blueprints_key_unique ON agent_blueprints FIELDS tenant_id, key UNIQUE;

UPSERT agent_memory_profiles:default CONTENT { tenant_id: NONE, key: 'default', name: 'Default Graph-Ranked Agent Memory', memory_mode: 'graph_ranked', status: 'active' };
UPSERT agent_guardrail_sets:default CONTENT { tenant_id: NONE, key: 'default', name: 'Default Agent Guardrails', input_guardrails: [{ kind: 'context_completeness_required' }], output_guardrails: [{ kind: 'source_grounding_required_for_factual_claims' }], tool_guardrails: [{ kind: 'authorization_required' }], memory_guardrails: [{ kind: 'pii_minimization_required' }], commerce_guardrails: [{ kind: 'payment_requires_mandate_and_approval' }], status: 'active' };

DEFINE FUNCTION fn::create_agent_skill($tenant_id, $key, $name, $description, $skill_kind, $input_modalities, $output_modalities, $required_tools, $required_knowledge_domains, $required_guardrail_ids, $default_constraints, $source_grounding_refs) {
  RETURN CREATE agent_skill_catalog CONTENT { tenant_id: $tenant_id, key: $key, name: $name, description: $description, skill_kind: $skill_kind, input_modalities: $input_modalities, output_modalities: $output_modalities, required_tools: $required_tools, required_knowledge_domains: $required_knowledge_domains, required_guardrail_ids: $required_guardrail_ids, default_constraints: $default_constraints, status: 'active', source_grounding_refs: $source_grounding_refs, created_at: time::now() };
};

DEFINE FUNCTION fn::create_agent_knowledge_base($tenant_id, $key, $name, $description, $domain, $source_policy, $retrieval_policy, $retention_policy) {
  RETURN CREATE agent_knowledge_bases CONTENT { tenant_id: $tenant_id, key: $key, name: $name, description: $description, domain: $domain, source_policy: $source_policy, retrieval_policy: $retrieval_policy, retention_policy: $retention_policy, status: 'active', created_at: time::now() };
};

DEFINE FUNCTION fn::add_agent_knowledge_item($tenant_id, $knowledge_base_id, $item_ref, $title, $content_kind, $content_text, $source_uri, $source_hash, $embedding_ref, $metadata, $actor_id, $expires_at) {
  LET $kb = SELECT * FROM $knowledge_base_id;
  IF count($kb) = 0 THEN { THROW 'agent_knowledge_base_not_found'; };
  IF $source_hash = NONE OR string::len($source_hash) = 0 THEN { THROW 'knowledge_source_hash_required'; };
  LET $trust = fn::compute_trust_v1($tenant_id, string::concat($knowledge_base_id), $actor_id, { type: 'knowledge_item', source_uri: $source_uri, source_hash: $source_hash });
  RETURN CREATE agent_knowledge_items CONTENT { tenant_id: $tenant_id, knowledge_base_id: $knowledge_base_id, item_ref: $item_ref, title: $title, content_kind: $content_kind, content_text: $content_text, source_uri: $source_uri, source_hash: $source_hash, embedding_ref: $embedding_ref, metadata: $metadata, trust_score_id: $trust.id, status: 'active', created_at: time::now(), expires_at: $expires_at };
};

DEFINE FUNCTION fn::create_agent_memory_profile($tenant_id, $key, $name, $memory_mode, $short_term_policy, $long_term_policy, $episodic_policy, $semantic_policy, $privacy_policy, $retrieval_policy) {
  RETURN CREATE agent_memory_profiles CONTENT { tenant_id: $tenant_id, key: $key, name: $name, memory_mode: $memory_mode, short_term_policy: $short_term_policy, long_term_policy: $long_term_policy, episodic_policy: $episodic_policy, semantic_policy: $semantic_policy, privacy_policy: $privacy_policy, retrieval_policy: $retrieval_policy, status: 'active', created_at: time::now() };
};

DEFINE FUNCTION fn::create_agent_constraint_set($tenant_id, $key, $name, $scope_kind, $scope_ref, $hard_constraints, $soft_constraints, $budget_constraints, $latency_constraints, $data_constraints) {
  RETURN CREATE agent_constraint_sets CONTENT { tenant_id: $tenant_id, key: $key, name: $name, scope_kind: $scope_kind, scope_ref: $scope_ref, hard_constraints: $hard_constraints, soft_constraints: $soft_constraints, budget_constraints: $budget_constraints, latency_constraints: $latency_constraints, data_constraints: $data_constraints, status: 'active', created_at: time::now() };
};

DEFINE FUNCTION fn::create_agent_constitution($tenant_id, $key, $name, $version, $principles, $prohibited_behaviors, $required_behaviors, $escalation_rules, $human_override_policy, $constitution_hash, $source_grounding_refs) {
  IF $constitution_hash = NONE OR string::len($constitution_hash) = 0 THEN { THROW 'agent_constitution_hash_required'; };
  RETURN CREATE agent_constitutions CONTENT { tenant_id: $tenant_id, key: $key, name: $name, version: $version, principles: $principles, prohibited_behaviors: $prohibited_behaviors, required_behaviors: $required_behaviors, escalation_rules: $escalation_rules, human_override_policy: $human_override_policy, constitution_hash: $constitution_hash, status: 'active', source_grounding_refs: $source_grounding_refs, created_at: time::now() };
};

DEFINE FUNCTION fn::create_agent_guardrail_set($tenant_id, $key, $name, $input_guardrails, $output_guardrails, $tool_guardrails, $memory_guardrails, $commerce_guardrails, $escalation_policy) {
  RETURN CREATE agent_guardrail_sets CONTENT { tenant_id: $tenant_id, key: $key, name: $name, input_guardrails: $input_guardrails, output_guardrails: $output_guardrails, tool_guardrails: $tool_guardrails, memory_guardrails: $memory_guardrails, commerce_guardrails: $commerce_guardrails, escalation_policy: $escalation_policy, status: 'active', created_at: time::now() };
};

DEFINE FUNCTION fn::create_agent_blueprint($tenant_id, $key, $name, $description, $application_id, $project_id, $skill_ids, $knowledge_base_ids, $memory_profile_id, $constraint_set_id, $constitution_id, $guardrail_set_id, $environment_config_id, $tool_config_id, $collaboration_space_id, $actor_id) {
  LET $decision_log = fn::log_decision_context($tenant_id, 'agent_blueprint_created', $key, $actor_id, NONE, NONE, { key: $key, name: $name, application_id: $application_id, project_id: $project_id }, {}, {}, {}, {}, {}, {}, { skill_ids: $skill_ids, knowledge_base_ids: $knowledge_base_ids, memory_profile_id: $memory_profile_id, constraint_set_id: $constraint_set_id, constitution_id: $constitution_id, guardrail_set_id: $guardrail_set_id }, [{ kind: 'skills_knowledge_memory_constraints_constitution_guardrails_required_for_release' }], { blueprint_complete: $memory_profile_id != NONE AND $constraint_set_id != NONE AND $constitution_id != NONE AND $guardrail_set_id != NONE }, [{ decision: 'create_blueprint' }, { decision: 'reject_blueprint' }], { decision: 'create_blueprint' }, [], 'agent_blueprint_recorded', { method: 'agx:agent-blueprint-v1' }, array::concat($skill_ids, $knowledge_base_ids), NONE, [], false);
  RETURN CREATE agent_blueprints CONTENT { tenant_id: $tenant_id, key: $key, name: $name, description: $description, application_id: $application_id, project_id: $project_id, skill_ids: $skill_ids, knowledge_base_ids: $knowledge_base_ids, memory_profile_id: $memory_profile_id, constraint_set_id: $constraint_set_id, constitution_id: $constitution_id, guardrail_set_id: $guardrail_set_id, environment_config_id: $environment_config_id, tool_config_id: $tool_config_id, collaboration_space_id: $collaboration_space_id, status: 'draft', decision_log_id: $decision_log.id, created_at: time::now(), updated_at: time::now() };
};

DEFINE FUNCTION fn::require_agent_blueprint_complete($agent_blueprint_id) {
  LET $bp = SELECT * FROM $agent_blueprint_id;
  IF count($bp) = 0 THEN { THROW 'agent_blueprint_not_found'; };
  IF count($bp[0].skill_ids) = 0 THEN { THROW 'agent_blueprint_skills_required'; };
  IF count($bp[0].knowledge_base_ids) = 0 THEN { THROW 'agent_blueprint_knowledge_required'; };
  IF $bp[0].memory_profile_id = NONE THEN { THROW 'agent_blueprint_memory_profile_required'; };
  IF $bp[0].constraint_set_id = NONE THEN { THROW 'agent_blueprint_constraints_required'; };
  IF $bp[0].constitution_id = NONE THEN { THROW 'agent_blueprint_constitution_required'; };
  IF $bp[0].guardrail_set_id = NONE THEN { THROW 'agent_blueprint_guardrails_required'; };
  RETURN true;
};

DEFINE FUNCTION fn::activate_agent_blueprint($agent_blueprint_id, $actor_id) {
  fn::require_agent_blueprint_complete($agent_blueprint_id);
  LET $bp = SELECT * FROM $agent_blueprint_id;
  UPDATE $agent_blueprint_id SET status = 'active', updated_at = time::now();
  CREATE audit_logs CONTENT { tenant_id: $bp[0].tenant_id, actor_id: $actor_id, action: 'agent_blueprint_activated', resource_type: 'agent_blueprints', resource_id: string::concat($agent_blueprint_id), metadata: { key: $bp[0].key }, semantic_id: rand::uuid(), jsonld_context: { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' }, jsonld_type: ['schema:Action', 'agx:AuditEvent'], time: { observed_at: time::now() }, created_at: time::now() };
  RETURN SELECT * FROM $agent_blueprint_id;
};
