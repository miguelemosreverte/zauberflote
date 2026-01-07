#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4205

resp=$(curl -s -X POST "$base/jobs" -H "Content-Type: application/json" -d '{"input":"abc"}')
job_id=$(echo "$resp" | rg -o '"id":\s*[0-9]+' | rg -o '[0-9]+' | head -n1)
[ -n "$job_id" ]

sleep 1
resp=$(curl -s "$base/jobs/$job_id")
echo "$resp" | rg -q '"status":"done"'
echo "$resp" | rg -q '"result":"cba"'

echo "4-5-jobs ok"
