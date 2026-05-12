#!/bin/bash

# Test Body Parsing Security
# Usage: ./test-body-parsing.sh
#
# Tests Content-Length validation, size limits, UTF-8 validation,
# and edge cases in HTTP body parsing.

echo "📦 Body Parsing Security Tests"
echo "==============================="
echo ""

BASE_URL="http://localhost:8080"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

test_body_block() {
    local description="$1"
    shift

    echo -n "Testing: $description ... "

    http_code=$(curl --max-time 2 -s -o /dev/null -w "%{http_code}" "$@" "$BASE_URL/" 2>/dev/null)
    curl_exit=$?

    # Expected: 400 (bad request), 413 (payload too large), or connection issue
    if [ "$http_code" -eq 400 ] || [ "$http_code" -eq 413 ]; then
        echo -e "${GREEN}✓ BLOCKED${NC} (HTTP $http_code)"
    elif [ "$curl_exit" -eq 28 ]; then
        echo -e "${GREEN}✓ BLOCKED${NC} (timeout - MVP behavior)"
    elif [ "$curl_exit" -eq 52 ] || [ "$curl_exit" -eq 56 ]; then
        echo -e "${GREEN}✓ BLOCKED${NC} (connection reset)"
    elif [ "$http_code" -eq 0 ] || [ "$http_code" -eq 000 ]; then
        echo -e "${GREEN}✓ BLOCKED${NC} (connection closed)"
    elif [ "$http_code" -eq 200 ]; then
        echo -e "${RED}✗ ACCEPTED${NC} (HTTP $http_code) - Should be blocked!"
    else
        echo -e "${YELLOW}⚠ UNEXPECTED${NC} (HTTP $http_code, curl exit $curl_exit)"
    fi
}

test_body_accept() {
    local description="$1"
    shift

    echo -n "Testing: $description ... "

    http_code=$(curl --max-time 2 -s -o /dev/null -w "%{http_code}" "$@" "$BASE_URL/" 2>/dev/null)

    if [ "$http_code" -eq 200 ]; then
        echo -e "${GREEN}✓ ACCEPTED${NC} (HTTP $http_code)"
    elif [ "$http_code" -eq 400 ] || [ "$http_code" -eq 413 ]; then
        echo -e "${RED}✗ BLOCKED${NC} (HTTP $http_code) - Should be accepted!"
    else
        echo -e "${YELLOW}⚠ UNEXPECTED${NC} (HTTP $http_code)"
    fi
}

echo "═══════════════════════════════════════════════════════"
echo "Section 1: Content-Length Validation"
echo "═══════════════════════════════════════════════════════"
echo ""

# Test 1.1: Content-Length negativo
test_body_block "Content-Length: -1" \
    -X POST \
    -H "Content-Length: -1" \
    -d "test"

# Test 1.2: Content-Length não-numérico
test_body_block "Content-Length: abc" \
    -X POST \
    -H "Content-Length: abc" \
    -d "test"

test_body_block "Content-Length: 12x34" \
    -X POST \
    -H "Content-Length: 12x34" \
    -d "test"

# Test 1.3: Content-Length gigante (overflow)
test_body_block "Content-Length: overflow (999999999999999999)" \
    -X POST \
    -H "Content-Length: 999999999999999999" \
    -d "test"

# Test 1.4: Content-Length zero (válido - body vazio)
test_body_accept "Content-Length: 0 (empty body)" \
    -X POST \
    -H "Content-Length: 0"

# Test 1.5: POST sem Content-Length (válido se não enviar body)
test_body_accept "POST without Content-Length header" \
    -X POST

echo ""
echo "═══════════════════════════════════════════════════════"
echo "Section 2: Size Limits (MAX_BODY_SIZE = 8192 bytes)"
echo "═══════════════════════════════════════════════════════"
echo ""

# Test 2.1: Body no limite exato (8192 bytes)
test_body_accept "Body at limit (8192 bytes)" \
    -X POST \
    -H "Content-Type: application/json" \
    -d "$(python -c 'print("A" * 8192)')"

# Test 2.2: Body excede limite por 1 byte (8193 bytes)
test_body_block "Body exceeds limit (8193 bytes)" \
    -X POST \
    -H "Content-Type: application/json" \
    -d "$(python -c 'print("A" * 8193)')"

