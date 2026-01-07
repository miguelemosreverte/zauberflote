#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4204

resp=$(curl -s "$base/items?limit=5&offset=0&order=desc")
echo "$resp" | rg -q '"items"'
echo "$resp" | rg -q '"order":"DESC"'

echo "4-4-pagination ok"
