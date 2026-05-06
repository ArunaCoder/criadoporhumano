#!/bin/bash

# Test Path Traversal Attacks
# Usage: ./test-path-traversal.sh

echo "🚨 Path Traversal Attack Tests"
echo "================================"
echo ""

BASE_URL="http://localhost:8080"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

test_path() {
    local description="$1"
    local path="$2"
    local extra_flags="$3"

    echo -n "Testing: $description ... "

    http_code=$(curl $extra_flags -s -o /dev/null -w "%{http_code}" "$BASE_URL$path" 2>/dev/null)

    if [ "$http_code" -eq 400 ] || [ "$http_code" -eq 404 ]; then
        echo -e "${GREEN}✓ BLOCKED${NC} (HTTP $http_code)"
    elif [ "$http_code" -eq 200 ]; then
        echo -e "${RED}✗ VULNERABLE${NC} (HTTP $http_code) - File accessed!"
    else
        echo -e "${YELLOW}? UNKNOWN${NC} (HTTP $http_code)"
    fi
}

echo "Expected: All tests should be BLOCKED (400/404)"
echo ""

# Test 1: Classic path traversal
test_path "Classic ../ attack" "/../secret.txt" "--path-as-is"

# Test 2: Multiple levels
test_path "Multiple ../ levels" "/../../../etc/passwd" "--path-as-is"

# Test 3: Double encoding
test_path "Double encoding bypass" "/%2e%2e%2fsecret.txt" ""

# Test 4: Double slashes
test_path "Double slashes //" "//etc/passwd" ""

# Test 5: Dot normalization
test_path "Dot normalization" "/./././secret.txt" "--path-as-is"

# Test 6: Escape and return
test_path "Escape and return" "/../public/index.html" "--path-as-is"

# Test 7: Windows separators
test_path "Windows path separator" "/..\secret.txt" "--path-as-is"

echo ""
echo "================================"
echo "Path traversal tests completed"
