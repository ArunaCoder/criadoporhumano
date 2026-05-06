#!/bin/bash

# Run All Security Tests
# Usage: ./run-all-tests.sh

echo "╔══════════════════════════════════════════════╗"
echo "║   Security Test Suite - Complete Run        ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# Check if server is running (accept any HTTP response, even 404)
if ! curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "[0-9]"; then
    echo "❌ Error: Server not running on localhost:8080"
    echo ""
    echo "Please start the server first:"
    echo "  cd backend/api"
    echo "  cargo run"
    exit 1
fi

echo "✓ Server is running"
echo ""

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Run each test suite
bash "$SCRIPT_DIR/test-legitimate.sh"
echo ""
echo ""

bash "$SCRIPT_DIR/test-path-traversal.sh"
echo ""
echo ""

bash "$SCRIPT_DIR/test-headers.sh"
echo ""
echo ""

bash "$SCRIPT_DIR/test-methods.sh"
echo ""
echo ""

echo "╔══════════════════════════════════════════════╗"
echo "║   All Security Tests Completed               ║"
echo "╚══════════════════════════════════════════════╝"
