#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4418

status=$(curl -s -o /dev/null -w "%{http_code}" "$base/applications")
[ "$status" = "200" ]

echo "6-5-8-logic-branching ok"
