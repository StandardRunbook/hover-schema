-- ClickHouse Schema for Metric-Log Stream Mappings
-- Supports many-to-many relationships between metrics and log streams

-- Organizations table
CREATE TABLE IF NOT EXISTS organizations (
    id String,
    name String,
    created_at DateTime DEFAULT now(),
    updated_at DateTime DEFAULT now()
) ENGINE = ReplacingMergeTree(updated_at)
ORDER BY (id)
PRIMARY KEY (id);

-- Metrics table
CREATE TABLE IF NOT EXISTS metrics (
    id String,
    org_id String,
    dashboard_name String,
    panel_title String,
    metric_name String,
    created_at DateTime DEFAULT now(),
    updated_at DateTime DEFAULT now()
) ENGINE = ReplacingMergeTree(updated_at)
ORDER BY (id, org_id)
PRIMARY KEY (id);

-- Log streams table
CREATE TABLE IF NOT EXISTS log_streams (
    id String,
    org_id String,
    service String,
    region String,
    log_stream_name String,
    created_at DateTime DEFAULT now(),
    updated_at DateTime DEFAULT now()
) ENGINE = ReplacingMergeTree(updated_at)
ORDER BY (id, service, region)
PRIMARY KEY (id);

-- Many-to-many mapping table
CREATE TABLE IF NOT EXISTS metric_log_mappings (
    id String,
    org_id String,
    metric_id String,
    log_stream_id String,
    created_at DateTime DEFAULT now(),
    is_active UInt8 DEFAULT 1,
    deleted_at DateTime DEFAULT toDateTime('1970-01-01 00:00:00')
) ENGINE = ReplacingMergeTree(deleted_at)
ORDER BY (id, org_id, metric_id, log_stream_id)
PRIMARY KEY (id);

-- Materialized view for fast hover queries
-- Pre-joins metric and log stream data for instant lookups
CREATE MATERIALIZED VIEW IF NOT EXISTS metric_log_hover_mv
ENGINE = MergeTree()
ORDER BY (org_id, dashboard_name, panel_title, metric_name, log_stream_id)
POPULATE
AS
SELECT
    mm.org_id AS org_id,
    m.dashboard_name AS dashboard_name,
    m.panel_title AS panel_title,
    m.metric_name AS metric_name,
    ls.id AS log_stream_id,
    ls.service AS service,
    ls.region AS region,
    ls.log_stream_name AS log_stream_name,
    mm.created_at AS created_at,
    mm.is_active AS is_active
FROM metric_log_mappings mm
JOIN metrics m ON mm.metric_id = m.id
JOIN log_streams ls ON mm.log_stream_id = ls.id;

-- Example queries:

-- 1. Get all log streams for a metric (hover query)
-- SELECT
--     log_stream_id,
--     service,
--     region,
--     log_stream_name
-- FROM metric_log_hover_mv
-- WHERE org_id = 'org123'
--   AND dashboard_name = 'main-dashboard'
--   AND panel_title = 'CPU Usage'
--   AND metric_name = 'cpu_percent'
--   AND is_active = 1;

-- 2. Get all active mappings with full details
-- SELECT
--     org_id,
--     dashboard_name,
--     panel_title,
--     metric_name,
--     service,
--     region,
--     log_stream_name,
--     created_at
-- FROM metric_log_hover_mv
-- WHERE is_active = 1
-- ORDER BY created_at DESC;

-- 3. Get mapping count by organization
-- SELECT
--     org_id,
--     count(*) as total_mappings
-- FROM metric_log_hover_mv
-- WHERE is_active = 1
-- GROUP BY org_id
-- ORDER BY total_mappings DESC;
