-- AGenNext Platform
-- 0049: Cloudflare R2 compatible object storage abstraction
-- Purpose: S3-compatible object artifact storage with governance, access control, audit, and lifecycle metadata.

DEFINE TABLE object_storage_providers SCHEMAFULL;
DEFINE FIELD tenant_id ON object_storage_providers TYPE record<tenants>;
DEFINE FIELD provider_key ON object_storage_providers TYPE string;
DEFINE FIELD provider_type ON object_storage_providers TYPE string;
DEFINE FIELD display_name ON object_storage_providers TYPE string;
DEFINE FIELD endpoint_url ON object_storage_providers TYPE string;
DEFINE FIELD region ON object_storage_providers TYPE string DEFAULT 'auto';
DEFINE FIELD signature_version ON object_storage_providers TYPE string DEFAULT 's3v4';
DEFINE FIELD addressing_style ON object_storage_providers TYPE string DEFAULT 'path';
DEFINE FIELD supports_presigned_urls ON object_storage_providers TYPE bool DEFAULT true;
DEFINE FIELD supports_multipart_upload ON object_storage_providers TYPE bool DEFAULT true;
DEFINE FIELD supports_object_lifecycle ON object_storage_providers TYPE bool DEFAULT true;
DEFINE FIELD credential_ref ON object_storage_providers TYPE option<string>;
DEFINE FIELD active ON object_storage_providers TYPE bool DEFAULT true;
DEFINE FIELD created_at ON object_storage_providers TYPE datetime DEFAULT time::now();
DEFINE INDEX object_storage_providers_key_unique ON object_storage_providers FIELDS tenant_id, provider_key UNIQUE;

DEFINE TABLE object_storage_buckets SCHEMAFULL;
DEFINE FIELD tenant_id ON object_storage_buckets TYPE record<tenants>;
DEFINE FIELD provider_id ON object_storage_buckets TYPE record<object_storage_providers>;
DEFINE FIELD bucket_name ON object_storage_buckets TYPE string;
DEFINE FIELD purpose ON object_storage_buckets TYPE string;
DEFINE FIELD data_classification ON object_storage_buckets TYPE string DEFAULT 'internal';
DEFINE FIELD default_retention_policy ON object_storage_buckets TYPE object DEFAULT {};
DEFINE FIELD default_encryption_policy ON object_storage_buckets TYPE object DEFAULT { required: true, mode: 'provider_managed' };
DEFINE FIELD public_access_blocked ON object_storage_buckets TYPE bool DEFAULT true;
DEFINE FIELD active ON object_storage_buckets TYPE bool DEFAULT true;
DEFINE FIELD created_at ON object_storage_buckets TYPE datetime DEFAULT time::now();
DEFINE INDEX object_storage_buckets_name_unique ON object_storage_buckets FIELDS tenant_id, provider_id, bucket_name UNIQUE;

