# hover-schema

ClickHouse schema for storing log templates and representative logs for KL divergence analysis.

## Quick Start

### Start ClickHouse

```bash
docker run -d --name clickhouse-server \
  -p 8123:8123 \
  -p 9000:9000 \
  --ulimit nofile=262144:262144 \
  clickhouse/clickhouse-server
```

### Create Schema

```bash
docker exec -i clickhouse-server clickhouse-client --multiquery < clickhouse_schema.sql
```

### Verify Setup

```bash
docker exec clickhouse-server clickhouse-client -q "SHOW TABLES"
```

## Schema Overview

### Table 1: `log_template_ids`

Stores the sequence of template IDs for each log stream. Used for KL divergence analysis.

**Columns:**
- `stream_name` - Log stream identifier
- `timestamp` - Log timestamp (DateTime64 with millisecond precision)
- `template_id` - Template ID that the log matches
- `log_message` - Original log message (optional reference)

**Features:**
- Partitioned by month (`toYYYYMM(timestamp)`)
- 30-day TTL (configurable)
- Ordered by `(stream_name, timestamp, template_id)`

### Table 2: `log_template_representatives`

Stores up to 3 representative logs for each template.

**Columns:**
- `stream_name` - Log stream identifier
- `template_id` - Template ID
- `template_pattern` - Template pattern string (e.g., "User <*> logged in from <*>")
- `representative_logs` - Array of up to 3 example log messages
- `log_count` - Total count of logs matching this template
- `first_seen` - First occurrence timestamp
- `last_seen` - Last occurrence timestamp

**Features:**
- Uses `ReplacingMergeTree` to deduplicate by latest `last_seen`
- Partitioned by `stream_name`

## Usage Examples

### Insert Template ID

```sql
INSERT INTO log_template_ids (stream_name, timestamp, template_id, log_message)
VALUES ('app-server', now(), 'tpl_001', 'User john logged in from 192.168.1.1');
```

### Insert/Update Representative Logs

```sql
INSERT INTO log_template_representatives
(stream_name, template_id, template_pattern, representative_logs, log_count, first_seen, last_seen)
VALUES (
  'app-server',
  'tpl_001',
  'User <*> logged in from <*>',
  ['User john logged in from 192.168.1.1', 'User jane logged in from 10.0.0.1', 'User bob logged in from 172.16.0.1'],
  150,
  now(),
  now()
);
```

### Query Templates for a Stream

```sql
SELECT * FROM log_template_representatives
WHERE stream_name = 'app-server'
ORDER BY log_count DESC;
```

### Query Template ID Sequence

```sql
SELECT timestamp, template_id
FROM log_template_ids
WHERE stream_name = 'app-server'
  AND timestamp >= now() - INTERVAL 1 HOUR
ORDER BY timestamp;
```

## Docker Management

### Stop ClickHouse

```bash
docker stop clickhouse-server
```

### Start Existing Container

```bash
docker start clickhouse-server
```

### Remove Container

```bash
docker rm -f clickhouse-server
```

### Access ClickHouse Client

```bash
docker exec -it clickhouse-server clickhouse-client
```

## Configuration

### Adjust TTL

Edit `clickhouse_schema.sql` and modify:
```sql
TTL timestamp + INTERVAL 30 DAY;  -- Change 30 to desired days
```

### Ports

- `8123` - HTTP interface
- `9000` - Native TCP interface
