-- AGenNext Platform
-- 0057: Enterprise revenue lifecycle
-- Purpose: model enterprise-led evaluation from demo/sandbox through POC, multi-persona evaluation, onboarding, UAT, go-live, check-ins, renewal, expansion.

DEFINE TABLE enterprise_accounts SCHEMAFULL;
DEFINE FIELD account_name ON enterprise_accounts TYPE string;
DEFINE FIELD account_domain ON enterprise_accounts TYPE option<string>;
DEFINE FIELD industry ON enterprise_accounts TYPE option<string>;
DEFINE FIELD account_stage ON enterprise_accounts TYPE string DEFAULT 'lead';
DEFINE FIELD owner_person_id ON enterprise_accounts TYPE option<record<identity_persons>>;
DEFINE FIELD tenant_id ON enterprise_accounts TYPE option<record<tenants>>;
DEFINE FIELD created_at ON enterprise_accounts TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON enterprise_accounts TYPE datetime DEFAULT time::now();

DEFINE TABLE enterprise_deals SCHEMAFULL;
DEFINE FIELD account_id ON enterprise_deals TYPE record<enterprise_accounts>;
DEFINE FIELD deal_name ON enterprise_deals TYPE string;
DEFINE FIELD deal_stage ON enterprise_deals TYPE string DEFAULT 'lead_generated';
DEFINE FIELD expected_value ON enterprise_deals TYPE option<number>;
DEFINE FIELD currency ON enterprise_deals TYPE string DEFAULT 'USD';
DEFINE FIELD close_target_at ON enterprise_deals TYPE option<datetime>;
DEFINE FIELD signed_at ON enterprise_deals TYPE option<datetime>;
DEFINE FIELD renewal_at ON enterprise_deals TYPE option<datetime>;
DEFINE FIELD created_at ON enterprise_deals TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON enterprise_deals TYPE datetime DEFAULT time::now();

DEFINE TABLE enterprise_lifecycle_phases SCHEMAFULL;
DEFINE FIELD phase_key ON enterprise_lifecycle_phases TYPE string;
DEFINE FIELD deal_id ON enterprise_lifecycle_phases TYPE record<enterprise_deals>;
DEFINE FIELD account_id ON enterprise_lifecycle_phases TYPE record<enterprise_accounts>;
DEFINE FIELD phase_name ON enterprise_lifecycle_phases TYPE string;
DEFINE FIELD phase_order ON enterprise_lifecycle_phases TYPE int;
DEFINE FIELD status ON enterprise_lifecycle_phases TYPE string DEFAULT 'not_started';
DEFINE FIELD owner_role ON enterprise_lifecycle_phases TYPE string;
DEFINE FIELD entry_criteria ON enterprise_lifecycle_phases TYPE array<string> DEFAULT [];
DEFINE FIELD exit_criteria ON enterprise_lifecycle_phases TYPE array<string> DEFAULT [];
DEFINE FIELD started_at ON enterprise_lifecycle_phases TYPE option<datetime>;
DEFINE FIELD completed_at ON enterprise_lifecycle_phases TYPE option<datetime>;
DEFINE FIELD created_at ON enterprise_lifecycle_phases TYPE datetime DEFAULT time::now();

DEFINE TABLE enterprise_evaluation_personas SCHEMAFULL;
DEFINE FIELD deal_id ON enterprise_evaluation_personas TYPE record<enterprise_deals>;
DEFINE FIELD account_id ON enterprise_evaluation_personas TYPE record<enterprise_accounts>;
DEFINE FIELD persona_key ON enterprise_evaluation_personas TYPE string;
DEFINE FIELD persona_name ON enterprise_evaluation_personas TYPE string;
DEFINE FIELD department ON enterprise_evaluation_personas TYPE option<string>;
DEFINE FIELD evaluation_focus ON enterprise_evaluation_personas TYPE array<string> DEFAULT [];
DEFINE FIELD decision_weight ON enterprise_evaluation_personas TYPE string DEFAULT 'influencer';
DEFINE FIELD status ON enterprise_evaluation_personas TYPE string DEFAULT 'invited';
DEFINE FIELD created_at ON enterprise_evaluation_personas TYPE datetime DEFAULT time::now();

