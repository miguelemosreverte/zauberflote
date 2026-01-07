#!/usr/bin/env bash
set -euo pipefail

VERSION=$(grep "version": package.json | cut -d '"' -f 4)
echo "📦 Current version: $VERSION"

if [[ "${1:-}" == "--bump" ]]; then
  # Basic version bump (increments patch)
  NEW_VERSION=$(echo $VERSION | awk -F. '{$NF = $NF + 1;} 1' | sed 's/ /./g')
  sed -i '' "s/"version": "$VERSION"/"version": "$NEW_VERSION"/" package.json
  VERSION=$NEW_VERSION
  echo "🚀 Bumped to version: $VERSION"
fi

# In JS, "publishing locally" can mean creating a tarball
echo "🔨 Packaging..."
npm pack

echo "✅ UI Library is ready for local use."
echo "To use it in an app, you can install the tarball or link the directory:"
echo "npm install ../path/to/libraries/ui"
