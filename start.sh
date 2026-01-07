#!/usr/bin/env bash
set -euo pipefail

MODE="dev"
while [[ $# -gt 0 ]]; do
  case $1 in
    --prod) MODE="prod"; shift ;;
    --dev)  MODE="dev"; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

ROOT_DIR=$(cd "$(dirname "$0")" && pwd)
./stop.sh || true

if [ "$MODE" == "dev" ]; then
  (cd "$ROOT_DIR/backend" && mix deps.get && mix compile)
  
  # Create the shadow library with the dev markers
  echo "🪄  Injecting development markers into shadow library..."
  echo 'console.log("🪄 Zauberflöte: Live Development Mode (Source: ui/src/ui.js)");' > "$ROOT_DIR/ui/src/.ui_dev.js"
  echo 'console.log("🚀 Any changes you save will appear here on refresh.");' >> "$ROOT_DIR/ui/src/.ui_dev.js"
  cat "$ROOT_DIR/ui/src/ui.js" >> "$ROOT_DIR/ui/src/.ui_dev.js"
fi

(cd "$ROOT_DIR/cookbook/portal" && go run . > /tmp/portal.log 2>&1 &)
sleep 2

find "$ROOT_DIR/cookbook" -name "mix.exs" -not -path "*/deps/*" -not -path "*/portal/*" | while read mixfile; do
  app_dir=$(dirname "$mixfile")
  app_name=$(basename "$app_dir")
  
  if [ "$MODE" == "dev" ]; then
    sed -i '' 's/{:zauberflote, [^}]*}/{:zauberflote, path: "..\/..\/..\/backend"}/' "$mixfile"
    [[ "$app_dir" == *"/chapter-0-welcome" ]] && sed -i '' 's/path: "..\/..\/..\/backend"/path: "..\/..\/backend"/' "$mixfile"
    
    mkdir -p "$app_dir/priv/static"
    # Point to the SHADOW library in dev mode
    ln -sf "$ROOT_DIR/ui/src/.ui_dev.js" "$app_dir/priv/static/ui.js"
    
    if [ -f "$app_dir/priv/static/index.html" ]; then
      sed -i '' 's|import ui from .*;|import ui from "/ui.js";|g' "$app_dir/priv/static/index.html"
    fi
  else
    sed -i '' 's/{:zauberflote, [^}]*}/{:zauberflote, "~> 1.0"}/' "$mixfile"
    rm -f "$app_dir/priv/static/ui.js"
    if [ -f "$app_dir/priv/static/index.html" ]; then
      sed -i '' 's|import ui from .*;|import ui from "https://unpkg.com/zauberflote@1.0.0/src/ui.js";|g' "$app_dir/priv/static/index.html"
    fi
  fi

  (cd "$app_dir" && mix deps.get && nohup mix run --no-halt > "/tmp/cookbook_${app_name}.log" 2>&1 &)
done
echo "✨ Started in ${MODE} mode. Portal: http://localhost:1990"
