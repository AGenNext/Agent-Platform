DEFINE TABLE temporal_contexts SCHEMAFULL;
DEFINE FIELD tenant_id ON temporal_contexts TYPE option<record<tenants>>;
DEFINE FIELD subject_id ON temporal_contexts TYPE string;
DEFINE FIELD observed_at ON temporal_contexts TYPE datetime;
DEFINE FIELD valid_from ON temporal_contexts TYPE option<datetime>;
DEFINE FIELD valid_until ON temporal_contexts TYPE option<datetime>;
DEFINE FIELD timezone ON temporal_contexts TYPE option<string>;
DEFINE FIELD precision ON temporal_contexts TYPE string DEFAULT 'instant';
DEFINE FIELD source_id ON temporal_contexts TYPE option<string>;
DEFINE FIELD jsonld_context ON temporal_contexts TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON temporal_contexts TYPE array<string> DEFAULT ['schema:Thing', 'agx:TemporalContext'];
DEFINE FIELD created_at ON temporal_contexts TYPE datetime DEFAULT time::now();

DEFINE TABLE location_contexts SCHEMAFULL;
DEFINE FIELD tenant_id ON location_contexts TYPE option<record<tenants>>;
DEFINE FIELD subject_id ON location_contexts TYPE string;
DEFINE FIELD plus_code ON location_contexts TYPE string;
DEFINE FIELD latitude ON location_contexts TYPE option<number>;
DEFINE FIELD longitude ON location_contexts TYPE option<number>;
DEFINE FIELD locality ON location_contexts TYPE option<string>;
DEFINE FIELD region ON location_contexts TYPE option<string>;
DEFINE FIELD country ON location_contexts TYPE option<string>;
DEFINE FIELD source_id ON location_contexts TYPE option<string>;
DEFINE FIELD observed_at ON location_contexts TYPE datetime DEFAULT time::now();
DEFINE FIELD jsonld_context ON location_contexts TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON location_contexts TYPE array<string> DEFAULT ['schema:Place', 'agx:LocationContext'];
DEFINE FIELD source_grounding_refs ON location_contexts TYPE array<string> DEFAULT ['open-location-code:plus-codes'];
DEFINE FIELD created_at ON location_contexts TYPE datetime DEFAULT time::now();
DEFINE INDEX location_contexts_subject_plus_unique ON location_contexts FIELDS tenant_id, subject_id, plus_code UNIQUE;

DEFINE FUNCTION fn::validate_plus_code($plus_code) {
  IF $plus_code = NONE THEN { THROW 'plus_code_required'; };
  IF string::len($plus_code) < 4 THEN { THROW 'plus_code_too_short'; };
  IF !string::contains($plus_code, '+') THEN { THROW 'plus_code_missing_separator'; };
  RETURN true;
};

DEFINE FUNCTION fn::record_temporal_context($tenant_id, $subject_id, $observed_at, $valid_from, $valid_until, $timezone, $precision, $source_id) {
  IF $observed_at = NONE THEN { THROW 'observed_at_required'; };
  IF $valid_from != NONE AND $valid_until != NONE AND $valid_until < $valid_from THEN { THROW 'invalid_temporal_range'; };

  RETURN CREATE temporal_contexts CONTENT {
    tenant_id: $tenant_id,
    subject_id: $subject_id,
    observed_at: $observed_at,
    valid_from: $valid_from,
    valid_until: $valid_until,
    timezone: $timezone,
    precision: $precision,
    source_id: $source_id,
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::record_location_context($tenant_id, $subject_id, $plus_code, $latitude, $longitude, $locality, $region, $country, $source_id) {
  fn::validate_plus_code($plus_code);
  IF ($latitude != NONE AND ($latitude < -90 OR $latitude > 90)) THEN { THROW 'invalid_latitude'; };
  IF ($longitude != NONE AND ($longitude < -180 OR $longitude > 180)) THEN { THROW 'invalid_longitude'; };

  RETURN CREATE location_contexts CONTENT {
    tenant_id: $tenant_id,
    subject_id: $subject_id,
    plus_code: $plus_code,
    latitude: $latitude,
    longitude: $longitude,
    locality: $locality,
    region: $region,
    country: $country,
    source_id: $source_id,
    observed_at: time::now(),
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::require_time_location_primitives($subject_id, $require_location) {
  LET $time_contexts = SELECT * FROM temporal_contexts WHERE subject_id = $subject_id LIMIT 1;
  IF count($time_contexts) = 0 THEN { THROW 'temporal_context_required'; };

  IF $require_location THEN {
    LET $location_contexts = SELECT * FROM location_contexts WHERE subject_id = $subject_id LIMIT 1;
    IF count($location_contexts) = 0 THEN { THROW 'location_context_required'; };
    fn::validate_plus_code($location_contexts[0].plus_code);
  };

  RETURN true;
};
