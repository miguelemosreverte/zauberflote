#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4105
jar=$(mktemp)

curl -s -c "$jar" -X POST "$base/auth/login" -H 'Content-Type: application/json' -d '{"user":"user","pass":"user123"}' >/dev/null
status=$(curl -s -b "$jar" -o /dev/null -w "%{http_code}" "$base/user")
[ "$status" = "200" ]
status=$(curl -s -b "$jar" -o /dev/null -w "%{http_code}" "$base/admin")
[ "$status" = "403" ]

rm -f "$jar"

echo "3-5-auth-roles ok"
