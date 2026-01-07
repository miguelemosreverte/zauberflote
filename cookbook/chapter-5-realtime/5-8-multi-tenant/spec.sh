#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4308

status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$base/items" -H "Content-Type: application/json" -H "X-Tenant-ID: alpha" -d '{"name":"alpha-item"}')
[ "$status" = "200" ]
status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$base/items" -H "Content-Type: application/json" -H "X-Tenant-ID: beta" -d '{"name":"beta-item"}')
[ "$status" = "200" ]

resp=$(curl -s "$base/items" -H "X-Tenant-ID: alpha")
echo "$resp" | rg -q 'alpha-item'

echo "5-8-multi-tenant ok"
