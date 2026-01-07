#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4401

status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$base/items" -H "Content-Type: application/json" -d '{"name":"","price":0}')
[ "$status" = "422" ]

status=$(curl -s -o /dev/null -w "%{http_code}" "$base/items")
[ "$status" = "200" ]

echo "6-1-sql-basics ok"
