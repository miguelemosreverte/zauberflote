#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4306
aux=http://localhost:4399

# rate limit
for i in 1 2 3 4 5; do
  status=$(curl -s -o /dev/null -w "%{http_code}" -H "X-Client: test" "$base/protected")
  [ "$status" = "200" ]
done
status=$(curl -s -o /dev/null -w "%{http_code}" -H "X-Client: test" "$base/protected")
[ "$status" = "429" ]

# circuit breaker
curl -s -X POST "$aux/flaky/reset" > /dev/null
status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$base/proxy")
[ "$status" = "502" ]
status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$base/proxy")
[ "$status" = "502" ]
status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$base/proxy")
[ "$status" = "503" ]

sleep 6
status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$base/proxy")
[ "$status" = "200" ]

echo "5-6-rate-circuit ok"
