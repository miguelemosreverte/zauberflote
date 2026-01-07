#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4407

status=$(curl -s -o /dev/null -w "%{http_code}" "$base/totals")
[ "$status" = "200" ]

echo "6-7-sql-views ok"
