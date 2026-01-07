#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4206

resp=$(curl -s "$base/summary")
echo "$resp" | rg -q '"cached":false'

resp=$(curl -s "$base/summary")
echo "$resp" | rg -q '"cached":true'

status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$base/events" -H "Content-Type: application/json" -d '{"amount":5}')
[ "$status" = "200" ]

resp=$(curl -s "$base/summary")
echo "$resp" | rg -q '"cached":false'

echo "4-6-caching ok"
