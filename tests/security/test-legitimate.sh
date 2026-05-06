#!/bin/bash

# Test Legitimate Requests (Baseline)
# Usage: ./test-legitimate.sh

echo "✅ Legitimate Request Tests (Baseline)"
echo "======================================"
echo ""

BASE_URL="http://localhost:8080"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

test_request() {
    local description="$1"
    shift
    local curl_args="$@"

    echo -n "Testing: $description ... "

    http_code=$(eval "curl -s -o /dev/null -w '%{http_code}' $curl_args 2>/dev/null")

    if [ "$http_code" -eq 200 ]; then
        echo -e "${GREEN}✓ SUCCESS${NC} (HTTP $http_code)"
    else
        echo -e "${RED}✗ FAILED${NC} (HTTP $http_code)"
    fi
}

echo "Expected: All legitimate requests should return 200 OK"
echo ""

# Test 1: Simple GET
test_request "Simple GET" "$BASE_URL/index.html"

# Test 2: GET with custom headers
test_request "GET with custom headers" \
    "$BASE_URL/index.html -H 'Content-Type: application/json' -H 'X-Custom-Header: test'"

# Test 3: POST with JSON
test_request "POST with JSON" \
    "$BASE_URL/api/data -X POST -H 'Content-Type: application/json' -d '{\"name\":\"test\",\"value\":123}'"
echo -e "  ${YELLOW}ℹ${NC}  Note: This will be corrected when POST method is implemented"

# Test 4: HEAD request
test_request "HEAD request" "$BASE_URL/index.html -X HEAD"

# Test 5: GET root path
test_request "GET root path" "$BASE_URL/"

echo ""
echo "======================================"
echo "Legitimate request tests completed"
