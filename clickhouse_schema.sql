-- Schema for storing logs with template IDs (log-stream-centric)
-- Grafana plugin backend schema for KL divergence analysis

-- Table 1: logs
-- Stores all log entries from log streams with their template IDs
CREATE TABLE IF NOT EXISTS logs
(
    org_id String,                   -- Organization identifier
    log_stream_id String,            -- Log stream identifier
    service String,                  -- Service name (e.g., api-server, database)
    region String,                   -- Region (e.g., us-east-1, eu-west-1)
    log_stream_name String,          -- Full log stream name
    timestamp DateTime64(3),         -- Timestamp of the log entry
    template_id String,              -- ID of the template this log matches
    message String,                  -- Original log message
    INDEX idx_log_stream (org_id, log_stream_id, timestamp) TYPE minmax GRANULARITY 4
)
ENGINE = MergeTree()
PARTITION BY (org_id, toYYYYMM(timestamp))
ORDER BY (org_id, log_stream_id, timestamp, template_id)
TTL timestamp + INTERVAL 30 DAY;


-- Table 2: template_examples
-- Stores representative example logs for each template in each log stream
CREATE TABLE IF NOT EXISTS template_examples
(
    org_id String,                   -- Organization identifier
    log_stream_id String,            -- Log stream identifier
    service String,                  -- Service name
    region String,                   -- Region
    template_id String,              -- ID of the template
    message String,                  -- Representative log message example
    timestamp DateTime64(3),         -- When this example was captured
    INDEX idx_template (org_id, log_stream_id, template_id) TYPE bloom_filter GRANULARITY 4
)
ENGINE = MergeTree()
PARTITION BY org_id
ORDER BY (org_id, log_stream_id, template_id, timestamp);
