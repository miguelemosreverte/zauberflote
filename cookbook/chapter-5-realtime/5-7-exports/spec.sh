#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4307

status=$(curl -s -o /dev/null -w "%{http_code}" "$base/export.csv")
[ "$status" = "200" ]
status=$(curl -s -o /dev/null -w "%{http_code}" "$base/export.json")
[ "$status" = "200" ]

echo "5-7-exports ok"
