#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4417

status=$(curl -s -o /dev/null -w "%{http_code}" "$base/projects")
[ "$status" = "200" ]

echo "6-5-7-logic-dependent ok"
