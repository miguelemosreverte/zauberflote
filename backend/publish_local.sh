#!/usr/bin/env bash
set -euo pipefail

# This script simulates "publishing" the library locally by ensuring
# it's compiled and potentially incrementing versions.

VERSION=$(grep 'version:' mix.exs | cut -d '"' -f 2)
echo "📦 Current version: $VERSION"

if [[ "${1:-}" == "--bump" ]]; then
  NEW_VERSION=$(echo $VERSION | awk -F. '{$NF = $NF + 1;} 1' | sed 's/ /./g')
  sed -i '' "s/version: \"$VERSION\"/version: \"$NEW_VERSION\"/" mix.exs
  VERSION=$NEW_VERSION
  echo "🚀 Bumped to version: $VERSION"
fi

# Run tests
echo "🧪 Running tests..."
mix test

# Compile
echo "🔨 Compiling..."
mix compile

echo "✅ Library 'shared' is ready for local use."
echo "To use it in an app, add this to your mix.exs deps:"
echo '  {:shared, path: "../path/to/libraries/shared"}'
