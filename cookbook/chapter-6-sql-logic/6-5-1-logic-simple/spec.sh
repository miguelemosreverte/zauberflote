#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4411

status=$(curl -s -o /dev/null -w "%{http_code}" "$base/tickets")
[ "$status" = "200" ]

echo "6-5-1-logic-simple ok"
