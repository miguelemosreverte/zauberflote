#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4903

# Test GET search without query (returns all)
status=$(curl -s -o /dev/null -w "%{http_code}" "$base/search")
[ "$status" = "200" ]

# Test search with query
resp=$(curl -s "$base/search?q=elixir")
echo "$resp" | grep -qi "elixir"

# Test search with different query
resp=$(curl -s "$base/search?q=sqlite")
echo "$resp" | grep -qi "sqlite"

echo "3-fuzzy-search ok"
