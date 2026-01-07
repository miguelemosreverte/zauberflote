#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4402

status=$(curl -s -o /dev/null -w "%{http_code}" "$base/products?limit=1&offset=0")
[ "$status" = "200" ]

echo "6-2-sql-filters ok"
