-- Agent DB Runtime Meta Model SurrealQL Design Schema
-- Status: design artifact only.
-- Do not include in runtime load order until validated.

DEFINE TABLE organization SCHEMAFULL;
DEFINE FIELD name ON organization TYPE string;
DEFINE FIELD industry ON organization TYPE option<string>;
DEFINE FIELD status ON organization TYPE string DEFAULT 'active';

DEFINE TABLE work_definition SCHEMAFULL;
DEFINE FIELD organization ON work_definition TYPE record<organization>;
DEFINE FIELD unit_name ON work_definition TYPE string;
DEFINE FIELD unit_description ON work_definition TYPE option<string>;
DEFINE FIELD measurement_rule ON work_definition TYPE string;
DEFINE FIELD evidence_required ON work_definition TYPE array<string> DEFAULT [];
DEFINE FIELD completion_criteria ON work_definition TYPE array<string> DEFAULT [];
DEFINE FIELD version ON work_definition TYPE string;

DEFINE TABLE unit_of_work SCHEMAFULL;
DEFINE FIELD work_definition ON unit_of_work TYPE record<work_definition>;
DEFINE FIELD planned_units ON unit_of_work TYPE number DEFAULT 0;
DEFINE FIELD completed_units ON unit_of_work TYPE number DEFAULT 0;
DEFINE FIELD progress ON unit_of_work TYPE number DEFAULT 0;

DEFINE TABLE project SCHEMAFULL;
DEFINE FIELD name ON project TYPE string;
DEFINE FIELD scope ON project TYPE string;
DEFINE FIELD owner ON project TYPE option<record<identity>>;
DEFINE FIELD status ON project TYPE string DEFAULT 'active';

DEFINE TABLE milestone SCHEMAFULL;
DEFINE FIELD project ON milestone TYPE record<project>;
DEFINE FIELD name ON milestone TYPE string;
DEFINE FIELD deadline ON milestone TYPE option<datetime>;
DEFINE FIELD status ON milestone TYPE string DEFAULT 'active';

DEFINE TABLE task SCHEMAFULL;
DEFINE FIELD project ON task TYPE record<project>;
DEFINE FIELD milestone ON task TYPE option<record<milestone>>;
DEFINE FIELD work_definition ON task TYPE option<record<work_definition>>;
DEFINE FIELD title ON task TYPE string;
DEFINE FIELD status ON task TYPE string DEFAULT 'open';
DEFINE FIELD planned_units ON task TYPE option<number>;
DEFINE FIELD completed_units ON task TYPE option<number>;
DEFINE FIELD progress ON task TYPE number DEFAULT 0;
DEFINE FIELD owner ON task TYPE option<record<identity>>;
DEFINE FIELD assignee ON task TYPE option<record<identity>>;

DEFINE TABLE identity SCHEMAFULL;
DEFINE FIELD identity_type ON identity TYPE string;
DEFINE FIELD display_name ON identity TYPE string;
DEFINE FIELD status ON identity TYPE string DEFAULT 'active';

DEFINE TABLE credential SCHEMAFULL;
DEFINE FIELD identity ON credential TYPE record<identity>;
DEFINE FIELD credential_type ON credential TYPE string;
DEFINE FIELD issuer ON credential TYPE option<string>;
DEFINE FIELD verification_state ON credential TYPE string DEFAULT 'unverified';

DEFINE TABLE operator SCHEMAFULL;
DEFINE FIELD operator_type ON operator TYPE string;
DEFINE FIELD identity ON operator TYPE record<identity>;
DEFINE FIELD status ON operator TYPE string DEFAULT 'active';

DEFINE TABLE skill SCHEMAFULL;
DEFINE FIELD name ON skill TYPE string;
DEFINE FIELD version ON skill TYPE string;
DEFINE FIELD status ON skill TYPE string DEFAULT 'draft';
DEFINE FIELD evaluation_criteria ON skill TYPE array<string> DEFAULT [];

