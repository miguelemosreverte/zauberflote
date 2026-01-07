#!/usr/bin/env bash
echo "🛑 Stopping all Book services..."
pkill -f "go run ." || true
pkill -9 -f "beam.smp" || true
# Clean up shadow dev assets
rm -f ui/src/.ui_dev.js
echo "✅ Done."
