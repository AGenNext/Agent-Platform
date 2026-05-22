DEFINE FUNCTION fn::start_retrieval_run($tenant_id, $agent_id, $query_text, $query_context) {
  LET $run = CREATE retrieval_runs CONTENT {
    tenant_id: $tenant_id,
    agent_id: $agent_id,
    query_text: $query_text,
    query_context: $query_context,
    status: 'running',
    strategy: 'hybrid_graph_multimodal',
    semantic_id: rand::uuid(),
    jsonld_context: { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' },
    jsonld_type: ['schema:SearchAction', 'agx:RetrievalRun'],
    source_grounding_refs: ['microsoft:graphrag', 'arxiv:2510.12323'],
    started_at: time::now()
  };

  CREATE retrieval_steps CONTENT {
    tenant_id: $tenant_id,
    retrieval_run_id: $run.id,
    sequence: 1,
    step_kind: 'start_retrieval_run',
    input: { query_text: $query_text, query_context: $query_context },
    output: { retrieval_run_id: $run.id },
    status: 'completed',
    semantic_id: rand::uuid(),
    jsonld_context: { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' },
    jsonld_type: ['schema:Action', 'agx:RetrievalStep'],
    observed_at: time::now()
  };

  RETURN $run;
};

DEFINE FUNCTION fn::ingest_source_document($tenant_id, $corpus_id, $name, $uri, $content_hash) {
  LET $document = CREATE source_documents CONTENT {
    tenant_id: $tenant_id,
    corpus_id: $corpus_id,
    name: $name,
    uri: $uri,
    content_hash: $content_hash,
    semantic_id: rand::uuid(),
    jsonld_context: { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' },
    jsonld_type: ['schema:DigitalDocument', 'schema:CreativeWork'],
    source_grounding_refs: [],
    created_at: time::now()
  };

  RELATE $corpus_id->contains_document->$document.id SET tenant_id = $tenant_id;

  RETURN $document;
};

DEFINE FUNCTION fn::add_document_region($tenant_id, $document_id, $region_kind, $page_number, $bounding_box, $text) {
  LET $region = CREATE document_regions CONTENT {
    tenant_id: $tenant_id,
    document_id: $document_id,
    region_kind: $region_kind,
    page_number: $page_number,
    bounding_box: $bounding_box,
    text: $text,
    semantic_id: rand::uuid(),
    jsonld_context: { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' },
    jsonld_type: ['schema:CreativeWork', 'agx:DocumentRegion'],
    created_at: time::now()
  };

  RELATE $document_id->has_region->$region.id SET tenant_id = $tenant_id;

  RETURN $region;
};

DEFINE FUNCTION fn::add_knowledge_chunk($tenant_id, $document_id, $region_id, $content, $chunk_kind, $embedding_ref) {
  LET $chunk = CREATE knowledge_chunks CONTENT {
    tenant_id: $tenant_id,
    document_id: $document_id,
    region_id: $region_id,
    content: $content,
    chunk_kind: $chunk_kind,
    semantic_id: rand::uuid(),
    jsonld_context: { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' },
    jsonld_type: ['schema:CreativeWork', 'agx:KnowledgeChunk'],
    embedding_ref: $embedding_ref,
    created_at: time::now()
  };

  IF $region_id != NONE THEN {
    RELATE $region_id->has_chunk->$chunk.id SET tenant_id = $tenant_id;
  } ELSE {
    RELATE $document_id->has_chunk->$chunk.id SET tenant_id = $tenant_id;
  };

  RETURN $chunk;
};

DEFINE FUNCTION fn::upsert_knowledge_entity($tenant_id, $name, $entity_kind, $aliases) {
  LET $sid = string::concat('urn:agx:entity:', string::slug($name));
  LET $existing = SELECT * FROM knowledge_entities WHERE tenant_id = $tenant_id AND semantic_id = $sid LIMIT 1;

  IF count($existing) > 0 THEN {
    RETURN $existing[0];
  } ELSE {
    RETURN CREATE knowledge_entities CONTENT {
      tenant_id: $tenant_id,
      name: $name,
      entity_kind: $entity_kind,
      semantic_id: $sid,
      aliases: $aliases,
      jsonld_context: { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' },
      jsonld_type: ['schema:Thing', 'agx:KnowledgeEntity'],
      created_at: time::now()
    };
  };
};

DEFINE FUNCTION fn::link_chunk_entity($tenant_id, $chunk_id, $entity_id) {
  LET $chunk = SELECT * FROM $chunk_id;
  LET $entity = SELECT * FROM $entity_id;

  IF count($chunk) = 0 OR count($entity) = 0 THEN {
    THROW 'chunk_or_entity_not_found';
  };

  IF $chunk[0].tenant_id != $tenant_id OR $entity[0].tenant_id != $tenant_id THEN {
    THROW 'cross_tenant_edge_rejected';
  };

  RETURN RELATE $chunk_id->mentions_entity->$entity_id SET tenant_id = $tenant_id;
};

DEFINE FUNCTION fn::link_cross_modal($tenant_id, $from_id, $to_id, $score) {
  LET $from = SELECT * FROM $from_id;
  LET $to = SELECT * FROM $to_id;

  IF count($from) = 0 OR count($to) = 0 THEN {
    THROW 'cross_modal_endpoint_not_found';
  };

  IF $from[0].tenant_id != $tenant_id OR $to[0].tenant_id != $tenant_id THEN {
    THROW 'cross_tenant_edge_rejected';
  };

  RETURN RELATE $from_id->cross_modal_related_to->$to_id SET tenant_id = $tenant_id, relation_score = $score;
};

DEFINE FUNCTION fn::link_text_semantic($tenant_id, $from_id, $to_id, $score) {
  LET $from = SELECT * FROM $from_id;
  LET $to = SELECT * FROM $to_id;

  IF count($from) = 0 OR count($to) = 0 THEN {
    THROW 'text_semantic_endpoint_not_found';
  };

  IF $from[0].tenant_id != $tenant_id OR $to[0].tenant_id != $tenant_id THEN {
    THROW 'cross_tenant_edge_rejected';
  };

  RETURN RELATE $from_id->text_semantically_related_to->$to_id SET tenant_id = $tenant_id, relation_score = $score;
};

DEFINE FUNCTION fn::record_retrieved_evidence($tenant_id, $retrieval_run_id, $evidence_ref, $evidence_kind, $score, $graph_distance, $modality_support) {
  LET $evidence = CREATE retrieved_evidence CONTENT {
    tenant_id: $tenant_id,
    retrieval_run_id: $retrieval_run_id,
    evidence_ref: $evidence_ref,
    evidence_kind: $evidence_kind,
    score: $score,
    graph_distance: $graph_distance,
    modality_support: $modality_support,
    semantic_id: rand::uuid(),
    jsonld_context: { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' },
    jsonld_type: ['schema:CreativeWork', 'agx:RetrievedEvidence'],
    created_at: time::now()
  };

  RELATE $retrieval_run_id->retrieval_returned_evidence->$evidence.id SET tenant_id = $tenant_id;
  RELATE $evidence.id->evidence_supported_by->$evidence_ref SET tenant_id = $tenant_id;

  RETURN $evidence;
};

DEFINE FUNCTION fn::critique_evidence($tenant_id, $retrieval_run_id, $evidence_id, $relevance_score, $cultural_alignment_score, $citation_quality_score, $contradiction_score, $explanation) {
  RETURN CREATE evidence_critiques CONTENT {
    tenant_id: $tenant_id,
    retrieval_run_id: $retrieval_run_id,
    evidence_id: $evidence_id,
    relevance_score: $relevance_score,
    cultural_alignment_score: $cultural_alignment_score,
    citation_quality_score: $citation_quality_score,
    contradiction_score: $contradiction_score,
    explanation: $explanation,
    semantic_id: rand::uuid(),
    jsonld_context: { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' },
    jsonld_type: ['schema:Review', 'agx:EvidenceCritique'],
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::check_retrieval_sufficiency($tenant_id, $retrieval_run_id, $sufficiency_score, $missing_evidence) {
  LET $sufficient = $sufficiency_score >= 0.75;
  LET $decision = IF $sufficient THEN 'generate' ELSE 'iterate' END;

  LET $check = CREATE evidence_sufficiency_checks CONTENT {
    tenant_id: $tenant_id,
    retrieval_run_id: $retrieval_run_id,
    sufficient: $sufficient,
    sufficiency_score: $sufficiency_score,
    missing_evidence: $missing_evidence,
    decision: $decision,
    semantic_id: rand::uuid(),
    jsonld_context: { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' },
    jsonld_type: ['schema:Action', 'agx:EvidenceSufficiencyCheck'],
    created_at: time::now()
  };

  CREATE retrieval_steps CONTENT {
    tenant_id: $tenant_id,
    retrieval_run_id: $retrieval_run_id,
    sequence: 900,
    step_kind: 'evidence_sufficiency_check',
    input: { retrieval_run_id: $retrieval_run_id },
    output: { sufficient: $sufficient, sufficiency_score: $sufficiency_score, decision: $decision },
    status: 'completed',
    semantic_id: rand::uuid(),
    jsonld_context: { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' },
    jsonld_type: ['schema:Action', 'agx:RetrievalStep'],
    observed_at: time::now()
  };

  IF $sufficient THEN {
    UPDATE $retrieval_run_id SET status = 'completed', ended_at = time::now();
  } ELSE {
    UPDATE $retrieval_run_id SET status = 'needs_iteration';
  };

  RETURN $check;
};