DEFINE TABLE object_storage_objects SCHEMAFULL;
DEFINE FIELD tenant_id ON object_storage_objects TYPE record<tenants>;
DEFINE FIELD provider_id ON object_storage_objects TYPE record<object_storage_providers>;
DEFINE FIELD bucket_id ON object_storage_objects TYPE record<object_storage_buckets>;
DEFINE FIELD object_key ON object_storage_objects TYPE string;
DEFINE FIELD object_uri ON object_storage_objects TYPE string;
DEFINE FIELD content_type ON object_storage_objects TYPE option<string>;
DEFINE FIELD content_length ON object_storage_objects TYPE option<number>;
DEFINE FIELD content_sha256 ON object_storage_objects TYPE option<string>;
DEFINE FIELD etag ON object_storage_objects TYPE option<string>;
DEFINE FIELD version_id ON object_storage_objects TYPE option<string>;
DEFINE FIELD metadata ON object_storage_objects TYPE object DEFAULT {};
DEFINE FIELD tags ON object_storage_objects TYPE object DEFAULT {};
DEFINE FIELD semantic_id ON object_storage_objects TYPE string;
DEFINE FIELD jsonld_context ON object_storage_objects TYPE object DEFAULT { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' };
DEFINE FIELD jsonld_type ON object_storage_objects TYPE array<string> DEFAULT ['schema:MediaObject', 'agx:ObjectStorageArtifact'];
DEFINE FIELD data_classification ON object_storage_objects TYPE string DEFAULT 'internal';
DEFINE FIELD owner_id ON object_storage_objects TYPE option<string>;
DEFINE FIELD source_ref ON object_storage_objects TYPE option<string>;
DEFINE FIELD evidence_refs ON object_storage_objects TYPE array<string> DEFAULT [];
DEFINE FIELD trace_id ON object_storage_objects TYPE option<string>;
DEFINE FIELD observation_run_id ON object_storage_objects TYPE option<record<observation_runs>>;
DEFINE FIELD retained_until ON object_storage_objects TYPE option<datetime>;
DEFINE FIELD legal_hold ON object_storage_objects TYPE bool DEFAULT false;
DEFINE FIELD status ON object_storage_objects TYPE string DEFAULT 'registered';
DEFINE FIELD created_at ON object_storage_objects TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON object_storage_objects TYPE datetime DEFAULT time::now();
DEFINE INDEX object_storage_objects_key_unique ON object_storage_objects FIELDS tenant_id, bucket_id, object_key UNIQUE;

DEFINE TABLE object_storage_access_requests SCHEMAFULL;
DEFINE FIELD tenant_id ON object_storage_access_requests TYPE record<tenants>;
DEFINE FIELD object_id ON object_storage_access_requests TYPE record<object_storage_objects>;
DEFINE FIELD subject_id ON object_storage_access_requests TYPE string;
DEFINE FIELD action ON object_storage_access_requests TYPE string;
DEFINE FIELD requested_ttl_seconds ON object_storage_access_requests TYPE int DEFAULT 900;
DEFINE FIELD purpose ON object_storage_access_requests TYPE string;
DEFINE FIELD context ON object_storage_access_requests TYPE object DEFAULT {};
DEFINE FIELD authorization_decision_id ON object_storage_access_requests TYPE option<string>;
DEFINE FIELD policy_decision_id ON object_storage_access_requests TYPE option<string>;
DEFINE FIELD relationship_access_check_id ON object_storage_access_requests TYPE option<string>;
DEFINE FIELD decision ON object_storage_access_requests TYPE string DEFAULT 'pending';
DEFINE FIELD reason ON object_storage_access_requests TYPE option<string>;
DEFINE FIELD created_at ON object_storage_access_requests TYPE datetime DEFAULT time::now();

DEFINE TABLE object_storage_presigned_operations SCHEMAFULL;
DEFINE FIELD tenant_id ON object_storage_presigned_operations TYPE record<tenants>;
DEFINE FIELD access_request_id ON object_storage_presigned_operations TYPE record<object_storage_access_requests>;
DEFINE FIELD provider_id ON object_storage_presigned_operations TYPE record<object_storage_providers>;
DEFINE FIELD bucket_id ON object_storage_presigned_operations TYPE record<object_storage_buckets>;
DEFINE FIELD object_id ON object_storage_presigned_operations TYPE record<object_storage_objects>;
DEFINE FIELD action ON object_storage_presigned_operations TYPE string;
DEFINE FIELD method ON object_storage_presigned_operations TYPE string;
DEFINE FIELD ttl_seconds ON object_storage_presigned_operations TYPE int;
DEFINE FIELD expires_at ON object_storage_presigned_operations TYPE datetime;
DEFINE FIELD signed_url_ref ON object_storage_presigned_operations TYPE option<string>;
DEFINE FIELD signed_url_hash ON object_storage_presigned_operations TYPE option<string>;
DEFINE FIELD headers ON object_storage_presigned_operations TYPE object DEFAULT {};
DEFINE FIELD status ON object_storage_presigned_operations TYPE string DEFAULT 'issued';
DEFINE FIELD created_at ON object_storage_presigned_operations TYPE datetime DEFAULT time::now();

DEFINE TABLE object_storage_multipart_uploads SCHEMAFULL;
DEFINE FIELD tenant_id ON object_storage_multipart_uploads TYPE record<tenants>;
DEFINE FIELD provider_id ON object_storage_multipart_uploads TYPE record<object_storage_providers>;
DEFINE FIELD bucket_id ON object_storage_multipart_uploads TYPE record<object_storage_buckets>;
DEFINE FIELD object_key ON object_storage_multipart_uploads TYPE string;
DEFINE FIELD upload_id ON object_storage_multipart_uploads TYPE string;
DEFINE FIELD initiated_by ON object_storage_multipart_uploads TYPE string;
DEFINE FIELD expected_content_type ON object_storage_multipart_uploads TYPE option<string>;
DEFINE FIELD expected_content_length ON object_storage_multipart_uploads TYPE option<number>;
DEFINE FIELD expected_sha256 ON object_storage_multipart_uploads TYPE option<string>;
DEFINE FIELD parts ON object_storage_multipart_uploads TYPE array<object> DEFAULT [];
DEFINE FIELD status ON object_storage_multipart_uploads TYPE string DEFAULT 'initiated';
DEFINE FIELD created_at ON object_storage_multipart_uploads TYPE datetime DEFAULT time::now();
DEFINE FIELD completed_at ON object_storage_multipart_uploads TYPE option<datetime>;

DEFINE TABLE object_storage_events SCHEMAFULL;
DEFINE FIELD tenant_id ON object_storage_events TYPE record<tenants>;
DEFINE FIELD provider_id ON object_storage_events TYPE option<record<object_storage_providers>>;
DEFINE FIELD bucket_id ON object_storage_events TYPE option<record<object_storage_buckets>>;
DEFINE FIELD object_id ON object_storage_events TYPE option<record<object_storage_objects>>;
DEFINE FIELD event_type ON object_storage_events TYPE string;
DEFINE FIELD actor_id ON object_storage_events TYPE option<string>;
DEFINE FIELD payload ON object_storage_events TYPE object DEFAULT {};
DEFINE FIELD observed_at ON object_storage_events TYPE datetime DEFAULT time::now();

DEFINE FUNCTION fn::register_r2_provider(
  $tenant_id: record<tenants>,
  $provider_key: string,
  $account_id: string,
  $credential_ref: option<string>,
  $display_name: option<string>
) {
  LET $endpoint = string::concat('https://', $account_id, '.r2.cloudflarestorage.com');

  RETURN UPSERT type::thing('object_storage_providers', $provider_key) CONTENT {
    tenant_id: $tenant_id,
    provider_key: $provider_key,
    provider_type: 'cloudflare_r2',
    display_name: IF $display_name != NONE THEN $display_name ELSE 'Cloudflare R2' END,
    endpoint_url: $endpoint,
    region: 'auto',
    signature_version: 's3v4',
    addressing_style: 'path',
    supports_presigned_urls: true,
    supports_multipart_upload: true,
    supports_object_lifecycle: true,
    credential_ref: $credential_ref,
    active: true,
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::register_object_storage_bucket(
  $tenant_id: record<tenants>,
  $provider_id: record<object_storage_providers>,
  $bucket_name: string,
  $purpose: string,
  $data_classification: string,
  $retention_policy: object,
  $encryption_policy: object
) {
  RETURN CREATE object_storage_buckets CONTENT {
    tenant_id: $tenant_id,
    provider_id: $provider_id,
    bucket_name: $bucket_name,
    purpose: $purpose,
    data_classification: $data_classification,
    default_retention_policy: $retention_policy,
    default_encryption_policy: $encryption_policy,
    public_access_blocked: true,
    active: true,
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::object_storage_uri(
  $provider: record<object_storage_providers>,
  $bucket: record<object_storage_buckets>,
  $object_key: string
) {
  RETURN string::concat('s3://', $bucket.bucket_name, '/', $object_key);
};

DEFINE FUNCTION fn::register_object_storage_object(
  $tenant_id: record<tenants>,
  $bucket_id: record<object_storage_buckets>,
  $object_key: string,
  $content_type: option<string>,
  $content_length: option<number>,
  $content_sha256: option<string>,
  $metadata: object,
  $tags: object,
  $owner_id: option<string>,
  $source_ref: option<string>,
  $actor_id: option<string>
) {
  LET $bucket = SELECT * FROM ONLY $bucket_id;
  IF $bucket = NONE THEN { THROW 'object_bucket_not_found'; };
  IF $bucket.tenant_id != $tenant_id THEN { THROW 'tenant_mismatch'; };

  LET $provider = SELECT * FROM ONLY $bucket.provider_id;
  IF $provider = NONE THEN { THROW 'object_provider_not_found'; };

  LET $semantic = string::concat('urn:agx:object:', string::replace(string::concat($bucket.bucket_name, '/', $object_key), '/', ':'));
  LET $uri = fn::object_storage_uri($provider, $bucket, $object_key);

  LET $object = CREATE object_storage_objects CONTENT {
    tenant_id: $tenant_id,
    provider_id: $provider.id,
    bucket_id: $bucket.id,
    object_key: $object_key,
    object_uri: $uri,
    content_type: $content_type,
    content_length: $content_length,
    content_sha256: $content_sha256,
    metadata: $metadata,
    tags: $tags,
    semantic_id: $semantic,
    jsonld_context: { schema: 'https://schema.org/', agx: 'https://agennext.ai/schema#' },
    jsonld_type: ['schema:MediaObject', 'agx:ObjectStorageArtifact'],
    data_classification: $bucket.data_classification,
    owner_id: $owner_id,
    source_ref: $source_ref,
    evidence_refs: [],
    status: 'registered',
    created_at: time::now(),
    updated_at: time::now()
  };

  CREATE object_storage_events CONTENT {
    tenant_id: $tenant_id,
    provider_id: $provider.id,
    bucket_id: $bucket.id,
    object_id: $object.id,
    event_type: 'object.registered',
    actor_id: $actor_id,
    payload: { object_key: $object_key, object_uri: $uri, content_sha256: $content_sha256 },
    observed_at: time::now()
  };

  CREATE audit_logs CONTENT {
    tenant_id: $tenant_id,
    actor_id: $actor_id,
    action: 'object_storage.object.registered',
    resource_type: 'object_storage_objects',
    resource_id: string::from($object.id),
    metadata: { bucket_id: $bucket.id, provider_id: $provider.id, object_key: $object_key },
    observed_at: time::now()
  };

  RETURN $object;
};

DEFINE FUNCTION fn::request_object_storage_access(
  $tenant_id: record<tenants>,
  $object_id: record<object_storage_objects>,
  $subject_id: string,
  $action: string,
  $ttl_seconds: int,
  $purpose: string,
  $context: object,
  $actor_id: option<string>
) {
  LET $object = SELECT * FROM ONLY $object_id;
  IF $object = NONE THEN { THROW 'object_not_found'; };
  IF $object.tenant_id != $tenant_id THEN { THROW 'tenant_mismatch'; };

  LET $access = fn::evaluate_resource_access($tenant_id, $subject_id, string::from($object_id), $action, $context, $actor_id);
  LET $decision = IF $access.decision = 'allow' THEN 'approved' ELSE 'denied' END;

  LET $request = CREATE object_storage_access_requests CONTENT {
    tenant_id: $tenant_id,
    object_id: $object_id,
    subject_id: $subject_id,
    action: $action,
    requested_ttl_seconds: $ttl_seconds,
    purpose: $purpose,
    context: $context,
    decision: $decision,
    reason: IF $decision = 'approved' THEN 'resource_access_allowed' ELSE 'resource_access_denied' END,
    created_at: time::now()
  };

  CREATE object_storage_events CONTENT {
    tenant_id: $tenant_id,
    provider_id: $object.provider_id,
    bucket_id: $object.bucket_id,
    object_id: $object_id,
    event_type: 'object.access_requested',
    actor_id: $actor_id,
    payload: { subject_id: $subject_id, action: $action, decision: $decision, access_decision: $access.id },
    observed_at: time::now()
  };

  RETURN $request;
};

DEFINE FUNCTION fn::create_object_presigned_operation(
  $tenant_id: record<tenants>,
  $access_request_id: record<object_storage_access_requests>,
  $method: string,
  $signed_url_ref: option<string>,
  $signed_url_hash: option<string>,
  $headers: object,
  $actor_id: option<string>
) {
  LET $request = SELECT * FROM ONLY $access_request_id;
  IF $request = NONE THEN { THROW 'object_access_request_not_found'; };
  IF $request.tenant_id != $tenant_id THEN { THROW 'tenant_mismatch'; };
  IF $request.decision != 'approved' THEN { THROW 'object_access_request_not_approved'; };

  LET $object = SELECT * FROM ONLY $request.object_id;
  IF $object = NONE THEN { THROW 'object_not_found'; };

  LET $ttl = IF $request.requested_ttl_seconds > 3600 THEN 3600 ELSE $request.requested_ttl_seconds END;
  LET $expires = time::now() + duration::from::secs($ttl);

  LET $operation = CREATE object_storage_presigned_operations CONTENT {
    tenant_id: $tenant_id,
    access_request_id: $request.id,
    provider_id: $object.provider_id,
    bucket_id: $object.bucket_id,
    object_id: $object.id,
    action: $request.action,
    method: $method,
    ttl_seconds: $ttl,
    expires_at: $expires,
    signed_url_ref: $signed_url_ref,
    signed_url_hash: $signed_url_hash,
    headers: $headers,
    status: 'issued',
    created_at: time::now()
  };

  CREATE object_storage_events CONTENT {
    tenant_id: $tenant_id,
    provider_id: $object.provider_id,
    bucket_id: $object.bucket_id,
    object_id: $object.id,
    event_type: 'object.presigned_operation.issued',
    actor_id: $actor_id,
    payload: { method: $method, action: $request.action, expires_at: $expires, signed_url_hash: $signed_url_hash },
    observed_at: time::now()
  };

  RETURN $operation;
};

DEFINE FUNCTION fn::initiate_object_multipart_upload(
  $tenant_id: record<tenants>,
  $bucket_id: record<object_storage_buckets>,
  $object_key: string,
  $upload_id: string,
  $initiated_by: string,
  $expected_content_type: option<string>,
  $expected_content_length: option<number>,
  $expected_sha256: option<string>
) {
  LET $bucket = SELECT * FROM ONLY $bucket_id;
  IF $bucket = NONE THEN { THROW 'object_bucket_not_found'; };
  IF $bucket.tenant_id != $tenant_id THEN { THROW 'tenant_mismatch'; };

  RETURN CREATE object_storage_multipart_uploads CONTENT {
    tenant_id: $tenant_id,
    provider_id: $bucket.provider_id,
    bucket_id: $bucket_id,
    object_key: $object_key,
    upload_id: $upload_id,
    initiated_by: $initiated_by,
    expected_content_type: $expected_content_type,
    expected_content_length: $expected_content_length,
    expected_sha256: $expected_sha256,
    parts: [],
    status: 'initiated',
    created_at: time::now()
  };
};

DEFINE FUNCTION fn::record_object_multipart_part(
  $tenant_id: record<tenants>,
  $multipart_id: record<object_storage_multipart_uploads>,
  $part_number: int,
  $etag: string,
  $size_bytes: number,
  $sha256: option<string>
) {
  LET $upload = SELECT * FROM ONLY $multipart_id;
  IF $upload = NONE THEN { THROW 'multipart_upload_not_found'; };
  IF $upload.tenant_id != $tenant_id THEN { THROW 'tenant_mismatch'; };
  IF $upload.status != 'initiated' THEN { THROW 'multipart_upload_not_open'; };

  UPDATE $multipart_id SET parts += [{ part_number: $part_number, etag: $etag, size_bytes: $size_bytes, sha256: $sha256, recorded_at: time::now() }];
  RETURN SELECT * FROM ONLY $multipart_id;
};

DEFINE FUNCTION fn::complete_object_multipart_upload(
  $tenant_id: record<tenants>,
  $multipart_id: record<object_storage_multipart_uploads>,
  $content_sha256: option<string>,
  $etag: option<string>,
  $actor_id: option<string>
) {
  LET $upload = SELECT * FROM ONLY $multipart_id;
  IF $upload = NONE THEN { THROW 'multipart_upload_not_found'; };
  IF $upload.tenant_id != $tenant_id THEN { THROW 'tenant_mismatch'; };
  IF count($upload.parts) = 0 THEN { THROW 'multipart_upload_has_no_parts'; };

  LET $object = fn::register_object_storage_object(
    $tenant_id,
    $upload.bucket_id,
    $upload.object_key,
    $upload.expected_content_type,
    $upload.expected_content_length,
    IF $content_sha256 != NONE THEN $content_sha256 ELSE $upload.expected_sha256 END,
    { multipart_upload_id: $upload.upload_id, parts: $upload.parts },
    {},
    $upload.initiated_by,
    NONE,
    $actor_id
  );

  UPDATE $multipart_id SET status = 'completed', completed_at = time::now();
  UPDATE $object.id SET etag = $etag, status = 'available', updated_at = time::now();

  RETURN SELECT * FROM ONLY $object.id;
};

DEFINE FUNCTION fn::mark_object_storage_deleted(
  $tenant_id: record<tenants>,
  $object_id: record<object_storage_objects>,
  $actor_id: option<string>,
  $reason: string
) {
  LET $object = SELECT * FROM ONLY $object_id;
  IF $object = NONE THEN { THROW 'object_not_found'; };
  IF $object.tenant_id != $tenant_id THEN { THROW 'tenant_mismatch'; };
  IF $object.legal_hold = true THEN { THROW 'object_under_legal_hold'; };

  UPDATE $object_id SET status = 'deleted', updated_at = time::now();

  CREATE object_storage_events CONTENT {
    tenant_id: $tenant_id,
    provider_id: $object.provider_id,
    bucket_id: $object.bucket_id,
    object_id: $object_id,
    event_type: 'object.deleted',
    actor_id: $actor_id,
    payload: { reason: $reason },
    observed_at: time::now()
  };

  RETURN SELECT * FROM ONLY $object_id;
};

DEFINE FUNCTION fn::require_object_available(
  $object_id: record<object_storage_objects>
) {
  LET $object = SELECT * FROM ONLY $object_id;
  IF $object = NONE THEN { THROW 'object_not_found'; };
  IF $object.status != 'available' AND $object.status != 'registered' THEN { THROW 'object_not_available'; };
  RETURN $object;
};
