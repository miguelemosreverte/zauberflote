#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4413

status=$(curl -s -o /dev/null -w "%{http_code}" "$base/stock")
[ "$status" = "200" ]

resp=$(curl -s -X POST "$base/reserve" -H "Content-Type: application/json" -d '{"sku":"SKU-1","qty":2}')
echo "$resp" | python3 -c "import json,sys; data=json.load(sys.stdin); assert data['data']['sku'] == 'SKU-1'"

fail=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$base/reserve" -H "Content-Type: application/json" -d '{"sku":"NOPE","qty":1}')
[ "$fail" = "422" ]

echo "6-5-3-logic-cross ok"
