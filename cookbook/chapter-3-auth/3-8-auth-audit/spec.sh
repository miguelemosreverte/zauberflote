#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4108

curl -s -X POST "$base/auth/login" -H 'Content-Type: application/json' -d '{"user":"admin","pass":"admin123"}' >/dev/null
count=$(curl -s "$base/audit" | python3 -c 'import sys, json; print(len(json.load(sys.stdin)["data"]))')
[ "$count" -ge 1 ]

echo "3-8-auth-audit ok"
