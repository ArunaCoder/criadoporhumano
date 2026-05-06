# 🔒 Curl Test Commands — Security Testing Cheatsheet

**Objetivo:** Comandos prontos para testar segurança do servidor HTTP Rust.

**Pré-requisito:** Servidor rodando em `http://localhost:8080`

```bash
# Terminal 1: Iniciar servidor
cd backend/api
cargo run

# Terminal 2: Executar comandos abaixo
```

---

## ✅ Requisições Legítimas (Baseline)

### GET simples

```bash
curl http://localhost:8080/index.html
```

### GET com verbose (ver headers)

```bash
curl -v http://localhost:8080/index.html
```

### GET com headers customizados

```bash
curl -H "Content-Type: application/json" -H "X-Custom-Header: test" http://localhost:8080/index.html
```

### POST com JSON

```bash
curl -X POST -H "Content-Type: application/json" -d '{"name":"test","value":123}' http://localhost:8080/api/data
```

---

## 🚨 Path Traversal Attacks

### Ataque clássico (tentar acessar arquivo fora de public/)

```bash
curl --path-as-is http://localhost:8080/../secret.txt
```

### Múltiplos níveis de escape

```bash
curl --path-as-is http://localhost:8080/../../../etc/passwd
```

### Double encoding bypass attempt

```bash
curl http://localhost:8080/%2e%2e%2fsecret.txt
```

### Path com barras duplas

```bash
curl http://localhost:8080//etc/passwd
```

### Normalização com ./././

```bash
curl --path-as-is http://localhost:8080/./././secret.txt
```

### Tentar escapar e voltar (ainda inválido)

```bash
curl --path-as-is http://localhost:8080/../public/index.html
```

### Windows path separators (se aplicável)

```bash
curl --path-as-is "http://localhost:8080/..\secret.txt"
```

---

## 💣 Header Bomb Attacks

### Quantidade massiva de headers (testar MAX_HEADERS)

```bash
curl -H "X-Test-1: value" -H "X-Test-2: value" -H "X-Test-3: value" \
     -H "X-Test-4: value" -H "X-Test-5: value" -H "X-Test-6: value" \
     -H "X-Test-7: value" -H "X-Test-8: value" -H "X-Test-9: value" \
     -H "X-Test-10: value" http://localhost:8080/
```

### Header gigante (testar MAX_LINE_SIZE)

```bash
curl -H "X-Giant: $(python3 -c 'print("A"*10000)')" http://localhost:8080/
```

### Combinação: múltiplos headers gigantes

```bash
curl -H "X-Giant-1: $(python3 -c 'print("A"*8000)')" \
     -H "X-Giant-2: $(python3 -c 'print("B"*8000)')" \
     http://localhost:8080/
```

### Header com espaços excessivos (testar trim)

```bash
curl -H "X-Custom-Header:   spaced value   " http://localhost:8080/
```

---

## 🐌 Slowloris Simulation

### Enviar request lentamente (testar timeout)

```bash
(echo -n "GET / HTTP/1.1\r\n"; sleep 10; echo "Host: localhost\r\n\r\n") | nc localhost 8080
```

### Request incompleta (nunca termina)

```bash
(echo -n "GET / HTTP/1.1\r\n"; sleep 30) | nc localhost 8080
```

### Headers lentos

```bash
(echo -n "GET / HTTP/1.1\r\nHost: localhost\r\n"; sleep 6; echo "User-Agent: test\r\n\r\n") | nc localhost 8080
```

---

## ⚔️ Method Attacks

### Método não permitido

```bash
curl -X DELETE http://localhost:8080/index.html
```

### Método inválido

```bash
curl -X HACK http://localhost:8080/
```

### PUT (se não implementado)

```bash
curl -X PUT -d "malicious data" http://localhost:8080/index.html
```

### TRACE (potencial XST attack)

```bash
curl -X TRACE http://localhost:8080/
```

---

## 📦 Body Attacks

### Body gigante (testar MAX_BODY_SIZE)

```bash
curl -X POST -H "Content-Type: application/json" \
     -d "$(python3 -c 'print("{"*10000)')" \
     http://localhost:8080/api/data
```