DEFINE TABLE runtime_interface SCHEMAFULL;
DEFINE FIELD name ON runtime_interface TYPE string;
DEFINE FIELD version ON runtime_interface TYPE option<string>;

DEFINE TABLE runtime_api SCHEMAFULL;
DEFINE FIELD name ON runtime_api TYPE string;
DEFINE FIELD api_type ON runtime_api TYPE string;

DEFINE TABLE protocol SCHEMAFULL;
DEFINE FIELD name ON protocol TYPE string;
DEFINE FIELD version ON protocol TYPE option<string>;

DEFINE TABLE protocol_binding SCHEMAFULL;
DEFINE FIELD protocol ON protocol_binding TYPE record<protocol>;
DEFINE FIELD entity_id ON protocol_binding TYPE string;
DEFINE FIELD conformance_state ON protocol_binding TYPE string DEFAULT 'unverified';

DEFINE TABLE toolkit SCHEMAFULL;
DEFINE FIELD name ON toolkit TYPE string;

DEFINE TABLE tool SCHEMAFULL;
DEFINE FIELD name ON tool TYPE string;
DEFINE FIELD tool_type ON tool TYPE string;
DEFINE FIELD outside_kernel ON tool TYPE bool DEFAULT true;
DEFINE FIELD data_source ON tool TYPE bool DEFAULT false;
DEFINE FIELD evidence_source ON tool TYPE bool DEFAULT false;
DEFINE FIELD reconstruction_source ON tool TYPE bool DEFAULT false;
DEFINE FIELD documentation_source ON tool TYPE option<string>;
DEFINE FIELD supported_operations ON tool TYPE array<string> DEFAULT [];

DEFINE TABLE registry_platform SCHEMAFULL;
DEFINE FIELD name ON registry_platform TYPE string;

DEFINE TABLE registry SCHEMAFULL;
DEFINE FIELD name ON registry TYPE string;

DEFINE TABLE registry_entry SCHEMAFULL;
DEFINE FIELD registry ON registry_entry TYPE record<registry>;
DEFINE FIELD card ON registry_entry TYPE record<card>;
DEFINE FIELD status ON registry_entry TYPE string DEFAULT 'active';

DEFINE TABLE card SCHEMAFULL;
DEFINE FIELD kind ON card TYPE string;
DEFINE FIELD name ON card TYPE string;
DEFINE FIELD display_name ON card TYPE option<string>;
DEFINE FIELD version ON card TYPE string;
DEFINE FIELD status ON card TYPE string DEFAULT 'draft';
DEFINE FIELD owner ON card TYPE option<record<identity>>;
DEFINE FIELD issuer ON card TYPE option<record<registry_platform>>;
DEFINE FIELD dependencies ON card TYPE array<record<card>> DEFAULT [];
DEFINE FIELD body ON card TYPE object DEFAULT {};

DEFINE TABLE signature SCHEMAFULL;
DEFINE FIELD card ON signature TYPE record<card>;
DEFINE FIELD signed ON signature TYPE bool DEFAULT false;
DEFINE FIELD issuer ON signature TYPE option<record<registry_platform>>;
DEFINE FIELD signature_ref ON signature TYPE option<string>;
DEFINE FIELD signed_at ON signature TYPE option<datetime>;
DEFINE FIELD signing_key_ref ON signature TYPE option<string>;
DEFINE FIELD digest ON signature TYPE option<string>;

DEFINE TABLE verification SCHEMAFULL;
DEFINE FIELD card ON verification TYPE option<record<card>>;
DEFINE FIELD verified ON verification TYPE bool DEFAULT false;
DEFINE FIELD verified_by ON verification TYPE option<record<identity>>;
DEFINE FIELD verified_at ON verification TYPE option<datetime>;
DEFINE FIELD verification_method ON verification TYPE option<string>;
DEFINE FIELD evidence ON verification TYPE array<record<evidence>> DEFAULT [];
DEFINE FIELD capability_verified ON verification TYPE bool DEFAULT false;
DEFINE FIELD verification_state ON verification TYPE string DEFAULT 'unverified';

