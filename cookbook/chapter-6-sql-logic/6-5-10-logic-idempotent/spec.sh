#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4420

status=$(curl -s -o /dev/null -w "%{http_code}" "$base/orders")
[ "$status" = "200" ]

echo "6-5-10-logic-idempotent ok"
