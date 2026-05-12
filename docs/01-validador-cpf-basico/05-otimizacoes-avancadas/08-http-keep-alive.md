# 5.8 HTTP Keep-Alive (Persistent Connections)

**Voltar para:** [Índice de Otimizações](05-otimizacoes-avancadas.md)

---

## 💭 Pensamento do Engenheiro

**Contexto:**

Na implementação básica do parser HTTP, usamos `Connection: close` forçado — cada request abre uma nova conexão TCP, processa, e fecha. Isso é **simples e seguro** (zero risco de vazamento de recursos), mas tem custo de performance significativo em cenários de múltiplas requisições.

**O problema:**

Cada nova conexão TCP requer **TCP handshake** (3-way handshake):

```
Cliente → SYN → Servidor         (1 RTT)
Cliente ← SYN-ACK ← Servidor     (1 RTT)
Cliente → ACK → Servidor         (0.5 RTT)
= Total: ~1.5 RTT de overhead
```

RTT (Round-Trip Time):

- Localhost: ~0.1ms
- Mesma cidade: ~10ms
- Intercontinental: ~200ms

**Com Connection: close (padrão básico):**

- 100 requests = 100 handshakes = 100 × 1.5 RTT = **150 RTTs desperdiçados**
- Cliente intercontinental: 150 × 200ms = **30 segundos só em handshakes**

**Com HTTP Keep-Alive:**

- 100 requests = 1 handshake = **1.5 RTT total**
- Cliente intercontinental: 1 × 200ms = **0.3 segundos**
- **Ganho: 100x menos latência**

---

## Como Funciona

Em vez de fechar a conexão após cada response, o servidor mantém o socket aberto e espera próxima request:

```rust
fn handle_connection(mut stream: TcpStream, config: &ServerConfig) {
    loop {  // ← Loop interno: múltiplas requests na mesma conexão
        match HttpRequest::parse(&mut reader, config) {
            Ok(req) => {
                let response = route_request(req);
                send_response(&mut stream, response)?;

                // Se cliente pedir Connection: close, sair do loop
                if req.headers.get("connection") == Some(&"close".to_string()) {
                    break;
                }
            }
            Err(_) => break,  // Erro = fechar conexão
        }
    }
}
```

**Fluxo visual:**

```
Request 1 → Process → Response 1 → (socket mantém aberto)
Request 2 → Process → Response 2 → (socket mantém aberto)
Request 3 → Process → Response 3 → (socket mantém aberto)
...
Connection: close → (fechar socket)
```

---

## Impacto em Performance

### Cenário Real: Frontend com Validador de CPF

**Sem keep-alive:**

```
Usuário carrega página:
1. GET /index.html      → handshake (20ms) + request (5ms) = 25ms
2. GET /style.css       → handshake (20ms) + request (5ms) = 25ms
3. GET /script.js       → handshake (20ms) + request (5ms) = 25ms
4. POST /api/validate   → handshake (20ms) + request (5ms) = 25ms
Total: 100ms
```

**Com keep-alive:**

```
Usuário carrega página:
1. GET /index.html      → handshake (20ms) + request (5ms) = 25ms
2. GET /style.css       → request (5ms) = 5ms (reusa conexão)
3. GET /script.js       → request (5ms) = 5ms (reusa conexão)
4. POST /api/validate   → request (5ms) = 5ms (reusa conexão)
Total: 40ms
```

**Resultado: 2.5x mais rápido** (de 100ms para 40ms)

Em conexões intercontinentais (RTT alto), o ganho pode chegar a **10-100x**.

---

## Proteções Necessárias

Keep-alive introduz complexidade de state management. Proteções críticas:

### 1. Timeout entre Requests

Se cliente fica idle (conectado mas sem enviar nada), precisa desconectar:

```rust
// Timeout de 30s para esperar próxima request
stream.set_read_timeout(Some(Duration::from_secs(30)))?;
```

**Motivo:** Prevenir esgotamento de file descriptors com conexões idle.

### 2. Limite de Requests por Conexão

Evitar que uma única conexão monopolize recursos:

```rust
const MAX_REQUESTS_PER_CONNECTION: usize = 100;

if request_count >= MAX_REQUESTS_PER_CONNECTION {
    // Enviar "Connection: close" e fechar gracefully
    break;
}
```

**Motivo:** Forçar reconnect periódico ajuda a distribuir carga e limpar state.

### 3. Detectar Connection: close

Respeitar quando cliente quer fechar:

```rust
if req.headers.get("connection").map(|v| v.as_str()) == Some("close") {
    break;
}
```

**Motivo:** Protocolo HTTP 1.1 permite ambos os lados requisitarem fechamento.

