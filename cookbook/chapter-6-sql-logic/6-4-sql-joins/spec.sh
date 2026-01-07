#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4404

for _ in {1..30}; do
  if [ "$(curl -s -o /dev/null -w "%{http_code}" "$base/books_with_tags")" = "200" ]; then
    break
  fi
  sleep 0.2
done

status=$(curl -s -o /dev/null -w "%{http_code}" "$base/books_with_tags")
[ "$status" = "200" ]

search=$(curl -s "$base/search?author=Ada&tag=classic&q=Algo")
echo "$search" | python3 -c "import json,sys; data=json.load(sys.stdin); assert isinstance(data['data'], list)"

echo "6-4-sql-joins ok"
