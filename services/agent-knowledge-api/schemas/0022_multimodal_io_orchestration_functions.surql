DEFINE TABLE multimodal_io_policies SCHEMAFULL;
DEFINE FIELD tenant_id ON multimodal_io_policies TYPE option<record<tenants>>;
DEFINE FIELD key ON multimodal_io_policies TYPE string;
DEFINE FIELD name ON multimodal_io_policies TYPE string;
DEFINE FIELD accepted_input_modalities ON multimodal_io_policies TYPE array<string> DEFAULT ['text', 'image', 'audio', 'video', 'document', 'table', 'code', 'json', 'url', 'location', 'time', 'sensor', 'binary'];
DEFINE FIELD allowed_output_modalities ON multimodal_io_policies TYPE array<string> DEFAULT ['text', 'json', 'markdown', 'table', 'image', 'audio', 'document', 'code', 'action_plan'];
DEFINE FIELD default_output_modalities ON multimodal_io_policies TYPE array<string> DEFAULT ['text', 'json'];
DEFINE FIELD max_input_items ON multimodal_io_policies TYPE int DEFAULT 32;
DEFINE FIELD max_total_bytes ON multimodal_io_policies TYPE int DEFAULT 104857600;
DEFINE FIELD require_context_completeness ON multimodal_io_policies TYPE bool DEFAULT true;
DEFINE FIELD require_human_confirmation_for_derived_actions ON multimodal_io_policies TYPE bool DEFAULT true;
DEFINE FIELD enabled ON multimodal_io_policies TYPE bool DEFAULT true;
DEFINE FIELD jsonld_context ON multimodal_io_policies TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON multimodal_io_policies TYPE array<string> DEFAULT ['schema:CreativeWork', 'agx:MultimodalIOPolicy'];
DEFINE FIELD created_at ON multimodal_io_policies TYPE datetime DEFAULT time::now();
DEFINE INDEX multimodal_io_policies_key_unique ON multimodal_io_policies FIELDS tenant_id, key UNIQUE;

DEFINE TABLE multimodal_sessions SCHEMAFULL;
DEFINE FIELD tenant_id ON multimodal_sessions TYPE option<record<tenants>>;
DEFINE FIELD agent_id ON multimodal_sessions TYPE option<record<agents>>;
DEFINE FIELD subject_id ON multimodal_sessions TYPE string;
DEFINE FIELD conversation_id ON multimodal_sessions TYPE option<string>;
DEFINE FIELD message_id ON multimodal_sessions TYPE option<string>;
DEFINE FIELD policy_id ON multimodal_sessions TYPE record<multimodal_io_policies>;
DEFINE FIELD requested_output_modalities ON multimodal_sessions TYPE array<string> DEFAULT [];
DEFINE FIELD detected_input_modalities ON multimodal_sessions TYPE array<string> DEFAULT [];
DEFINE FIELD selected_processing_plan_id ON multimodal_sessions TYPE option<record<multimodal_processing_plans>>;
DEFINE FIELD status ON multimodal_sessions TYPE string DEFAULT 'collecting_inputs';
DEFINE FIELD observation_run_id ON multimodal_sessions TYPE option<record<observation_runs>>;
DEFINE FIELD decision_log_id ON multimodal_sessions TYPE option<record<decision_context_logs>>;
DEFINE FIELD jsonld_context ON multimodal_sessions TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON multimodal_sessions TYPE array<string> DEFAULT ['schema:Action', 'agx:MultimodalSession'];
DEFINE FIELD created_at ON multimodal_sessions TYPE datetime DEFAULT time::now();
DEFINE FIELD completed_at ON multimodal_sessions TYPE option<datetime>;

