-- AGenNext Platform
-- 0050: Identity verification, duplicate identity resolution, and multi-profile tenant membership model
-- Purpose: support one verified person with multiple emails, profiles, and tenant relationships while keeping current org, alumni, contractor, vendor, customer, and community access separate.

DEFINE TABLE identity_persons SCHEMAFULL;
DEFINE FIELD canonical_subject_id ON identity_persons TYPE string;
DEFINE FIELD display_name ON identity_persons TYPE option<string>;
DEFINE FIELD primary_email ON identity_persons TYPE option<string>;
DEFINE FIELD verification_level ON identity_persons TYPE string DEFAULT 'email_verified';
DEFINE FIELD status ON identity_persons TYPE string DEFAULT 'active';
DEFINE FIELD created_at ON identity_persons TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON identity_persons TYPE datetime DEFAULT time::now();
DEFINE INDEX identity_persons_subject_unique ON identity_persons FIELDS canonical_subject_id UNIQUE;

DEFINE TABLE identity_email_addresses SCHEMAFULL;
DEFINE FIELD person_id ON identity_email_addresses TYPE record<identity_persons>;
DEFINE FIELD email ON identity_email_addresses TYPE string;
DEFINE FIELD normalized_email ON identity_email_addresses TYPE string;
DEFINE FIELD domain ON identity_email_addresses TYPE string;
DEFINE FIELD verification_status ON identity_email_addresses TYPE string DEFAULT 'pending';
DEFINE FIELD verification_method ON identity_email_addresses TYPE option<string>;
DEFINE FIELD is_primary ON identity_email_addresses TYPE bool DEFAULT false;
DEFINE FIELD first_seen_at ON identity_email_addresses TYPE datetime DEFAULT time::now();
DEFINE FIELD verified_at ON identity_email_addresses TYPE option<datetime>;
DEFINE INDEX identity_email_unique ON identity_email_addresses FIELDS normalized_email UNIQUE;

DEFINE TABLE identity_profiles SCHEMAFULL;
DEFINE FIELD person_id ON identity_profiles TYPE record<identity_persons>;
DEFINE FIELD profile_key ON identity_profiles TYPE string;
DEFINE FIELD profile_kind ON identity_profiles TYPE string;
DEFINE FIELD display_name ON identity_profiles TYPE option<string>;
DEFINE FIELD default_email_id ON identity_profiles TYPE option<record<identity_email_addresses>>;
DEFINE FIELD tenant_id ON identity_profiles TYPE option<record<tenants>>;
DEFINE FIELD status ON identity_profiles TYPE string DEFAULT 'active';
DEFINE FIELD metadata ON identity_profiles TYPE object DEFAULT {};
DEFINE FIELD created_at ON identity_profiles TYPE datetime DEFAULT time::now();
DEFINE INDEX identity_profiles_unique ON identity_profiles FIELDS person_id, profile_key UNIQUE;

DEFINE TABLE tenant_memberships SCHEMAFULL;
DEFINE FIELD tenant_id ON tenant_memberships TYPE record<tenants>;
DEFINE FIELD person_id ON tenant_memberships TYPE record<identity_persons>;
DEFINE FIELD profile_id ON tenant_memberships TYPE record<identity_profiles>;
DEFINE FIELD membership_kind ON tenant_memberships TYPE string;
DEFINE FIELD relationship_to_tenant ON tenant_memberships TYPE string;
DEFINE FIELD status ON tenant_memberships TYPE string DEFAULT 'active';
DEFINE FIELD roles ON tenant_memberships TYPE array<string> DEFAULT [];
DEFINE FIELD current_context ON tenant_memberships TYPE bool DEFAULT false;
DEFINE FIELD starts_at ON tenant_memberships TYPE option<datetime>;
DEFINE FIELD ends_at ON tenant_memberships TYPE option<datetime>;
DEFINE FIELD access_scope ON tenant_memberships TYPE object DEFAULT {};
DEFINE FIELD created_at ON tenant_memberships TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON tenant_memberships TYPE datetime DEFAULT time::now();
DEFINE INDEX tenant_membership_unique ON tenant_memberships FIELDS tenant_id, person_id, profile_id UNIQUE;

