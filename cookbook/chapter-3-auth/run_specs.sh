#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")" && pwd)
for d in 3-1-auth-basic 3-2-auth-apikey 3-3-auth-jwt 3-4-auth-cookie 3-5-auth-roles 3-6-auth-csrf 3-7-auth-combined 3-8-auth-audit; do
  "$root/$d/spec.sh"
done
