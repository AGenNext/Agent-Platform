-- Schema: agent
-- Agent registry — every agent MUST be registered here before the runtime assigns an ID.
-- An agent without a registry entry cannot execute objectives, receive tasks, or emit traces.
--
-- Required capabilities for registration:
--   analytics, billing, health, tracing, auth, artifacts, skills, trust

DEFINE TABLE agent SCHEMAFULL;

DEFINE FIELD `@context`    ON TABLE agent TYPE string DEFAULT 'https://schema.org';
DEFINE FIELD `@type`       ON TABLE agent TYPE string DEFAULT 'SoftwareAgent';

-- schema:SoftwareAgent identity
DEFINE FIELD name          ON TABLE agent TYPE string ASSERT $value != NONE;
DEFINE FIELD description   ON TABLE agent TYPE option<string>;
DEFINE FIELD version       ON TABLE agent TYPE string DEFAULT '0.1.0';
DEFINE FIELD url           ON TABLE agent TYPE option<string>;

-- Registry identity
DEFINE FIELD agent_id      ON TABLE agent TYPE string ASSERT $value != NONE;
DEFINE FIELD tenant_id     ON TABLE agent TYPE string ASSERT $value != NONE;
DEFINE FIELD status        ON TABLE agent TYPE string DEFAULT 'registered'
    ASSERT $value IN ['registered', 'active', 'inactive', 'deregistered'];

-- Declared capabilities — ALL must be true for runtime to accept the agent
-- Runtime enforces: no ID assignment until all capabilities declared true
DEFINE FIELD capabilities  ON TABLE agent TYPE object DEFAULT {
    analytics: false,
    billing: false,
    health: false,
    tracing: false,
    auth: false,
    artifacts: false,
    skills: false,
    trust: false
} ASSERT
    $value.analytics  = true
    AND $value.billing    = true
    AND $value.health     = true
    AND $value.tracing    = true
    AND $value.auth       = true
    AND $value.artifacts  = true
    AND $value.skills     = true
    AND $value.trust      = true;

-- Runtime metadata
DEFINE FIELD goal_types    ON TABLE agent TYPE array DEFAULT [];
DEFINE FIELD skill_ids     ON TABLE agent TYPE array DEFAULT [];
DEFINE FIELD model_policy  ON TABLE agent TYPE option<object>;
DEFINE FIELD cost_limit_usd ON TABLE agent TYPE option<float>;

DEFINE FIELD registered_at ON TABLE agent TYPE datetime DEFAULT time::now();
DEFINE FIELD last_seen_at  ON TABLE agent TYPE datetime DEFAULT time::now();
DEFINE FIELD metadata      ON TABLE agent TYPE option<object>;

DEFINE INDEX idx_agent_id        ON TABLE agent COLUMNS agent_id UNIQUE;
DEFINE INDEX idx_agent_tenant    ON TABLE agent COLUMNS tenant_id;
DEFINE INDEX idx_agent_status    ON TABLE agent COLUMNS status;

-- Event: on registration, auto-emit analytics and seed default memory
-- Every agent gets implicit understanding of runtime + ecosystem + memory by default.
-- No agent executes without this seeding.
DEFINE EVENT agent_registered ON TABLE agent
    WHEN $event = 'CREATE'
    THEN {
        -- 1. Analytics: emit registration event
        CREATE event CONTENT {
            name: 'agent.registered',
            category: 'agent',
            action: 'register',
            label: $after.name,
            metadata: {
                agent_id: $after.agent_id,
                tenant_id: $after.tenant_id,
                capabilities: $after.capabilities
            }
        };

        -- 2. Seed: runtime identity memory (procedural — who am I)
        CREATE memory CONTENT {
            agent_id: $after.agent_id,
            tenant_id: $after.tenant_id,
            memory_type: 'procedural',
            content: string::concat(
                'I am ', $after.name,
                ' (', $after.agent_id, ')',
                ', version ', $after.version,
                ', tenant ', $after.tenant_id,
                '. My capabilities: analytics, billing, health, tracing, auth, artifacts, skills, trust.'
            ),
            summary: 'Agent identity and capability declaration',
            importance: 1.0,
            tags: ['identity', 'runtime', 'capabilities']
        };

        -- 3. Seed: ecosystem context memory (semantic — what ecosystem do I live in)
        CREATE memory CONTENT {
            agent_id: $after.agent_id,
            tenant_id: $after.tenant_id,
            memory_type: 'semantic',
            content: 'This agent operates inside the AGenNext Agent Platform. The runtime is SurrealDB. All data, decisions, context, and memory live in SurrealDB. The platform uses Schema.org JSON-LD as its graph data model. The semantic web IS the knowledge graph. Objectives are schema:Action. Artifacts are schema:CreativeWork. Trust is schema:Rating.',
            summary: 'Platform runtime and ecosystem context',
            importance: 1.0,
            tags: ['ecosystem', 'runtime', 'surrealdb', 'jsonld', 'schema-org']
        };

        -- 4. Seed: operational memory (episodic — what just happened)
        CREATE memory CONTENT {
            agent_id: $after.agent_id,
            tenant_id: $after.tenant_id,
            memory_type: 'episodic',
            content: string::concat(
                'Agent registered at ', <string>time::now(),
                '. Status: registered. Awaiting first objective assignment.'
            ),
            summary: 'Initial registration event',
            importance: 0.7,
            tags: ['registration', 'episodic']
        };
    };

-- Event: update last_seen_at on agent activity
DEFINE EVENT agent_heartbeat ON TABLE agent
    WHEN $event = 'UPDATE' AND $before.status = $after.status
    THEN (
        UPDATE $after.id SET last_seen_at = time::now()
    );
