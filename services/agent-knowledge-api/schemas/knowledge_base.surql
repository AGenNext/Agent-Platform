-- Schema: knowledge_base
-- Managed RAG document collections for agent retrieval.
-- Sits above the raw memory table: a knowledge_base owns multiple documents,
-- each chunk-embedded and indexed for semantic + BM25 hybrid search.

-- ─── Knowledge base collection ───────────────────────────────────────────────

DEFINE TABLE knowledge_base SCHEMAFULL;

DEFINE FIELD `@context`    ON TABLE knowledge_base TYPE string DEFAULT 'https://schema.org';
DEFINE FIELD `@type`       ON TABLE knowledge_base TYPE string DEFAULT 'Dataset';

DEFINE FIELD kb_id         ON TABLE knowledge_base TYPE string ASSERT $value != NONE;
DEFINE FIELD tenant_id     ON TABLE knowledge_base TYPE string ASSERT $value != NONE;
DEFINE FIELD agent_id      ON TABLE knowledge_base TYPE option<string>;  -- None = tenant-wide
DEFINE FIELD name          ON TABLE knowledge_base TYPE string ASSERT $value != NONE;
DEFINE FIELD description   ON TABLE knowledge_base TYPE option<string>;

DEFINE FIELD kb_type       ON TABLE knowledge_base TYPE string DEFAULT 'documents'
    ASSERT $value IN ['documents', 'faq', 'code', 'policies', 'runbooks', 'product', 'custom'];

-- Embedding model used for this collection
DEFINE FIELD embed_model   ON TABLE knowledge_base TYPE string DEFAULT 'text-embedding-3-small';
DEFINE FIELD embed_dim     ON TABLE knowledge_base TYPE int DEFAULT 1536;

-- Chunking strategy
DEFINE FIELD chunk_size    ON TABLE knowledge_base TYPE int DEFAULT 512;
DEFINE FIELD chunk_overlap ON TABLE knowledge_base TYPE int DEFAULT 64;

-- Stats
DEFINE FIELD doc_count     ON TABLE knowledge_base TYPE int DEFAULT 0;
DEFINE FIELD chunk_count   ON TABLE knowledge_base TYPE int DEFAULT 0;
DEFINE FIELD total_tokens  ON TABLE knowledge_base TYPE int DEFAULT 0;

DEFINE FIELD active        ON TABLE knowledge_base TYPE bool DEFAULT true;
DEFINE FIELD created_at    ON TABLE knowledge_base TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at    ON TABLE knowledge_base TYPE datetime DEFAULT time::now();

DEFINE INDEX idx_kb_id      ON TABLE knowledge_base COLUMNS kb_id UNIQUE;
DEFINE INDEX idx_kb_tenant  ON TABLE knowledge_base COLUMNS tenant_id;
DEFINE INDEX idx_kb_agent   ON TABLE knowledge_base COLUMNS agent_id;

-- ─── Document ────────────────────────────────────────────────────────────────

DEFINE TABLE kb_document SCHEMAFULL;

DEFINE FIELD `@context`    ON TABLE kb_document TYPE string DEFAULT 'https://schema.org';
DEFINE FIELD `@type`       ON TABLE kb_document TYPE string DEFAULT 'CreativeWork';

DEFINE FIELD doc_id        ON TABLE kb_document TYPE string ASSERT $value != NONE;
DEFINE FIELD kb_id         ON TABLE kb_document TYPE record<knowledge_base> ASSERT $value != NONE;
DEFINE FIELD tenant_id     ON TABLE kb_document TYPE string ASSERT $value != NONE;

DEFINE FIELD title         ON TABLE kb_document TYPE string ASSERT $value != NONE;
DEFINE FIELD source_url    ON TABLE kb_document TYPE option<string>;
DEFINE FIELD source_type   ON TABLE kb_document TYPE string DEFAULT 'text'
    ASSERT $value IN ['text', 'markdown', 'pdf', 'html', 'code', 'json', 'csv', 'docx'];
DEFINE FIELD content       ON TABLE kb_document TYPE option<string>;
    -- Raw full text (before chunking); may be large
DEFINE FIELD content_hash  ON TABLE kb_document TYPE option<string>;
    -- SHA-256 of content for dedup

-- Status
DEFINE FIELD status        ON TABLE kb_document TYPE string DEFAULT 'pending'
    ASSERT $value IN ['pending', 'processing', 'indexed', 'failed', 'archived'];
DEFINE FIELD error         ON TABLE kb_document TYPE option<string>;
DEFINE FIELD chunk_count   ON TABLE kb_document TYPE int DEFAULT 0;
DEFINE FIELD token_count   ON TABLE kb_document TYPE int DEFAULT 0;

