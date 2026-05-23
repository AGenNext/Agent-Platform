-- Schema: geospatial
-- Native SurrealDB geometry types for agent location tracking,
-- edge deployment regions, and geofenced objective routing.
-- Ref: https://surrealdb.com/docs/learn/data-models/geospatial/overview

-- ─── Agent location ──────────────────────────────────────────────────────────

DEFINE TABLE agent_location SCHEMAFULL;

DEFINE FIELD `@context`    ON TABLE agent_location TYPE string DEFAULT 'https://schema.org';
DEFINE FIELD `@type`       ON TABLE agent_location TYPE string DEFAULT 'Place';

DEFINE FIELD agent_id      ON TABLE agent_location TYPE string ASSERT $value != NONE;
DEFINE FIELD tenant_id     ON TABLE agent_location TYPE string ASSERT $value != NONE;

-- Native SurrealDB geometry: point = { type: 'Point', coordinates: [lng, lat] }
DEFINE FIELD location      ON TABLE agent_location TYPE geometry<point>;
DEFINE FIELD altitude_m    ON TABLE agent_location TYPE option<float>;
DEFINE FIELD accuracy_m    ON TABLE agent_location TYPE option<float>;

-- Deployment context (cloud region, edge node, on-prem DC)
DEFINE FIELD region        ON TABLE agent_location TYPE option<string>;
DEFINE FIELD node_id       ON TABLE agent_location TYPE option<string>;
DEFINE FIELD environment   ON TABLE agent_location TYPE string DEFAULT 'cloud'
    ASSERT $value IN ['cloud', 'edge', 'on-prem', 'mobile'];

DEFINE FIELD recorded_at   ON TABLE agent_location TYPE datetime DEFAULT time::now();

DEFINE INDEX idx_location_agent    ON TABLE agent_location COLUMNS agent_id;
DEFINE INDEX idx_location_tenant   ON TABLE agent_location COLUMNS tenant_id;
DEFINE INDEX idx_location_recorded ON TABLE agent_location COLUMNS recorded_at;
DEFINE INDEX idx_location_geo      ON TABLE agent_location COLUMNS location;

-- ─── Geofence regions ────────────────────────────────────────────────────────

DEFINE TABLE geofence SCHEMAFULL;

DEFINE FIELD `@context`    ON TABLE geofence TYPE string DEFAULT 'https://schema.org';
DEFINE FIELD `@type`       ON TABLE geofence TYPE string DEFAULT 'Place';

DEFINE FIELD name          ON TABLE geofence TYPE string ASSERT $value != NONE;
DEFINE FIELD description   ON TABLE geofence TYPE option<string>;
DEFINE FIELD tenant_id     ON TABLE geofence TYPE string ASSERT $value != NONE;

-- Polygon, MultiPolygon, or Collection for complex regions
DEFINE FIELD boundary      ON TABLE geofence TYPE geometry<polygon|multipolygon|collection>;
DEFINE FIELD fence_type    ON TABLE geofence TYPE string DEFAULT 'deploy_region'
    ASSERT $value IN ['deploy_region', 'data_residency', 'compliance_zone', 'routing_zone'];

-- Data residency rules (EU, US, APAC)
DEFINE FIELD data_residency ON TABLE geofence TYPE option<string>;
DEFINE FIELD compliance_tags ON TABLE geofence TYPE array DEFAULT [];
DEFINE FIELD active         ON TABLE geofence TYPE bool DEFAULT true;
DEFINE FIELD created_at     ON TABLE geofence TYPE datetime DEFAULT time::now();

DEFINE INDEX idx_geofence_tenant ON TABLE geofence COLUMNS tenant_id;
DEFINE INDEX idx_geofence_active ON TABLE geofence COLUMNS active;
DEFINE INDEX idx_geofence_geo    ON TABLE geofence COLUMNS boundary;

-- ─── Infrastructure node map ─────────────────────────────────────────────────

DEFINE TABLE infra_node SCHEMAFULL;

DEFINE FIELD node_id       ON TABLE infra_node TYPE string ASSERT $value != NONE;
DEFINE FIELD name          ON TABLE infra_node TYPE string ASSERT $value != NONE;
DEFINE FIELD node_type     ON TABLE infra_node TYPE string DEFAULT 'cloud'
    ASSERT $value IN ['cloud', 'edge', 'on-prem', 'satellite'];
DEFINE FIELD location      ON TABLE infra_node TYPE geometry<point>;
DEFINE FIELD region        ON TABLE infra_node TYPE option<string>;
DEFINE FIELD capacity      ON TABLE infra_node TYPE int DEFAULT 0;
DEFINE FIELD active_agents ON TABLE infra_node TYPE int DEFAULT 0;
DEFINE FIELD status        ON TABLE infra_node TYPE string DEFAULT 'healthy'
    ASSERT $value IN ['healthy', 'degraded', 'offline'];
DEFINE FIELD last_seen     ON TABLE infra_node TYPE datetime DEFAULT time::now();

DEFINE INDEX idx_node_id     ON TABLE infra_node COLUMNS node_id UNIQUE;
DEFINE INDEX idx_node_status ON TABLE infra_node COLUMNS status;
DEFINE INDEX idx_node_geo    ON TABLE infra_node COLUMNS location;

-- ─── Geospatial query patterns ───────────────────────────────────────────────

-- Find agents within 50km of a point:
-- SELECT agent_id, location
-- FROM agent_location
-- WHERE location INSIDE {
--     type: 'Circle',
--     center: { type: 'Point', coordinates: [-0.118, 51.509] },
--     radius: 50000
-- };

-- Find all agents inside a geofence:
-- LET $fence = SELECT boundary FROM geofence WHERE name = 'EU-West';
-- SELECT agent_id FROM agent_location
-- WHERE location INSIDE $fence[0].boundary;

-- Find nearest infra node to an agent:
-- SELECT node_id, name, geo::distance(location, $agent_point) AS distance_m
-- FROM infra_node
-- WHERE status = 'healthy'
-- ORDER BY distance_m ASC LIMIT 1;

-- Find agents in a data residency zone for compliance:
-- SELECT al.agent_id, al.location, gf.data_residency
-- FROM agent_location AS al, geofence AS gf
-- WHERE al.location INSIDE gf.boundary
--   AND gf.fence_type = 'data_residency';
