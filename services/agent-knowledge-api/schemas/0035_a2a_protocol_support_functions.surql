DEFINE TABLE a2a_protocol_standards SCHEMAFULL;
DEFINE FIELD tenant_id ON a2a_protocol_standards TYPE option<record<tenants>>;
DEFINE FIELD key ON a2a_protocol_standards TYPE string;
DEFINE FIELD name ON a2a_protocol_standards TYPE string;
DEFINE FIELD standard_uri ON a2a_protocol_standards TYPE string;
DEFINE FIELD standard_version ON a2a_protocol_standards TYPE string DEFAULT 'latest';
DEFINE FIELD status ON a2a_protocol_standards TYPE string DEFAULT 'active';
DEFINE FIELD source_grounding_refs ON a2a_protocol_standards TYPE array<string> DEFAULT ['github:a2aproject/A2A'];
DEFINE FIELD jsonld_context ON a2a_protocol_standards TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON a2a_protocol_standards TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:A2AProtocolStandard'];
DEFINE FIELD created_at ON a2a_protocol_standards TYPE datetime DEFAULT time::now();
DEFINE INDEX a2a_protocol_standards_key_unique ON a2a_protocol_standards FIELDS tenant_id, key, standard_version UNIQUE;

DEFINE TABLE a2a_agent_cards SCHEMAFULL;
DEFINE FIELD tenant_id ON a2a_agent_cards TYPE option<record<tenants>>;
DEFINE FIELD agent_id ON a2a_agent_cards TYPE option<record<agents>>;
DEFINE FIELD identity_subject_id ON a2a_agent_cards TYPE option<record<agent_identity_subjects>>;
DEFINE FIELD card_uri ON a2a_agent_cards TYPE option<string>;
DEFINE FIELD card_hash ON a2a_agent_cards TYPE string;
DEFINE FIELD name ON a2a_agent_cards TYPE string;
DEFINE FIELD description ON a2a_agent_cards TYPE string;
DEFINE FIELD version ON a2a_agent_cards TYPE string DEFAULT '1.0.0';
DEFINE FIELD endpoint_uri ON a2a_agent_cards TYPE string;
DEFINE FIELD capabilities ON a2a_agent_cards TYPE array<object> DEFAULT [];
DEFINE FIELD skills ON a2a_agent_cards TYPE array<object> DEFAULT [];
DEFINE FIELD input_modalities ON a2a_agent_cards TYPE array<string> DEFAULT ['text'];
DEFINE FIELD output_modalities ON a2a_agent_cards TYPE array<string> DEFAULT ['text'];
DEFINE FIELD authentication ON a2a_agent_cards TYPE object DEFAULT {};
DEFINE FIELD authorization ON a2a_agent_cards TYPE object DEFAULT {};
DEFINE FIELD trust_policy ON a2a_agent_cards TYPE object DEFAULT {};
DEFINE FIELD status ON a2a_agent_cards TYPE string DEFAULT 'active';
DEFINE FIELD source_grounding_refs ON a2a_agent_cards TYPE array<string> DEFAULT ['github:a2aproject/A2A'];
DEFINE FIELD jsonld_context ON a2a_agent_cards TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON a2a_agent_cards TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:A2AAgentCard'];
DEFINE FIELD created_at ON a2a_agent_cards TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON a2a_agent_cards TYPE datetime DEFAULT time::now();
DEFINE INDEX a2a_agent_cards_hash_unique ON a2a_agent_cards FIELDS tenant_id, card_hash UNIQUE;

