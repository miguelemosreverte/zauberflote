#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4406

status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$base/transfer" -H "Content-Type: application/json" -d '{"from":1,"to":2,"amount":5}')
[ "$status" = "200" ]

status=$(curl -s -o /dev/null -w "%{http_code}" "$base/ledger")
[ "$status" = "200" ]

echo "6-6-sql-transactions ok"
