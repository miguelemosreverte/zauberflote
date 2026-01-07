#!/usr/bin/env bash
set -euo pipefail

if [ ! -f .env ]; then
  echo "❌ Error: .env file missing."
  exit 1
fi

# Load variables from .env
export $(grep -v '^#' .env | xargs)

# Use TOKEN if NPM_TOKEN is not set (supporting the user's specific .env format)
AUTH_TOKEN=${NPM_TOKEN:-${TOKEN:-}}

if [ -z "$AUTH_TOKEN" ]; then
  echo "❌ Error: Neither NPM_TOKEN nor TOKEN set in .env"
  exit 1
fi

echo "📦 Preparing to publish 'zauberflote'..."

# Create a temporary .npmrc to avoid messing with global settings
NPMRC=$(mktemp)
echo "//registry.npmjs.org/:_authToken=$AUTH_TOKEN" > "$NPMRC"

echo "🚀 Publishing to NPM registry..."
npm_config_userconfig="$NPMRC" npm publish --access public

rm "$NPMRC"
echo "✅ Published successfully!"