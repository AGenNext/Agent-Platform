-- Schema: twin
-- Digital twin backbone — SurrealDB as the canonical data backbone.
-- Every entity in the platform has a digital twin record.
-- Twins are connected via graph edges (RELATE), enabling traversal queries.
-- Schema.org JSON-LD types are the twin vocabulary.

DEFINE TABLE twin SCHEMAFULL;

DEFINE FIELD `@context`    ON TABLE twin TYPE string DEFAULT 'https://schema.org';
DEFINE FIELD `@type`       ON TABLE twin TYPE string DEFAULT 'Thing';

-- Twin identity
DEFINE FIELD twin_id       ON TABLE twin TYPE string ASSERT $value != NONE;
DEFINE FIELD tenant_id     ON TABLE twin TYPE string ASSERT $value != NONE;
DEFINE FIELD name          ON TABLE twin TYPE string;
DEFINE FIELD description   ON TABLE twin TYPE option<string>;

-- What real-world entity this twin represents
DEFINE FIELD entity_type   ON TABLE twin TYPE string DEFAULT 'generic'
    ASSERT $value IN ['agent', 'objective', 'artifact', 'task', 'user', 'document', 'process', 'system'];
DEFINE FIELD entity_ref    ON TABLE twin TYPE option<string>;

-- Twin state
DEFINE FIELD state         ON TABLE twin TYPE object DEFAULT {};
DEFINE FIELD sync_status   ON TABLE twin TYPE string DEFAULT 'synced'
    ASSERT $value IN ['synced', 'stale', 'error'];
DEFINE FIELD last_synced   ON TABLE twin TYPE datetime DEFAULT time::now();

-- Embedding for semantic graph traversal
DEFINE FIELD embedding     ON TABLE twin TYPE option<array>;

DEFINE FIELD created_at    ON TABLE twin TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at    ON TABLE twin TYPE datetime DEFAULT time::now();
DEFINE FIELD metadata      ON TABLE twin TYPE option<object>;

DEFINE INDEX idx_twin_id       ON TABLE twin COLUMNS twin_id UNIQUE;
DEFINE INDEX idx_twin_tenant   ON TABLE twin COLUMNS tenant_id;
DEFINE INDEX idx_twin_type     ON TABLE twin COLUMNS entity_type;

-- Vector index for semantic twin similarity
DEFINE INDEX idx_twin_embedding ON TABLE twin FIELDS embedding MTREE DIMENSION 1536;

-- ─── Graph relationship tables ────────────────────────────────────────────────
-- Edges connect twins to form the knowledge graph backbone.
-- Uses SurrealDB's native RELATE statement.

DEFINE TABLE twin_relates_to SCHEMAFULL TYPE RELATION IN twin OUT twin;
DEFINE FIELD relation_type ON TABLE twin_relates_to TYPE string DEFAULT 'related';
DEFINE FIELD weight        ON TABLE twin_relates_to TYPE float DEFAULT 1.0;
DEFINE FIELD metadata      ON TABLE twin_relates_to TYPE option<object>;
DEFINE FIELD created_at    ON TABLE twin_relates_to TYPE datetime DEFAULT time::now();

-- Traversal query examples (not schema, for documentation):
-- Find all twins related to a given twin:
--   SELECT ->twin_relates_to->twin.* FROM twin:$id
-- Find shortest path between two twins:
--   SELECT * FROM twin WHERE id = graph::bfs(twin:$start, twin:$end)

-- Auto-create twin when agent is registered
DEFINE EVENT agent_twin_created ON TABLE agent
    WHEN $event = 'CREATE'
    THEN (
        CREATE twin CONTENT {
            twin_id: $after.agent_id,
            tenant_id: $after.tenant_id,
            name: $after.name,
            description: $after.description,
            entity_type: 'agent',
            entity_ref: <string>$after.id,
            state: { status: 'registered', capabilities: $after.capabilities }
        }
    );

-- Auto-create twin when artifact is created
DEFINE EVENT artifact_twin_created ON TABLE artifact
    WHEN $event = 'CREATE'
    THEN (
        CREATE twin CONTENT {
            twin_id: <string>$after.id,
            tenant_id: $after.tenant_id ?? 'platform',
            name: $after.name ?? 'artifact',
            entity_type: 'artifact',
            entity_ref: <string>$after.id,
            state: { schema_type: $after.`@type`, encoding: $after.encodingFormat }
        }
    );
