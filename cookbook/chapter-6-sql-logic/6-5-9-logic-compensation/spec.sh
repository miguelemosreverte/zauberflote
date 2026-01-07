#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4419

status=$(curl -s -o /dev/null -w "%{http_code}" "$base/orders")
[ "$status" = "200" ]

echo "6-5-9-logic-compensation ok"