DEFINE TABLE multimodal_inputs SCHEMAFULL;
DEFINE FIELD tenant_id ON multimodal_inputs TYPE option<record<tenants>>;
DEFINE FIELD session_id ON multimodal_inputs TYPE record<multimodal_sessions>;
DEFINE FIELD input_kind ON multimodal_inputs TYPE string;
DEFINE FIELD media_type ON multimodal_inputs TYPE option<string>;
DEFINE FIELD uri ON multimodal_inputs TYPE option<string>;
DEFINE FIELD content_text ON multimodal_inputs TYPE option<string>;
DEFINE FIELD payload_ref ON multimodal_inputs TYPE option<string>;
DEFINE FIELD payload_hash ON multimodal_inputs TYPE option<string>;
DEFINE FIELD byte_size ON multimodal_inputs TYPE int DEFAULT 0;
DEFINE FIELD metadata ON multimodal_inputs TYPE object DEFAULT {};
DEFINE FIELD detected_entities ON multimodal_inputs TYPE array<record<knowledge_entities>> DEFAULT [];
DEFINE FIELD extracted_context ON multimodal_inputs TYPE object DEFAULT {};
DEFINE FIELD processing_status ON multimodal_inputs TYPE string DEFAULT 'pending';
DEFINE FIELD jsonld_context ON multimodal_inputs TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON multimodal_inputs TYPE array<string> DEFAULT ['schema:MediaObject', 'agx:MultimodalInput'];
DEFINE FIELD created_at ON multimodal_inputs TYPE datetime DEFAULT time::now();

DEFINE TABLE multimodal_processing_plans SCHEMAFULL;
DEFINE FIELD tenant_id ON multimodal_processing_plans TYPE option<record<tenants>>;
DEFINE FIELD session_id ON multimodal_processing_plans TYPE record<multimodal_sessions>;
DEFINE FIELD plan_kind ON multimodal_processing_plans TYPE string DEFAULT 'auto_selected';
DEFINE FIELD input_modalities ON multimodal_processing_plans TYPE array<string> DEFAULT [];
DEFINE FIELD output_modalities ON multimodal_processing_plans TYPE array<string> DEFAULT [];
DEFINE FIELD processors ON multimodal_processing_plans TYPE array<object> DEFAULT [];
DEFINE FIELD routing_reason ON multimodal_processing_plans TYPE object DEFAULT {};
DEFINE FIELD estimated_cost_usd ON multimodal_processing_plans TYPE number DEFAULT 0;
DEFINE FIELD estimated_latency_ms ON multimodal_processing_plans TYPE number DEFAULT 0;
DEFINE FIELD selected_llm_run_id ON multimodal_processing_plans TYPE option<record<llm_selection_runs>>;
DEFINE FIELD selected_context_run_id ON multimodal_processing_plans TYPE option<record<context_optimization_runs>>;
DEFINE FIELD status ON multimodal_processing_plans TYPE string DEFAULT 'planned';
DEFINE FIELD jsonld_context ON multimodal_processing_plans TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON multimodal_processing_plans TYPE array<string> DEFAULT ['schema:Action', 'agx:MultimodalProcessingPlan'];
DEFINE FIELD created_at ON multimodal_processing_plans TYPE datetime DEFAULT time::now();

DEFINE TABLE multimodal_outputs SCHEMAFULL;
DEFINE FIELD tenant_id ON multimodal_outputs TYPE option<record<tenants>>;
DEFINE FIELD session_id ON multimodal_outputs TYPE record<multimodal_sessions>;
DEFINE FIELD plan_id ON multimodal_outputs TYPE option<record<multimodal_processing_plans>>;
DEFINE FIELD output_kind ON multimodal_outputs TYPE string;
DEFINE FIELD media_type ON multimodal_outputs TYPE option<string>;
DEFINE FIELD content_text ON multimodal_outputs TYPE option<string>;
DEFINE FIELD payload_ref ON multimodal_outputs TYPE option<string>;
DEFINE FIELD payload_hash ON multimodal_outputs TYPE option<string>;
DEFINE FIELD metadata ON multimodal_outputs TYPE object DEFAULT {};
DEFINE FIELD quality_score ON multimodal_outputs TYPE option<number> ASSERT $value = NONE OR ($value >= 0 AND $value <= 1);
DEFINE FIELD jsonld_context ON multimodal_outputs TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON multimodal_outputs TYPE array<string> DEFAULT ['schema:MediaObject', 'agx:MultimodalOutput'];
DEFINE FIELD created_at ON multimodal_outputs TYPE datetime DEFAULT time::now();

