-- Schema: blueprint
-- Agent blueprints — canonical templates for every agent type on the platform.
-- An agent is instantiated FROM a blueprint. Blueprint defines the contract.
-- Aligns with Agent-Blueprint repo.

DEFINE TABLE blueprint SCHEMAFULL;

DEFINE FIELD `@context`    ON TABLE blueprint TYPE string DEFAULT 'https://schema.org';
DEFINE FIELD `@type`       ON TABLE blueprint TYPE string DEFAULT 'HowTo';

-- schema:HowTo — a blueprint is a how-to for building an agent
DEFINE FIELD name          ON TABLE blueprint TYPE string ASSERT $value != NONE;
DEFINE FIELD description   ON TABLE blueprint TYPE option<string>;
DEFINE FIELD blueprint_id  ON TABLE blueprint TYPE string ASSERT $value != NONE;

-- What the agent can do
DEFINE FIELD goal_types    ON TABLE blueprint TYPE array DEFAULT [];
DEFINE FIELD skill_ids     ON TABLE blueprint TYPE array DEFAULT [];
DEFINE FIELD capabilities  ON TABLE blueprint TYPE object DEFAULT {
    analytics: true, billing: true, health: true, tracing: true,
    auth: true, artifacts: true, skills: true, trust: true
};

-- Model preferences
DEFINE FIELD preferred_models ON TABLE blueprint TYPE array DEFAULT [];
DEFINE FIELD model_policy     ON TABLE blueprint TYPE option<object>;
DEFINE FIELD cost_limit_usd   ON TABLE blueprint TYPE float DEFAULT 1.0;

-- Memory seeds (pre-loaded on agent instantiation from this blueprint)
DEFINE FIELD memory_seeds  ON TABLE blueprint TYPE array DEFAULT [];

-- Agent Graph entrypoint (LangGraph node reference)
DEFINE FIELD graph_node    ON TABLE blueprint TYPE option<string>;
DEFINE FIELD version       ON TABLE blueprint TYPE string DEFAULT '0.1.0';
DEFINE FIELD active        ON TABLE blueprint TYPE bool DEFAULT true;
DEFINE FIELD created_at    ON TABLE blueprint TYPE datetime DEFAULT time::now();

DEFINE INDEX idx_blueprint_id     ON TABLE blueprint COLUMNS blueprint_id UNIQUE;
DEFINE INDEX idx_blueprint_active ON TABLE blueprint COLUMNS active;

-- ─── Pre-populated platform agent blueprints ─────────────────────────────────
-- Seeded on startup via INSERT IGNORE (idempotent).

