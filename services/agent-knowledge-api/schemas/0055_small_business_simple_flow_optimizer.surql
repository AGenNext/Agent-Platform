-- AGenNext Platform
-- 0055: Small business simple-flow optimizer
-- Purpose: small business marketplace apps should expose many simple linear flows, not complex branching agent-builder experiences.

DEFINE TABLE simple_flow_templates SCHEMAFULL;
DEFINE FIELD flow_key ON simple_flow_templates TYPE string;
DEFINE FIELD app_key ON simple_flow_templates TYPE string;
DEFINE FIELD title ON simple_flow_templates TYPE string;
DEFINE FIELD description ON simple_flow_templates TYPE string;
DEFINE FIELD target_user ON simple_flow_templates TYPE string DEFAULT 'non_technical_small_business_owner';
DEFINE FIELD complexity_level ON simple_flow_templates TYPE string DEFAULT 'simple';
DEFINE FIELD max_steps ON simple_flow_templates TYPE int DEFAULT 5;
DEFINE FIELD steps ON simple_flow_templates TYPE array<object> DEFAULT [];
DEFINE FIELD required_inputs ON simple_flow_templates TYPE array<string> DEFAULT [];
DEFINE FIELD output_assets ON simple_flow_templates TYPE array<string> DEFAULT [];
DEFINE FIELD external_actions ON simple_flow_templates TYPE array<string> DEFAULT [];
DEFINE FIELD fallback_flow_keys ON simple_flow_templates TYPE array<string> DEFAULT [];
DEFINE FIELD active ON simple_flow_templates TYPE bool DEFAULT true;
DEFINE INDEX simple_flow_template_unique ON simple_flow_templates FIELDS flow_key UNIQUE;

DEFINE TABLE simple_flow_runs SCHEMAFULL;
DEFINE FIELD flow_key ON simple_flow_runs TYPE string;
DEFINE FIELD app_install_id ON simple_flow_runs TYPE option<record<small_business_app_installs>>;
DEFINE FIELD person_id ON simple_flow_runs TYPE record<identity_persons>;
DEFINE FIELD status ON simple_flow_runs TYPE string DEFAULT 'active';
DEFINE FIELD current_step_index ON simple_flow_runs TYPE int DEFAULT 0;
DEFINE FIELD collected_inputs ON simple_flow_runs TYPE object DEFAULT {};
DEFINE FIELD missing_inputs ON simple_flow_runs TYPE array<string> DEFAULT [];
DEFINE FIELD generated_outputs ON simple_flow_runs TYPE array<object> DEFAULT [];
DEFINE FIELD created_at ON simple_flow_runs TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON simple_flow_runs TYPE datetime DEFAULT time::now();

DEFINE TABLE flow_complexity_evaluations SCHEMAFULL;
DEFINE FIELD flow_key ON flow_complexity_evaluations TYPE string;
DEFINE FIELD branch_count ON flow_complexity_evaluations TYPE int DEFAULT 0;
DEFINE FIELD step_count ON flow_complexity_evaluations TYPE int DEFAULT 0;
DEFINE FIELD complexity_score ON flow_complexity_evaluations TYPE number DEFAULT 0;
DEFINE FIELD decision ON flow_complexity_evaluations TYPE string;
DEFINE FIELD recommendation ON flow_complexity_evaluations TYPE string;
DEFINE FIELD created_at ON flow_complexity_evaluations TYPE datetime DEFAULT time::now();

