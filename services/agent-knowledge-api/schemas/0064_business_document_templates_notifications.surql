-- AGenNext Platform
-- 0064: Native multimedia business document templates and transactional notifications
-- Purpose: support versioned templated business documents, template customization, generation logs, SMTP configuration, and granular RBAC-based transactional notifications only.

DEFINE TABLE business_document_templates SCHEMAFULL;
DEFINE FIELD tenant_id ON business_document_templates TYPE option<record<tenants>>;
DEFINE FIELD template_key ON business_document_templates TYPE string;
DEFINE FIELD template_name ON business_document_templates TYPE string;
DEFINE FIELD document_kind ON business_document_templates TYPE string;
DEFINE FIELD supported_output_formats ON business_document_templates TYPE array<string> DEFAULT ['html','pdf','docx'];
DEFINE FIELD supported_media_kinds ON business_document_templates TYPE array<string> DEFAULT ['text','image','table','chart','attachment'];
DEFINE FIELD template_status ON business_document_templates TYPE string DEFAULT 'active';
DEFINE FIELD owner_role ON business_document_templates TYPE string DEFAULT 'document_admin';
DEFINE FIELD created_by_person_id ON business_document_templates TYPE option<record<identity_persons>>;
DEFINE FIELD created_at ON business_document_templates TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON business_document_templates TYPE datetime DEFAULT time::now();
DEFINE INDEX business_document_template_unique ON business_document_templates FIELDS tenant_id, template_key UNIQUE;

DEFINE TABLE business_document_template_versions SCHEMAFULL;
DEFINE FIELD template_id ON business_document_template_versions TYPE record<business_document_templates>;
DEFINE FIELD version_ref ON business_document_template_versions TYPE string;
DEFINE FIELD version_label ON business_document_template_versions TYPE string;
DEFINE FIELD schema_version ON business_document_template_versions TYPE string DEFAULT '1.0.0';
DEFINE FIELD template_body ON business_document_template_versions TYPE object DEFAULT {};
DEFINE FIELD variables_schema ON business_document_template_versions TYPE object DEFAULT {};
DEFINE FIELD media_slots ON business_document_template_versions TYPE array<object> DEFAULT [];
DEFINE FIELD approval_status ON business_document_template_versions TYPE string DEFAULT 'draft';
DEFINE FIELD change_summary ON business_document_template_versions TYPE option<string>;
DEFINE FIELD created_by_person_id ON business_document_template_versions TYPE option<record<identity_persons>>;
DEFINE FIELD created_at ON business_document_template_versions TYPE datetime DEFAULT time::now();
DEFINE INDEX business_document_template_version_unique ON business_document_template_versions FIELDS template_id, version_ref UNIQUE;

DEFINE TABLE generated_business_documents SCHEMAFULL;
DEFINE FIELD tenant_id ON generated_business_documents TYPE option<record<tenants>>;
DEFINE FIELD template_id ON generated_business_documents TYPE record<business_document_templates>;
DEFINE FIELD template_version_id ON generated_business_documents TYPE record<business_document_template_versions>;
DEFINE FIELD document_ref ON generated_business_documents TYPE string;
DEFINE FIELD document_kind ON generated_business_documents TYPE string;
DEFINE FIELD document_title ON generated_business_documents TYPE string;
DEFINE FIELD generation_context ON generated_business_documents TYPE object DEFAULT {};
DEFINE FIELD output_assets ON generated_business_documents TYPE array<object> DEFAULT [];
DEFINE FIELD status ON generated_business_documents TYPE string DEFAULT 'draft_generated';
DEFINE FIELD created_by_person_id ON generated_business_documents TYPE option<record<identity_persons>>;
DEFINE FIELD created_at ON generated_business_documents TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON generated_business_documents TYPE datetime DEFAULT time::now();
DEFINE INDEX generated_business_document_ref_unique ON generated_business_documents FIELDS document_ref UNIQUE;

DEFINE TABLE business_document_audit_logs SCHEMAFULL;
DEFINE FIELD tenant_id ON business_document_audit_logs TYPE option<record<tenants>>;
DEFINE FIELD document_id ON business_document_audit_logs TYPE option<record<generated_business_documents>>;
DEFINE FIELD template_id ON business_document_audit_logs TYPE option<record<business_document_templates>>;
DEFINE FIELD actor_person_id ON business_document_audit_logs TYPE option<record<identity_persons>>;
DEFINE FIELD action_key ON business_document_audit_logs TYPE string;
DEFINE FIELD action_summary ON business_document_audit_logs TYPE string;
DEFINE FIELD evidence_refs ON business_document_audit_logs TYPE array<string> DEFAULT [];
DEFINE FIELD occurred_at ON business_document_audit_logs TYPE datetime DEFAULT time::now();