UPSERT multimodal_io_policies:default CONTENT {
  tenant_id: NONE,
  key: 'default',
  name: 'Default Multimodal IO Policy',
  accepted_input_modalities: ['text', 'image', 'audio', 'video', 'document', 'table', 'code', 'json', 'url', 'location', 'time', 'sensor', 'binary'],
  allowed_output_modalities: ['text', 'json', 'markdown', 'table', 'image', 'audio', 'document', 'code', 'action_plan'],
  default_output_modalities: ['text', 'json'],
  max_input_items: 32,
  max_total_bytes: 104857600,
  require_context_completeness: true,
  require_human_confirmation_for_derived_actions: true,
  enabled: true
};

DEFINE FUNCTION fn::select_multimodal_io_policy($tenant_id, $key) {
  LET $tenant_policy = SELECT * FROM multimodal_io_policies WHERE tenant_id = $tenant_id AND key = $key AND enabled = true LIMIT 1;
  IF count($tenant_policy) > 0 THEN { RETURN $tenant_policy[0]; };
  LET $global_policy = SELECT * FROM multimodal_io_policies WHERE tenant_id = NONE AND key = $key AND enabled = true LIMIT 1;
  IF count($global_policy) > 0 THEN { RETURN $global_policy[0]; };
  RETURN multimodal_io_policies:default;
};

