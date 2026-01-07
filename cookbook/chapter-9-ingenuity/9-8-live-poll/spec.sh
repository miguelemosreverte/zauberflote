#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4908

# Test GET polls
status=$(curl -s -o /dev/null -w "%{http_code}" "$base/polls")
[ "$status" = "200" ]

# Test GET poll by id (seeded poll)
resp=$(curl -s "$base/polls/1")
echo "$resp" | grep -q "programming language"

# Verify poll options exist
echo "$resp" | grep -q "options"

# Test voting
status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$base/vote/1")
[ "$status" = "200" ]

# Test results endpoint
resp=$(curl -s "$base/results/1")
echo "$resp" | grep -q "votes"

# Test POST new poll
resp=$(curl -s -X POST "$base/polls" -H "Content-Type: application/json" -d '{"question":"Test poll?","options":"Yes,No,Maybe"}')
echo "$resp" | grep -q '"ok"'

# Test validation - question required
status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$base/polls" -H "Content-Type: application/json" -d '{"question":"","options":"A,B"}')
[ "$status" = "422" ]

echo "8-live-poll ok"