### Content-Length mentiroso (maior que real)

```bash
printf "POST / HTTP/1.1\r\nHost: localhost:8080\r\nContent-Length: 999999\r\n\r\nshort" | nc localhost 8080
```

### POST sem Content-Type

```bash
curl -X POST -d '{"test":"data"}' http://localhost:8080/api/data
```

---

## 🔍 Protocol Attacks

### HTTP/0.9 (versão antiga)

```bash
printf "GET /\r\n\r\n" | nc localhost 8080
```

### HTTP/2.0 (não suportada)

```bash
printf "GET / HTTP/2.0\r\nHost: localhost\r\n\r\n" | nc localhost 8080
```

### Request line malformada (faltando partes)

```bash
printf "GET\r\n\r\n" | nc localhost 8080
```

### Múltiplos espaços na request line

```bash
printf "GET    /    HTTP/1.1\r\nHost: localhost\r\n\r\n" | nc localhost 8080
```

---

## 🧪 Edge Cases

### Path vazio

```bash
curl http://localhost:8080/
```

### Path apenas com /

```bash
curl http://localhost:8080//
```

### Query string (se implementado)

```bash
curl "http://localhost:8080/index.html?param=value&test=123"
```

### Fragment identifier (ignorado por servidor)

```bash
curl "http://localhost:8080/index.html#section"
```

### URL encoding normal (deve funcionar)

```bash
curl "http://localhost:8080/test%20file.html"
```

---

## 📊 Load Testing (Apache Bench)

### Teste de carga básico

```bash
ab -n 1000 -c 10 http://localhost:8080/index.html
```

### Teste de carga agressivo

```bash
ab -n 10000 -c 100 http://localhost:8080/index.html
```

### Teste com POST

```bash
ab -n 1000 -c 10 -p payload.json -T application/json http://localhost:8080/api/data
```

---

## 🎯 Debug Mode Tests (se --features debug-http)

### Testar captura de raw bytes

```bash
curl -v -H "Content-Type: application/json" \
     -H "X-Custom:   spaces   " \
     -H "Authorization: Bearer_escapa_gitleaks_ token123" \
     http://localhost:8080/index.html

# Verificar: backend/api/debug_request.txt
cat backend/api/debug_request.txt
```

---

## 📝 Resultados Esperados

### ✅ Devem FUNCIONAR:

- GET/POST legítimos
- Headers normais
- Paths válidos dentro de public/

### ❌ Devem FALHAR (400 Bad Request):

- Path traversal (qualquer variação)
- Headers gigantes (>8KB por linha)
- Muitos headers (>100)
- Métodos não permitidos
- Versões HTTP inválidas
- Body muito grande (>8KB)

### ⏱️ Devem TIMEOUT (~5s):

- Slowloris attacks
- Requests incompletas
- Headers lentos

---

## 🛠️ Ferramentas Úteis

### Netcat (nc) — Raw TCP

```bash
# Enviar request manual
echo -e "GET / HTTP/1.1\r\nHost: localhost\r\n\r\n" | nc localhost 8080
```

### Python3 — Gerar payloads

```bash
# String gigante
python3 -c 'print("A"*10000)'

# JSON malformado
python3 -c 'print("{"*1000)'
```

### Watch — Monitorar logs

```bash
# Terminal separado para ver logs do servidor
tail -f /caminho/para/logs
```

---

## 🚀 Automação

### Script bash para rodar todos os testes de path traversal

```bash
#!/bin/bash
echo "=== Path Traversal Tests ==="
for path in "/../secret.txt" "/../../../etc/passwd" "/./././secret.txt" "//etc/passwd"; do
    echo "Testing: $path"
    curl --path-as-is -s -o /dev/null -w "%{http_code}\n" "http://localhost:8080$path"
done
```

### Script para testar headers

```bash
#!/bin/bash
echo "=== Header Tests ==="
for i in {1..150}; do
    HEADERS="$HEADERS -H \"X-Test-$i: value\""
done
eval "curl $HEADERS http://localhost:8080/"
```

---

**Autor:** Security Testing Framework
**Versão:** 1.0
**Última atualização:** 2026-05-06
