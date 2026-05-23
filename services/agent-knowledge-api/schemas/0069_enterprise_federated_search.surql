-- AGenNext Platform
-- 0069: Enterprise federated search, deep search, semantic search, knowledge graph search, local/radius search
-- Purpose: provide governed enterprise search across internal systems, external search providers, documents, data lakes, knowledge graphs, schema.org entities, time/location-aware contexts, and local/radius discovery.

DEFINE TABLE enterprise_search_connectors SCHEMAFULL;
DEFINE FIELD tenant_id ON enterprise_search_connectors TYPE option<record<tenants>>;
DEFINE FIELD connector_key ON enterprise_search_connectors TYPE string;
DEFINE FIELD connector_name ON enterprise_search_connectors TYPE string;
DEFINE FIELD connector_kind ON enterprise_search_connectors TYPE string;
DEFINE FIELD provider_name ON enterprise_search_connectors TYPE string;
DEFINE FIELD capabilities ON enterprise_search_connectors TYPE array<string> DEFAULT [];
DEFINE FIELD supported_auth_modes ON enterprise_search_connectors TYPE array<string> DEFAULT [];
DEFINE FIELD result_policy ON enterprise_search_connectors TYPE string DEFAULT 'source_cited';
DEFINE FIELD source_of_record_policy ON enterprise_search_connectors TYPE string DEFAULT 'source_system_remains_authoritative';
DEFINE FIELD connection_status ON enterprise_search_connectors TYPE string DEFAULT 'pending';
DEFINE FIELD governance_status ON enterprise_search_connectors TYPE string DEFAULT 'review_required';
DEFINE FIELD active ON enterprise_search_connectors TYPE bool DEFAULT true;
DEFINE FIELD created_at ON enterprise_search_connectors TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON enterprise_search_connectors TYPE datetime DEFAULT time::now();
DEFINE INDEX enterprise_search_connector_unique ON enterprise_search_connectors FIELDS tenant_id, connector_key UNIQUE;

DEFINE TABLE enterprise_search_indexes SCHEMAFULL;
DEFINE FIELD tenant_id ON enterprise_search_indexes TYPE record<tenants>;
DEFINE FIELD index_key ON enterprise_search_indexes TYPE string;
DEFINE FIELD index_name ON enterprise_search_indexes TYPE string;
DEFINE FIELD index_kind ON enterprise_search_indexes TYPE string;
DEFINE FIELD source_refs ON enterprise_search_indexes TYPE array<string> DEFAULT [];
DEFINE FIELD supported_search_modes ON enterprise_search_indexes TYPE array<string> DEFAULT [];
DEFINE FIELD schema_org_entity_types ON enterprise_search_indexes TYPE array<string> DEFAULT [];
DEFINE FIELD embedding_model_ref ON enterprise_search_indexes TYPE option<string>;
DEFINE FIELD graph_ref ON enterprise_search_indexes TYPE option<string>;
DEFINE FIELD geo_enabled ON enterprise_search_indexes TYPE bool DEFAULT false;
DEFINE FIELD temporal_enabled ON enterprise_search_indexes TYPE bool DEFAULT false;
DEFINE FIELD access_policy_ref ON enterprise_search_indexes TYPE option<string>;
DEFINE FIELD status ON enterprise_search_indexes TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON enterprise_search_indexes TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON enterprise_search_indexes TYPE datetime DEFAULT time::now();
DEFINE INDEX enterprise_search_index_unique ON enterprise_search_indexes FIELDS tenant_id, index_key UNIQUE;

