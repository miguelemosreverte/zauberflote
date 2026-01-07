#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4203

status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$base/transfer" -H "Content-Type: application/json" -d '{"from":1,"to":2,"amount":9999}')
[ "$status" = "422" ]

status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$base/transfer" -H "Content-Type: application/json" -d '{"from":1,"to":2,"amount":10}')
[ "$status" = "200" ]

resp=$(curl -s "$base/accounts")
echo "$resp" | rg -q '"id"'

echo "4-3-transactions ok"
