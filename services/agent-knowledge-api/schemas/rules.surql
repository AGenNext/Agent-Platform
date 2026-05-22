-- Schema: rules
-- Hard platform rules — enforced at the SurrealDB layer, not in application code.
-- These cannot be bypassed. Application code that violates them will get a DB error.
-- Ref: https://surrealdb.com/docs/build/ai-agents/agent-rules

-- ─── Global rule parameters ───────────────────────────────────────────────────
-- DEFINE PARAM stores platform-wide constants accessible in all SurrealQL.

DEFINE PARAM $PLATFORM_VERSION VALUE '0.1.0';
DEFINE PARAM $REQUIRED_CAPABILITIES VALUE ['analytics','billing','health','tracing','auth','artifacts','skills','trust'];
DEFINE PARAM $MIN_TRUST_SCORE VALUE 0.7;
DEFINE PARAM $MAX_PRIORITY VALUE 10;
DEFINE PARAM $MAX_COST_PER_OBJECTIVE VALUE 50.0;

-- ─── Hard Rule 1: No objective without tenant attribution ────────────────────
-- Every objective must be attributable to a tenant for billing.
-- Enforced via: objective.goal ASSERT + policy.cost.no-unattributed-objective

-- ─── Hard Rule 2: No artifact surfaced without trust evaluation ──────────────
-- Artifacts start with eval_status = 'pending'. Must be 'passed' to surface.
-- Enforced via: DEFINE PERMISSION on artifact for external reads

-- ─── Hard Rule 3: No agent executes without registry entry ───────────────────
-- All 8 capabilities must be declared true.
-- Enforced via: agent.capabilities ASSERT in agent.surql

-- ─── Hard Rule 4: Audit log is immutable ─────────────────────────────────────
-- No one can UPDATE or DELETE audit records.
-- Enforced via: DEFINE TABLE audit_log PERMISSIONS FOR update NONE FOR delete NONE

-- ─── Hard Rule 5: Usage records are immutable ────────────────────────────────
-- Billing records cannot be altered after creation.
-- Enforced via: DEFINE TABLE usage_record PERMISSIONS FOR update NONE FOR delete NONE

-- ─── Hard Rule 6: Memory is agent-scoped ─────────────────────────────────────
-- Agents can only read and write their own memory.
-- Enforced via: DEFINE TABLE memory PERMISSIONS

-- ─── Hard Rule 7: Trust score threshold ─────────────────────────────────────
-- Trust scores must be in [0.0, 1.0]. CLEAR pass requires >= $MIN_TRUST_SCORE.
-- Enforced via: trust_record.ratingValue ASSERT

-- ─── Hard Rule 8: Agent skill declarations must exist in registry ─────────────
-- skill_ids declared on agent must exist in the skill table.
-- Enforced at query time:
--   SELECT * FROM skill WHERE skill_id IN $agent.skill_ids

-- ─── Hard Rule 9: Policy blocks evaluated before objective runs ───────────────
-- query to evaluate active BLOCK policies before execution:
-- SELECT * FROM policy WHERE active = true AND action = 'block' ORDER BY priority ASC

-- ─── Skill registry definitions ──────────────────────────────────────────────
-- Platform built-in skills seeded on startup.

INSERT IGNORE INTO skill [
    { skill_id: 'skill.decompose',      name: 'Decompose Objective',    category: 'orchestration' },
    { skill_id: 'skill.assign',         name: 'Assign Task',             category: 'orchestration' },
    { skill_id: 'skill.synthesize',     name: 'Synthesize Results',      category: 'orchestration' },
    { skill_id: 'skill.search',         name: 'Web Search',              category: 'research' },
    { skill_id: 'skill.scrape',         name: 'Document Scrape',         category: 'research' },
    { skill_id: 'skill.summarize',      name: 'Summarize',               category: 'research' },
    { skill_id: 'skill.cite',           name: 'Generate Citations',      category: 'research' },
    { skill_id: 'skill.write',          name: 'Write Artifact',          category: 'writing' },
    { skill_id: 'skill.structure',      name: 'Structure Content',       category: 'writing' },
    { skill_id: 'skill.format',         name: 'Format Output',           category: 'writing' },
    { skill_id: 'skill.brand_align',    name: 'Brand Alignment',         category: 'writing' },
    { skill_id: 'skill.clear_score',    name: 'CLEAR Evaluation',        category: 'evaluation' },
    { skill_id: 'skill.fact_check',     name: 'Fact Check',              category: 'evaluation' },
    { skill_id: 'skill.trust_evaluate', name: 'Trust Evaluation',        category: 'evaluation' },
    { skill_id: 'skill.model_select',   name: 'Model Selection',         category: 'routing' },
    { skill_id: 'skill.cost_estimate',  name: 'Cost Estimation',         category: 'routing' },
    { skill_id: 'skill.policy_check',   name: 'Policy Check',            category: 'routing' },
    { skill_id: 'skill.rag',            name: 'RAG Query',               category: 'knowledge' },
    { skill_id: 'skill.embed',          name: 'Generate Embedding',      category: 'knowledge' },
    { skill_id: 'skill.graph_query',    name: 'Graph Traversal Query',   category: 'knowledge' },
    { skill_id: 'skill.fts',            name: 'Full-Text Search',        category: 'knowledge' },
    { skill_id: 'skill.provenance',     name: 'Build Provenance Chain',  category: 'trust' },
    { skill_id: 'skill.evidence_check', name: 'Validate Evidence',       category: 'trust' },
    { skill_id: 'skill.trust_score',    name: 'Assign Trust Score',      category: 'trust' },
    { skill_id: 'skill.health_ping',    name: 'Health Ping',             category: 'monitoring' },
    { skill_id: 'skill.diagnose',       name: 'Diagnose Failure',        category: 'monitoring' },
    { skill_id: 'skill.alert',          name: 'Emit Alert',              category: 'monitoring' }
];