DEFINE TABLE smtp_configurations SCHEMAFULL;
DEFINE FIELD tenant_id ON smtp_configurations TYPE record<tenants>;
DEFINE FIELD config_key ON smtp_configurations TYPE string;
DEFINE FIELD provider_name ON smtp_configurations TYPE string;
DEFINE FIELD host ON smtp_configurations TYPE string;
DEFINE FIELD port ON smtp_configurations TYPE int DEFAULT 587;
DEFINE FIELD security_mode ON smtp_configurations TYPE string DEFAULT 'starttls';
DEFINE FIELD from_email ON smtp_configurations TYPE string;
DEFINE FIELD from_name ON smtp_configurations TYPE option<string>;
DEFINE FIELD status ON smtp_configurations TYPE string DEFAULT 'pending_verification';
DEFINE FIELD allowed_notification_kinds ON smtp_configurations TYPE array<string> DEFAULT ['transactional'];
DEFINE FIELD created_at ON smtp_configurations TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON smtp_configurations TYPE datetime DEFAULT time::now();
DEFINE INDEX smtp_configuration_unique ON smtp_configurations FIELDS tenant_id, config_key UNIQUE;

DEFINE TABLE transactional_notification_policies SCHEMAFULL;
DEFINE FIELD tenant_id ON transactional_notification_policies TYPE record<tenants>;
DEFINE FIELD policy_key ON transactional_notification_policies TYPE string;
DEFINE FIELD notification_kind ON transactional_notification_policies TYPE string DEFAULT 'transactional';
DEFINE FIELD event_key ON transactional_notification_policies TYPE string;
DEFINE FIELD allowed_recipient_roles ON transactional_notification_policies TYPE array<string> DEFAULT [];
DEFINE FIELD blocked_recipient_roles ON transactional_notification_policies TYPE array<string> DEFAULT [];
DEFINE FIELD channels ON transactional_notification_policies TYPE array<string> DEFAULT ['email'];
DEFINE FIELD requires_rbac_check ON transactional_notification_policies TYPE bool DEFAULT true;
DEFINE FIELD marketing_content_allowed ON transactional_notification_policies TYPE bool DEFAULT false;
DEFINE FIELD status ON transactional_notification_policies TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON transactional_notification_policies TYPE datetime DEFAULT time::now();
DEFINE INDEX transactional_notification_policy_unique ON transactional_notification_policies FIELDS tenant_id, policy_key UNIQUE;

DEFINE TABLE transactional_notification_events SCHEMAFULL;
DEFINE FIELD tenant_id ON transactional_notification_events TYPE record<tenants>;
DEFINE FIELD event_key ON transactional_notification_events TYPE string;
DEFINE FIELD recipient_person_id ON transactional_notification_events TYPE option<record<identity_persons>>;
DEFINE FIELD recipient_role ON transactional_notification_events TYPE string;
DEFINE FIELD channel ON transactional_notification_events TYPE string DEFAULT 'email';
DEFINE FIELD subject ON transactional_notification_events TYPE string;
DEFINE FIELD body_ref ON transactional_notification_events TYPE option<string>;
DEFINE FIELD related_resource_ref ON transactional_notification_events TYPE option<string>;
DEFINE FIELD delivery_status ON transactional_notification_events TYPE string DEFAULT 'queued';
DEFINE FIELD marketing_content_detected ON transactional_notification_events TYPE bool DEFAULT false;
DEFINE FIELD created_at ON transactional_notification_events TYPE datetime DEFAULT time::now();
DEFINE FIELD sent_at ON transactional_notification_events TYPE option<datetime>;

DEFINE FUNCTION fn::create_business_document_template($tenant_id: option<record<tenants>>, $template_key: string, $template_name: string, $document_kind: string, $owner_role: string, $created_by_person_id: option<record<identity_persons>>) {
  RETURN UPSERT type::thing('business_document_templates', $template_key) CONTENT {
    tenant_id: $tenant_id,
    template_key: $template_key,
    template_name: $template_name,
    document_kind: $document_kind,
    supported_output_formats: ['html','pdf','docx','pptx'],
    supported_media_kinds: ['text','image','table','chart','attachment','signature_block'],
    template_status: 'active',
    owner_role: $owner_role,
    created_by_person_id: $created_by_person_id,
    created_at: time::now(),
    updated_at: time::now()
  };
};

