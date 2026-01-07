#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4303

status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$base/reset")
[ "$status" = "200" ]

resp=$(curl -s -X POST "$base/fetch" -H "Content-Type: application/json" -d '{"retries":3}')
echo "$resp" | rg -q '"attempts"'

echo "5-3-http-client ok"