---

## Implementação

### Passo 1: Atualizar HttpResponse

**Remover `Connection: close` forçado:**

```rust
// ANTES (01.4-response-builder.md):
format!(
    "HTTP/1.1 {} {}\r\n...\r\nConnection: close\r\n\r\n{}",
    status_code, status_text, body
)

// DEPOIS:
format!(
    "HTTP/1.1 {} {}\r\n...\r\nConnection: keep-alive\r\n\r\n{}",
    status_code, status_text, body
)
```

### Passo 2: Loop Interno no handle_connection

**Arquivo:** `backend/shared/src/http/server.rs`

```rust
use std::time::Duration;
use crate::ServerConfig;
use crate::http::request::HttpRequest;

fn handle_connection(mut stream: TcpStream, config: &ServerConfig) {
    // Configurar timeouts iniciais (parse da request)
    stream.set_read_timeout(Some(Duration::from_secs(5))).unwrap();
    stream.set_write_timeout(Some(Duration::from_secs(5))).unwrap();

    let mut request_count = 0;
    const MAX_REQUESTS_PER_CONNECTION: usize = 100;

    loop {
        // Após primeira request, aumentar timeout para esperar próxima
        if request_count > 0 {
            stream.set_read_timeout(Some(Duration::from_secs(30))).unwrap();
        }

        let mut reader = BufReader::new(&mut stream);

        match HttpRequest::parse(&mut reader, config) {
            Ok(req) => {
                request_count += 1;

                // Processar request
                let response = route_request(req);

                // Enviar response
                if let Err(e) = stream.write_all(&response.to_bytes()) {
                    eprintln!("Failed to send response: {}", e);
                    break;
                }
                stream.flush().ok();

                // Verificar condições de fechamento
                if req.headers.get("connection").map(|v| v.as_str()) == Some("close") {
                    break;  // Cliente pediu para fechar
                }

                if request_count >= MAX_REQUESTS_PER_CONNECTION {
                    // Enviar última response com Connection: close
                    // (implementação específica depende da sua struct HttpResponse)
                    break;
                }
            }
            Err(e) => {
                eprintln!("❌ Parse error: {}", e);
                break;  // Parse error = fechar conexão
            }
        }
    }

    // Fechar gracefully
    stream.shutdown(std::net::Shutdown::Both).ok();
}
```

### Passo 3: Detectar Timeout vs Parse Error

Diferenciar timeout de idle (normal) de parse error (malicioso):

```rust
match HttpRequest::parse(&mut reader, config) {
    Ok(req) => { /* processar */ }
    Err(e) => {
        // Se for timeout após primeira request = idle normal
        if request_count > 0 && is_timeout_error(&e) {
            // Fechar silenciosamente (cliente foi embora)
            break;
        } else {
            // Parse error real = logar
            eprintln!("❌ Parse error: {}", e);
            break;
        }
    }
}

fn is_timeout_error(e: &str) -> bool {
    e.contains("timed out") || e.contains("10060")
}
```

---

## Trade-offs

### ✅ Vantagens

- **Performance brutal:** 10-100x redução de latência em múltiplas requests
- **Experiência do usuário:** Páginas web carregam muito mais rápido
- **Eficiência de rede:** Menos overhead de handshakes
- **Padrão da indústria:** HTTP/1.1 espera keep-alive por padrão

### ⚠️ Desvantagens

- **Complexidade:** Loop interno, state management, múltiplos timeouts
- **Recursos:** Conexões idle ocupam file descriptors até timeout
- **Debugging:** Mais difícil rastrear qual request causou erro
- **Memory leaks:** Se esquecer de limpar state entre requests

---

## Quando Implementar

### ✅ Implementar keep-alive se:

- Frontend faz **múltiplas chamadas** na mesma sessão
- Servindo arquivos estáticos (HTML + CSS + JS + imagens = 5-10 requests)
- API recebe bursts de requests do mesmo cliente
- Latência de rede é alta (clientes remotos)
- Quer performance competitiva com servidores modernos

### ❌ Pular keep-alive se:

- **Webhooks:** 1 request esporádico por conexão
- **Cron jobs:** Chamadas isoladas com minutos/horas de intervalo
- **Aprendizado:** Focado em entender parsing HTTP básico
- **MVP simples:** Validador de CPF com 1 request por sessão

---

## Testes de Validação

### Teste 1: Verificar Keep-Alive Funcionando

```bash
# Fazer múltiplas requests na mesma conexão
curl -v http://localhost:8080/index.html http://localhost:8080/style.css

# Deve ver:
# < Connection: keep-alive
# * Re-using existing connection! 0 to host localhost
```