DEFINE TABLE certification SCHEMAFULL;
DEFINE FIELD card ON certification TYPE record<card>;
DEFINE FIELD certified ON certification TYPE bool DEFAULT false;
DEFINE FIELD certification_state ON certification TYPE string DEFAULT 'not-certified';
DEFINE FIELD certified_by ON certification TYPE option<record<identity>>;
DEFINE FIELD certified_at ON certification TYPE option<datetime>;
DEFINE FIELD expires_at ON certification TYPE option<datetime>;
DEFINE FIELD scope ON certification TYPE object DEFAULT {};
DEFINE FIELD evidence ON certification TYPE array<record<evidence>> DEFAULT [];
DEFINE FIELD conditions ON certification TYPE array<string> DEFAULT [];
DEFINE FIELD rejection_reasons ON certification TYPE array<string> DEFAULT [];

DEFINE TABLE accreditation SCHEMAFULL;
DEFINE FIELD authority ON accreditation TYPE option<record<identity>>;
DEFINE FIELD accredited ON accreditation TYPE bool DEFAULT false;
DEFINE FIELD accreditation_state ON accreditation TYPE string DEFAULT 'not-accredited';
DEFINE FIELD accredited_by ON accreditation TYPE option<record<identity>>;
DEFINE FIELD accredited_at ON accreditation TYPE option<datetime>;
DEFINE FIELD expires_at ON accreditation TYPE option<datetime>;
DEFINE FIELD scope ON accreditation TYPE object DEFAULT {};
DEFINE FIELD evidence ON accreditation TYPE array<record<evidence>> DEFAULT [];
DEFINE FIELD conditions ON accreditation TYPE array<string> DEFAULT [];
DEFINE FIELD rejection_reasons ON accreditation TYPE array<string> DEFAULT [];

DEFINE TABLE recognition SCHEMAFULL;
DEFINE FIELD subject_card ON recognition TYPE option<record<card>>;
DEFINE FIELD recognition_state ON recognition TYPE string DEFAULT 'unknown';
DEFINE FIELD recognized_by ON recognition TYPE array<record<identity>> DEFAULT [];
DEFINE FIELD scope ON recognition TYPE object DEFAULT {};
DEFINE FIELD signals ON recognition TYPE array<string> DEFAULT [];
DEFINE FIELD score ON recognition TYPE option<number>;
DEFINE FIELD evidence ON recognition TYPE array<record<evidence>> DEFAULT [];
DEFINE FIELD bias_risk ON recognition TYPE option<string>;
DEFINE FIELD last_assessed_at ON recognition TYPE option<datetime>;

DEFINE TABLE qualification SCHEMAFULL;
DEFINE FIELD card ON qualification TYPE record<card>;
DEFINE FIELD qualified ON qualification TYPE bool DEFAULT false;
DEFINE FIELD qualification_state ON qualification TYPE string DEFAULT 'unknown';
DEFINE FIELD qualified_for ON qualification TYPE array<string> DEFAULT [];
DEFINE FIELD evidence ON qualification TYPE array<record<evidence>> DEFAULT [];
DEFINE FIELD qualification_reasons ON qualification TYPE array<string> DEFAULT [];
DEFINE FIELD disqualification_reasons ON qualification TYPE array<string> DEFAULT [];

DEFINE TABLE eligibility SCHEMAFULL;
DEFINE FIELD card ON eligibility TYPE record<card>;
DEFINE FIELD eligible ON eligibility TYPE bool DEFAULT false;
DEFINE FIELD eligibility_state ON eligibility TYPE string DEFAULT 'unknown';
DEFINE FIELD eligible_for ON eligibility TYPE array<string> DEFAULT [];
DEFINE FIELD required_conditions ON eligibility TYPE array<string> DEFAULT [];
DEFINE FIELD blocking_conditions ON eligibility TYPE array<string> DEFAULT [];
DEFINE FIELD rejection_reasons ON eligibility TYPE array<string> DEFAULT [];

