#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4901

# Test GET employees (seeded with CEO)
status=$(curl -s -o /dev/null -w "%{http_code}" "$base/employees")
[ "$status" = "200" ]

# Verify data exists
resp=$(curl -s "$base/employees")
echo "$resp" | grep -q "Alice"

# Test GET employees/tree (recursive CTE)
status=$(curl -s -o /dev/null -w "%{http_code}" "$base/employees/tree")
[ "$status" = "200" ]

resp=$(curl -s "$base/employees/tree")
echo "$resp" | grep -q "Alice"
echo "$resp" | grep -q "depth"

echo "1-org-chart ok"
