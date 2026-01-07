#!/usr/bin/env bash
set -euo pipefail

for dir in aux-service 5-1-ws-server 5-2-ws-client 5-3-http-client 5-4-webhooks 5-5-scheduler 5-6-rate-circuit 5-7-exports 5-8-multi-tenant; do
  echo "Running $dir spec..."
  (cd "$(dirname "$0")/$dir" && ./spec.sh)
done
