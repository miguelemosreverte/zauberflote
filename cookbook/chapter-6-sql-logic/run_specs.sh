#!/usr/bin/env bash
set -euo pipefail

apps=(
  6-1-sql-basics 6-2-sql-filters 6-3-sql-aggregations 6-4-sql-joins
  6-6-sql-transactions 6-7-sql-views 6-8-sql-windows
  6-5-1-logic-simple 6-5-2-logic-workflow 6-5-3-logic-cross 6-5-4-logic-policy 6-5-5-logic-readmodel
  6-5-6-logic-time 6-5-7-logic-dependent 6-5-8-logic-branching 6-5-9-logic-compensation 6-5-10-logic-idempotent
)

for dir in "${apps[@]}"; do
  echo "Running $dir spec..."
  (cd "$(dirname "$0")/$dir" && ./spec.sh)
done
