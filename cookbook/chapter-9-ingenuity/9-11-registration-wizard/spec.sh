#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4911

# Test step 1: Create registration with email and fullname
email="test$(date +%s)@example.com"
resp=$(curl -s -X POST "$base/register/step1" -H "Content-Type: application/json" -d "{\"email\":\"$email\",\"fullname\":\"Test User\"}")
echo "$resp" | grep -q '"step":2'

# Test step 2: Choose a plan
resp=$(curl -s -X POST "$base/register/step2" -H "Content-Type: application/json" -d "{\"email\":\"$email\",\"plan\":\"PRO\"}")
echo "$resp" | grep -q '"step":3'

# Test step 3: Complete registration
resp=$(curl -s -X POST "$base/register/complete" -H "Content-Type: application/json" -d "{\"email\":\"$email\"}")
echo "$resp" | grep -q '"message"'

# Test GET registration state (responses wrapped in "data")
resp=$(curl -s "$base/register?email=$email")
echo "$resp" | grep -q '"step"'

echo "11-registration-wizard ok"
