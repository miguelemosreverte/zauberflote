#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4304
aux=http://localhost:4399

payload='{"event":"invoice.paid","amount":120}'
sig=$(printf "%s" "$payload" | openssl dgst -sha256 -hmac "chapter5_secret" -binary | xxd -p -c 256)

status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$base/webhooks/receive" -H "Content-Type: application/json" -H "X-Signature: $sig" -d "$payload")
[ "$status" = "200" ]

status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$base/webhooks/send" -H "Content-Type: application/json" -d '{"payload":{"event":"notify"}}')
[ "$status" = "200" ]

status=$(curl -s -o /dev/null -w "%{http_code}" "$aux/webhook/log")
[ "$status" = "200" ]

echo "5-4-webhooks ok"