DEFINE FUNCTION fn::evaluate_simple_flow_complexity($flow_key: string) {
  LET $flow = SELECT * FROM ONLY simple_flow_templates WHERE flow_key = $flow_key AND active = true LIMIT 1;
  IF $flow = NONE THEN { THROW 'simple_flow_template_not_found'; };

  LET $branch_count = count(array::filter($flow.steps, |$step| $step.kind = 'branch' OR $step.kind = 'conditional'));
  LET $step_count = count($flow.steps);
  LET $score = $step_count + ($branch_count * 3);
  LET $decision = IF $score <= 7 AND $branch_count <= 1 THEN 'simple_enough' ELSE 'split_required' END;

  RETURN CREATE flow_complexity_evaluations CONTENT {
    flow_key: $flow_key,
    branch_count: $branch_count,
    step_count: $step_count,
    complexity_score: $score,
    decision: $decision,
    recommendation: IF $decision = 'split_required' THEN 'Split into multiple smaller marketplace flows.' ELSE 'Flow is suitable for non-technical users.' END,
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::start_simple_flow_run(
  $person_id: record<identity_persons>,
  $app_install_id: option<record<small_business_app_installs>>,
  $flow_key: string,
  $initial_inputs: object
) {
  LET $flow = SELECT * FROM ONLY simple_flow_templates WHERE flow_key = $flow_key AND active = true LIMIT 1;
  IF $flow = NONE THEN { THROW 'simple_flow_template_not_found'; };

  LET $complexity = fn::evaluate_simple_flow_complexity($flow_key);
  IF $complexity.decision = 'split_required' THEN { THROW 'flow_too_complex_for_small_business_user_split_required'; };

  LET $missing = [];
  FOR $field IN $flow.required_inputs {
    IF $initial_inputs[$field] = NONE OR $initial_inputs[$field] = '' THEN {
      LET $missing += $field;
    };
  };

  RETURN CREATE simple_flow_runs CONTENT {
    flow_key: $flow_key,
    app_install_id: $app_install_id,
    person_id: $person_id,
    status: IF count($missing) > 0 THEN 'needs_context' ELSE 'active' END,
    current_step_index: 0,
    collected_inputs: $initial_inputs,
    missing_inputs: $missing,
    generated_outputs: [],
    created_at: time::now(),
    updated_at: time::now()
  };
};

CREATE simple_flow_templates:website_homepage_copy CONTENT {
  flow_key: 'website_homepage_copy',
  app_key: 'website_starter',
  title: 'Write homepage copy',
  description: 'Collect basic business details and draft a homepage.',
  max_steps: 4,
  required_inputs: ['business_name', 'business_category', 'services', 'location'],
  output_assets: ['homepage_headline', 'about_section', 'services_section', 'contact_cta'],
  external_actions: [],
  steps: [
    { key: 'business_basics', label: 'Business basics', kind: 'collect' },
    { key: 'services', label: 'Services', kind: 'collect' },
    { key: 'draft_copy', label: 'Draft website copy', kind: 'generate' },
    { key: 'review', label: 'Review and edit', kind: 'review' }
  ],
  active: true
};

CREATE simple_flow_templates:google_profile_description CONTENT {
  flow_key: 'google_profile_description',
  app_key: 'google_business_setup',
  title: 'Prepare Google profile description',
  description: 'Create a simple business description and category suggestions.',
  max_steps: 4,
  required_inputs: ['business_name', 'business_category', 'address_or_service_area', 'hours'],
  output_assets: ['business_description', 'category_suggestions', 'service_area_summary'],
  external_actions: [],
  steps: [
    { key: 'business_info', label: 'Business info', kind: 'collect' },
    { key: 'location_hours', label: 'Location and hours', kind: 'collect' },
    { key: 'draft_profile', label: 'Draft profile content', kind: 'generate' },
    { key: 'review', label: 'Review checklist', kind: 'review' }
  ],
  active: true
};

CREATE simple_flow_templates:lead_offer_draft CONTENT {
  flow_key: 'lead_offer_draft',
  app_key: 'lead_booster',
  title: 'Create a lead offer',
  description: 'Draft one simple offer to attract leads.',
  max_steps: 5,
  required_inputs: ['business_category', 'target_customer', 'monthly_goal'],
  output_assets: ['offer_headline', 'offer_details', 'followup_message'],
  external_actions: [],
  steps: [
    { key: 'goal', label: 'Goal', kind: 'collect' },
    { key: 'customer', label: 'Target customer', kind: 'collect' },
    { key: 'offer', label: 'Draft offer', kind: 'generate' },
    { key: 'followup', label: 'Draft follow-up', kind: 'generate' },
    { key: 'review', label: 'Review', kind: 'review' }
  ],
  active: true
};