DEFINE TABLE enterprise_workspaces SCHEMAFULL;
DEFINE FIELD deal_id ON enterprise_workspaces TYPE record<enterprise_deals>;
DEFINE FIELD account_id ON enterprise_workspaces TYPE record<enterprise_accounts>;
DEFINE FIELD workspace_kind ON enterprise_workspaces TYPE string;
DEFINE FIELD workspace_name ON enterprise_workspaces TYPE string;
DEFINE FIELD tenant_id ON enterprise_workspaces TYPE option<record<tenants>>;
DEFINE FIELD environment ON enterprise_workspaces TYPE string DEFAULT 'sandbox';
DEFINE FIELD status ON enterprise_workspaces TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON enterprise_workspaces TYPE datetime DEFAULT time::now();

DEFINE TABLE enterprise_review_items SCHEMAFULL;
DEFINE FIELD deal_id ON enterprise_review_items TYPE record<enterprise_deals>;
DEFINE FIELD account_id ON enterprise_review_items TYPE record<enterprise_accounts>;
DEFINE FIELD phase_key ON enterprise_review_items TYPE string;
DEFINE FIELD item_type ON enterprise_review_items TYPE string;
DEFINE FIELD title ON enterprise_review_items TYPE string;
DEFINE FIELD owner_role ON enterprise_review_items TYPE string;
DEFINE FIELD status ON enterprise_review_items TYPE string DEFAULT 'open';
DEFINE FIELD evidence_refs ON enterprise_review_items TYPE array<string> DEFAULT [];
DEFINE FIELD due_at ON enterprise_review_items TYPE option<datetime>;
DEFINE FIELD completed_at ON enterprise_review_items TYPE option<datetime>;
DEFINE FIELD created_at ON enterprise_review_items TYPE datetime DEFAULT time::now();

DEFINE TABLE enterprise_checkins SCHEMAFULL;
DEFINE FIELD deal_id ON enterprise_checkins TYPE record<enterprise_deals>;
DEFINE FIELD account_id ON enterprise_checkins TYPE record<enterprise_accounts>;
DEFINE FIELD checkin_kind ON enterprise_checkins TYPE string;
DEFINE FIELD scheduled_at ON enterprise_checkins TYPE datetime;
DEFINE FIELD owner_role ON enterprise_checkins TYPE string;
DEFINE FIELD agenda ON enterprise_checkins TYPE array<string> DEFAULT [];
DEFINE FIELD outcome ON enterprise_checkins TYPE option<string>;
DEFINE FIELD status ON enterprise_checkins TYPE string DEFAULT 'scheduled';
DEFINE FIELD created_at ON enterprise_checkins TYPE datetime DEFAULT time::now();

DEFINE FUNCTION fn::create_enterprise_deal_lifecycle($account_name: string, $account_domain: option<string>, $deal_name: string, $expected_value: option<number>) {
  LET $account = CREATE enterprise_accounts CONTENT {
    account_name: $account_name,
    account_domain: $account_domain,
    account_stage: 'enterprise_sales_qualified',
    created_at: time::now(),
    updated_at: time::now()
  };
  LET $deal = CREATE enterprise_deals CONTENT {
    account_id: $account.id,
    deal_name: $deal_name,
    deal_stage: 'demo_scheduled',
    expected_value: $expected_value,
    currency: 'USD',
    created_at: time::now(),
    updated_at: time::now()
  };
  LET $phases = [
    ['lead_generated','Lead generated',1,'sales'],
    ['discovery_demo','Discovery and demo',2,'sales'],
    ['sandbox','Demo sandbox',3,'solutions'],
    ['poc','POC',4,'solutions'],
    ['multi_persona_evaluation','Multi-persona evaluation',5,'solutions'],
    ['security_compliance_review','Security and compliance review',6,'security'],
    ['commercial_negotiation','Commercial negotiation',7,'sales'],
    ['deal_signature','Deal signing',8,'legal'],
    ['it_admin_onboarding','IT admin onboarding',9,'implementation'],
    ['uat','UAT',10,'customer_it'],
    ['go_live','Go live',11,'implementation'],
    ['periodic_checkins','Periodic check-ins',12,'customer_success'],
    ['renewal_expansion','Renewal and expansion',13,'customer_success']
  ];
  FOR $phase IN $phases {
    CREATE enterprise_lifecycle_phases CONTENT {
      phase_key: $phase[0], deal_id: $deal.id, account_id: $account.id, phase_name: $phase[1], phase_order: $phase[2], owner_role: $phase[3], status: IF $phase[0] = 'lead_generated' THEN 'completed' ELSE 'not_started' END, created_at: time::now()
    };
  };
  RETURN { account: $account, deal: $deal, phases: SELECT * FROM enterprise_lifecycle_phases WHERE deal_id = $deal.id ORDER BY phase_order };
};