DEFINE TABLE identity_duplicate_candidates SCHEMAFULL;
DEFINE FIELD candidate_ref ON identity_duplicate_candidates TYPE string;
DEFINE FIELD normalized_email ON identity_duplicate_candidates TYPE option<string>;
DEFINE FIELD domain ON identity_duplicate_candidates TYPE option<string>;
DEFINE FIELD matched_person_ids ON identity_duplicate_candidates TYPE array<record<identity_persons>> DEFAULT [];
DEFINE FIELD confidence ON identity_duplicate_candidates TYPE number DEFAULT 0;
DEFINE FIELD signals ON identity_duplicate_candidates TYPE object DEFAULT {};
DEFINE FIELD decision ON identity_duplicate_candidates TYPE string DEFAULT 'pending';
DEFINE FIELD created_at ON identity_duplicate_candidates TYPE datetime DEFAULT time::now();

DEFINE TABLE identity_verification_challenges SCHEMAFULL;
DEFINE FIELD person_id ON identity_verification_challenges TYPE option<record<identity_persons>>;
DEFINE FIELD email_id ON identity_verification_challenges TYPE option<record<identity_email_addresses>>;
DEFINE FIELD challenge_kind ON identity_verification_challenges TYPE string;
DEFINE FIELD target ON identity_verification_challenges TYPE string;
DEFINE FIELD status ON identity_verification_challenges TYPE string DEFAULT 'pending';
DEFINE FIELD expires_at ON identity_verification_challenges TYPE datetime;
DEFINE FIELD created_at ON identity_verification_challenges TYPE datetime DEFAULT time::now();
DEFINE FIELD verified_at ON identity_verification_challenges TYPE option<datetime>;

DEFINE TABLE tenant_context_switch_events SCHEMAFULL;
DEFINE FIELD person_id ON tenant_context_switch_events TYPE record<identity_persons>;
DEFINE FIELD from_tenant_id ON tenant_context_switch_events TYPE option<record<tenants>>;
DEFINE FIELD to_tenant_id ON tenant_context_switch_events TYPE record<tenants>;
DEFINE FIELD profile_id ON tenant_context_switch_events TYPE record<identity_profiles>;
DEFINE FIELD reason ON tenant_context_switch_events TYPE string;
DEFINE FIELD observed_at ON tenant_context_switch_events TYPE datetime DEFAULT time::now();

DEFINE FUNCTION fn::normalize_email($email: string) {
  RETURN string::lowercase(string::trim($email));
};

DEFINE FUNCTION fn::email_domain($email: string) {
  LET $parts = string::split(fn::normalize_email($email), '@');
  RETURN IF count($parts) = 2 THEN $parts[1] ELSE '' END;
};

DEFINE FUNCTION fn::create_or_get_identity_person(
  $email: string,
  $display_name: option<string>,
  $verification_method: string
) {
  LET $normalized = fn::normalize_email($email);
  LET $existing_email = SELECT * FROM ONLY identity_email_addresses WHERE normalized_email = $normalized LIMIT 1;

  IF $existing_email != NONE THEN {
    RETURN SELECT * FROM ONLY $existing_email.person_id;
  };

  LET $person = CREATE identity_persons CONTENT {
    canonical_subject_id: string::concat('person:', rand::uuid()),
    display_name: $display_name,
    primary_email: $normalized,
    verification_level: 'email_verified',
    status: 'active',
    created_at: time::now(),
    updated_at: time::now()
  };

  CREATE identity_email_addresses CONTENT {
    person_id: $person.id,
    email: $email,
    normalized_email: $normalized,
    domain: fn::email_domain($email),
    verification_status: 'verified',
    verification_method: $verification_method,
    is_primary: true,
    first_seen_at: time::now(),
    verified_at: time::now()
  };

  CREATE identity_profiles CONTENT {
    person_id: $person.id,
    profile_key: 'personal_trial',
    profile_kind: 'personal_trial',
    display_name: $display_name,
    tenant_id: NONE,
    status: 'active',
    metadata: { no_credit_card_required: true, no_sso_required: true, no_rbac_setup_required: true },
    created_at: time::now()
  };

  RETURN $person;
};

DEFINE FUNCTION fn::add_identity_email(
  $person_id: record<identity_persons>,
  $email: string,
  $verification_method: string,
  $is_primary: bool
) {
  LET $normalized = fn::normalize_email($email);
  LET $existing = SELECT * FROM ONLY identity_email_addresses WHERE normalized_email = $normalized LIMIT 1;
  IF $existing != NONE AND $existing.person_id != $person_id THEN {
    THROW 'email_already_linked_to_another_person';
  };

  LET $email_record = UPSERT type::thing('identity_email_addresses', string::replace($normalized, '@', '_at_')) CONTENT {
    person_id: $person_id,
    email: $email,
    normalized_email: $normalized,
    domain: fn::email_domain($email),
    verification_status: 'verified',
    verification_method: $verification_method,
    is_primary: $is_primary,
    first_seen_at: time::now(),
    verified_at: time::now()
  };

  IF $is_primary = true THEN {
    UPDATE identity_email_addresses SET is_primary = false WHERE person_id = $person_id AND id != $email_record.id;
    UPDATE $person_id SET primary_email = $normalized, updated_at = time::now();
  };

  RETURN $email_record;
};

