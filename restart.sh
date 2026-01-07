#!/usr/bin/env bash
set -euo pipefail

# Default to dev mode unless specified
MODE=${1:-"--dev"}

echo "♻️ Restarting Zauberflöte Cookbook in ${MODE} mode..."

./stop.sh
./start.sh "$MODE"
