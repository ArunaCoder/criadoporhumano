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

test_allowed_method() {
    local description="$1"
    local method="$2"
    local extra_args="$3"

    echo -n "Testing: $description ... "

    http_code=$(curl -X "$method" $extra_args -s -o /dev/null -w "%{http_code}" "$BASE_URL/index.html" 2>/dev/null)

    if [ "$http_code" -eq 200 ]; then
        echo -e "${GREEN}✓ SUCCESS${NC} (HTTP $http_code)"
    elif [ "$http_code" -eq 400 ] || [ "$http_code" -eq 405 ]; then
        echo -e "${RED}✗ BLOCKED${NC} (HTTP $http_code) - Should be allowed!"
    else
        echo -e "${YELLOW}? UNKNOWN${NC} (HTTP $http_code)"
    fi
}

test_forbidden_method() {
    local description="$1"
    local method="$2"
    local extra_args="$3"

    echo -n "Testing: $description ... "

    http_code=$(curl -X "$method" $extra_args -s -o /dev/null -w "%{http_code}" "$BASE_URL/index.html" 2>/dev/null)

    if [ "$http_code" -eq 400 ] || [ "$http_code" -eq 405 ]; then
        echo -e "${GREEN}✓ BLOCKED${NC} (HTTP $http_code)"
    elif [ "$http_code" -eq 200 ]; then
        echo -e "${RED}✗ ALLOWED${NC} (HTTP $http_code) - Should be blocked!"
    else
        echo -e "${YELLOW}? UNKNOWN${NC} (HTTP $http_code)"
    fi
}

echo "Expected: Only GET, POST, HEAD, OPTIONS should work"
echo ""

# Allowed methods (should work)
echo "Allowed methods:"
test_allowed_method "GET" "GET" ""
test_allowed_method "POST" "POST" ""
test_allowed_method "HEAD" "HEAD" ""
test_allowed_method "OPTIONS" "OPTIONS" ""

echo ""
echo "Forbidden methods (should be blocked):"

# Forbidden methods
test_forbidden_method "DELETE" "DELETE" ""
test_forbidden_method "PUT" "PUT" "-d 'malicious data'"
test_forbidden_method "PATCH" "PATCH" ""
test_forbidden_method "TRACE" "TRACE" ""
test_forbidden_method "CONNECT" "CONNECT" ""
test_forbidden_method "HACK (invalid)" "HACK" ""

echo ""
echo "============================"
echo "Method tests completed"
