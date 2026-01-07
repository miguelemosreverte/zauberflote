#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4403

status=$(curl -s -o /dev/null -w "%{http_code}" "$base/report")
[ "$status" = "200" ]

echo "6-3-sql-aggregations ok"