DEFINE TABLE discovery_query SCHEMAFULL;
DEFINE FIELD need ON discovery_query TYPE string;
DEFINE FIELD project ON discovery_query TYPE option<record<project>>;
DEFINE FIELD task ON discovery_query TYPE option<record<task>>;

DEFINE TABLE discovery_candidate SCHEMAFULL;
DEFINE FIELD query ON discovery_candidate TYPE record<discovery_query>;
DEFINE FIELD card ON discovery_candidate TYPE record<card>;
DEFINE FIELD qualification ON discovery_candidate TYPE option<record<qualification>>;
DEFINE FIELD eligibility ON discovery_candidate TYPE option<record<eligibility>>;

DEFINE TABLE recommendation SCHEMAFULL;
DEFINE FIELD request ON recommendation TYPE string;
DEFINE FIELD candidates ON recommendation TYPE array<record<card>> DEFAULT [];
DEFINE FIELD recommended_card ON recommendation TYPE option<record<card>>;
DEFINE FIELD confidence ON recommendation TYPE option<number>;
DEFINE FIELD rationale ON recommendation TYPE option<string>;
DEFINE FIELD alternatives_considered ON recommendation TYPE array<record<card>> DEFAULT [];
DEFINE FIELD tradeoffs ON recommendation TYPE array<string> DEFAULT [];
DEFINE FIELD risks ON recommendation TYPE array<string> DEFAULT [];
DEFINE FIELD evidence ON recommendation TYPE array<record<evidence>> DEFAULT [];

DEFINE TABLE selection SCHEMAFULL;
DEFINE FIELD selected_card ON selection TYPE record<card>;
DEFINE FIELD selected_by ON selection TYPE option<record<identity>>;
DEFINE FIELD selected_at ON selection TYPE option<datetime>;
DEFINE FIELD selected_for ON selection TYPE option<string>;
DEFINE FIELD selection_reason ON selection TYPE string;
DEFINE FIELD evidence ON selection TYPE array<record<evidence>> DEFAULT [];

DEFINE TABLE rejection SCHEMAFULL;
DEFINE FIELD rejected_card ON rejection TYPE record<card>;
DEFINE FIELD rejected_by ON rejection TYPE option<record<identity>>;
DEFINE FIELD rejected_at ON rejection TYPE option<datetime>;
DEFINE FIELD rejection_reasons ON rejection TYPE array<string> DEFAULT [];
DEFINE FIELD alternatives_considered ON rejection TYPE array<record<card>> DEFAULT [];
DEFINE FIELD evidence ON rejection TYPE array<record<evidence>> DEFAULT [];

DEFINE TABLE action_invocation SCHEMAFULL;
DEFINE FIELD operator ON action_invocation TYPE option<record<operator>>;
DEFINE FIELD tool ON action_invocation TYPE option<record<tool>>;
DEFINE FIELD task ON action_invocation TYPE option<record<task>>;
DEFINE FIELD operation ON action_invocation TYPE string;
DEFINE FIELD status ON action_invocation TYPE string DEFAULT 'draft';

DEFINE TABLE protocol_message SCHEMAFULL;
DEFINE FIELD protocol ON protocol_message TYPE record<protocol>;
DEFINE FIELD action_invocation ON protocol_message TYPE option<record<action_invocation>>;
DEFINE FIELD direction ON protocol_message TYPE string;
DEFINE FIELD payload_ref ON protocol_message TYPE option<string>;

DEFINE TABLE decision SCHEMAFULL;
DEFINE FIELD task ON decision TYPE option<record<task>>;
DEFINE FIELD rationale ON decision TYPE string;
DEFINE FIELD selected_option ON decision TYPE option<string>;
DEFINE FIELD tradeoffs ON decision TYPE array<string> DEFAULT [];

