#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4399

status=$(curl -s -o /dev/null -w "%{http_code}" "$base/ping")
[ "$status" = "200" ]

resp=$(curl -s "$base/data")
echo "$resp" | rg -q '"items"'

echo "aux-service ok"