DEFINE FUNCTION fn::detect_identity_duplicate_candidates($email: string) {
  LET $normalized = fn::normalize_email($email);
  LET $domain = fn::email_domain($email);
  LET $exact_email = SELECT person_id FROM identity_email_addresses WHERE normalized_email = $normalized;
  LET $domain_matches = SELECT person_id FROM identity_email_addresses WHERE domain = $domain LIMIT 25;

  LET $confidence = IF count($exact_email) > 0 THEN 1 ELSE IF count($domain_matches) > 0 THEN 0.35 ELSE 0 END END;

  RETURN CREATE identity_duplicate_candidates CONTENT {
    candidate_ref: rand::uuid(),
    normalized_email: $normalized,
    domain: $domain,
    matched_person_ids: array::distinct(array::concat($exact_email.person_id, $domain_matches.person_id)),
    confidence: $confidence,
    signals: { exact_email_matches: count($exact_email), same_domain_matches: count($domain_matches) },
    decision: 'pending',
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::create_identity_profile(
  $person_id: record<identity_persons>,
  $profile_key: string,
  $profile_kind: string,
  $display_name: option<string>,
  $tenant_id: option<record<tenants>>,
  $metadata: object
) {
  RETURN UPSERT type::thing('identity_profiles', string::concat(string::replace(string::from($person_id), ':', '_'), '_', $profile_key)) CONTENT {
    person_id: $person_id,
    profile_key: $profile_key,
    profile_kind: $profile_kind,
    display_name: $display_name,
    tenant_id: $tenant_id,
    status: 'active',
    metadata: $metadata,
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::grant_tenant_membership(
  $tenant_id: record<tenants>,
  $person_id: record<identity_persons>,
  $profile_id: record<identity_profiles>,
  $membership_kind: string,
  $relationship_to_tenant: string,
  $roles: array<string>,
  $current_context: bool,
  $access_scope: object
) {
  IF $current_context = true THEN {
    UPDATE tenant_memberships SET current_context = false WHERE person_id = $person_id;
  };

  RETURN CREATE tenant_memberships CONTENT {
    tenant_id: $tenant_id,
    person_id: $person_id,
    profile_id: $profile_id,
    membership_kind: $membership_kind,
    relationship_to_tenant: $relationship_to_tenant,
    status: 'active',
    roles: $roles,
    current_context: $current_context,
    access_scope: $access_scope,
    created_at: time::now(),
    updated_at: time::now()
  };
};

DEFINE FUNCTION fn::switch_current_tenant_context(
  $person_id: record<identity_persons>,
  $tenant_id: record<tenants>,
  $profile_id: record<identity_profiles>,
  $reason: string
) {
  LET $current = SELECT * FROM ONLY tenant_memberships WHERE person_id = $person_id AND current_context = true LIMIT 1;
  LET $target = SELECT * FROM ONLY tenant_memberships WHERE person_id = $person_id AND tenant_id = $tenant_id AND profile_id = $profile_id AND status = 'active' LIMIT 1;
  IF $target = NONE THEN { THROW 'tenant_membership_not_found'; };

  UPDATE tenant_memberships SET current_context = false WHERE person_id = $person_id;
  UPDATE $target.id SET current_context = true, updated_at = time::now();

  CREATE tenant_context_switch_events CONTENT {
    person_id: $person_id,
    from_tenant_id: $current.tenant_id,
    to_tenant_id: $tenant_id,
    profile_id: $profile_id,
    reason: $reason,
    observed_at: time::now()
  };

  RETURN SELECT * FROM ONLY $target.id;
};

DEFINE FUNCTION fn::identity_access_context($person_id: record<identity_persons>) {
  RETURN {
    person: SELECT * FROM ONLY $person_id,
    emails: SELECT * FROM identity_email_addresses WHERE person_id = $person_id,
    profiles: SELECT * FROM identity_profiles WHERE person_id = $person_id AND status = 'active',
    memberships: SELECT * FROM tenant_memberships WHERE person_id = $person_id AND status = 'active' ORDER BY current_context DESC, updated_at DESC,
    current_membership: SELECT * FROM tenant_memberships WHERE person_id = $person_id AND status = 'active' AND current_context = true LIMIT 1
  };
};
