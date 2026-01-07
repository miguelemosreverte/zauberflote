#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4909

# Test GET settings (seeded)
status=$(curl -s -o /dev/null -w "%{http_code}" "$base/settings")
[ "$status" = "200" ]

resp=$(curl -s "$base/settings")
echo "$resp" | grep -q "site_name"

# Test GET diff (no changes yet)
resp=$(curl -s "$base/settings/diff")
echo "$resp" | grep -q "has_diff"

# Test POST settings (update)
resp=$(curl -s -X POST "$base/settings" -H "Content-Type: application/json" -d '{"site_name":"Updated Site","active":0}')
echo "$resp" | grep -q "Updated Site"

# Test diff after change
resp=$(curl -s "$base/settings/diff")
echo "$resp" | grep -q "has_diff"

echo "9-audit-diff ok"