DEFINE TABLE evidence SCHEMAFULL;
DEFINE FIELD evidence_type ON evidence TYPE string;
DEFINE FIELD source ON evidence TYPE option<string>;
DEFINE FIELD artifact ON evidence TYPE option<record<artifact>>;
DEFINE FIELD source_anchor ON evidence TYPE option<record<source_anchor>>;
DEFINE FIELD created_at ON evidence TYPE datetime DEFAULT time::now();

DEFINE TABLE artifact SCHEMAFULL;
DEFINE FIELD artifact_type ON artifact TYPE string;
DEFINE FIELD uri ON artifact TYPE option<string>;
DEFINE FIELD hash ON artifact TYPE option<string>;
DEFINE FIELD signed ON artifact TYPE bool DEFAULT false;
DEFINE FIELD verification_state ON artifact TYPE string DEFAULT 'unverified';
DEFINE FIELD source_anchor ON artifact TYPE option<record<source_anchor>>;

DEFINE TABLE knowledge_candidate SCHEMAFULL;
DEFINE FIELD artifact ON knowledge_candidate TYPE record<artifact>;
DEFINE FIELD evidence ON knowledge_candidate TYPE array<record<evidence>> DEFAULT [];
DEFINE FIELD verification_state ON knowledge_candidate TYPE string DEFAULT 'unverified';

DEFINE TABLE knowledge SCHEMAFULL;
DEFINE FIELD source_artifact ON knowledge TYPE record<artifact>;
DEFINE FIELD canonical_source_anchor ON knowledge TYPE option<record<source_anchor>>;
DEFINE FIELD verification_state ON knowledge TYPE string DEFAULT 'unverified';
DEFINE FIELD governance_approved ON knowledge TYPE bool DEFAULT false;

DEFINE TABLE source_anchor SCHEMAFULL;
DEFINE FIELD source_url ON source_anchor TYPE option<string>;
DEFINE FIELD source_type ON source_anchor TYPE option<string>;
DEFINE FIELD source_authority ON source_anchor TYPE option<string>;
DEFINE FIELD source_publisher ON source_anchor TYPE option<string>;
DEFINE FIELD source_version ON source_anchor TYPE option<string>;
DEFINE FIELD source_published_at ON source_anchor TYPE option<datetime>;
DEFINE FIELD source_accessed_at ON source_anchor TYPE option<datetime>;
DEFINE FIELD source_hash ON source_anchor TYPE option<string>;
DEFINE FIELD source_confidence ON source_anchor TYPE option<number>;

DEFINE TABLE memory SCHEMAFULL;
DEFINE FIELD memory_type ON memory TYPE string;
DEFINE FIELD summary ON memory TYPE option<string>;
DEFINE FIELD artifact_pointers ON memory TYPE array<record<artifact>> DEFAULT [];
DEFINE FIELD knowledge_pointers ON memory TYPE array<record<knowledge>> DEFAULT [];
DEFINE FIELD source_anchors ON memory TYPE array<record<source_anchor>> DEFAULT [];
DEFINE FIELD reconstruction_instruction ON memory TYPE option<string>;
DEFINE FIELD retention_policy ON memory TYPE option<string>;

DEFINE TABLE rag_index SCHEMAFULL;
DEFINE FIELD name ON rag_index TYPE string;
DEFINE FIELD artifacts ON rag_index TYPE array<record<artifact>> DEFAULT [];
DEFINE FIELD knowledge ON rag_index TYPE array<record<knowledge>> DEFAULT [];
DEFINE FIELD source_anchors ON rag_index TYPE array<record<source_anchor>> DEFAULT [];
DEFINE FIELD chunk_metadata ON rag_index TYPE object DEFAULT {};

DEFINE TABLE evaluation SCHEMAFULL;
DEFINE FIELD subject_id ON evaluation TYPE string;
DEFINE FIELD evaluator ON evaluation TYPE option<record<identity>>;
DEFINE FIELD status ON evaluation TYPE string DEFAULT 'draft';
DEFINE FIELD evidence ON evaluation TYPE array<record<evidence>> DEFAULT [];

