#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4302

status=$(curl -s -o /dev/null -w "%{http_code}" "$base/")
[ "$status" = "200" ]

echo "5-2-ws-client ok"