DEFINE TABLE a2a_tasks SCHEMAFULL;
DEFINE FIELD tenant_id ON a2a_tasks TYPE option<record<tenants>>;
DEFINE FIELD local_agent_card_id ON a2a_tasks TYPE record<a2a_agent_cards>;
DEFINE FIELD remote_agent_card_id ON a2a_tasks TYPE record<a2a_agent_cards>;
DEFINE FIELD task_ref ON a2a_tasks TYPE string;
DEFINE FIELD task_kind ON a2a_tasks TYPE string;
DEFINE FIELD status ON a2a_tasks TYPE string DEFAULT 'submitted';
DEFINE FIELD input_message ON a2a_tasks TYPE object DEFAULT {};
DEFINE FIELD context_id ON a2a_tasks TYPE option<record<execution_contexts>>;
DEFINE FIELD authorization_decision_id ON a2a_tasks TYPE option<record<authorization_access_evaluation_decisions>>;
DEFINE FIELD policy_decision_result_id ON a2a_tasks TYPE option<record<policy_decision_results>>;
DEFINE FIELD relationship_access_check_id ON a2a_tasks TYPE option<record<relationship_access_checks>>;
DEFINE FIELD observation_run_id ON a2a_tasks TYPE option<record<observation_runs>>;
DEFINE FIELD decision_log_id ON a2a_tasks TYPE option<record<decision_context_logs>>;
DEFINE FIELD source_grounding_refs ON a2a_tasks TYPE array<string> DEFAULT ['github:a2aproject/A2A'];
DEFINE FIELD jsonld_context ON a2a_tasks TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON a2a_tasks TYPE array<string> DEFAULT ['schema:Action', 'agx:A2ATask'];
DEFINE FIELD created_at ON a2a_tasks TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON a2a_tasks TYPE datetime DEFAULT time::now();
DEFINE INDEX a2a_tasks_ref_unique ON a2a_tasks FIELDS tenant_id, task_ref UNIQUE;

DEFINE TABLE a2a_messages SCHEMAFULL;
DEFINE FIELD tenant_id ON a2a_messages TYPE option<record<tenants>>;
DEFINE FIELD a2a_task_id ON a2a_messages TYPE record<a2a_tasks>;
DEFINE FIELD message_ref ON a2a_messages TYPE string;
DEFINE FIELD sender_card_id ON a2a_messages TYPE record<a2a_agent_cards>;
DEFINE FIELD receiver_card_id ON a2a_messages TYPE record<a2a_agent_cards>;
DEFINE FIELD role ON a2a_messages TYPE string;
DEFINE FIELD parts ON a2a_messages TYPE array<object> DEFAULT [];
DEFINE FIELD metadata ON a2a_messages TYPE object DEFAULT {};
DEFINE FIELD payload_hash ON a2a_messages TYPE string;
DEFINE FIELD observed_at ON a2a_messages TYPE datetime DEFAULT time::now();
DEFINE FIELD jsonld_context ON a2a_messages TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON a2a_messages TYPE array<string> DEFAULT ['schema:Message', 'agx:A2AMessage'];
DEFINE FIELD created_at ON a2a_messages TYPE datetime DEFAULT time::now();
DEFINE INDEX a2a_messages_ref_unique ON a2a_messages FIELDS tenant_id, message_ref UNIQUE;

DEFINE TABLE a2a_artifacts SCHEMAFULL;
DEFINE FIELD tenant_id ON a2a_artifacts TYPE option<record<tenants>>;
DEFINE FIELD a2a_task_id ON a2a_artifacts TYPE record<a2a_tasks>;
DEFINE FIELD artifact_ref ON a2a_artifacts TYPE string;
DEFINE FIELD artifact_kind ON a2a_artifacts TYPE string;
DEFINE FIELD parts ON a2a_artifacts TYPE array<object> DEFAULT [];
DEFINE FIELD uri ON a2a_artifacts TYPE option<string>;
DEFINE FIELD payload_hash ON a2a_artifacts TYPE string;
DEFINE FIELD metadata ON a2a_artifacts TYPE object DEFAULT {};
DEFINE FIELD created_at ON a2a_artifacts TYPE datetime DEFAULT time::now();
DEFINE FIELD jsonld_context ON a2a_artifacts TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON a2a_artifacts TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:A2AArtifact'];
DEFINE INDEX a2a_artifacts_ref_unique ON a2a_artifacts FIELDS tenant_id, artifact_ref UNIQUE;

UPSERT a2a_protocol_standards:a2a_latest CONTENT { tenant_id: NONE, key: 'a2a', name: 'Agent2Agent Protocol', standard_uri: 'https://github.com/a2aproject/A2A', standard_version: 'latest', status: 'active', source_grounding_refs: ['github:a2aproject/A2A'] };

