#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4905

# Test GET activities
status=$(curl -s -o /dev/null -w "%{http_code}" "$base/activities")
[ "$status" = "200" ]

# Test GET stats
status=$(curl -s -o /dev/null -w "%{http_code}" "$base/stats")
[ "$status" = "200" ]

# Test POST activity
today=$(date +%Y-%m-%d)
resp=$(curl -s -X POST "$base/activities" -H "Content-Type: application/json" -d "{\"date\":\"$today\",\"count\":5,\"category\":\"commits\"}")
echo "$resp" | grep -q '"ok"'

# Test validation - count must be positive
status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$base/activities" -H "Content-Type: application/json" -d '{"date":"2024-01-01","count":0,"category":"test"}')
[ "$status" = "422" ]

echo "5-activity-heatmap ok"
