#!/bin/bash

# Test Header Bomb Attacks
# Usage: ./test-headers.sh

echo "💣 Header Bomb Attack Tests"
echo "============================"
echo ""

BASE_URL="http://localhost:8080"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

test_header() {
    local description="$1"
    shift

    echo -n "Testing: $description ... "

    http_code=$(curl -s -o /dev/null -w "%{http_code}" "$@" "$BASE_URL/" 2>/dev/null)

    if [ "$http_code" -eq 400 ] || [ "$http_code" -eq 431 ]; then
        echo -e "${GREEN}✓ BLOCKED${NC} (HTTP $http_code)"
    elif [ "$http_code" -eq 200 ]; then
        echo -e "${YELLOW}⚠ ACCEPTED${NC} (HTTP $http_code)"
    else
        echo -e "${RED}✗ ERROR${NC} (HTTP $http_code)"
    fi
}

test_header_success() {
    local description="$1"
    shift

    echo -n "Testing: $description ... "

    http_code=$(curl -s -o /dev/null -w "%{http_code}" "$@" "$BASE_URL/" 2>/dev/null)

    if [ "$http_code" -eq 200 ]; then
        echo -e "${GREEN}✓ SUCCESS${NC} (HTTP $http_code)"
    elif [ "$http_code" -eq 400 ] || [ "$http_code" -eq 431 ]; then
        echo -e "${RED}✗ BLOCKED${NC} (HTTP $http_code) - Should be accepted!"
    else
        echo -e "${RED}✗ ERROR${NC} (HTTP $http_code)"
    fi
}

echo "Expected: Giant headers and excessive quantity should be BLOCKED"
echo ""

# Test 1: Giant header (exceeds MAX_LINE_SIZE)
test_header "Giant header (10KB)" -H "X-Giant: $(python -c 'import sys; sys.stdout.write("A"*10000)')"

# Test 2: Many headers (exceeds MAX_HEADERS)
echo -n "Testing: Many headers (150) ... "
HEADERS=""
for i in {1..150}; do
    HEADERS="$HEADERS -H \"X-Test-$i: value\""
done
http_code=$(eval "curl -s -o /dev/null -w '%{http_code}' $HEADERS $BASE_URL/ 2>/dev/null")

if [ "$http_code" -eq 400 ]; then
    echo -e "${GREEN}✓ BLOCKED${NC} (HTTP $http_code)"
elif [ "$http_code" -eq 200 ]; then
    echo -e "${YELLOW}⚠ ACCEPTED${NC} (HTTP $http_code)"
else
    echo -e "${RED}✗ ERROR${NC} (HTTP $http_code)"
fi

# Test 3: Header with spaces (valid HTTP behavior, server trims correctly)
test_header_success "Spaced header values (trim test)" -H "X-Custom-Header:   spaced value   "

echo ""
echo "============================"
echo "Header tests completed"
