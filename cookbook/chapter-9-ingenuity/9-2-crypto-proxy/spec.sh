#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4902

# Test GET prices
status=$(curl -s -o /dev/null -w "%{http_code}" "$base/prices")
[ "$status" = "200" ]

# Verify response contains btc and eth prices
resp=$(curl -s "$base/prices")
echo "$resp" | grep -q "btc"
echo "$resp" | grep -q "eth"

echo "2-crypto-proxy ok"
