#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4107
jar=$(mktemp)

# api key
status=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer key-123" "$base/protected")
[ "$status" = "200" ]

# session
curl -s -c "$jar" -X POST "$base/auth/login" -H 'Content-Type: application/json' -d '{"user":"admin","pass":"admin123"}' >/dev/null
status=$(curl -s -b "$jar" -o /dev/null -w "%{http_code}" "$base/protected")
[ "$status" = "200" ]

rm -f "$jar"

echo "3-7-auth-combined ok"
