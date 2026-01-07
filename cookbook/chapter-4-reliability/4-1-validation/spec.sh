#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4201

status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$base/items" -H "Content-Type: application/json" -d '{"name":"","price":0}')
[ "$status" = "422" ]

name="Item$(date +%s)"
resp=$(curl -s -X POST "$base/items" -H "Content-Type: application/json" -d "{\"name\":\"$name\",\"price\":12.5}")
echo "$resp" | grep -q '"id"'

status=$(curl -s -o /dev/null -w "%{http_code}" "$base/items")
[ "$status" = "200" ]

echo "4-1-validation ok"
