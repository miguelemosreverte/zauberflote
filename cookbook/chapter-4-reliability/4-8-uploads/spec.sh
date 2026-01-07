#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4208

file=$(mktemp)
echo "hello upload" > "$file"

resp=$(curl -s -X POST "$base/uploads" -F "file=@$file")
rm -f "$file"

echo "$resp" | rg -q '"filename"'

status=$(curl -s -o /dev/null -w "%{http_code}" "$base/uploads")
[ "$status" = "200" ]

echo "4-8-uploads ok"
