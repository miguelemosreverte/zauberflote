#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4102

status=$(curl -s -o /dev/null -w "%{http_code}" "$base/protected")
[ "$status" = "401" ]

status=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer key-123" "$base/protected")
[ "$status" = "200" ]

echo "3-2-auth-apikey ok"