DEFINE TABLE enterprise_search_queries SCHEMAFULL;
DEFINE FIELD tenant_id ON enterprise_search_queries TYPE record<tenants>;
DEFINE FIELD query_ref ON enterprise_search_queries TYPE string;
DEFINE FIELD query_text ON enterprise_search_queries TYPE string;
DEFINE FIELD search_modes ON enterprise_search_queries TYPE array<string> DEFAULT ['federated'];
DEFINE FIELD target_connector_keys ON enterprise_search_queries TYPE array<string> DEFAULT [];
DEFINE FIELD target_index_keys ON enterprise_search_queries TYPE array<string> DEFAULT [];
DEFINE FIELD entity_filters ON enterprise_search_queries TYPE array<object> DEFAULT [];
DEFINE FIELD time_context ON enterprise_search_queries TYPE object DEFAULT {};
DEFINE FIELD location_context ON enterprise_search_queries TYPE object DEFAULT {};
DEFINE FIELD radius_context ON enterprise_search_queries TYPE object DEFAULT {};
DEFINE FIELD requester_person_id ON enterprise_search_queries TYPE option<record<identity_persons>>;
DEFINE FIELD requester_role ON enterprise_search_queries TYPE option<string>;
DEFINE FIELD governance_status ON enterprise_search_queries TYPE string DEFAULT 'allowed';
DEFINE FIELD created_at ON enterprise_search_queries TYPE datetime DEFAULT time::now();
DEFINE INDEX enterprise_search_query_ref_unique ON enterprise_search_queries FIELDS query_ref UNIQUE;

DEFINE TABLE enterprise_search_results SCHEMAFULL;
DEFINE FIELD tenant_id ON enterprise_search_results TYPE record<tenants>;
DEFINE FIELD query_id ON enterprise_search_results TYPE record<enterprise_search_queries>;
DEFINE FIELD result_ref ON enterprise_search_results TYPE string;
DEFINE FIELD source_connector_key ON enterprise_search_results TYPE string;
DEFINE FIELD source_record_ref ON enterprise_search_results TYPE option<string>;
DEFINE FIELD title ON enterprise_search_results TYPE string;
DEFINE FIELD snippet ON enterprise_search_results TYPE option<string>;
DEFINE FIELD result_kind ON enterprise_search_results TYPE string;
DEFINE FIELD entity_type ON enterprise_search_results TYPE option<string>;
DEFINE FIELD schema_org_type ON enterprise_search_results TYPE option<string>;
DEFINE FIELD score ON enterprise_search_results TYPE number DEFAULT 0;
DEFINE FIELD semantic_score ON enterprise_search_results TYPE option<number>;
DEFINE FIELD graph_score ON enterprise_search_results TYPE option<number>;
DEFINE FIELD temporal_score ON enterprise_search_results TYPE option<number>;
DEFINE FIELD geo_score ON enterprise_search_results TYPE option<number>;
DEFINE FIELD source_citation ON enterprise_search_results TYPE option<string>;
DEFINE FIELD location_context ON enterprise_search_results TYPE object DEFAULT {};
DEFINE FIELD time_context ON enterprise_search_results TYPE object DEFAULT {};
DEFINE FIELD metadata ON enterprise_search_results TYPE object DEFAULT {};
DEFINE FIELD created_at ON enterprise_search_results TYPE datetime DEFAULT time::now();
DEFINE INDEX enterprise_search_result_ref_unique ON enterprise_search_results FIELDS result_ref UNIQUE;

DEFINE TABLE enterprise_knowledge_graph_entities SCHEMAFULL;
DEFINE FIELD tenant_id ON enterprise_knowledge_graph_entities TYPE record<tenants>;
DEFINE FIELD entity_ref ON enterprise_knowledge_graph_entities TYPE string;
DEFINE FIELD entity_name ON enterprise_knowledge_graph_entities TYPE string;
DEFINE FIELD entity_type ON enterprise_knowledge_graph_entities TYPE string;
DEFINE FIELD schema_org_type ON enterprise_knowledge_graph_entities TYPE option<string>;
DEFINE FIELD identifiers ON enterprise_knowledge_graph_entities TYPE array<object> DEFAULT [];
DEFINE FIELD attributes ON enterprise_knowledge_graph_entities TYPE object DEFAULT {};
DEFINE FIELD source_refs ON enterprise_knowledge_graph_entities TYPE array<string> DEFAULT [];
DEFINE FIELD location_context ON enterprise_knowledge_graph_entities TYPE object DEFAULT {};
DEFINE FIELD time_context ON enterprise_knowledge_graph_entities TYPE object DEFAULT {};
DEFINE FIELD confidence_score ON enterprise_knowledge_graph_entities TYPE number DEFAULT 1;
DEFINE FIELD status ON enterprise_knowledge_graph_entities TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON enterprise_knowledge_graph_entities TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON enterprise_knowledge_graph_entities TYPE datetime DEFAULT time::now();
DEFINE INDEX enterprise_knowledge_graph_entity_ref_unique ON enterprise_knowledge_graph_entities FIELDS tenant_id, entity_ref UNIQUE;

