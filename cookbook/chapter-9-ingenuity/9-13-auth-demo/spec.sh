#!/bin/bash
# 9.13 Auth Demo - Login/Register with Task Management
# Demonstrates: User authentication flow, session handling, role-based display

echo "=== Auth Demo ==="
echo ""
echo "Demo accounts:"
echo "  admin / admin123 (admin)"
echo "  alice / alice123 (user)"
echo "  bob   / bob123   (user)"
echo ""

# Test register
echo "1. Register new user 'testuser'..."
curl -s -X POST http://localhost:4913/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"test123"}' | jq .

# Test login
echo ""
echo "2. Login as admin..."
curl -s -X POST http://localhost:4913/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' | jq .

# Test tasks
echo ""
echo "3. List tasks..."
curl -s http://localhost:4913/tasks | jq '.data[:2]'

echo ""
echo "Open http://localhost:4913 in browser for full demo"
