#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4414

status=$(curl -s -o /dev/null -w "%{http_code}" "$base/requests")
[ "$status" = "200" ]

echo "6-5-4-logic-policy ok"
