#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4103

status=$(curl -s -o /dev/null -w "%{http_code}" "$base/protected")
[ "$status" = "401" ]

token=$(curl -s -X POST "$base/auth/login" -H 'Content-Type: application/json' -d '{"user":"admin","pass":"admin123"}' | python3 -c 'import sys, json; print(json.load(sys.stdin)["data"]["token"])')
status=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $token" "$base/protected")
[ "$status" = "200" ]

echo "3-3-auth-jwt ok"