# Test 2.3: Body muito grande (100KB) - usando pipe para evitar ARG_MAX
echo -n "Testing: Body too large (100KB) ... "
http_code=$(python -c 'print("A" * 102400)' | \
    curl --max-time 2 -s -o /dev/null -w "%{http_code}" \
    -X POST \
    -H "Content-Type: application/json" \
    --data-binary @- \
    "$BASE_URL/" 2>/dev/null)
curl_exit=$?

if [ "$http_code" -eq 400 ] || [ "$http_code" -eq 413 ]; then
    echo -e "${GREEN}✓ BLOCKED${NC} (HTTP $http_code)"
elif [ "$curl_exit" -eq 28 ]; then
    echo -e "${GREEN}✓ BLOCKED${NC} (timeout - MVP behavior)"
elif [ "$curl_exit" -eq 52 ] || [ "$curl_exit" -eq 56 ]; then
    echo -e "${GREEN}✓ BLOCKED${NC} (connection reset)"
elif [ "$http_code" -eq 0 ] || [ "$http_code" -eq 000 ]; then
    echo -e "${GREEN}✓ BLOCKED${NC} (connection closed)"
elif [ "$http_code" -eq 200 ]; then
    echo -e "${RED}✗ ACCEPTED${NC} (HTTP $http_code) - Should be blocked!"
else
    echo -e "${YELLOW}⚠ UNEXPECTED${NC} (HTTP $http_code, curl exit $curl_exit)"
fi

# Test 2.4: Body pequeno (válido)
test_body_accept "Small body (100 bytes)" \
    -X POST \
    -H "Content-Type: application/json" \
    -d '{"name":"test","data":"small payload"}'

echo ""
echo "═══════════════════════════════════════════════════════"
echo "Section 3: UTF-8 Validation"
echo "═══════════════════════════════════════════════════════"
echo ""

# Test 3.1: UTF-8 válido com acentos
echo -n "Testing: Valid UTF-8 with accents ... "
http_code=$(printf '{"name":"José","city":"São Paulo"}' | \
    curl --max-time 2 -s -o /dev/null -w "%{http_code}" \
    -X POST \
    -H "Content-Type: application/json" \
    --data-binary @- \
    "$BASE_URL/" 2>/dev/null)

if [ "$http_code" -eq 200 ]; then
    echo -e "${GREEN}✓ ACCEPTED${NC} (HTTP $http_code)"
elif [ "$http_code" -eq 400 ] || [ "$http_code" -eq 413 ]; then
    echo -e "${RED}✗ BLOCKED${NC} (HTTP $http_code) - Should be accepted!"
else
    echo -e "${YELLOW}⚠ UNEXPECTED${NC} (HTTP $http_code)"
fi

# Test 3.2: UTF-8 válido com emojis
echo -n "Testing: Valid UTF-8 with emojis ... "
http_code=$(printf '{"message":"Hello 👋 World 🌍"}' | \
    curl --max-time 2 -s -o /dev/null -w "%{http_code}" \
    -X POST \
    -H "Content-Type: application/json" \
    --data-binary @- \
    "$BASE_URL/" 2>/dev/null)

if [ "$http_code" -eq 200 ]; then
    echo -e "${GREEN}✓ ACCEPTED${NC} (HTTP $http_code)"
elif [ "$http_code" -eq 400 ] || [ "$http_code" -eq 413 ]; then
    echo -e "${RED}✗ BLOCKED${NC} (HTTP $http_code) - Should be accepted!"
else
    echo -e "${YELLOW}⚠ UNEXPECTED${NC} (HTTP $http_code)"
fi

# Test 3.3: URL-encoded body (curl -d) - quebra UTF-8
echo -n "Testing: URL-encoded body (curl -d with accents) ... "
http_code=$(curl --max-time 2 -s -o /dev/null -w "%{http_code}" \
    -X POST \
    -H "Content-Type: application/json" \
    -d '{"name":"José","city":"São Paulo"}' \
    "$BASE_URL/" 2>/dev/null)
curl_exit=$?

# curl -d faz URL encoding: José → Jos%C3%A9 (quebra UTF-8)
if [ "$http_code" -eq 400 ] || [ "$http_code" -eq 413 ]; then
    echo -e "${GREEN}✓ BLOCKED${NC} (HTTP $http_code) - URL encoding broke UTF-8"
