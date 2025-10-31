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

-- Example queries:

-- 1. Get all active mappings with full details
-- SELECT
--     o.name,
--     m.dashboard_name,
--     m.panel_title,
--     m.metric_name,
--     ls.service,
--     ls.region,
--     ls.log_stream_name,
--     mm.created_at
-- FROM metric_log_mappings mm FINAL
-- JOIN organizations o ON mm.org_id = o.id
-- JOIN metrics m ON mm.metric_id = m.id
-- JOIN log_streams ls ON mm.log_stream_id = ls.id
-- WHERE mm.is_active = 1
-- ORDER BY mm.created_at DESC;

-- 2. Get mapping count by organization
-- SELECT
--     o.name,
--     count(*) as total_mappings
-- FROM metric_log_mappings mm FINAL
-- JOIN organizations o ON mm.org_id = o.id
-- WHERE mm.is_active = 1
-- GROUP BY o.name
-- ORDER BY total_mappings DESC;
