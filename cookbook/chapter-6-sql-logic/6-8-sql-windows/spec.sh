#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4408

status=$(curl -s -o /dev/null -w "%{http_code}" "$base/rankings")
[ "$status" = "200" ]

echo "6-8-sql-windows ok"