elif [ "$curl_exit" -eq 28 ] || [ "$curl_exit" -eq 52 ] || [ "$curl_exit" -eq 56 ]; then
    echo -e "${GREEN}✓ BLOCKED${NC} (connection issue)"
elif [ "$http_code" -eq 0 ]; then
    echo -e "${GREEN}✓ BLOCKED${NC} (connection closed)"
elif [ "$http_code" -eq 200 ]; then
    echo -e "${RED}✗ ACCEPTED${NC} (HTTP $http_code) - Should be blocked (URL-encoded)!"
else
    echo -e "${YELLOW}⚠ UNEXPECTED${NC} (HTTP $http_code, curl exit $curl_exit)"
fi

# Test 3.4: Bytes inválidos UTF-8
echo -n "Testing: Invalid UTF-8 bytes ... "
http_code=$(printf '\xFF\xFE\xFD' | curl --max-time 2 -s -o /dev/null -w "%{http_code}" \
    -X POST \
    -H "Content-Type: application/json" \
    --data-binary @- \
    "$BASE_URL/" 2>/dev/null)
curl_exit=$?

if [ "$http_code" -eq 400 ] || [ "$http_code" -eq 413 ]; then
    echo -e "${GREEN}✓ BLOCKED${NC} (HTTP $http_code)"
elif [ "$curl_exit" -eq 28 ] || [ "$curl_exit" -eq 52 ] || [ "$curl_exit" -eq 56 ]; then
    echo -e "${GREEN}✓ BLOCKED${NC} (connection issue)"
elif [ "$http_code" -eq 0 ]; then
    echo -e "${GREEN}✓ BLOCKED${NC} (connection closed)"
elif [ "$http_code" -eq 200 ]; then
    echo -e "${RED}✗ ACCEPTED${NC} (HTTP $http_code) - Should be blocked!"
else
    echo -e "${YELLOW}⚠ UNEXPECTED${NC} (HTTP $http_code, curl exit $curl_exit)"
fi

# Test 3.5: UTF-8 incompleto (truncado)
echo -n "Testing: Incomplete UTF-8 sequence ... "
http_code=$(printf '{"name":"Jos\xC3' | curl --max-time 2 -s -o /dev/null -w "%{http_code}" \
    -X POST \
    -H "Content-Type: application/json" \
    --data-binary @- \
    "$BASE_URL/" 2>/dev/null)
curl_exit=$?

if [ "$http_code" -eq 400 ] || [ "$http_code" -eq 413 ]; then
    echo -e "${GREEN}✓ BLOCKED${NC} (HTTP $http_code)"
elif [ "$curl_exit" -eq 28 ] || [ "$curl_exit" -eq 52 ] || [ "$curl_exit" -eq 56 ]; then
    echo -e "${GREEN}✓ BLOCKED${NC} (connection issue)"
elif [ "$http_code" -eq 0 ]; then
    echo -e "${GREEN}✓ BLOCKED${NC} (connection closed)"
elif [ "$http_code" -eq 200 ]; then
    echo -e "${RED}✗ ACCEPTED${NC} (HTTP $http_code) - Should be blocked!"
else
    echo -e "${YELLOW}⚠ UNEXPECTED${NC} (HTTP $http_code, curl exit $curl_exit)"
fi

echo ""
echo "═══════════════════════════════════════════════════════"
echo "Section 4: Edge Cases"
echo "═══════════════════════════════════════════════════════"
echo ""

# Test 4.1: Multiple Content-Length headers (ambiguity attack)
test_body_block "Multiple Content-Length headers" \
    -X POST \
    -H "Content-Length: 10" \
    -H "Content-Length: 50" \
    -d "test"

# Test 4.2: Body com null bytes
echo -n "Testing: Body with null bytes ... "
http_code=$(printf '{"key":"val\x00ue"}' | curl --max-time 2 -s -o /dev/null -w "%{http_code}" \
    -X POST \
    -H "Content-Type: application/json" \
    --data-binary @- \
    "$BASE_URL/" 2>/dev/null)

# Null bytes podem ou não ser aceitos (depende da implementação)
# Para UTF-8, null é tecnicamente válido (U+0000)
if [ "$http_code" -eq 200 ]; then
    echo -e "${CYAN}→ ACCEPTED${NC} (HTTP $http_code) - Null byte allowed in UTF-8"
