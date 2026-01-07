#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4412

for _ in {1..30}; do
  if [ "$(curl -s -o /dev/null -w "%{http_code}" "$base/orders")" = "200" ]; then
    break
  fi
  sleep 0.2
done

status=$(curl -s -o /dev/null -w "%{http_code}" "$base/orders")
[ "$status" = "200" ]

resp=$(curl -s -X POST "$base/orders" -H "Content-Type: application/json" -d '{"item":"Spec Order"}')
id=$(echo "$resp" | python3 -c "import json,sys; data=json.load(sys.stdin); print(data['data']['id'])")

ship_status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$base/orders/$id/ship")
[ "$ship_status" = "422" ]

paid=$(curl -s -X POST "$base/orders/$id/pay")
echo "$paid" | python3 -c "import json,sys; data=json.load(sys.stdin); assert data['data']['status'] == 'paid'"

shipped=$(curl -s -X POST "$base/orders/$id/ship")
echo "$shipped" | python3 -c "import json,sys; data=json.load(sys.stdin); assert data['data']['status'] == 'shipped'"

echo "6-5-2-logic-workflow ok"
