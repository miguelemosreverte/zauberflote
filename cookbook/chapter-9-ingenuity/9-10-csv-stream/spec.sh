#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4910

# Test GET stats
status=$(curl -s -o /dev/null -w "%{http_code}" "$base/stats")
[ "$status" = "200" ]

resp=$(curl -s "$base/stats")
echo "$resp" | grep -q "total_records"

# Test CSV export endpoint
status=$(curl -s -o /dev/null -w "%{http_code}" "$base/export")
[ "$status" = "200" ]

# Verify CSV has header
resp=$(curl -s "$base/export" | head -1)
echo "$resp" | grep -q "id,sensor_id,reading,timestamp"

echo "10-csv-stream ok"