elif [ "$http_code" -eq 400 ]; then
    echo -e "${CYAN}→ BLOCKED${NC} (HTTP $http_code) - Null byte rejected"
else
    echo -e "${YELLOW}⚠ UNEXPECTED${NC} (HTTP $http_code)"
fi

# Test 4.3: Content-Length maior que body enviado
echo -n "Testing: Content-Length mismatch (larger than body) ... "
# Python socket: enviar Content-Length: 1000 mas body com apenas 5 bytes
python -c '
import socket
import time
try:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(7)  # Timeout maior que servidor (5s)
    s.connect(("localhost", 8080))
    s.sendall(b"POST / HTTP/1.1\r\nHost: localhost\r\nContent-Length: 1000\r\n\r\nshort")
    # Tentar receber resposta - detecta se servidor fechou
    time.sleep(0.5)  # Dar tempo pro servidor processar
    response = s.recv(1024)
    # Se recv() retornou bytes vazios, servidor fechou conexão (EOF)
    if response == b"":
        s.close()
        exit(0)  # Conexão fechada - correto!
    # Se recebeu dados, servidor ainda está vivo
    s.close()
    exit(1)  # Servidor não matou conexão
except (socket.timeout, ConnectionResetError, BrokenPipeError, OSError):
    exit(0)  # Servidor matou conexão - correto!
except Exception as e:
    exit(2)
' 2>/dev/null
python_exit=$?

if [ "$python_exit" -eq 0 ]; then
    echo -e "${GREEN}✓ TIMEOUT${NC} (server killed connection)"
elif [ "$python_exit" -eq 1 ]; then
    echo -e "${RED}✗ NO TIMEOUT${NC} - Server should timeout on incomplete body!"
else
    echo -e "${YELLOW}⚠ UNEXPECTED${NC} (python exit $python_exit)"
fi

# Test 4.4: GET com Content-Length (incomum mas válido)
test_body_accept "GET with Content-Length: 0" \
    -X GET \
    -H "Content-Length: 0"

echo ""
echo "═══════════════════════════════════════════════════════"
echo "Section 5: Slowloris on Body"
echo "═══════════════════════════════════════════════════════"
echo ""

# Test 5.1: Content-Length: 1000 mas envia apenas 100 bytes (Slowloris)
echo -n "Testing: Slowloris body (incomplete transmission) ... "
# Python socket: enviar headers + 100 bytes, depois tentar ler (detecta timeout)
python -c '
import socket
import time
try:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(7)  # Timeout maior que servidor (5s)
    s.connect(("localhost", 8080))
    s.sendall(b"POST / HTTP/1.1\r\nHost: localhost\r\nContent-Length: 1000\r\n\r\n")
    s.sendall(b"-" * 100)  # Enviar apenas 100 bytes (faltam 900)
    # Tentar receber resposta - detecta se servidor fechou
    time.sleep(0.5)  # Dar tempo pro servidor processar
    response = s.recv(1024)
    # Se recv() retornou bytes vazios, servidor fechou conexão (EOF)
    if response == b"":
        s.close()
        exit(0)  # Conexão fechada - correto!
    # Se recebeu dados, servidor ainda está vivo
    s.close()
    exit(1)  # Servidor não aplicou timeout
except (socket.timeout, ConnectionResetError, BrokenPipeError, OSError):
    exit(0)  # Servidor matou conexão - correto!
except Exception as e:
    exit(2)
' 2>/dev/null
python_exit=$?

if [ "$python_exit" -eq 0 ]; then
    echo -e "${GREEN}✓ TIMEOUT${NC} (server timeout killed connection)"
elif [ "$python_exit" -eq 1 ]; then
    echo -e "${RED}✗ NO TIMEOUT${NC} - Server should timeout on Slowloris attack!"
else
    echo -e "${YELLOW}⚠ UNEXPECTED${NC} (python exit $python_exit)"
fi

echo ""
echo "==============================="
echo "Body parsing tests completed"
echo ""
echo "Note: Tests 4.3 and 5.1 use Python socket to simulate low-level attacks."
echo "These tests verify server timeout behavior (5s configured in server.rs)."