DEFINE FUNCTION fn::register_a2a_agent_card($tenant_id, $agent_id, $identity_subject_id, $card_uri, $card_hash, $name, $description, $version, $endpoint_uri, $capabilities, $skills, $input_modalities, $output_modalities, $authentication, $authorization, $trust_policy) {
  IF $card_hash = NONE OR string::len($card_hash) = 0 THEN { THROW 'a2a_agent_card_hash_required'; };
  RETURN CREATE a2a_agent_cards CONTENT { tenant_id: $tenant_id, agent_id: $agent_id, identity_subject_id: $identity_subject_id, card_uri: $card_uri, card_hash: $card_hash, name: $name, description: $description, version: $version, endpoint_uri: $endpoint_uri, capabilities: $capabilities, skills: $skills, input_modalities: $input_modalities, output_modalities: $output_modalities, authentication: $authentication, authorization: $authorization, trust_policy: $trust_policy, status: 'active', source_grounding_refs: ['github:a2aproject/A2A'], created_at: time::now(), updated_at: time::now() };
};

DEFINE FUNCTION fn::verify_a2a_agent_card($tenant_id, $card_id, $verifier_id) {
  LET $card = SELECT * FROM $card_id;
  IF count($card) = 0 THEN { THROW 'a2a_agent_card_not_found'; };
  LET $trust = fn::compute_trust_v1($tenant_id, string::concat($card_id), $verifier_id, { type: 'a2a_agent_card_verification', endpoint_uri: $card[0].endpoint_uri });
  CREATE trust_evidence CONTENT { tenant_id: $tenant_id, subject_id: string::concat($card_id), evidence_kind: 'agent_card_verification', source_id: $verifier_id, weight: $trust.score, confidence: 0.85, payload: { card_id: $card_id, card_hash: $card[0].card_hash, endpoint_uri: $card[0].endpoint_uri }, observed_at: time::now(), source_grounding_refs: ['github:a2aproject/A2A'], jsonld_context: { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' }, jsonld_type: ['schema:CreativeWork', 'agx:TrustEvidence'] };
  RETURN $trust;
};

DEFINE FUNCTION fn::start_a2a_task($tenant_id, $local_agent_card_id, $remote_agent_card_id, $task_ref, $task_kind, $input_message, $execution_context_id, $authorization_decision_id, $policy_decision_result_id, $relationship_access_check_id, $actor_id) {
  LET $local = SELECT * FROM $local_agent_card_id;
  LET $remote = SELECT * FROM $remote_agent_card_id;
  IF count($local) = 0 OR count($remote) = 0 THEN { THROW 'a2a_agent_card_not_found'; };
  IF $execution_context_id != NONE THEN { fn::require_complete_execution_context($execution_context_id); };
  IF $authorization_decision_id != NONE THEN { fn::require_access_evaluation_allowed($authorization_decision_id); };
  IF $policy_decision_result_id != NONE THEN { fn::require_policy_allowed($policy_decision_result_id); };
  IF $relationship_access_check_id != NONE THEN { fn::require_relationship_access_allowed($relationship_access_check_id); };
  LET $obs = fn::create_observation_run($tenant_id, $local[0].agent_id, 'a2a_task', 'agx:a2a-protocol-v1');
  LET $decision_log = fn::log_decision_context($tenant_id, 'a2a_task_start', string::concat($remote_agent_card_id), $actor_id, NONE, NONE, { task_ref: $task_ref, task_kind: $task_kind, input_message: $input_message }, {}, {}, {}, { local_agent_card_id: $local_agent_card_id, remote_agent_card_id: $remote_agent_card_id }, {}, {}, { authorization_decision_id: $authorization_decision_id, policy_decision_result_id: $policy_decision_result_id, relationship_access_check_id: $relationship_access_check_id }, [{ kind: 'a2a_agent_card_required' }, { kind: 'context_authorization_policy_relationship_gates_if_present' }], { local_agent_card_id: $local_agent_card_id, remote_agent_card_id: $remote_agent_card_id }, [{ decision: 'submit_task' }, { decision: 'block_task' }], { decision: 'submit_task' }, [], 'a2a_task_authorized_for_submission', { method: 'agx:a2a-protocol-v1' }, [$local_agent_card_id, $remote_agent_card_id], $obs.id, [], false);
  LET $task = CREATE a2a_tasks CONTENT { tenant_id: $tenant_id, local_agent_card_id: $local_agent_card_id, remote_agent_card_id: $remote_agent_card_id, task_ref: $task_ref, task_kind: $task_kind, status: 'submitted', input_message: $input_message, context_id: $execution_context_id, authorization_decision_id: $authorization_decision_id, policy_decision_result_id: $policy_decision_result_id, relationship_access_check_id: $relationship_access_check_id, observation_run_id: $obs.id, decision_log_id: $decision_log.id, source_grounding_refs: ['github:a2aproject/A2A'], created_at: time::now(), updated_at: time::now() };
  fn::add_observation_step($obs.id, 1, 'start_a2a_task', { task_ref: $task_ref, task_kind: $task_kind }, { a2a_task_id: $task.id }, 'completed', 'agx:a2a-protocol-v1');
  RETURN $task;
};

DEFINE FUNCTION fn::record_a2a_message($tenant_id, $a2a_task_id, $message_ref, $sender_card_id, $receiver_card_id, $role, $parts, $metadata, $payload_hash) {
  LET $task = SELECT * FROM $a2a_task_id;
  IF count($task) = 0 THEN { THROW 'a2a_task_not_found'; };
  IF $payload_hash = NONE OR string::len($payload_hash) = 0 THEN { THROW 'a2a_message_payload_hash_required'; };
  LET $message = CREATE a2a_messages CONTENT { tenant_id: $tenant_id, a2a_task_id: $a2a_task_id, message_ref: $message_ref, sender_card_id: $sender_card_id, receiver_card_id: $receiver_card_id, role: $role, parts: $parts, metadata: $metadata, payload_hash: $payload_hash, observed_at: time::now(), created_at: time::now() };
  fn::add_observation_step($task[0].observation_run_id, 10 + count(SELECT * FROM a2a_messages WHERE a2a_task_id = $a2a_task_id), 'record_a2a_message', { message_ref: $message_ref, role: $role }, { message_id: $message.id }, 'completed', 'agx:a2a-protocol-v1');
  RETURN $message;
};

DEFINE FUNCTION fn::record_a2a_artifact($tenant_id, $a2a_task_id, $artifact_ref, $artifact_kind, $parts, $uri, $payload_hash, $metadata) {
  LET $task = SELECT * FROM $a2a_task_id;
  IF count($task) = 0 THEN { THROW 'a2a_task_not_found'; };
  IF $payload_hash = NONE OR string::len($payload_hash) = 0 THEN { THROW 'a2a_artifact_payload_hash_required'; };
  RETURN CREATE a2a_artifacts CONTENT { tenant_id: $tenant_id, a2a_task_id: $a2a_task_id, artifact_ref: $artifact_ref, artifact_kind: $artifact_kind, parts: $parts, uri: $uri, payload_hash: $payload_hash, metadata: $metadata, created_at: time::now() };
};

DEFINE FUNCTION fn::complete_a2a_task($a2a_task_id, $status, $quality_score) {
  LET $task = SELECT * FROM $a2a_task_id;
  IF count($task) = 0 THEN { THROW 'a2a_task_not_found'; };
  UPDATE $a2a_task_id SET status = $status, updated_at = time::now();
  fn::record_reliability_event($task[0].tenant_id, string::concat($task[0].remote_agent_card_id), 'a2a_task', IF $status = 'completed' THEN 'success' ELSE 'failure' END, IF $quality_score = NONE THEN 0.5 ELSE $quality_score END, NONE, string::concat($a2a_task_id), { task_ref: $task[0].task_ref, task_kind: $task[0].task_kind });
  fn::finish_observation_run($task[0].observation_run_id, $status, { quality_score: $quality_score });
  RETURN SELECT * FROM $a2a_task_id;
};