DEFINE TABLE enterprise_search_saved_views SCHEMAFULL;
DEFINE FIELD tenant_id ON enterprise_search_saved_views TYPE record<tenants>;
DEFINE FIELD view_key ON enterprise_search_saved_views TYPE string;
DEFINE FIELD view_name ON enterprise_search_saved_views TYPE string;
DEFINE FIELD search_modes ON enterprise_search_saved_views TYPE array<string> DEFAULT [];
DEFINE FIELD default_filters ON enterprise_search_saved_views TYPE object DEFAULT {};
DEFINE FIELD target_personas ON enterprise_search_saved_views TYPE array<string> DEFAULT [];
DEFINE FIELD rbac_visibility_roles ON enterprise_search_saved_views TYPE array<string> DEFAULT [];
DEFINE FIELD status ON enterprise_search_saved_views TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON enterprise_search_saved_views TYPE datetime DEFAULT time::now();
DEFINE INDEX enterprise_search_saved_view_unique ON enterprise_search_saved_views FIELDS tenant_id, view_key UNIQUE;

DEFINE FUNCTION fn::register_enterprise_search_connector($tenant_id: option<record<tenants>>, $connector_key: string, $connector_name: string, $connector_kind: string, $provider_name: string, $capabilities: array<string>, $supported_auth_modes: array<string>) {
  RETURN UPSERT type::thing('enterprise_search_connectors', $connector_key) CONTENT {
    tenant_id: $tenant_id,
    connector_key: $connector_key,
    connector_name: $connector_name,
    connector_kind: $connector_kind,
    provider_name: $provider_name,
    capabilities: $capabilities,
    supported_auth_modes: $supported_auth_modes,
    result_policy: 'source_cited',
    source_of_record_policy: 'source_system_remains_authoritative',
    connection_status: 'connected',
    governance_status: 'active',
    active: true,
    created_at: time::now(),
    updated_at: time::now()
  };
};

DEFINE FUNCTION fn::create_enterprise_search_index($tenant_id: record<tenants>, $index_key: string, $index_name: string, $index_kind: string, $source_refs: array<string>, $supported_search_modes: array<string>, $schema_org_entity_types: array<string>, $geo_enabled: bool, $temporal_enabled: bool) {
  RETURN UPSERT type::thing('enterprise_search_indexes', string::concat(string::replace(string::from($tenant_id), ':', '_'), '_', $index_key)) CONTENT {
    tenant_id: $tenant_id,
    index_key: $index_key,
    index_name: $index_name,
    index_kind: $index_kind,
    source_refs: $source_refs,
    supported_search_modes: $supported_search_modes,
    schema_org_entity_types: $schema_org_entity_types,
    geo_enabled: $geo_enabled,
    temporal_enabled: $temporal_enabled,
    status: 'active',
    created_at: time::now(),
    updated_at: time::now()
  };
};

