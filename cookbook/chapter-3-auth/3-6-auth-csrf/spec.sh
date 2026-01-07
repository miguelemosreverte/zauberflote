#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4106
jar=$(mktemp)

curl -s -c "$jar" -X POST "$base/auth/login" -H 'Content-Type: application/json' -d '{"user":"admin","pass":"admin123"}' >/dev/null
csrf=$(curl -s -b "$jar" "$base/csrf" | python3 -c 'import sys, json; print(json.load(sys.stdin)["data"]["token"])')
status=$(curl -s -b "$jar" -o /dev/null -w "%{http_code}" -X POST "$base/protected" -H "X-CSRF-Token: $csrf" -H 'Content-Type: application/json' -d '{"ping":true}')
[ "$status" = "200" ]

rm -f "$jar"

echo "3-6-auth-csrf ok"