DEFINE TABLE score SCHEMAFULL;
DEFINE FIELD dimension ON score TYPE string;
DEFINE FIELD value ON score TYPE number;
DEFINE FIELD method ON score TYPE option<string>;
DEFINE FIELD evidence ON score TYPE array<record<evidence>> DEFAULT [];
DEFINE FIELD scored_at ON score TYPE option<datetime>;

DEFINE TABLE rating SCHEMAFULL;
DEFINE FIELD rater ON rating TYPE option<record<identity>>;
DEFINE FIELD value ON rating TYPE number;
DEFINE FIELD comment ON rating TYPE option<string>;
DEFINE FIELD rated_at ON rating TYPE option<datetime>;

DEFINE TABLE review SCHEMAFULL;
DEFINE FIELD reviewer ON review TYPE option<record<identity>>;
DEFINE FIELD rating ON review TYPE option<record<rating>>;
DEFINE FIELD comments ON review TYPE option<string>;
DEFINE FIELD recommendation ON review TYPE option<string>;
DEFINE FIELD evidence ON review TYPE array<record<evidence>> DEFAULT [];
DEFINE FIELD reviewed_at ON review TYPE option<datetime>;

DEFINE TABLE trust_assessment SCHEMAFULL;
DEFINE FIELD subject_id ON trust_assessment TYPE string;
DEFINE FIELD trust_level ON trust_assessment TYPE string;
DEFINE FIELD score ON trust_assessment TYPE number;
DEFINE FIELD evidence ON trust_assessment TYPE array<record<evidence>> DEFAULT [];

DEFINE TABLE trust_event SCHEMAFULL;
DEFINE FIELD trust_assessment ON trust_event TYPE record<trust_assessment>;
DEFINE FIELD event_type ON trust_event TYPE string;
DEFINE FIELD delta ON trust_event TYPE option<number>;
DEFINE FIELD evidence ON trust_event TYPE array<record<evidence>> DEFAULT [];
DEFINE FIELD created_at ON trust_event TYPE datetime DEFAULT time::now();

DEFINE TABLE incident SCHEMAFULL;
DEFINE FIELD severity ON incident TYPE string;
DEFINE FIELD status ON incident TYPE string DEFAULT 'open';
DEFINE FIELD evidence ON incident TYPE array<record<evidence>> DEFAULT [];

DEFINE TABLE sla SCHEMAFULL;
DEFINE FIELD name ON sla TYPE string;
DEFINE FIELD threshold ON sla TYPE string;

DEFINE TABLE commitment SCHEMAFULL;
DEFINE FIELD statement ON commitment TYPE string;

DEFINE TABLE duty SCHEMAFULL;
DEFINE FIELD description ON duty TYPE string;

DEFINE TABLE responsibility SCHEMAFULL;
DEFINE FIELD accountable_party ON responsibility TYPE record<identity>;
DEFINE FIELD description ON responsibility TYPE string;

DEFINE TABLE assurance SCHEMAFULL;
DEFINE FIELD assurance_type ON assurance TYPE string;

DEFINE TABLE insurance SCHEMAFULL;
DEFINE FIELD assurance ON insurance TYPE record<assurance>;
DEFINE FIELD risk_transferred ON insurance TYPE string;

DEFINE TABLE claim SCHEMAFULL;
DEFINE FIELD claim_type ON claim TYPE string;
DEFINE FIELD statement ON claim TYPE string;
DEFINE FIELD evidence ON claim TYPE array<record<evidence>> DEFAULT [];
DEFINE FIELD resolution ON claim TYPE option<record<resolution>>;

DEFINE TABLE resolution SCHEMAFULL;
DEFINE FIELD resolution_type ON resolution TYPE string;
DEFINE FIELD outcome ON resolution TYPE string;
DEFINE FIELD evidence ON resolution TYPE array<record<evidence>> DEFAULT [];