DEFINE FUNCTION fn::add_business_document_template_version($template_id: record<business_document_templates>, $version_label: string, $template_body: object, $variables_schema: object, $media_slots: array<object>, $change_summary: option<string>, $created_by_person_id: option<record<identity_persons>>) {
  RETURN CREATE business_document_template_versions CONTENT {
    template_id: $template_id,
    version_ref: rand::uuid(),
    version_label: $version_label,
    schema_version: '1.0.0',
    template_body: $template_body,
    variables_schema: $variables_schema,
    media_slots: $media_slots,
    approval_status: 'draft',
    change_summary: $change_summary,
    created_by_person_id: $created_by_person_id,
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::generate_business_document($tenant_id: option<record<tenants>>, $template_id: record<business_document_templates>, $template_version_id: record<business_document_template_versions>, $document_title: string, $generation_context: object, $created_by_person_id: option<record<identity_persons>>) {
  LET $template = SELECT * FROM ONLY $template_id;
  RETURN CREATE generated_business_documents CONTENT {
    tenant_id: $tenant_id,
    template_id: $template_id,
    template_version_id: $template_version_id,
    document_ref: rand::uuid(),
    document_kind: $template.document_kind,
    document_title: $document_title,
    generation_context: $generation_context,
    output_assets: [],
    status: 'draft_generated',
    created_by_person_id: $created_by_person_id,
    created_at: time::now(),
    updated_at: time::now()
  };
};

DEFINE FUNCTION fn::queue_transactional_notification($tenant_id: record<tenants>, $event_key: string, $recipient_person_id: option<record<identity_persons>>, $recipient_role: string, $channel: string, $subject: string, $body_ref: option<string>, $related_resource_ref: option<string>) {
  LET $policy = SELECT * FROM ONLY transactional_notification_policies WHERE tenant_id = $tenant_id AND event_key = $event_key AND status = 'active' LIMIT 1;
  IF $policy = NONE THEN { THROW 'transactional_notification_policy_not_found'; };
  IF $policy.marketing_content_allowed = true THEN { THROW 'marketing_content_not_allowed_in_transactional_notifications'; };
  IF $recipient_role NOTINSIDE $policy.allowed_recipient_roles THEN { THROW 'recipient_role_not_allowed_for_notification'; };
  IF $recipient_role INSIDE $policy.blocked_recipient_roles THEN { THROW 'recipient_role_blocked_for_notification'; };

  RETURN CREATE transactional_notification_events CONTENT {
    tenant_id: $tenant_id,
    event_key: $event_key,
    recipient_person_id: $recipient_person_id,
    recipient_role: $recipient_role,
    channel: $channel,
    subject: $subject,
    body_ref: $body_ref,
    related_resource_ref: $related_resource_ref,
    delivery_status: 'queued',
    marketing_content_detected: false,
    created_at: time::now()
  };
};

-- Built-in document template families.
CREATE business_document_templates:rfq CONTENT { template_key: 'rfq', template_name: 'Request for Quote', document_kind: 'rfq', supported_output_formats: ['html','pdf','docx'], supported_media_kinds: ['text','table','attachment','signature_block'], template_status: 'active', owner_role: 'procurement_admin', created_at: time::now(), updated_at: time::now() };
CREATE business_document_templates:invoice CONTENT { template_key: 'invoice', template_name: 'Invoice', document_kind: 'invoice', supported_output_formats: ['html','pdf'], supported_media_kinds: ['text','table','logo','signature_block'], template_status: 'active', owner_role: 'finance_admin', created_at: time::now(), updated_at: time::now() };
CREATE business_document_templates:contract CONTENT { template_key: 'contract', template_name: 'Contract', document_kind: 'contract', supported_output_formats: ['html','pdf','docx'], supported_media_kinds: ['text','clause_table','attachment','signature_block'], template_status: 'active', owner_role: 'legal_admin', created_at: time::now(), updated_at: time::now() };
CREATE business_document_templates:pitch_deck CONTENT { template_key: 'pitch_deck', template_name: 'Pitch Deck', document_kind: 'pitch_deck', supported_output_formats: ['pptx','pdf'], supported_media_kinds: ['text','image','chart','table'], template_status: 'active', owner_role: 'sales_admin', created_at: time::now(), updated_at: time::now() };
CREATE business_document_templates:sales_pitch CONTENT { template_key: 'sales_pitch', template_name: 'Sales Pitch', document_kind: 'sales_pitch', supported_output_formats: ['html','pdf','pptx'], supported_media_kinds: ['text','image','chart','customer_logo'], template_status: 'active', owner_role: 'sales_admin', created_at: time::now(), updated_at: time::now() };
CREATE business_document_templates:investor_pitch CONTENT { template_key: 'investor_pitch', template_name: 'Investor Pitch', document_kind: 'investor_pitch', supported_output_formats: ['pptx','pdf'], supported_media_kinds: ['text','image','chart','financial_table'], template_status: 'active', owner_role: 'executive_admin', created_at: time::now(), updated_at: time::now() };
CREATE business_document_templates:policy_document CONTENT { template_key: 'policy_document', template_name: 'Policy Document', document_kind: 'policy_document', supported_output_formats: ['html','pdf','docx'], supported_media_kinds: ['text','control_table','approval_block'], template_status: 'active', owner_role: 'governance_admin', created_at: time::now(), updated_at: time::now() };
CREATE business_document_templates:sla_breach_incident_response CONTENT { template_key: 'sla_breach_incident_response', template_name: 'SLA Breach Incident Response', document_kind: 'sla_breach_incident_response', supported_output_formats: ['html','pdf','docx'], supported_media_kinds: ['text','timeline','incident_table','remediation_plan'], template_status: 'active', owner_role: 'sre_admin', created_at: time::now(), updated_at: time::now() };