DEFINE FIELD metadata      ON TABLE kb_document TYPE object DEFAULT {};
DEFINE FIELD created_at    ON TABLE kb_document TYPE datetime DEFAULT time::now();
DEFINE FIELD indexed_at    ON TABLE kb_document TYPE option<datetime>;

DEFINE INDEX idx_doc_id      ON TABLE kb_document COLUMNS doc_id UNIQUE;
DEFINE INDEX idx_doc_kb      ON TABLE kb_document COLUMNS kb_id;
DEFINE INDEX idx_doc_tenant  ON TABLE kb_document COLUMNS tenant_id;
DEFINE INDEX idx_doc_hash    ON TABLE kb_document COLUMNS content_hash;
DEFINE INDEX idx_doc_status  ON TABLE kb_document COLUMNS status;

-- FTS on document title
DEFINE INDEX idx_doc_title_fts
    ON TABLE kb_document FIELDS title
    SEARCH ANALYZER analyzer_en BM25;

-- ─── Chunk (indexed unit for retrieval) ──────────────────────────────────────

DEFINE TABLE kb_chunk SCHEMAFULL;

DEFINE FIELD doc_id        ON TABLE kb_chunk TYPE record<kb_document> ASSERT $value != NONE;
DEFINE FIELD kb_id         ON TABLE kb_chunk TYPE record<knowledge_base> ASSERT $value != NONE;
DEFINE FIELD tenant_id     ON TABLE kb_chunk TYPE string ASSERT $value != NONE;
DEFINE FIELD chunk_index   ON TABLE kb_chunk TYPE int ASSERT $value >= 0;

DEFINE FIELD content       ON TABLE kb_chunk TYPE string ASSERT $value != NONE;
DEFINE FIELD token_count   ON TABLE kb_chunk TYPE int DEFAULT 0;

-- Vector embedding for semantic retrieval
DEFINE FIELD embedding     ON TABLE kb_chunk TYPE option<array<float>>;

DEFINE FIELD metadata      ON TABLE kb_chunk TYPE object DEFAULT {};
DEFINE FIELD created_at    ON TABLE kb_chunk TYPE datetime DEFAULT time::now();

DEFINE INDEX idx_chunk_doc    ON TABLE kb_chunk COLUMNS doc_id;
DEFINE INDEX idx_chunk_kb     ON TABLE kb_chunk COLUMNS kb_id;
DEFINE INDEX idx_chunk_tenant ON TABLE kb_chunk COLUMNS tenant_id;

-- Vector index: MTREE for cosine similarity (production: HNSW when available)
DEFINE INDEX idx_chunk_vec
    ON TABLE kb_chunk
    FIELDS embedding
    MTREE DIMENSION 1536 DIST COSINE;

-- BM25 on chunk content for hybrid retrieval
DEFINE INDEX idx_chunk_fts
    ON TABLE kb_chunk
    FIELDS content
    SEARCH ANALYZER analyzer_en BM25(1.2, 0.75)
    HIGHLIGHTS;

-- ─── Auto-update kb stats on document indexed ─────────────────────────────────

DEFINE EVENT kb_doc_indexed ON TABLE kb_document
    WHEN $event = 'UPDATE'
      AND $before.status != 'indexed'
      AND $after.status = 'indexed'
    THEN (
        UPDATE $after.kb_id SET
            doc_count   += 1,
            chunk_count += $after.chunk_count,
            total_tokens += $after.token_count,
            updated_at   = time::now()
    );

-- ─── Hybrid retrieval pattern ────────────────────────────────────────────────

-- Semantic retrieval (vector):
-- SELECT doc_id, content, vector::similarity::cosine(embedding, $query_embedding) AS score
-- FROM kb_chunk
-- WHERE kb_id IN (SELECT id FROM knowledge_base WHERE agent_id = $agent_id)
-- ORDER BY score DESC LIMIT 10;

-- BM25 retrieval:
-- SELECT content, search::highlight('<b>','</b>', 1) AS highlighted, search::score(1) AS score
-- FROM kb_chunk
-- WHERE kb_id IN (SELECT id FROM knowledge_base WHERE agent_id = $agent_id)
--   AND content @1@ $query_text
-- ORDER BY score DESC LIMIT 10;

-- Hybrid (RRF fusion):
-- LET $vec = SELECT id, vector::similarity::cosine(embedding, $emb) AS score FROM kb_chunk
--     WHERE kb_id IN $kbs ORDER BY score DESC LIMIT 20;
-- LET $bm25 = SELECT id, search::score(1) AS score FROM kb_chunk
--     WHERE kb_id IN $kbs AND content @1@ $query ORDER BY score DESC LIMIT 20;
-- SELECT id, math::sum(score) AS rrf FROM [$vec, $bm25] GROUP BY id ORDER BY rrf DESC LIMIT 5;
