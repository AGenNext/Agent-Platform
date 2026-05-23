-- Seed default modules loaded into every agent

UPSERT agent_modules:trust_engine CONTENT {
  key: 'trust_engine',
  name: 'Trust Engine',
  description: 'Computes contextual trust using evidence-backed, explainable, versioned methods.',
  enabled_by_default: true,
  load_order: 10,
  source_grounding_refs: ['arxiv:2402.12545','arxiv:2409.11242','arxiv:2205.12784','arxiv:2306.13339','arxiv:2603.13290']
};

UPSERT agent_modules:observability CONTENT {
  key: 'observability',
  name: 'Observability',
  description: 'Captures every intermediate stop as structured observation steps.',
  enabled_by_default: true,
  load_order: 20,
  source_grounding_refs: ['arxiv:2605.20173']
};

UPSERT agent_modules:memory_substrate CONTENT {
  key: 'memory_substrate',
  name: 'Memory Substrate',
  description: 'Graph-native, evidence-aware, self-consolidating memory.',
  enabled_by_default: true,
  load_order: 30,
  source_grounding_refs: ['arxiv:2604.19795']
};

UPSERT agent_modules:retrieval_engine CONTENT {
  key: 'retrieval_engine',
  name: 'Retrieval Engine',
  description: 'Adaptive multimodal retrieval with critique and sufficiency checks.',
  enabled_by_default: true,
  load_order: 40,
  source_grounding_refs: ['arxiv:2510.12323','arxiv:2604.25676']
};

UPSERT agent_modules:cognitive_guardrails CONTENT {
  key: 'cognitive_guardrails',
  name: 'Cognitive Guardrails',
  description: 'Cheap-first safety and policy gates.',
  enabled_by_default: true,
  load_order: 50,
  source_grounding_refs: ['arxiv:2505.23576']
};

UPSERT agent_modules:federation CONTENT {
  key: 'federation',
  name: 'Federation',
  description: 'External registry identity resolution and trust-aware import.',
  enabled_by_default: true,
  load_order: 60,
  source_grounding_refs: ['schemaorg:vocabulary']
};

UPSERT agent_modules:self_evolution CONTENT {
  key: 'self_evolution',
  name: 'Self Evolution',
  description: 'Governed adaptation of prompts, memory, tools, and workflows.',
  enabled_by_default: true,
  load_order: 70,
  source_grounding_refs: ['arxiv:2508.07407','arxiv:2511.10395']
};

UPSERT agent_modules:sdb_boundary CONTENT {
  key: 'sdb_boundary',
  name: 'Stochastic Deterministic Boundary',
  description: 'Proposer, verifier, commit, reject contract for every action.',
  enabled_by_default: true,
  load_order: 80,
  source_grounding_refs: ['arxiv:2605.20173']
};

UPSERT trust_policies:default CONTENT {
  key: 'default',
  name: 'Default Trust Policy',
  scope: 'global',
  method_version: 'agx:trust-weighted-evidence-v1',
  thresholds: {
    autonomous: 0.85,
    assisted: 0.70,
    verify: 0.50
  },
  caps: {
    no_provenance: 0.60,
    unknown_source: 0.50,
    failed_graph_validation: 0.40,
    active_revocation: 0.10
  }
};
