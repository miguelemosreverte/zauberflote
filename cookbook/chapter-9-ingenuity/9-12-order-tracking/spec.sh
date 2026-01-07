#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4912

# Test creating an order
resp=$(curl -s -X POST "$base/orders" -H "Content-Type: application/json" -d '{"product":"Test Product"}')
tracking_id=$(echo "$resp" | grep -o '"tracking_id":"[^"]*"' | cut -d'"' -f4)
[ -n "$tracking_id" ]

# Test listing orders
status=$(curl -s -o /dev/null -w "%{http_code}" "$base/orders")
[ "$status" = "200" ]

# Test updating order status
resp=$(curl -s -X POST "$base/orders/$tracking_id/update" -H "Content-Type: application/json" -d "{\"tracking_id\":\"$tracking_id\",\"status\":\"SHIPPED\",\"note\":\"Package dispatched\"}")
echo "$resp" | grep -q '"ok"'

# Test tracking an order
resp=$(curl -s "$base/orders/track?id=$tracking_id")
echo "$resp" | grep -q '"events"'
echo "$resp" | grep -q 'SHIPPED'

echo "12-order-tracking ok"
