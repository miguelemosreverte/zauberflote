#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4907

# Test GET locations (seeded with cities)
status=$(curl -s -o /dev/null -w "%{http_code}" "$base/locations")
[ "$status" = "200" ]

# Verify seeded data exists
resp=$(curl -s "$base/locations")
echo "$resp" | grep -q "San Francisco"

# Test search endpoint
resp=$(curl -s "$base/search?q=London")
echo "$resp" | grep -q "London"

# Test POST location
resp=$(curl -s -X POST "$base/locations" -H "Content-Type: application/json" -d '{"name":"Test City","description":"A test","lat":40.0,"lng":-74.0,"category":"test"}')
echo "$resp" | grep -q '"ok"'

# Test validation - name required
status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$base/locations" -H "Content-Type: application/json" -d '{"name":"","lat":40.0,"lng":-74.0}')
[ "$status" = "422" ]

echo "7-geo-search ok"
