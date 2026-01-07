#!/usr/bin/env bash
set -euo pipefail

for dir in 4-1-validation 4-2-idempotency 4-3-transactions 4-4-pagination 4-5-jobs 4-6-caching 4-7-observability 4-8-uploads; do
  echo "Running $dir spec..."
  (cd "$(dirname "$0")/$dir" && ./spec.sh)
done
