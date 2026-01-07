#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4101

# Unauthorized
status=$(curl -s -o /dev/null -w "%{http_code}" "$base/protected")
[ "$status" = "401" ]

# Authorized
auth=$(printf 'admin:admin123' | base64)
status=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Basic $auth" "$base/protected")
[ "$status" = "200" ]

echo "3-1-auth-basic ok"
