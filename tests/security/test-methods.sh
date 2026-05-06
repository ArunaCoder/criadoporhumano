#!/bin/bash

# Test HTTP Method Attacks
# Usage: ./test-methods.sh

echo "⚔️  HTTP Method Attack Tests"
echo "============================"
echo ""

BASE_URL="http://localhost:8080"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

test_method() {
    local description="$1"
    local method="$2"
    local extra_args="$3"

    echo -n "Testing: $description ... "

    http_code=$(curl -X "$method" $extra_args -s -o /dev/null -w "%{http_code}" "$BASE_URL/index.html" 2>/dev/null)

    if [ "$http_code" -eq 400 ] || [ "$http_code" -eq 405 ]; then
        echo -e "${GREEN}✓ BLOCKED${NC} (HTTP $http_code)"
    elif [ "$http_code" -eq 200 ]; then
        echo -e "${RED}✗ ALLOWED${NC} (HTTP $http_code)"
    else
        echo -e "${YELLOW}? UNKNOWN${NC} (HTTP $http_code)"
    fi
}

echo "Expected: Only GET, POST, HEAD, OPTIONS should work"
echo ""

# Allowed methods (should work)
echo "Allowed methods:"
test_method "GET" "GET" ""
test_method "POST" "POST" ""
test_method "HEAD" "HEAD" ""
test_method "OPTIONS" "OPTIONS" ""

echo ""
echo "Forbidden methods (should be blocked):"

# Forbidden methods
test_method "DELETE" "DELETE" ""
test_method "PUT" "PUT" "-d 'malicious data'"
test_method "PATCH" "PATCH" ""
test_method "TRACE" "TRACE" ""
test_method "CONNECT" "CONNECT" ""
test_method "HACK (invalid)" "HACK" ""

echo ""
echo "============================"
echo "Method tests completed"
