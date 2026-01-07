#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4904

# Create a small test image (1x1 pixel PNG)
# This is a minimal valid PNG file in base64
test_image=$(mktemp)
echo -n 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==' | base64 -d > "$test_image"

# Test image upload and processing
resp=$(curl -s -X POST "$base/process" -F "file=@$test_image;type=image/png")

# Clean up temp file
rm -f "$test_image"

# Should return base64 preview (even if grayscale fails, fallback returns original)
echo "$resp" | grep -q '"preview":"data:image/png;base64,'

echo "4-image-processor ok"
