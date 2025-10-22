-- Schema for storing log templates and representative logs
-- Two tables per log stream: one for template IDs and one for representative logs

-- Table 1: Log template IDs for a stream
-- Stores the sequence of template IDs for KL divergence analysis
CREATE TABLE IF NOT EXISTS log_template_ids
(
    org String,                      -- Organization identifier
    dashboard String,                -- Dashboard identifier
    panel_title String,              -- Panel title/identifier
    metric_name String,              -- Metric name identifier
    timestamp DateTime64(3),         -- Timestamp of the log entry
    template_id String,              -- ID of the template this log matches
    log_message String,              -- Original log message (optional, for reference)
    INDEX idx_org_dashboard (org, dashboard, panel_title, metric_name, timestamp) TYPE minmax GRANULARITY 4
)
ENGINE = MergeTree()
PARTITION BY (org, toYYYYMM(timestamp))
ORDER BY (org, dashboard, panel_title, metric_name, timestamp, template_id)
TTL timestamp + INTERVAL 30 DAY;  -- Adjust retention as needed


-- Table 2: Representative logs for each template
-- Stores up to 3 example logs for each template
CREATE TABLE IF NOT EXISTS log_template_representatives
(
    org String,                      -- Organization identifier
    dashboard String,                -- Dashboard identifier
    panel_title String,              -- Panel title/identifier
    metric_name String,              -- Metric name identifier
    template_id String,              -- ID of the template
    template_pattern String,         -- The actual template pattern (e.g., "User <*> logged in from <*>")
    representative_logs Array(String), -- Array of up to 3 representative log messages
    log_count UInt64,                -- Total count of logs matching this template
    first_seen DateTime64(3),        -- When this template was first seen
    last_seen DateTime64(3),         -- When this template was last seen
    INDEX idx_org_template (org, dashboard, panel_title, metric_name, template_id) TYPE bloom_filter GRANULARITY 4
)
ENGINE = ReplacingMergeTree(last_seen)
PARTITION BY (org, dashboard)
ORDER BY (org, dashboard, panel_title, metric_name, template_id);


-- Materialized view to maintain representative log samples (optional)
-- This automatically updates the representatives table as new logs come in
CREATE MATERIALIZED VIEW IF NOT EXISTS log_template_representatives_mv
TO log_template_representatives
AS
SELECT
    org,
    dashboard,
    panel_title,
    metric_name,
    template_id,
    '' as template_pattern,  -- Set by ingestion service
    groupArray(3)(log_message) as representative_logs,
    count() as log_count,
    min(timestamp) as first_seen,
    max(timestamp) as last_seen
FROM log_template_ids
GROUP BY org, dashboard, panel_title, metric_name, template_id;
