#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4104
jar=$(mktemp)

status=$(curl -s -o /dev/null -w "%{http_code}" "$base/protected")
[ "$status" = "401" ]

curl -s -c "$jar" -X POST "$base/auth/login" -H 'Content-Type: application/json' -d '{"user":"admin","pass":"admin123"}' >/dev/null
status=$(curl -s -b "$jar" -o /dev/null -w "%{http_code}" "$base/protected")
[ "$status" = "200" ]

rm -f "$jar"

echo "3-4-auth-cookie ok"
