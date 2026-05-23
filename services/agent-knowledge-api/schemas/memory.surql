-- Schema: memory
-- Agent long-term memory — native SurrealDB vector + graph storage.
-- Every registered agent gets a memory store. No external vector DB needed.
-- Uses SurrealDB's native vector search for semantic retrieval.

DEFINE TABLE memory SCHEMAFULL;

DEFINE FIELD `@context`    ON TABLE memory TYPE string DEFAULT 'https://schema.org';
DEFINE FIELD `@type`       ON TABLE memory TYPE string DEFAULT 'MemoryObject';

-- Memory identity
DEFINE FIELD agent_id      ON TABLE memory TYPE string ASSERT $value != NONE;
DEFINE FIELD tenant_id     ON TABLE memory TYPE string ASSERT $value != NONE;

-- Content
DEFINE FIELD content       ON TABLE memory TYPE string ASSERT $value != NONE;
DEFINE FIELD summary       ON TABLE memory TYPE option<string>;
DEFINE FIELD memory_type   ON TABLE memory TYPE string DEFAULT 'episodic'
    ASSERT $value IN ['episodic', 'semantic', 'procedural', 'working'];

-- Vector embedding for semantic retrieval (1536-dim for ada-002 / 768-dim for local models)
DEFINE FIELD embedding     ON TABLE memory TYPE option<array>;

-- Provenance — what created this memory
DEFINE FIELD objective_id  ON TABLE memory TYPE option<record<objective>>;
DEFINE FIELD task_id       ON TABLE memory TYPE option<record<task>>;
DEFINE FIELD artifact_id   ON TABLE memory TYPE option<record<artifact>>;

-- Metadata
DEFINE FIELD importance    ON TABLE memory TYPE float DEFAULT 0.5
    ASSERT $value >= 0.0 AND $value <= 1.0;
DEFINE FIELD tags          ON TABLE memory TYPE array DEFAULT [];
DEFINE FIELD expires_at    ON TABLE memory TYPE option<datetime>;

DEFINE FIELD created_at    ON TABLE memory TYPE datetime DEFAULT time::now();
DEFINE FIELD accessed_at   ON TABLE memory TYPE datetime DEFAULT time::now();
DEFINE FIELD access_count  ON TABLE memory TYPE int DEFAULT 0;

-- Vector index for semantic similarity search
DEFINE INDEX idx_memory_embedding ON TABLE memory FIELDS embedding MTREE DIMENSION 1536;

DEFINE INDEX idx_memory_agent      ON TABLE memory COLUMNS agent_id;
DEFINE INDEX idx_memory_tenant     ON TABLE memory COLUMNS tenant_id;
DEFINE INDEX idx_memory_type       ON TABLE memory COLUMNS memory_type;
DEFINE INDEX idx_memory_importance ON TABLE memory COLUMNS importance;

-- Full-text search on content
DEFINE ANALYZER memory_analyzer TOKENIZERS blank,class FILTERS ascii,snowball(english);
DEFINE INDEX idx_memory_content ON TABLE memory FIELDS content
    SEARCH ANALYZER memory_analyzer BM25;

-- Event: increment access count and update accessed_at on read (via UPDATE)
DEFINE EVENT memory_accessed ON TABLE memory
    WHEN $event = 'UPDATE' AND $before.accessed_at != $after.accessed_at
    THEN (
        UPDATE $after.id SET access_count = $after.access_count + 1
    );
