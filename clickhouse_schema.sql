-- Schema for storing log templates and representative logs
-- Grafana plugin backend schema for KL divergence analysis

-- Table 1: logs
-- Stores all log entries with their template IDs for KL divergence analysis
CREATE TABLE IF NOT EXISTS logs
(
    org String,                      -- Organization identifier
    dashboard String,                -- Dashboard identifier
    panel_name String,               -- Panel name/identifier
    metric_name String,              -- Metric name identifier
    timestamp DateTime64(3),         -- Timestamp of the log entry
    template_id String,              -- ID of the template this log matches
    message String,                  -- Original log message
    INDEX idx_org_dashboard (org, dashboard, panel_name, metric_name, timestamp) TYPE minmax GRANULARITY 4
)
ENGINE = MergeTree()
PARTITION BY (org, toYYYYMM(timestamp))
ORDER BY (org, dashboard, panel_name, metric_name, timestamp, template_id)
TTL timestamp + INTERVAL 30 DAY;  -- Adjust retention as needed


-- Table 2: template_examples
-- Stores up to 3 representative example logs for each template
CREATE TABLE IF NOT EXISTS template_examples
(
    org String,                      -- Organization identifier
    dashboard String,                -- Dashboard identifier
    panel_name String,               -- Panel name/identifier
    metric_name String,              -- Metric name identifier
    template_id String,              -- ID of the template
    message String,                  -- Representative log message example
    timestamp DateTime64(3),         -- When this example was captured
    INDEX idx_org_template (org, dashboard, panel_name, metric_name, template_id) TYPE bloom_filter GRANULARITY 4
)
ENGINE = MergeTree()
PARTITION BY (org, dashboard)
ORDER BY (org, dashboard, panel_name, metric_name, template_id, timestamp);