INSERT IGNORE INTO blueprint [
    {
        blueprint_id: 'agent.orchestrator',
        name: 'Orchestrator Agent',
        description: 'Decomposes objectives into tasks and assigns them to specialist agents. Owns the objective execution loop.',
        goal_types: ['decompose_objective', 'assign_tasks', 'synthesize_results', 'report_completion'],
        skill_ids: ['skill.decompose', 'skill.assign', 'skill.synthesize'],
        cost_limit_usd: 2.0,
        memory_seeds: [
            {
                memory_type: 'procedural',
                content: 'I decompose high-level objectives into executable tasks and coordinate specialist agents. I own the execution loop from objective receipt to result synthesis.',
                importance: 1.0,
                tags: ['role', 'orchestration']
            }
        ],
        graph_node: 'orchestrator'
    },
    {
        blueprint_id: 'agent.researcher',
        name: 'Research Agent',
        description: 'Discovers, retrieves, and synthesises information from sources. Produces research artifacts.',
        goal_types: ['web_research', 'document_retrieval', 'source_synthesis', 'knowledge_extraction'],
        skill_ids: ['skill.search', 'skill.scrape', 'skill.summarize', 'skill.cite'],
        cost_limit_usd: 1.0,
        memory_seeds: [
            {
                memory_type: 'procedural',
                content: 'I research topics by searching the web, retrieving documents, and synthesising findings into structured research artifacts with full citation provenance.',
                importance: 1.0,
                tags: ['role', 'research']
            },
            {
                memory_type: 'semantic',
                content: 'All research outputs are stored as schema:CreativeWork artifacts in SurrealDB with trust scores and provenance chains.',
                importance: 0.9,
                tags: ['artifacts', 'provenance']
            }
        ],
        graph_node: 'researcher'
    },
    {
        blueprint_id: 'agent.writer',
        name: 'Writer Agent',
        description: 'Generates written artifacts — blog posts, product docs, sales decks, RFP responses — from source material.',
        goal_types: ['write_blog', 'write_product_doc', 'write_sales_deck', 'write_rfp', 'write_pitch_deck'],
        skill_ids: ['skill.write', 'skill.structure', 'skill.format', 'skill.brand_align'],
        cost_limit_usd: 1.5,
        memory_seeds: [
            {
                memory_type: 'procedural',
                content: 'I generate high-quality written artifacts from source material. Every output is structured, formatted, and aligned with brand guidelines. Outputs are always schema:CreativeWork.',
                importance: 1.0,
                tags: ['role', 'writing', 'artifacts']
            }
        ],
        graph_node: 'writer'
    },
    {
        blueprint_id: 'agent.evaluator',
        name: 'Evaluator Agent',
        description: 'Evaluates artifact quality, accuracy, and trust using CLEAR scoring. Assigns trust_record to every artifact.',
        goal_types: ['evaluate_artifact', 'score_trust', 'flag_hallucination', 'approve_release'],
        skill_ids: ['skill.clear_score', 'skill.fact_check', 'skill.trust_evaluate'],
        cost_limit_usd: 0.5,
        memory_seeds: [
            {
                memory_type: 'procedural',
                content: 'I evaluate every artifact using the CLEAR framework: Correct, Logical, Evidence-backed, Aligned, Readable. I assign a trust_record (schema:Rating) and block release of artifacts that fail.',
                importance: 1.0,
                tags: ['role', 'evaluation', 'trust', 'CLEAR']
            }
        ],
        graph_node: 'evaluator'
    },
    {
        blueprint_id: 'agent.router',
        name: 'Model Router Agent',
        description: 'Routes tasks to the optimal model/provider under cost, quality, and policy constraints.',
        goal_types: ['route_model', 'enforce_policy', 'attribute_cost', 'select_provider'],
        skill_ids: ['skill.model_select', 'skill.cost_estimate', 'skill.policy_check'],
        cost_limit_usd: 0.1,
        memory_seeds: [
            {
                memory_type: 'procedural',
                content: 'I select the optimal model and provider for each task. I enforce model policies, estimate costs, and attribute every token to a tenant and objective. No model call runs without my approval.',
                importance: 1.0,
                tags: ['role', 'routing', 'model', 'finops']
            }
        ],
        graph_node: 'router'
    },
    {
        blueprint_id: 'agent.knowledge',
        name: 'Knowledge Agent',
        description: 'Enterprise knowledge retrieval — RAG, semantic search, knowledge graph traversal.',
        goal_types: ['rag_query', 'semantic_search', 'graph_traversal', 'knowledge_extraction'],
        skill_ids: ['skill.rag', 'skill.embed', 'skill.graph_query', 'skill.fts'],
        cost_limit_usd: 0.5,
        memory_seeds: [
            {
                memory_type: 'procedural',
                content: 'I answer questions and retrieve knowledge from the enterprise knowledge graph stored in SurrealDB. I use vector similarity, full-text search, and graph traversal. All sources are cited.',
                importance: 1.0,
                tags: ['role', 'knowledge', 'rag', 'retrieval']
            }
        ],
        graph_node: 'knowledge'
    },
    {
        blueprint_id: 'agent.trust',
        name: 'Trust Agent',
        description: 'Builds provenance chains, validates evidence, and maintains trust scores across artifacts and objectives.',
        goal_types: ['build_provenance', 'validate_evidence', 'assign_trust_score', 'generate_handoff_package'],
        skill_ids: ['skill.provenance', 'skill.evidence_check', 'skill.trust_score'],
        cost_limit_usd: 0.3,
        memory_seeds: [
            {
                memory_type: 'procedural',
                content: 'I maintain the provenance chain for every artifact. Every claim must have evidence. Every artifact must have a complete evidence trail before trust can be assigned.',
                importance: 1.0,
                tags: ['role', 'trust', 'provenance', 'evidence']
            }
        ],
        graph_node: 'trust'
    },
    {
        blueprint_id: 'agent.monitor',
        name: 'Platform Monitor Agent',
        description: 'Monitors platform health, emits health_check records, and alerts on degraded agents.',
        goal_types: ['health_check', 'alert', 'diagnose', 'auto_recover'],
        skill_ids: ['skill.health_ping', 'skill.diagnose', 'skill.alert'],
        cost_limit_usd: 0.1,
        memory_seeds: [
            {
                memory_type: 'procedural',
                content: 'I continuously monitor all registered agents and services. I emit health_check records every 60 seconds. I alert when any agent is degraded or unreachable.',
                importance: 1.0,
                tags: ['role', 'monitoring', 'health']
            }
        ],
        graph_node: 'monitor'
    }
];