DEFINE FUNCTION fn::record_enterprise_search_query($tenant_id: record<tenants>, $query_text: string, $search_modes: array<string>, $target_connector_keys: array<string>, $target_index_keys: array<string>, $entity_filters: array<object>, $time_context: object, $location_context: object, $radius_context: object, $requester_person_id: option<record<identity_persons>>, $requester_role: option<string>) {
  RETURN CREATE enterprise_search_queries CONTENT {
    tenant_id: $tenant_id,
    query_ref: rand::uuid(),
    query_text: $query_text,
    search_modes: $search_modes,
    target_connector_keys: $target_connector_keys,
    target_index_keys: $target_index_keys,
    entity_filters: $entity_filters,
    time_context: $time_context,
    location_context: $location_context,
    radius_context: $radius_context,
    requester_person_id: $requester_person_id,
    requester_role: $requester_role,
    governance_status: 'allowed',
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::record_enterprise_search_result($tenant_id: record<tenants>, $query_id: record<enterprise_search_queries>, $source_connector_key: string, $source_record_ref: option<string>, $title: string, $snippet: option<string>, $result_kind: string, $entity_type: option<string>, $schema_org_type: option<string>, $score: number, $semantic_score: option<number>, $graph_score: option<number>, $temporal_score: option<number>, $geo_score: option<number>, $source_citation: option<string>, $location_context: object, $time_context: object, $metadata: object) {
  RETURN CREATE enterprise_search_results CONTENT {
    tenant_id: $tenant_id,
    query_id: $query_id,
    result_ref: rand::uuid(),
    source_connector_key: $source_connector_key,
    source_record_ref: $source_record_ref,
    title: $title,
    snippet: $snippet,
    result_kind: $result_kind,
    entity_type: $entity_type,
    schema_org_type: $schema_org_type,
    score: $score,
    semantic_score: $semantic_score,
    graph_score: $graph_score,
    temporal_score: $temporal_score,
    geo_score: $geo_score,
    source_citation: $source_citation,
    location_context: $location_context,
    time_context: $time_context,
    metadata: $metadata,
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::enterprise_search_context($tenant_id: record<tenants>) {
  RETURN {
    connectors: SELECT * FROM enterprise_search_connectors WHERE tenant_id = $tenant_id OR tenant_id = NONE ORDER BY connector_kind, connector_name,
    indexes: SELECT * FROM enterprise_search_indexes WHERE tenant_id = $tenant_id ORDER BY index_kind, index_name,
    saved_views: SELECT * FROM enterprise_search_saved_views WHERE tenant_id = $tenant_id AND status = 'active' ORDER BY view_name,
    recent_queries: SELECT * FROM enterprise_search_queries WHERE tenant_id = $tenant_id ORDER BY created_at DESC LIMIT 50,
    knowledge_graph_entities: SELECT * FROM enterprise_knowledge_graph_entities WHERE tenant_id = $tenant_id AND status = 'active' ORDER BY updated_at DESC LIMIT 50
  };
};

-- Built-in search connector templates.
CREATE enterprise_search_connectors:enterprise_full_text CONTENT { connector_key: 'enterprise_full_text', connector_name: 'Enterprise Full Text Search', connector_kind: 'full_text', provider_name: 'AGenNext', capabilities: ['full_text_search','fielded_search','faceted_search','highlighting','source_citation'], supported_auth_modes: ['tenant_rbac'], result_policy: 'source_cited', source_of_record_policy: 'source_system_remains_authoritative', connection_status: 'template', governance_status: 'review_required', active: true, created_at: time::now(), updated_at: time::now() };
CREATE enterprise_search_connectors:enterprise_semantic CONTENT { connector_key: 'enterprise_semantic', connector_name: 'Enterprise Semantic Search', connector_kind: 'semantic', provider_name: 'AGenNext', capabilities: ['semantic_search','hybrid_search','embedding_search','reranking','evidence_grounding'], supported_auth_modes: ['tenant_rbac'], result_policy: 'source_cited', source_of_record_policy: 'retrieval_index_not_source_of_record', connection_status: 'template', governance_status: 'review_required', active: true, created_at: time::now(), updated_at: time::now() };
CREATE enterprise_search_connectors:knowledge_graph_search CONTENT { connector_key: 'knowledge_graph_search', connector_name: 'Knowledge Graph Search', connector_kind: 'knowledge_graph', provider_name: 'AGenNext', capabilities: ['entity_search','relationship_search','path_search','schema_org_entity_search','graph_rag'], supported_auth_modes: ['tenant_rbac'], result_policy: 'source_cited', source_of_record_policy: 'graph_is_contextual_not_authoritative_unless_configured', connection_status: 'template', governance_status: 'review_required', active: true, created_at: time::now(), updated_at: time::now() };
CREATE enterprise_search_connectors:federated_deep_search CONTENT { connector_key: 'federated_deep_search', connector_name: 'Federated Deep Search', connector_kind: 'federated', provider_name: 'AGenNext', capabilities: ['multi_source_search','deep_search','query_planning','cross_source_reranking','evidence_synthesis'], supported_auth_modes: ['tenant_rbac','connector_delegated_auth'], result_policy: 'source_cited', source_of_record_policy: 'source_system_remains_authoritative', connection_status: 'template', governance_status: 'review_required', active: true, created_at: time::now(), updated_at: time::now() };
CREATE enterprise_search_connectors:google_custom_search CONTENT { connector_key: 'google_custom_search', connector_name: 'Google Custom Search', connector_kind: 'web_search', provider_name: 'Google', capabilities: ['web_search','site_restricted_search','source_citation','local_web_context'], supported_auth_modes: ['api_key','service_account'], result_policy: 'source_cited', source_of_record_policy: 'external_web_source', connection_status: 'template', governance_status: 'review_required', active: true, created_at: time::now(), updated_at: time::now() };
CREATE enterprise_search_connectors:searxng_metasearch CONTENT { connector_key: 'searxng_metasearch', connector_name: 'SearXNG Metasearch', connector_kind: 'metasearch', provider_name: 'SearXNG', capabilities: ['metasearch','privacy_preserving_search','source_citation','category_search'], supported_auth_modes: ['none','api_key','reverse_proxy_auth'], result_policy: 'source_cited', source_of_record_policy: 'external_sources', connection_status: 'template', governance_status: 'review_required', active: true, created_at: time::now(), updated_at: time::now() };
CREATE enterprise_search_connectors:local_radius_search CONTENT { connector_key: 'local_radius_search', connector_name: 'Local and Radius Search', connector_kind: 'geo_search', provider_name: 'AGenNext', capabilities: ['local_search','radius_search','nearby_entity_search','geo_filtering','time_location_aware_ranking'], supported_auth_modes: ['tenant_rbac','provider_api_key'], result_policy: 'source_cited', source_of_record_policy: 'location_source_remains_authoritative', connection_status: 'template', governance_status: 'review_required', active: true, created_at: time::now(), updated_at: time::now() };

-- Built-in saved search views.
CREATE enterprise_search_saved_views:enterprise_everything CONTENT { view_key: 'enterprise_everything', view_name: 'Enterprise Everything Search', search_modes: ['federated','full_text','semantic','knowledge_graph'], default_filters: {}, target_personas: ['it_admin','security','business_owner','auditor'], rbac_visibility_roles: ['tenant_admin','security_admin','auditor','business_owner'], status: 'active', created_at: time::now() };
CREATE enterprise_search_saved_views:time_location_search CONTENT { view_key: 'time_location_search', view_name: 'Time and Location Aware Search', search_modes: ['federated','semantic','geo','temporal'], default_filters: { temporal_enabled: true, geo_enabled: true }, target_personas: ['operations','field_team','customer_success','security'], rbac_visibility_roles: ['tenant_admin','operations_admin','security_admin'], status: 'active', created_at: time::now() };
CREATE enterprise_search_saved_views:schema_org_entity_search CONTENT { view_key: 'schema_org_entity_search', view_name: 'Schema.org Entity Search', search_modes: ['knowledge_graph','semantic','structured'], default_filters: { schema_org_enabled: true }, target_personas: ['data_steward','seo','content','commerce','knowledge_admin'], rbac_visibility_roles: ['tenant_admin','data_steward','content_admin'], status: 'active', created_at: time::now() };
