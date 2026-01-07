#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4301

status=$(curl -s -o /dev/null -w "%{http_code}" "$base/messages")
[ "$status" = "200" ]

resp=$(cd "$(dirname "$0")/../tools/ws_client" && go run . -url ws://localhost:4301/ws -msg test123)
echo "$resp" | rg -q 'test123'

echo "5-1-ws-server ok"
