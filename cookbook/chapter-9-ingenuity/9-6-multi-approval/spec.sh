#!/usr/bin/env bash
set -euo pipefail
base=http://localhost:4906

# The seed data creates invoice ID 1 with status 'DRAFT'
# First, we need to update it to PENDING_MANAGER for the workflow test
# Let's use the seed invoice ID 1 for testing the approval workflow

# Test listing invoices (should have the seeded invoice)
resp=$(curl -s "$base/invoices")
echo "$resp" | grep -q 'Server Upgrade'

# Test creating a new invoice
resp=$(curl -s -X POST "$base/invoices" -H "Content-Type: application/json" -d '{"amount":250.00,"description":"Test Invoice"}')
echo "$resp" | grep -q '"ok"'

# List invoices to find the new one - should see PENDING_MANAGER
resp=$(curl -s "$base/invoices")
echo "$resp" | grep -q 'PENDING_MANAGER'

# Extract the ID of the new invoice (highest ID with PENDING_MANAGER status)
# We'll use jq-like parsing with grep - get last id before PENDING_MANAGER
invoice_id=$(echo "$resp" | grep -o '"id":[0-9]*' | tail -1 | grep -o '[0-9]*')
[ -n "$invoice_id" ]

# Test manager approval
resp=$(curl -s -X POST "$base/invoices/$invoice_id/approve-manager" -H "Content-Type: application/json" -d "{\"id\":$invoice_id}")
echo "$resp" | grep -q '"ok"'

# Verify status changed to PENDING_ACCOUNTANT
resp=$(curl -s "$base/invoices")
echo "$resp" | grep -q 'PENDING_ACCOUNTANT'

# Test accountant payment
resp=$(curl -s -X POST "$base/invoices/$invoice_id/pay" -H "Content-Type: application/json" -d "{\"id\":$invoice_id}")
echo "$resp" | grep -q '"ok"'

# Verify status changed to PAID
resp=$(curl -s "$base/invoices")
echo "$resp" | grep -q 'PAID'

# Test rejection flow - create another invoice then reject it
curl -s -X POST "$base/invoices" -H "Content-Type: application/json" -d '{"amount":99.99,"description":"To Reject"}' > /dev/null
resp=$(curl -s "$base/invoices")
# Get the newest invoice ID
reject_id=$(echo "$resp" | grep -o '"id":[0-9]*' | tail -1 | grep -o '[0-9]*')
resp=$(curl -s -X POST "$base/invoices/$reject_id/reject" -H "Content-Type: application/json" -d "{\"id\":$reject_id}")
echo "$resp" | grep -q '"ok"'

echo "6-multi-approval ok"
