#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4202

key="demo-key-$(date +%s)"
resp=$(curl -s -X POST "$base/charge" -H "Content-Type: application/json" -H "Idempotency-Key: $key" -d '{"amount":25}')
echo "$resp" | rg -q '"source":"new"'

resp=$(curl -s -X POST "$base/charge" -H "Content-Type: application/json" -H "Idempotency-Key: $key" -d '{"amount":25}')
echo "$resp" | rg -q '"source":"cached"'

echo "4-2-idempotency ok"