### Teste 2: Respeitar Connection: close

```bash
curl -v -H "Connection: close" http://localhost:8080/

# Deve ver:
# < Connection: close
# * Closing connection 0
```

### Teste 3: Timeout de Idle

```bash
# Conectar e ficar idle por 35 segundos
python -c "
import socket, time
s = socket.socket()
s.connect(('localhost', 8080))
print('Conectado, esperando 35s...')
time.sleep(35)
s.sendall(b'GET / HTTP/1.1\r\n\r\n')
print(s.recv(1024))
"

# Esperado: Erro após 30s (timeout de idle)
```

### Teste 4: Limite de Requests

```bash
# Fazer 101 requests na mesma conexão
for i in {1..101}; do
    echo "Request $i"
    curl -s http://localhost:8080/ > /dev/null
done

# Servidor deve forçar reconnect após 100 requests
```

### Teste 5: Monitorar File Descriptors

```bash
# Linux/Mac
watch -n 1 'lsof -p $(pgrep api) | wc -l'

# Fazer requests e observar:
# - FDs aumentam com conexões keep-alive
# - FDs diminuem após timeout de idle
# - Não devem crescer infinitamente
```

---

## Observabilidade

Adicionar métricas para monitorar comportamento de keep-alive:

```rust
struct ConnectionStats {
    total_connections: AtomicUsize,
    reused_connections: AtomicUsize,
    requests_per_connection: Vec<usize>,
}

// No handle_connection:
if request_count > 1 {
    stats.reused_connections.fetch_add(1, Ordering::Relaxed);
}

// Ao fechar conexão:
stats.requests_per_connection.push(request_count);
```

**Métricas úteis:**

- Taxa de reuso de conexão: `reused / total`
- Média de requests por conexão: `sum(requests) / total`
- Distribuição de lifetimes de conexão

---

## Comparação com Alternativas

### HTTP/1.1 Keep-Alive (este guia)

- ✅ Simples de implementar
- ✅ Compatível com todos os clientes
- ⚠️ Limitado a 1 request por vez por conexão
- ⚠️ Head-of-line blocking

### HTTP/2 Multiplexing

- ✅ Múltiplas requests simultâneas na mesma conexão
- ✅ Elimina head-of-line blocking
- ❌ Complexo (requer crate como `h2`)
- ❌ Não suportado por clientes antigos

### HTTP/3 (QUIC)

- ✅ Ainda mais rápido (sem TCP handshake)
- ✅ Melhor em redes ruins (loss recovery)
- ❌ Muito complexo (requer `quinn` crate)
- ❌ Suporte limitado em clientes

**Recomendação para este projeto:** HTTP/1.1 Keep-Alive oferece 80% dos ganhos com 20% da complexidade.

---

## Checklist de Implementação

- [ ] **REFATORAR:** Remover `Connection: close` forçado do `HttpResponse::to_bytes()`
- [ ] **ADICIONAR:** Header `Connection: keep-alive` nas responses
- [ ] **LOOP INTERNO:** Envolver lógica de request/response em loop
- [ ] **CONTADOR:** Rastrear `request_count` por conexão
- [ ] **TIMEOUT IDLE:** Configurar `set_read_timeout(30s)` após primeira request
- [ ] **LIMITE:** Implementar `MAX_REQUESTS_PER_CONNECTION = 100`
- [ ] **DETECÇÃO:** Verificar header `Connection: close` do cliente
- [ ] **GRACEFUL SHUTDOWN:** Adicionar `stream.shutdown(Both)` ao sair do loop
- [ ] **TESTE:** Validar keep-alive com curl (ver "Testes de Validação" acima)
- [ ] **TESTE:** Validar que `Connection: close` funciona
- [ ] **TESTE:** Validar timeout de idle
- [ ] **MONITORAMENTO:** Adicionar logging de reuso de conexões
- [ ] **DOCUMENTAÇÃO:** Atualizar [99-decisoes-metricas.md](../99-decisoes-metricas.md) com resultados de benchmark

---

## Referências

- [RFC 7230 Section 6.3: Persistence](https://datatracker.ietf.org/doc/html/rfc7230#section-6.3)
- [MDN: Connection management in HTTP/1.x](https://developer.mozilla.org/en-US/docs/Web/HTTP/Connection_management_in_HTTP_1.x)
- [Cloudflare: What is HTTP keep-alive?](https://www.cloudflare.com/learning/performance/http-keep-alive/)

---

**Anterior:** [07-drenagem-buffer-residual.md](07-drenagem-buffer-residual.md)
**Índice:** [README.md](../../README.md)
