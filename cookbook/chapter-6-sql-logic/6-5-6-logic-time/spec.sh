#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4416

status=$(curl -s -o /dev/null -w "%{http_code}" "$base/subscriptions")
[ "$status" = "200" ]

echo "6-5-6-logic-time ok"
