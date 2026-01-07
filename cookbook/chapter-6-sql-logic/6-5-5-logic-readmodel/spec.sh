#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4415

status=$(curl -s -o /dev/null -w "%{http_code}" "$base/balances")
[ "$status" = "200" ]

echo "6-5-5-logic-readmodel ok"
