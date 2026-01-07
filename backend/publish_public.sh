#!/usr/bin/env bash
set -euo pipefail

if [ ! -f .env ]; then
  echo "❌ Error: .env file missing."
  exit 1
fi

# Load variables from .env
export $(grep -v '^#' .env | xargs)

# Use HEX_API_KEY if set, otherwise check for TOKEN (matching user pattern)
AUTH_KEY=${HEX_API_KEY:-${TOKEN:-}}

if [ -z "$AUTH_KEY" ]; then
  echo "❌ Error: Neither HEX_API_KEY nor TOKEN set in .env"
  exit 1
fi

echo "📦 Preparing to publish 'zauberflote' to Hex.pm..."

# Ensure we are in the correct directory
cd "$(dirname "$0")"

# We use the key for the session
echo "🚀 Publishing to Hex.pm..."
mix deps.get
HEX_API_KEY="$AUTH_KEY" mix hex.publish --yes

echo "✅ Published successfully!"