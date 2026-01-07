#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4305

status=$(curl -s -o /dev/null -w "%{http_code}" "$base/status")
[ "$status" = "200" ]

sleep 3
status=$(curl -s -o /dev/null -w "%{http_code}" "$base/ticks")
[ "$status" = "200" ]

echo "5-5-scheduler ok"