DEFINE FUNCTION fn::infer_input_kind($media_type, $uri, $content_text, $metadata) {
  RETURN IF $metadata.input_kind != NONE THEN $metadata.input_kind ELSE IF $media_type != NONE AND string::starts_with($media_type, 'image/') THEN 'image' ELSE IF $media_type != NONE AND string::starts_with($media_type, 'audio/') THEN 'audio' ELSE IF $media_type != NONE AND string::starts_with($media_type, 'video/') THEN 'video' ELSE IF $media_type IN ['application/pdf', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'text/html'] THEN 'document' ELSE IF $media_type IN ['text/csv', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'] THEN 'table' ELSE IF $media_type IN ['application/json', 'application/ld+json'] THEN 'json' ELSE IF $media_type != NONE AND string::starts_with($media_type, 'text/') THEN 'text' ELSE IF $uri != NONE THEN 'url' ELSE IF $content_text != NONE THEN 'text' ELSE 'binary' END END END END END END END END END END;
};

DEFINE FUNCTION fn::start_multimodal_session($tenant_id, $agent_id, $subject_id, $conversation_id, $message_id, $policy_key, $requested_output_modalities) {
  LET $policy = fn::select_multimodal_io_policy($tenant_id, $policy_key);
  LET $obs = fn::create_observation_run($tenant_id, $agent_id, 'multimodal_io_session', 'agx:multimodal-io-v1');
  LET $outputs = IF count($requested_output_modalities) = 0 THEN $policy.default_output_modalities ELSE $requested_output_modalities END;
  LET $invalid_outputs = array::filter($outputs, |$m| !$m INSIDE $policy.allowed_output_modalities);
  IF count($invalid_outputs) > 0 THEN { THROW 'unsupported_output_modality'; };
  LET $session = CREATE multimodal_sessions CONTENT { tenant_id: $tenant_id, agent_id: $agent_id, subject_id: $subject_id, conversation_id: $conversation_id, message_id: $message_id, policy_id: $policy.id, requested_output_modalities: $outputs, detected_input_modalities: [], status: 'collecting_inputs', observation_run_id: $obs.id, created_at: time::now() };
  fn::add_observation_step($obs.id, 1, 'start_multimodal_session', { requested_output_modalities: $outputs }, { session_id: $session.id, policy_id: $policy.id }, 'completed', 'agx:multimodal-io-v1');
  RETURN $session;
};

DEFINE FUNCTION fn::add_multimodal_input($tenant_id, $session_id, $media_type, $uri, $content_text, $payload_ref, $payload_hash, $byte_size, $metadata) {
  LET $session = SELECT * FROM $session_id;
  IF count($session) = 0 THEN { THROW 'multimodal_session_not_found'; };
  LET $policy = SELECT * FROM $session[0].policy_id;
  LET $existing = SELECT * FROM multimodal_inputs WHERE session_id = $session_id;
  IF count($existing) >= $policy[0].max_input_items THEN { THROW 'too_many_multimodal_inputs'; };
  LET $total_bytes = math::sum($existing[*].byte_size) + $byte_size;
  IF $total_bytes > $policy[0].max_total_bytes THEN { THROW 'multimodal_input_bytes_exceed_policy'; };
  LET $kind = fn::infer_input_kind($media_type, $uri, $content_text, $metadata);
  IF !$kind INSIDE $policy[0].accepted_input_modalities THEN { THROW 'unsupported_input_modality'; };
  LET $input = CREATE multimodal_inputs CONTENT { tenant_id: $tenant_id, session_id: $session_id, input_kind: $kind, media_type: $media_type, uri: $uri, content_text: $content_text, payload_ref: $payload_ref, payload_hash: $payload_hash, byte_size: $byte_size, metadata: $metadata, extracted_context: {}, processing_status: 'pending', created_at: time::now() };
  UPDATE $session_id SET detected_input_modalities = array::distinct(array::concat(detected_input_modalities, [$kind]));
  fn::add_observation_step($session[0].observation_run_id, 10 + count($existing), 'add_multimodal_input', { media_type: $media_type, byte_size: $byte_size }, { input_id: $input.id, input_kind: $kind }, 'completed', 'agx:multimodal-io-v1');
  RETURN $input;
};

DEFINE FUNCTION fn::derive_multimodal_processors($input_modalities, $output_modalities) {
  LET $processors = [];
  IF 'image' INSIDE $input_modalities THEN { LET $processors += [{ processor: 'vision_understanding', purpose: 'extract visual entities, text, layout and scene context' }]; };
  IF 'audio' INSIDE $input_modalities THEN { LET $processors += [{ processor: 'audio_transcription', purpose: 'transcribe speech and audio cues' }]; };
  IF 'video' INSIDE $input_modalities THEN { LET $processors += [{ processor: 'video_scene_understanding', purpose: 'sample frames, transcribe audio and track temporal events' }]; };
  IF 'document' INSIDE $input_modalities THEN { LET $processors += [{ processor: 'document_parser', purpose: 'extract pages, structure, entities and citations' }]; };
  IF 'table' INSIDE $input_modalities THEN { LET $processors += [{ processor: 'table_parser', purpose: 'normalize rows, columns, metrics and relationships' }]; };
  IF 'code' INSIDE $input_modalities THEN { LET $processors += [{ processor: 'code_analyzer', purpose: 'parse code structure and execution intent' }]; };
  IF 'json' INSIDE $input_modalities THEN { LET $processors += [{ processor: 'jsonld_semantic_mapper', purpose: 'map structured data into semantic graph' }]; };
  IF 'url' INSIDE $input_modalities THEN { LET $processors += [{ processor: 'url_fetch_and_grounding', purpose: 'fetch and ground remote source' }]; };
  IF 'location' INSIDE $input_modalities THEN { LET $processors += [{ processor: 'location_normalizer', purpose: 'normalize plus code and geospatial context' }]; };
  IF 'time' INSIDE $input_modalities THEN { LET $processors += [{ processor: 'temporal_normalizer', purpose: 'normalize time and validity intervals' }]; };
  IF count($output_modalities) > 0 THEN { LET $processors += [{ processor: 'multimodal_response_composer', purpose: 'compose requested output modalities' }]; };
  RETURN $processors;
};

DEFINE FUNCTION fn::plan_multimodal_processing($session_id, $task_kind, $risk_level, $input_tokens_estimate, $output_tokens_estimate) {
  LET $session = SELECT * FROM $session_id;
  IF count($session) = 0 THEN { THROW 'multimodal_session_not_found'; };
  LET $inputs = SELECT * FROM multimodal_inputs WHERE session_id = $session_id;
  IF count($inputs) = 0 THEN { THROW 'multimodal_inputs_required'; };
  LET $input_modalities = array::distinct($inputs[*].input_kind);
  LET $processors = fn::derive_multimodal_processors($input_modalities, $session[0].requested_output_modalities);
  LET $llm_run = fn::start_llm_selection($session[0].tenant_id, $session[0].agent_id, $session[0].subject_id, $task_kind, $risk_level, 'default', $input_tokens_estimate, $output_tokens_estimate, [{ kind: 'modalities', input: $input_modalities, output: $session[0].requested_output_modalities }]);
  LET $plan = CREATE multimodal_processing_plans CONTENT { tenant_id: $session[0].tenant_id, session_id: $session_id, plan_kind: 'auto_selected', input_modalities: $input_modalities, output_modalities: $session[0].requested_output_modalities, processors: $processors, routing_reason: { input_modalities: $input_modalities, output_modalities: $session[0].requested_output_modalities, task_kind: $task_kind }, estimated_cost_usd: 0, estimated_latency_ms: 0, selected_llm_run_id: $llm_run.id, status: 'planned', created_at: time::now() };
  UPDATE $session_id SET selected_processing_plan_id = $plan.id, status = 'planned';
  fn::add_observation_step($session[0].observation_run_id, 100, 'plan_multimodal_processing', { input_modalities: $input_modalities, output_modalities: $session[0].requested_output_modalities }, { plan_id: $plan.id, processors: $processors, llm_selection_run_id: $llm_run.id }, 'completed', 'agx:multimodal-io-v1');
  RETURN $plan;
};

DEFINE FUNCTION fn::record_multimodal_extraction($input_id, $extracted_context, $detected_entity_ids) {
  LET $input = SELECT * FROM $input_id;
  IF count($input) = 0 THEN { THROW 'multimodal_input_not_found'; };
  UPDATE $input_id SET extracted_context = $extracted_context, detected_entities = $detected_entity_ids, processing_status = 'processed';
  RETURN SELECT * FROM $input_id;
};

DEFINE FUNCTION fn::compose_execution_context_from_multimodal($session_id, $task_kind, $constraints) {
  LET $session = SELECT * FROM $session_id;
  IF count($session) = 0 THEN { THROW 'multimodal_session_not_found'; };
  LET $inputs = SELECT * FROM multimodal_inputs WHERE session_id = $session_id;
  LET $base = { environment: NONE, tool: NONE, actions_requested: NONE, expected_outcome: NONE, target_audience: NONE, necessary_data: { multimodal_inputs: $inputs[*].id, extracted_contexts: $inputs[*].extracted_context, input_modalities: array::distinct($inputs[*].input_kind) } };
  RETURN fn::prepare_prompt_context_before_execution($session[0].tenant_id, $session[0].subject_id, $session[0].conversation_id, $session[0].message_id, $task_kind, $base, $constraints);
};

DEFINE FUNCTION fn::record_multimodal_output($tenant_id, $session_id, $plan_id, $output_kind, $media_type, $content_text, $payload_ref, $payload_hash, $metadata, $quality_score) {
  LET $session = SELECT * FROM $session_id;
  IF count($session) = 0 THEN { THROW 'multimodal_session_not_found'; };
  LET $policy = SELECT * FROM $session[0].policy_id;
  IF !$output_kind INSIDE $policy[0].allowed_output_modalities THEN { THROW 'unsupported_output_modality'; };
  LET $output = CREATE multimodal_outputs CONTENT { tenant_id: $tenant_id, session_id: $session_id, plan_id: $plan_id, output_kind: $output_kind, media_type: $media_type, content_text: $content_text, payload_ref: $payload_ref, payload_hash: $payload_hash, metadata: $metadata, quality_score: $quality_score, created_at: time::now() };
  RETURN $output;
};

DEFINE FUNCTION fn::finalize_multimodal_session($session_id, $success, $quality_score) {
  LET $session = SELECT * FROM $session_id;
  IF count($session) = 0 THEN { THROW 'multimodal_session_not_found'; };
  LET $outputs = SELECT * FROM multimodal_outputs WHERE session_id = $session_id;
  IF count($outputs) = 0 THEN { THROW 'multimodal_outputs_required'; };
  UPDATE $session_id SET status = IF $success THEN 'completed' ELSE 'failed' END, completed_at = time::now();
  fn::record_reliability_event($session[0].tenant_id, $session[0].subject_id, 'multimodal_io', IF $success THEN 'success' ELSE 'failure' END, IF $quality_score = NONE THEN 0.5 ELSE $quality_score END, NONE, string::concat($session_id), { output_count: count($outputs), modalities: $outputs[*].output_kind });
  fn::finish_observation_run($session[0].observation_run_id, IF $success THEN 'completed' ELSE 'failed' END, { output_count: count($outputs), quality_score: $quality_score });
  RETURN SELECT * FROM $session_id;
};
