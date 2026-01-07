#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4207

status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$base/orders" -H "Content-Type: application/json" -d '{"total":15}')
[ "$status" = "200" ]

resp=$(curl -s "$base/metrics")
echo "$resp" | rg -q 'requests_total'

echo "4-7-observability ok"
