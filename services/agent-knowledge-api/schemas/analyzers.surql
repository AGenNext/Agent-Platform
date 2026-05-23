-- Schema: analyzers
-- DEFINE ANALYZER — custom text analysis pipelines for BM25 full-text search.
-- Applied to memory.content, artifact.text, objective.goal, skill.name.
-- Ref: https://surrealdb.com/docs/surrealql/statements/define/analyzer

-- ─── Analyzers ───────────────────────────────────────────────────────────────

-- Standard English analyzer: tokenize on whitespace/punct, lowercase, snowball stem
DEFINE ANALYZER analyzer_en
    TOKENIZERS blank, class, punct
    FILTERS lowercase, snowball(english);

-- Code/ID analyzer: tokenize on camelCase and snake_case boundaries
DEFINE ANALYZER analyzer_code
    TOKENIZERS camel, blank, class
    FILTERS lowercase;

-- Tag analyzer: exact match, no stemming (for skill_id, capability names)
DEFINE ANALYZER analyzer_tag
    TOKENIZERS blank
    FILTERS lowercase, ascii;

-- ─── FTS indexes using custom analyzers ──────────────────────────────────────

-- Memory content — English stemming for semantic recall
DEFINE INDEX idx_memory_fts
    ON TABLE memory
    FIELDS content
    SEARCH ANALYZER analyzer_en BM25(1.2, 0.75)
    HIGHLIGHTS;

-- Artifact text — English stemming
DEFINE INDEX idx_artifact_fts
    ON TABLE artifact
    FIELDS text, name, description
    SEARCH ANALYZER analyzer_en BM25(1.2, 0.75)
    HIGHLIGHTS;

-- Objective goal — English stemming
DEFINE INDEX idx_objective_fts
    ON TABLE objective
    FIELDS goal, name, description
    SEARCH ANALYZER analyzer_en BM25(1.2, 0.75);

-- Skill name + description — English stemming
DEFINE INDEX idx_skill_fts
    ON TABLE skill
    FIELDS name
    SEARCH ANALYZER analyzer_en BM25;

-- Blueprint name + description — English stemming
DEFINE INDEX idx_blueprint_fts
    ON TABLE blueprint
    FIELDS name, description
    SEARCH ANALYZER analyzer_en BM25;

-- Agent name — tag analyzer (exact-ish match)
DEFINE INDEX idx_agent_name_fts
    ON TABLE agent
    FIELDS name
    SEARCH ANALYZER analyzer_tag BM25;

-- ─── FTS query patterns ──────────────────────────────────────────────────────

-- Search memory with BM25 score + highlights:
-- SELECT content, search::highlight('<b>', '</b>', 1) AS highlighted,
--        search::score(1) AS score
-- FROM memory
-- WHERE agent_id = $agent_id
--   AND content @1@ 'SurrealDB vector similarity'
-- ORDER BY score DESC LIMIT 10;

-- Cross-table search (memory + artifacts + objectives):
-- SELECT 'memory' AS source, content AS text, search::score(1) AS score
-- FROM memory WHERE content @1@ $query
-- UNION ALL
-- SELECT 'artifact' AS source, text AS text, search::score(1) AS score
-- FROM artifact WHERE text @1@ $query
-- UNION ALL
-- SELECT 'objective' AS source, goal AS text, search::score(1) AS score
-- FROM objective WHERE goal @1@ $query
-- ORDER BY score DESC LIMIT 20;
